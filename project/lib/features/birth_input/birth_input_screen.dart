import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/storage/birth_info_store.dart';
import '../../core/storage/deep_dive_info_store.dart';
import '../../shared/widgets/pastel_pill_button.dart';
import '../../shared/widgets/pastel_toggle_row.dart';
import '../deep_dive/deep_dive_info.dart';
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

  // MBTI는 원래 별도 화면(심층 분석 입력)에서 물었지만, 사용자 정보를 한 번에 받는 편이
  // 자연스러워 이 화면으로 옮겼다(2026-07-07, 사용자 요청) — 모르는 사람이 많으므로
  // "태어난 시간을 몰라요"와 같은 방식으로 기본은 꺼둔 채 체크해야 네 축이 보인다.
  bool _knowsMbti = false;
  MbtiEi _ei = MbtiEi.e;
  MbtiSn _sn = MbtiSn.s;
  MbtiTf _tf = MbtiTf.t;
  MbtiJp _jp = MbtiJp.j;

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
    // 다이얼로그가 떠 있는 동안(await 구간) 이 화면이 사라질 수 있다 — 다른 비동기
    // 메서드(_submit() 등)와 같은 이유로 방어한다(2026-07-11 발견, 이 화면의 두 피커
    // 메서드만 이 가드가 빠져 있었음 — 정확한 경쟁 상태 재현은 위젯 테스트로는
    // 결정적으로 만들기 어려워 값 검증 테스트 없이 기존 관례에 맞춰 방어만 추가함).
    if (!mounted) return;
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime,
    );
    if (!mounted) return;
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
    // MBTI는 여기서 미리 저장해두고, 관심사는 deep_dive_input_screen.dart의 기존
    // 기본값(전체 선택)으로 채워둔다 — 사용자가 나중에 상세 리포트의 "MBTI·관심사로
    // 심층 분석 받기"에 들어가면 이 MBTI를 그대로 이어받고 관심사만 고르면 된다.
    // **2026-07-08 버그 수정**: 원래는 이 저장이 항상 관심사를 "전체 선택"으로
    // 덮어썼는데, 사주 결과 화면은 이 화면이 여전히 스택 아래에 남아 있어(계산 중
    // 화면만 pushReplacement로 교체됨) Flutter가 AppBar에 자동으로 뒤로 가기 버튼을
    // 붙여준다 — "다시 입력하기"(명시적으로 두 스토어를 함께 지움)를 거치지 않고
    // 이 자동 뒤로 가기로 돌아와 재제출하면, 이미 심층 분석에서 관심사를 좁혀뒀어도
    // 조용히 전체 선택으로 되돌아가는 실제 데이터 유실 버그였다. 기존에 저장된
    // 관심사가 있으면 그대로 유지하고, 첫 방문(저장된 값 없음)일 때만 전체 선택으로
    // 채운다.
    try {
      final existing = await DeepDiveInfoStore.load();
      await DeepDiveInfoStore.save(
        DeepDiveInfo(
          mbti: _knowsMbti ? Mbti(ei: _ei, sn: _sn, tf: _tf, jp: _jp) : null,
          interests: existing?.interests ?? {...Interest.values},
        ),
      );
    } catch (_) {
      // 무시 — 상세 리포트의 심층 분석에서 다시 이어받으면 된다.
    }
    if (!mounted) return;
    // **2026-07-13 변경**: 이전에는 pushNamed()를 써서 이 화면이 스택에 그대로 남아있었다
    // — calculating_screen.dart가 이미 pushReplacementNamed로 자기 자신을 결과 화면으로
    // 교체하지만, 그 아래 이 입력 화면은 남아 있어서 계산 중 화면에서 기기 뒤로가기를
    // 누르면 다시 이 입력 화면으로 돌아올 수 있었다(제출 직후 뒤로가기 한 번으로 입력
    // 내용이 그대로 남은 채 재진입 가능). pushReplacementNamed로 바꿔 이 화면 자체를
    // 스택에서 제거하면 계산 중 화면에서 뒤로가기를 눌러도 이 화면으로 돌아올 수 없다.
    // 이 화면이 스택에서 사라지므로 아래로 다시 돌아와 _isSubmitting을 되돌릴 일이
    // 없어졌다(제출이 진행 중인 동안 재진입을 막는 더블탭 가드 자체는 여전히 유효).
    Navigator.of(context).pushReplacementNamed(AppRoutes.calculating, arguments: birthInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('생년월일시를 알려주세요')),
      body: SafeArea(
        child: ListView(
          // 목업(`.screen-body`)의 기본 padding은 14px 20px 18px인데 지금까지는
          // 24/8/24/24였다(2026-07-07 대조 발견).
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
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
            // 목업(`.skip`)은 11px/font-weight 700인데 지금까지는 13px에 기본 굵기였다
            // (2026-07-07 대조 발견) — 아래 "건너뛰어도 괜찮아요 →"(태어난 곳)와 같은
            // 안내 문구 패턴이라 같은 스타일로 통일한다.
            const Text(
              '이름 없이도 괜찮아요 →',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            // 목업(`.field`)은 margin-bottom:14px인데 지금까지는 20px이었다
            // (2026-07-07 대조 발견) — 이하 필드 그룹 사이 간격 전부 동일하게 수정.
            const SizedBox(height: 14),
            _FieldLabel('태어난 날짜'),
            const SizedBox(height: 8),
            PastelPillButton(label: _formattedDate, onTap: _pickDate),
            const SizedBox(height: 14),
            PastelToggleRow<_Calendar>(
              value: _calendar,
              options: const {_Calendar.solar: '양력', _Calendar.lunar: '음력'},
              onChanged: (v) => setState(() => _calendar = v),
              // 이 토글은 위의 "태어난 날짜" _FieldLabel과 달리 전용 라벨이 따로
              // 없어(목업도 같은 구조), 스크린 리더가 순서대로 안 읽고 곧장 이
              // 버튼으로 이동하면 "양력/음력"이 뭘 고르는 건지 맥락이 없었다.
              semanticLabel: '양력 또는 음력',
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            _FieldLabel('성별'),
            const SizedBox(height: 8),
            PastelToggleRow<Gender>(
              value: _gender,
              options: const {Gender.female: '여성', Gender.male: '남성'},
              onChanged: (v) => setState(() => _gender = v),
              semanticLabel: '성별 선택',
            ),
            const SizedBox(height: 14),
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
            // 목업(`.skip`)은 11px/font-weight 700인데 지금까지는 13px에 기본 굵기였다
            // (2026-07-07 대조 발견).
            const Text(
              '건너뛰어도 괜찮아요 →',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            // MBTI 입력 — deep_dive_input_screen.dart에 있던 것을 그대로 옮겨왔다
            // (2026-07-07, 사용자 요청). 모르면 체크하지 않아도 되는 선택 항목.
            CheckboxListTile(
              value: _knowsMbti,
              onChanged: (v) => setState(() => _knowsMbti = v ?? false),
              activeColor: AppColors.accent,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'MBTI를 알고 있어요',
                style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            if (_knowsMbti) ...[
              const SizedBox(height: 8),
              PastelToggleRow<MbtiEi>(
                value: _ei,
                options: const {MbtiEi.e: 'E · 외향', MbtiEi.i: 'I · 내향'},
                onChanged: (v) => setState(() => _ei = v),
                semanticLabel: '외향 또는 내향',
              ),
              const SizedBox(height: 8),
              PastelToggleRow<MbtiSn>(
                value: _sn,
                options: const {MbtiSn.s: 'S · 감각', MbtiSn.n: 'N · 직관'},
                onChanged: (v) => setState(() => _sn = v),
                semanticLabel: '감각 또는 직관',
              ),
              const SizedBox(height: 8),
              PastelToggleRow<MbtiTf>(
                value: _tf,
                options: const {MbtiTf.t: 'T · 사고', MbtiTf.f: 'F · 감정'},
                onChanged: (v) => setState(() => _tf = v),
                semanticLabel: '사고 또는 감정',
              ),
              const SizedBox(height: 8),
              PastelToggleRow<MbtiJp>(
                value: _jp,
                options: const {MbtiJp.j: 'J · 판단', MbtiJp.p: 'P · 인식'},
                onChanged: (v) => setState(() => _jp = v),
                semanticLabel: '판단 또는 인식',
              ),
            ],
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

