import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/storage/birth_info_store.dart';
import '../../shared/widgets/pastel_pill_button.dart';
import '../../shared/widgets/pastel_toggle_row.dart';
import 'birth_info.dart';

enum _Calendar { solar, lunar }

/// 생년월일시 정보 입력 화면.
/// 참고: docs/mockups/01-pastel-cute.html STEP 2
class BirthInputScreen extends StatefulWidget {
  const BirthInputScreen({super.key});

  @override
  State<BirthInputScreen> createState() => _BirthInputScreenState();
}

class _BirthInputScreenState extends State<BirthInputScreen> {
  DateTime _birthDate = DateTime(1998, 8, 15);
  TimeOfDay _birthTime = const TimeOfDay(hour: 14, minute: 30);
  bool _timeUnknown = false;
  _Calendar _calendar = _Calendar.solar;
  Gender _gender = Gender.female;
  final _nameController = TextEditingController();
  final _birthPlaceController = TextEditingController();

  /// `_submit()`의 `BirthInfoStore.save()` await 구간에서 버튼을 빠르게 두 번
  /// 연속으로 누르면(실제 기기에서 재현되는 상황), 첫 호출이 아직 끝나지 않은 채
  /// 두 번째 호출이 그대로 들어와 calculating 라우트가 중복으로 push되는 실제 버그가
  /// 있었다 — 제출이 진행 중인 동안 재진입을 막는다.
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime,
    );
    if (picked != null) {
      setState(() => _birthTime = picked);
    }
  }

  String get _formattedDate =>
      '${_birthDate.year}.${_birthDate.month.toString().padLeft(2, '0')}.${_birthDate.day.toString().padLeft(2, '0')}';

  String get _formattedTime {
    final period = _birthTime.hour < 12 ? '오전' : '오후';
    final hour12 = _birthTime.hourOfPeriod == 0 ? 12 : _birthTime.hourOfPeriod;
    return '$period $hour12시 ${_birthTime.minute.toString().padLeft(2, '0')}분';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    final trimmedName = _nameController.text.trim();
    final trimmedBirthPlace = _birthPlaceController.text.trim();
    final birthInfo = BirthInfo(
      date: _birthDate,
      hour: _timeUnknown ? null : _birthTime.hour,
      minute: _timeUnknown ? null : _birthTime.minute,
      isLunar: _calendar == _Calendar.lunar,
      name: trimmedName.isEmpty ? null : trimmedName,
      birthPlace: trimmedBirthPlace.isEmpty ? null : trimmedBirthPlace,
      gender: _gender,
    );
    // 저장은 "다음에 열 때 바로 보여주기 위한" 부가 기능일 뿐이므로, 저장이 실패해도
    // (플랫폼 채널 오류 등) 지금 이 세션의 진행은 막지 않는다.
    try {
      await BirthInfoStore.save(birthInfo);
    } catch (_) {
      // 무시 — 다음에 앱을 열면 다시 입력하면 된다.
    }
    if (!mounted) return;
    // pushNamed()가 반환하는 Future는 이 화면 위에 올라간 라우트가 나중에 pop되어
    // 이 화면으로 돌아왔을 때 비로소 완료된다 — 그 시점에 맞춰 플래그를 되돌려야,
    // 제출 후 뒤로가기로 이 화면에 돌아왔을 때 "사주 보러가기"가 계속 먹통이 되지
    // 않는다(한 번 true가 된 뒤로 다시 false가 될 일이 없던 실제 버그였음).
    await Navigator.of(context).pushNamed(AppRoutes.calculating, arguments: birthInfo);
    if (mounted) {
      _isSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('생년월일시를 알려주세요')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            _FieldLabel('이름 (선택)'),
            const SizedBox(height: 8),
            // hintText만으로는 스크린 리더가 "예: 민지"를 필드 이름으로 잘못 읽는다(필드가
            // 비어 있을 때 hintText가 시맨틱 label로 그대로 노출됨 — 실제 확인함). 위의
            // _FieldLabel은 시각적으로만 보이고 이 TextField와 시맨틱으로 연결되지 않으므로,
            // excludeSemantics 없는 Semantics(label:)로 감싸 "이름 (선택)"과 병합되게 한다.
            Semantics(
              label: '이름 (선택)',
              child: TextField(
                controller: _nameController,
                maxLength: 20,
                // 공유 카드(share_card.dart)가 폭 고정 레이아웃이라, 이름이 너무 길면
                // "$name의 사주팔자" 헤더가 카드 높이를 넘겨 잘리거나 겹칠 수 있다 — 입력 단계에서 제한.
                decoration: const InputDecoration(hintText: '예: 민지', counterText: ''),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '이름 없이도 괜찮아요 →',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _FieldLabel('태어난 날짜'),
            const SizedBox(height: 8),
            PastelPillButton(label: _formattedDate, onTap: _pickDate),
            const SizedBox(height: 20),
            PastelToggleRow<_Calendar>(
              value: _calendar,
              options: const {_Calendar.solar: '양력', _Calendar.lunar: '음력'},
              onChanged: (v) => setState(() => _calendar = v),
              // 이 토글은 위의 "태어난 날짜" _FieldLabel과 달리 전용 라벨이 따로
              // 없어(목업도 같은 구조), 스크린 리더가 순서대로 안 읽고 곧장 이
              // 버튼으로 이동하면 "양력/음력"이 뭘 고르는 건지 맥락이 없었다.
              semanticLabel: '양력 또는 음력',
            ),
            const SizedBox(height: 20),
            _FieldLabel('태어난 시간'),
            const SizedBox(height: 8),
            PastelPillButton(
              label: _timeUnknown ? '시간 모름' : _formattedTime,
              onTap: _timeUnknown ? null : _pickTime,
            ),
            const SizedBox(height: 8),
            // CheckboxListTile을 써서 체크박스뿐 아니라 "태어난 시간을 몰라요" 글자를 눌러도
            // 반응하게 한다 (터치 영역이 넓어져 접근성/사용성 모두 개선됨).
            CheckboxListTile(
              value: _timeUnknown,
              onChanged: (v) => setState(() => _timeUnknown = v ?? false),
              activeColor: AppColors.accent,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              // 목업(`.check-row`)은 12px인데 지금까지 기본 크기였다(2026-07-06 대조 발견).
              title: const Text(
                '태어난 시간을 몰라요',
                style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel('성별'),
            const SizedBox(height: 8),
            PastelToggleRow<Gender>(
              value: _gender,
              options: const {Gender.female: '여성', Gender.male: '남성'},
              onChanged: (v) => setState(() => _gender = v),
              semanticLabel: '성별 선택',
            ),
            const SizedBox(height: 20),
            _FieldLabel('태어난 곳 (선택)'),
            const SizedBox(height: 8),
            Semantics(
              label: '태어난 곳 (선택)',
              child: TextField(
                controller: _birthPlaceController,
                maxLength: 30,
                decoration: const InputDecoration(hintText: '예: 서울특별시', counterText: ''),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '건너뛰어도 괜찮아요 →',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('사주 보러가기 🔮'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppColors.inkSoft,
      ),
    );
  }
}

