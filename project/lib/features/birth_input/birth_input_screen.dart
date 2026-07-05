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
    final trimmedName = _nameController.text.trim();
    final trimmedBirthPlace = _birthPlaceController.text.trim();
    final birthInfo = BirthInfo(
      date: _birthDate,
      hour: _timeUnknown ? null : _birthTime.hour,
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
    Navigator.of(context).pushNamed(AppRoutes.calculating, arguments: birthInfo);
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
              title: const Text(
                '태어난 시간을 몰라요',
                style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel('성별'),
            const SizedBox(height: 8),
            PastelToggleRow<Gender>(
              value: _gender,
              options: const {Gender.female: '여성', Gender.male: '남성'},
              onChanged: (v) => setState(() => _gender = v),
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

