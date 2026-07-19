import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/storage/deep_dive_info_store.dart';
import '../birth_input/birth_info.dart';
import 'deep_dive_info.dart';
import 'deep_dive_readings.dart';
import 'deep_dive_result_screen.dart';

/// 관심사 입력 화면 — 상세 리포트의 "MBTI·관심사로 심층 분석 받기"에서 진입.
/// **2026-07-07 변경(사용자 요청)**: MBTI 질문 자체는 birth_input_screen.dart로
/// 옮겨졌다 — 이 화면에는 더 이상 체크박스가 없고, 그때 저장된 MBTI를 다시 묻지
/// 않고 그대로 이어받아(`_mbti`) 관심사와 함께 저장만 한다.
/// **2026-07-19 변경(목업 STEP 5 리팩터, `/grill-me` 합의)**: 실제 광고 SDK 연동
/// 없이, 화면 상단에 목업(`.ad-gate-card`)과 같은 그라데이션 게이트 카드를 추가했다
/// — "광고 보고 계속하기"를 탭하면(`_adWatched`) 그 아래 MBTI 확인 뱃지+관심사
/// 선택+제출 버튼이 자연스럽게 나타나는 UI만 구현한다(실제 광고 시청/보상형 광고
/// 연동은 별도 작업).
class DeepDiveInputScreen extends StatefulWidget {
  const DeepDiveInputScreen({super.key, this.birthInfo});

  final BirthInfo? birthInfo;

  @override
  State<DeepDiveInputScreen> createState() => _DeepDiveInputScreenState();
}

class _DeepDiveInputScreenState extends State<DeepDiveInputScreen> {
  // 관심사는 기본 전체 선택 — 먼저 다 보여주고 원하지 않는 것만 빼는 편이
  // 하나하나 골라 담는 것보다 진입 장벽이 낮다.
  Set<Interest> _interests = {...Interest.values};

  /// 상단 광고 게이트 카드(`_AdGateCard`)의 "광고 보고 계속하기"를 탭했는지 여부.
  /// 실제 광고 SDK 연동은 아직 없어 탭 즉시 true가 된다 — MBTI 확인 뱃지·관심사
  /// 선택·제출 버튼은 전부 이 값이 true일 때만 보여, 광고 시청이 그 다음 단계를
  /// 여는 자연스러운 흐름처럼 보이게 한다(2026-07-19).
  bool _adWatched = false;

  // birth_input_screen.dart에서 이미 물어본 MBTI를 그대로 이어받아 저장할 때만
  // 쓴다 — 이 화면에서 새로 입력받거나 고칠 수 있는 값이 아니다.
  Mbti? _mbti;

  /// birth_input_screen.dart의 `_submit()`과 같은 이유로 필요하다 — `_saveAndContinue()`의
  /// `DeepDiveInfoStore.save()` await 구간에서 "심층 분석 보기"를 빠르게 두 번 누르면
  /// `DeepDiveResultScreen`이 중복으로 push되는 걸 막는다.
  bool _isSubmitting = false;

  /// **2026-07-11 버그 수정**: `initState()`가 `_loadSaved()`를 기다리지 않고(fire-and-forget)
  /// 바로 반환하는데, 이미 저장된 관심사가 있는 상태(재방문)에서 그 비동기 로드가
  /// 끝나기 전에 사용자가 칩을 탭하면 `_toggleInterest()`의 `setState`가 곧바로 뒤이어
  /// 도착하는 `_loadSaved()`의 `setState`(저장된 값으로 무조건 덮어씀)에 조용히
  /// 덮여써져, 방금 누른 탭이 화면에는 잠깐 반영됐다가 다시 예전 값으로 되돌아가는
  /// 실제 버그였다. 사용자가 한 번이라도 직접 상호작용했으면 그 뒤에 로드가 끝나도
  /// 더 이상 덮어쓰지 않도록 막는다.
  bool _userInteracted = false;

  /// **2026-07-15 버그 수정**: `initState()`가 `_loadSaved()`를 fire-and-forget으로
  /// 던지기만 하고 기다리지 않아서, birth_input_screen.dart에서 이미 골라둔 MBTI가
  /// `SharedPreferences`에서 아직 읽히기 전에 사용자가 곧바로 "심층 분석 보기"를
  /// 누르면 `_mbti`의 초기값(`null`)이 그대로 저장돼 MBTI가 조용히 유실되는 실제
  /// 버그였다(이 화면엔 MBTI를 보여주는 UI가 없어 사용자가 눈치챌 방법도 없었다).
  /// `_saveAndContinue()`가 저장 직전 이 Future를 기다리게 해서 로드가 끝난 뒤의
  /// `_mbti` 값을 저장하도록 막는다.
  late final Future<void> _loadFuture = _loadSaved();

  @override
  void initState() {
    super.initState();
    _loadFuture;
  }

  /// 이전에 저장된 선택이 있으면 불러와 반영한다. 저장된 적이 한 번도 없으면(첫 방문)
  /// 기본값(관심사 전체 선택, MBTI 모름)을 그대로 둔다 — 저장/조회 실패해도 화면
  /// 진행에는 지장 없도록 방어한다(BirthInfoStore와 동일한 패턴).
  Future<void> _loadSaved() async {
    DeepDiveInfo? saved;
    try {
      saved = await DeepDiveInfoStore.load();
    } catch (_) {
      saved = null;
    }
    if (saved == null || !mounted || _userInteracted) return;

    setState(() {
      _interests = saved!.interests;
      _mbti = saved.mbti;
    });
  }

  void _toggleInterest(Interest interest) {
    _userInteracted = true;
    setState(() {
      _interests = _interests.contains(interest)
          ? ({..._interests}..remove(interest))
          : {..._interests, interest};
    });
  }

  /// 제출 시 다음에 다시 열었을 때 이어서 보이도록 저장한다. 저장이 실패해도
  /// (플랫폼 채널 오류 등) 지금 화면 전환은 막지 않는다.
  Future<void> _saveAndContinue(BuildContext context, BirthInfo birthInfo) async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    // 로드가 끝나기 전에 눌려도(위 `_loadFuture` 주석 참고) `_mbti`가 초기값(null)인
    // 채로 저장되지 않도록, 저장을 구성하기 전에 로드 완료를 먼저 기다린다. 로드가
    // 이미 끝나 있었다면 즉시 반환되므로 체감 지연은 없다. 로드 완료 시점에 이미
    // 화면을 벗어났다면(`mounted`가 false) 그 이후 사용자 조작은 불가능하므로
    // `_userInteracted`와 무관하게 안전하다.
    try {
      await _loadFuture;
    } catch (_) {
      // _loadSaved()가 이미 자체적으로 실패를 흡수하지만, 혹시 모를 예외도 저장/화면
      // 전환을 막지 않는다.
    }
    if (!mounted) return;

    final deepDiveInfo = DeepDiveInfo(mbti: _mbti, interests: _interests);
    try {
      await DeepDiveInfoStore.save(deepDiveInfo);
    } catch (_) {
      // 무시 — 다음에 열면 다시 고르면 된다.
    }
    if (!context.mounted) return;
    // birth_input_screen.dart의 _submit()과 같은 이유로, push()가 반환하는 Future가
    // 완료되는 시점(이 화면으로 다시 돌아왔을 때)에 맞춰 플래그를 되돌린다 — 그렇지
    // 않으면 제출 후 뒤로가기로 이 화면에 돌아왔을 때 "심층 분석 보기"가 계속
    // 먹통이 되는 실제 버그가 있었다(한 번 true가 된 뒤로 다시 false가 될 일이 없었음).
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeepDiveResultScreen(birthInfo: birthInfo, deepDiveInfo: deepDiveInfo),
      ),
    );
    if (context.mounted) {
      _isSubmitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthInfo = widget.birthInfo ??
        (ModalRoute.of(context)?.settings.arguments as BirthInfo?) ??
        BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);
    final mbtiNickname = mbtiNicknameFor(_mbti?.code);

    return Scaffold(
      appBar: AppBar(title: const Text('더 자세히 알아보기')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          children: [
            const Text(
              '명식·오행 상세 풀이부터 관심사별 이야기까지, 짧은 광고 하나면 전부 확인할 수 있어요',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 14),
            _AdGateCard(watched: _adWatched, onWatch: _handleWatchAd),
            if (_adWatched) ...[
              const SizedBox(height: 14),
              if (_mbti != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _MbtiKnownChip(code: _mbti!.code, nickname: mbtiNickname),
                ),
              const SizedBox(height: 14),
              // pastel_toggle_row.dart의 semanticLabel과 같은 이유(2026-07-13 발견) — 안내
              // Text가 칩 Wrap 바로 앞에 있어도, 스크린 리더 사용자가 순서대로 읽지 않고
              // (explore-by-touch 등) 칩으로 곧장 이동하면 이 안내를 놓칠 수 있다. 그룹의
              // container Semantics 자체에는 excludeSemantics를 안 줘서 각 칩의
              // selected/button 개별 상태는 그대로 유지한다 — 그룹 라벨과 개별 칩 상태를
              // 둘 다 들려주기 위함(pastel_toggle_row.dart 82~89행과 동일한 방식).
              Semantics(
                container: true,
                label: '관심 있는 영역 선택',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 안내 Text 자체는 액션이 없는 순수 라벨이라 excludeSemantics 없이 그냥
                    // 두면 Flutter가 이 노드를 부모(그룹) 노드로 병합해버려, 위 그룹
                    // label과 이 Text의 자동 라벨이 한 노드 안에 줄바꿈으로 이어 붙어
                    // "관심 있는 영역 선택\n관심 있는 영역을 골라주세요"처럼 같은 안내를
                    // 두 번 들려주게 된다(실측 확인) — 이 Text가 전달하려던 내용은 이미
                    // 위 그룹 label에 담겨 있으므로 ExcludeSemantics로 중복 병합만 막는다.
                    const ExcludeSemantics(
                      child: Text(
                        '무엇이 가장 궁금하세요? (하나 이상 선택)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.inkSoft),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final interest in Interest.values)
                          _InterestChip(
                            interest: interest,
                            selected: _interests.contains(interest),
                            onTap: () => _toggleInterest(interest),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveAndContinue(context, birthInfo),
                  child: const Text('결과 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 상단 광고 게이트 카드의 "광고 보고 계속하기" 콜백. 실제 광고 SDK 연동은
  /// 없어 탭 즉시 그 아래(MBTI 뱃지+관심사 선택+제출 버튼)가 드러난다.
  void _handleWatchAd() {
    setState(() => _adWatched = true);
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.interest, required this.selected, required this.onTap});

  final Interest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      // 2026-07-08 발견: result_screen.dart의 _CategoryCard/_OhaengMeaningCard는
      // 이미 같은 이유(장식용 이모지까지 스크린 리더가 유니코드 이름으로 읽어
      // 혼란스러움, 2026-07-07 발견·수정)로 라벨에서 이모지를 뺐는데, 정작 그
      // 관심사 목록의 "원본"인 이 칩만 라벨에 이모지를 그대로 포함하고 있었다 —
      // 시각적 표시(아래 Text)에는 이모지를 그대로 유지하고 라벨만 뗀다.
      label: interest.categoryTitle,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // PastelPillButton/PastelToggleRow와 같은 이유(목업 `.pill`은
          // padding:9px 14px)로 맞춘다(2026-07-07 대조 발견, 기존 16/10).
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            // PastelToggleRow와 같은 이유로 accent+흰 글자 대신 목업의 `.pill.is-active`와
            // 같은 accentSoft+accentText 조합을 쓴다(2026-07-06, WCAG AA 텍스트 대비 자연 해결).
            color: selected ? AppColors.accentSoft : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            // 목업(`.pill`)은 1.5px 테두리를 쓰는데 지금까지는 기본값인 1px이었다
            // (2026-07-07 대조 발견).
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            '${interest.icon} ${interest.categoryTitle}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.accentText : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// 목업(`.ad-gate-card`)의 광고 시청 게이트 카드 — accentSoft→metalSoft 그라데이션
/// 배경에 안내 문구+"광고 보고 계속하기" 버튼. 실제 광고 SDK 연동 전이라 [onWatch]는
/// 탭 즉시 호출되고, [watched]가 true가 되면(부모의 `_adWatched`) 버튼 문구만
/// "시청 완료"로 바뀌어 다시 눌러도 무해하다는 걸 보여준다.
class _AdGateCard extends StatelessWidget {
  const _AdGateCard({required this.watched, required this.onWatch});

  final bool watched;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.accentSoft, AppColors.metalSoft],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '🎬 15초 광고 하나만 보면\n상세 리포트가 열려요',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: onWatch,
              child: Text(watched ? '✅ 시청 완료' : '광고 보고 계속하기'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 목업(`.mbti-known-chip`)의 "✅ ENFP · 스파크 메이커" 확인 뱃지 — birth_input에서
/// 이미 MBTI를 골라뒀을 때만(`_mbti` non-null) 표시한다. 별칭(`nickname`)이 없는
/// 코드(알 수 없는 값)면 코드만 보여준다.
class _MbtiKnownChip extends StatelessWidget {
  const _MbtiKnownChip({required this.code, required this.nickname});

  final String code;
  final String? nickname;

  @override
  Widget build(BuildContext context) {
    final label = nickname != null ? '$code · $nickname' : code;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '✅ $label',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: AppColors.ink),
      ),
    );
  }
}
