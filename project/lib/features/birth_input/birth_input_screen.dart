import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/storage/birth_info_store.dart';
import '../../core/storage/deep_dive_info_store.dart';
import '../../shared/widgets/pastel_checkbox_row.dart';
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
  // **2026-07-17 버그 수정**: 이전에는 두 값이 처음부터 유효한 기본값(1998-08-15,
  // 14:30)으로 채워져 있었고 제출 버튼도 폼 상태와 무관하게 항상 활성화돼 있었다 —
  // 사용자가 아무 필드도 건드리지 않고 "사주 보러가기"만 눌러도 그대로 결과 화면까지
  // 넘어가는 실제 버그였다("아무 데이터도 입력하지 않은 상태에서는 결과 화면으로
  // 넘어가면 안 됨" 리포트). null을 진짜 "아직 선택 안 함"으로 취급하고, 사용자가
  // 피커에서 실제로 확인을 눌러야만 값이 채워지게 한다 — `_canSubmit`이 이 두 값을
  // 근거로 제출 가능 여부를 판단한다.
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  bool _timeUnknown = false;
  _Calendar _calendar = _Calendar.solar;
  // 2026-07-19: 성별·혈액형이 목업(`.field-required`)대로 필수값이 됐다 — 이름/날짜/
  // 시간처럼 "아직 아무것도 안 고르지 않은 상태"를 실제로 표현해야 하므로, 조용히
  // 유효한 기본값(예: 여성)으로 미리 채워두지 않고 둘 다 null에서 시작한다.
  Gender? _gender;
  BloodType? _bloodType;
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
  void initState() {
    super.initState();
    // 2026-07-19 버그 수정: 이름이 이제 필수값이라 `_canSubmit`이 이름 입력 여부를
    // 봐야 하는데, `_nameController`에 리스너가 없어서 타이핑을 해도 위젯이 다시
    // 그려지지 않아(setState 없음) 제출 버튼이 계속 비활성 상태로 보였다(실제로는
    // 다른 필드를 모두 채우고 나서야 뒤늦게 갱신되는 식으로 드러남).
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // 아직 선택한 값이 없으면(null) 피커의 초기 위치만 합리적인 기본값으로 잡는다 —
      // 사용자가 실제로 확인을 눌러야만 아래 setState에서 _birthDate에 반영된다.
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
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
      // _pickDate와 같은 이유 — 초기 위치만 잡을 뿐 실제 반영은 사용자의 확인 이후.
      initialTime: _birthTime ?? const TimeOfDay(hour: 14, minute: 30),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _birthTime = picked);
    }
  }

  // 자시(23시~01시, four_pillars.dart의 `midnight` 관법 주석과 동일한 경계) 출생자는
  // 일주 계산 방식이 앱마다 갈릴 수 있다는 리서치 결과(docs/research/운세/입력_온보딩_설계.md)에
  // 따라 안내 문구만 추가한다 — 계산 로직(관법)은 건드리지 않는다. "23시~01시" 두 시간은
  // 23:00~23:59와 00:00~00:59로 구성되므로 hour가 23 또는 0일 때만 해당한다. 아직 시간을
  // 선택하지 않았으면(null) 안내 자체가 의미 없으니 false로 취급한다.
  bool get _isJasiRange {
    final time = _birthTime;
    return time != null && (time.hour == 23 || time.hour == 0);
  }

  // 아직 아무 값도 고르지 않은 초기 상태를 유효한 기본값(예: 1998.08.15)으로 조용히
  // 채워두지 않기 위해 null-safe하게 만들었다 — "아무 데이터도 입력하지 않은 상태"를
  // 그대로 화면에 드러내는 플레이스홀더 문구를 대신 보여준다.
  String get _formattedDate {
    final date = _birthDate;
    if (date == null) return '날짜를 선택해주세요';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String get _formattedTime {
    final time = _birthTime;
    if (time == null) return '시간을 선택해주세요';
    final period = time.hour < 12 ? '오전' : '오후';
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '$period $hour12시 ${time.minute.toString().padLeft(2, '0')}분';
  }

  // 2026-07-19: 목업(`.field-required` 이름/태어난 날짜/태어난 시간/성별/혈액형)에 맞춰
  // 다섯 항목을 전부 필수로 재정의했다 — 날짜는 반드시 골라야 하고, 시간은 "태어난
  // 시간을 몰라요"에 체크했더라도 대략적인 시간대 선택 자체는 여전히 필요하다(7번
  // 안내 문구 참고). 이름은 trim 후 빈 문자열이면 미입력으로 취급, 성별/혈액형은
  // null이 아니어야 한다(둘 다 더 이상 조용한 기본값을 갖지 않는다).
  bool get _canSubmit =>
      _birthDate != null &&
      (_timeUnknown || _birthTime != null) &&
      _nameController.text.trim().isNotEmpty &&
      _gender != null &&
      _bloodType != null;

  Future<void> _submit() async {
    if (_isSubmitting || !_canSubmit) return;
    // 버튼이 onPressed 조건(_canSubmit && !_isSubmitting)으로 다시 비활성화되도록
    // setState로 갱신한다 — 이전에는 _isSubmitting을 그냥 대입만 해서 화면이 다시
    // 그려지기 전까지는 버튼이 여전히 눌리는 것처럼 보일 수 있었다.
    setState(() => _isSubmitting = true);

    final trimmedName = _nameController.text.trim();
    final trimmedBirthPlace = _birthPlaceController.text.trim();
    // _canSubmit이 이미 널 아님을 보장한다(날짜·이름·성별·혈액형은 항상, 시간은
    // 시간-모름이 아닐 때만).
    final birthDate = _birthDate!;
    final birthTime = _birthTime;
    final birthInfo = BirthInfo(
      date: birthDate,
      hour: _timeUnknown ? null : birthTime!.hour,
      minute: _timeUnknown ? null : birthTime!.minute,
      isLunar: _calendar == _Calendar.lunar,
      name: trimmedName,
      birthPlace: trimmedBirthPlace.isEmpty ? null : trimmedBirthPlace,
      gender: _gender,
      bloodType: _bloodType,
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
            // 2026-07-19: 목업(`.field-required` "이름")대로 필수값으로 바뀌면서
            // "(선택)" 표기와 그 아래 "이름 없이도 괜찮아요 →" 안내 문구를 함께 제거했다.
            const _FieldLabel('이름', required: true),
            // 목업(`.field label`)은 margin-bottom:7px인데 지금까지는 8px이었다
            // (2026-07-16 오버나이트 대조 발견).
            const SizedBox(height: 7),
            // hintText만으로는 스크린 리더가 "예: 민지"를 필드 이름으로 잘못 읽는다(필드가
            // 비어 있을 때 hintText가 시맨틱 label로 그대로 노출됨 — 실제 확인함). 위의
            // _FieldLabel은 시각적으로만 보이고 이 TextField와 시맨틱으로 연결되지 않으므로,
            // excludeSemantics 없는 Semantics(label:)로 감싸 "이름"과 병합되게 한다.
            Semantics(
              label: '이름',
              child: TextField(
                controller: _nameController,
                maxLength: 20,
                // 공유 카드(share_card.dart)가 폭 고정 레이아웃이라, 이름이 너무 길면
                // "$name의 사주팔자" 헤더가 카드 높이를 넘겨 잘리거나 겹칠 수 있다 — 입력 단계에서 제한.
                decoration: const InputDecoration(hintText: '예: 민지', counterText: ''),
              ),
            ),
            // 목업(`.field`)은 margin-bottom:14px인데 지금까지는 20px이었다
            // (2026-07-07 대조 발견) — 이하 필드 그룹 사이 간격 전부 동일하게 수정.
            const SizedBox(height: 14),
            const _FieldLabel('태어난 날짜', required: true),
            // 목업(`.field label`)은 margin-bottom:7px인데 지금까지는 8px이었다
            // (2026-07-16 오버나이트 대조 발견).
            const SizedBox(height: 7),
            // PastelPillButton 자체 라벨은 버튼에 표시된 값("1998.08.15")뿐이라, 스크린
            // 리더가 바로 위 _FieldLabel("태어난 날짜")을 건너뛰고 이 버튼에 도달하면
            // 무슨 값인지 맥락이 없다 — `fieldLabel`을 지정하면 위젯 내부에서 필드
            // 맥락을 더한 라벨('태어난 날짜 1998.08.15')로 조합해준다(2026-07-15 접근성
            // 발견, 이후 위젯 내부로 이동해 중복 제거·2026-07-15).
            PastelPillButton(
              label: _formattedDate,
              fieldLabel: '태어난 날짜',
              onTap: _pickDate,
            ),
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
            const _FieldLabel('태어난 시간', required: true),
            // 목업(`.field label`)은 margin-bottom:7px인데 지금까지는 8px이었다
            // (2026-07-16 오버나이트 대조 발견).
            const SizedBox(height: 7),
            // 날짜 pill과 같은 이유(2026-07-15 접근성 발견) — 필드 맥락("태어난 시간")을
            // `fieldLabel`로 더해준다. onTap이 null이면 PastelPillButton이 알아서
            // enabled:false로 표시하므로 여기서 따로 enabled를 지정할 필요가 없다.
            // 시간 모름 상태에서는 버튼에 "시간 모름"이 보이지만, "태어난 시간 시간
            // 모름"처럼 "시간"이 중복되지 않도록 `semanticValue`로 "모름"만 조합한다.
            PastelPillButton(
              label: _timeUnknown ? '시간 모름' : _formattedTime,
              fieldLabel: '태어난 시간',
              semanticValue: _timeUnknown ? '모름' : _formattedTime,
              onTap: _timeUnknown ? null : _pickTime,
            ),
            // 자시 경계 안내 — 시간을 모른다고 체크했으면 어차피 시주를 계산하지 않으므로
            // 이 안내는 의미가 없어 숨긴다. "자시" 같은 한자어 대신 순화된 표현으로 안내.
            if (_isJasiRange && !_timeUnknown) ...[
              const SizedBox(height: 6),
              // 시간 피커 선택/"태어난 시간을 몰라요" 체크박스 토글에 따라 화면 전환 없이
              // 동적으로 나타나거나 사라지는 문구라, calculating_screen.dart의 로딩 문구와
              // 같은 이유로 liveRegion으로 감싸 스크린 리더가 변화를 자동으로 안내하게 한다.
              // 위 시간 pill(fieldLabel Semantics)과는 별개 노드로 유지된다.
              Semantics(
                liveRegion: true,
                child: const Text(
                  '밤 11시~새벽 1시 사이는 앱마다 계산 방식이 조금씩 달라요. '
                  '병원 기록상 시간이 있다면 다시 확인해보세요.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 8),
            // CheckboxListTile을 써서 체크박스뿐 아니라 "태어난 시간을 몰라요" 글자를 눌러도
            // 반응하게 한다 (터치 영역이 넓어져 접근성/사용성 모두 개선됨).
            PastelCheckboxRow(
              label: '태어난 시간을 몰라요',
              value: _timeUnknown,
              onChanged: (v) => setState(() => _timeUnknown = v ?? false),
            ),
            // 2026-07-19: "몰라요"에 체크해도 시간 선택 자체는 그대로 필요하다는 걸
            // 분명히 하는 안내 문구(목업 `.jasi-tip`의 새 워딩과 같은 취지) — 이 체크는
            // "정확한 시간까지는 모른다"는 뜻일 뿐, 대략적인 시간대조차 안 골라도 된다는
            // 뜻이 아니다.
            const SizedBox(height: 6),
            const Text(
              '체크해도 시간 선택은 필요해요 — 그래도 대략적인 시간대라도 골라주시면 '
              '그 안에서 최대한 정확하게 봐드릴게요',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('성별', required: true),
            // 목업(`.field label`)은 margin-bottom:7px인데 지금까지는 8px이었다
            // (2026-07-16 오버나이트 대조 발견).
            const SizedBox(height: 7),
            PastelToggleRow<Gender>(
              value: _gender,
              options: const {Gender.female: '여성', Gender.male: '남성'},
              onChanged: (v) => setState(() => _gender = v),
              semanticLabel: '성별 선택',
            ),
            const SizedBox(height: 14),
            // 2026-07-19 추가: 목업(`.field-required` "혈액형")대로 성별과 같은 필수
            // 토글 패턴으로 A/B/AB/O형을 고르게 한다 — 사주 계산과는 무관한 순수 저장
            // 필드(BloodType, birth_info.dart 참고).
            const _FieldLabel('혈액형', required: true),
            const SizedBox(height: 7),
            PastelToggleRow<BloodType>(
              value: _bloodType,
              options: const {
                BloodType.a: 'A형',
                BloodType.b: 'B형',
                BloodType.ab: 'AB형',
                BloodType.o: 'O형',
              },
              onChanged: (v) => setState(() => _bloodType = v),
              semanticLabel: '혈액형 선택',
            ),
            const SizedBox(height: 14),
            const _FieldLabel('태어난 곳 (선택)'),
            // 목업(`.field label`)은 margin-bottom:7px인데 지금까지는 8px이었다
            // (2026-07-16 오버나이트 대조 발견).
            const SizedBox(height: 7),
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
              semanticsLabel: '건너뛰어도 괜찮아요',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            // MBTI 입력 — deep_dive_input_screen.dart에 있던 것을 그대로 옮겨왔다
            // (2026-07-07, 사용자 요청). 모르면 체크하지 않아도 되는 선택 항목.
            PastelCheckboxRow(
              label: 'MBTI를 알고 있어요',
              value: _knowsMbti,
              onChanged: (v) => setState(() => _knowsMbti = v ?? false),
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
                // 이름·날짜·시간·성별·혈액형을 모두 채우기 전까지는 버튼을 비활성화한다
                // — "아무 데이터도 입력하지 않은 상태에서는 결과 화면으로 넘어가면
                // 안 됨" 버그 수정(2026-07-17), 2026-07-19 필수값 확장에 맞춰 조건 갱신.
                onPressed: _canSubmit && !_isSubmitting ? _submit : null,
                child: const Text(
                  '사주 보러가기 🔮',
                  semanticsLabel: '사주 보러가기',
                ),
              ),
            ),
            // 목업(`.input-hint`)과 같은 안내 문구 — 제출 버튼이 왜 안 눌리는지
            // 궁금해할 사용자를 위해 어떤 필드가 필수인지 알려준다(2026-07-19 추가).
            const SizedBox(height: 6),
            const Text(
              '이름 · 날짜 · 시간 · 성별 · 혈액형을 다 채워야 눌러져요',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.required = false});
  final String text;

  /// true면 목업(`.field-required::after{content:" *"}`)처럼 라벨 뒤에 accent 색
  /// `*`를 붙인다 — 2026-07-19 필수값 확장(이름/날짜/시간/성별/혈액형)에 맞춰 추가.
  final bool required;

  @override
  Widget build(BuildContext context) {
    // 목업(`.field label`)은 font-size:11px/font-weight:800/letter-spacing:.02em인데
    // 지금까지는 13px/700/자간 없음이었다(2026-07-16 오버나이트 대조 발견).
    const baseStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 11,
      letterSpacing: 0.22,
      color: AppColors.inkSoft,
    );
    if (!required) return Text(text, style: baseStyle);
    // 목업(`.field-required::after{content:" *"; color:var(--app-accent)}`)처럼
    // `*`만 accent 색으로 강조한다 — 순수 텍스트 접미사(별도 위젯/장식 없이 TextSpan
    // 하나만 색을 달리함)로 충분하다는 지시에 따름.
    return Text.rich(
      TextSpan(
        text: text,
        style: baseStyle,
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: AppColors.accent)),
        ],
      ),
    );
  }
}

