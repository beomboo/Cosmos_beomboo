import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/storage/deep_dive_info_store.dart';
import '../birth_input/birth_info.dart';
import 'deep_dive_info.dart';
import 'deep_dive_result_screen.dart';

/// 관심사 입력 화면 — 상세 리포트의 "MBTI·관심사로 심층 분석 받기"에서 진입.
/// 목업에는 없는 화면이라(1단계 신규 기능), 파스텔 큐트 톤에 맞춘 커스텀 칩(`_InterestChip`)으로
/// 관심사를 다중 선택한다.
/// **2026-07-07 변경(사용자 요청)**: MBTI 질문 자체는 birth_input_screen.dart로
/// 옮겨졌다 — 이 화면에는 더 이상 체크박스가 없고, 그때 저장된 MBTI를 다시 묻지
/// 않고 그대로 이어받아(`_mbti`) 관심사와 함께 저장만 한다.
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

  // birth_input_screen.dart에서 이미 물어본 MBTI를 그대로 이어받아 저장할 때만
  // 쓴다 — 이 화면에서 새로 입력받거나 고칠 수 있는 값이 아니다.
  Mbti? _mbti;

  /// birth_input_screen.dart의 `_submit()`과 같은 이유로 필요하다 — `_saveAndContinue()`의
  /// `DeepDiveInfoStore.save()` await 구간에서 "심층 분석 보기"를 빠르게 두 번 누르면
  /// `DeepDiveResultScreen`이 중복으로 push되는 걸 막는다.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
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
    if (saved == null || !mounted) return;

    setState(() {
      _interests = saved!.interests;
      _mbti = saved.mbti;
    });
  }

  void _toggleInterest(Interest interest) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('조금 더 깊이 볼까요?')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const Text(
              '관심 있는 영역을 골라주세요',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.inkSoft),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveAndContinue(context, birthInfo),
                child: const Text('심층 분석 보기'),
              ),
            ),
          ],
        ),
      ),
    );
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
