import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/storage/deep_dive_info_store.dart';
import '../../shared/widgets/pastel_toggle_row.dart';
import '../birth_input/birth_info.dart';
import 'deep_dive_info.dart';
import 'deep_dive_result_screen.dart';

/// MBTI·관심사 입력 화면 — 결과 화면의 "MBTI·관심사로 심층 분석 받기"에서 진입.
/// 목업에는 없는 화면이라(1단계 신규 기능), 기존 birth_input 화면의 토글/체크박스
/// 패턴(PastelToggleRow, "몰라요" 체크로 선택 입력 감추기)을 그대로 재사용해 톤을 맞춘다.
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

  // MBTI는 모르는 사람이 많으므로 기본은 꺼둔 채, birth_input의 "시간 모름" 체크와
  // 같은 방식으로 켰을 때만 네 축 토글을 보여준다.
  bool _knowsMbti = false;
  MbtiEi _ei = MbtiEi.e;
  MbtiSn _sn = MbtiSn.s;
  MbtiTf _tf = MbtiTf.t;
  MbtiJp _jp = MbtiJp.j;

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
      final mbti = saved.mbti;
      if (mbti != null) {
        _knowsMbti = true;
        _ei = mbti.ei;
        _sn = mbti.sn;
        _tf = mbti.tf;
        _jp = mbti.jp;
      }
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

    final deepDiveInfo = DeepDiveInfo(
      mbti: _knowsMbti ? Mbti(ei: _ei, sn: _sn, tf: _tf, jp: _jp) : null,
      interests: _interests,
    );
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
            CheckboxListTile(
              value: _knowsMbti,
              onChanged: (v) => setState(() => _knowsMbti = v ?? false),
              activeColor: AppColors.accent,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              // birth_input_screen.dart의 "태어난 시간을 몰라요"와 같은 이유(목업
              // `.check-row`는 12px)로 크기 조정(2026-07-06 대조 발견).
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
      label: '${interest.icon} ${interest.categoryTitle}',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            // PastelToggleRow와 같은 이유로 accent+흰 글자 대신 목업의 `.pill.is-active`와
            // 같은 accentSoft+accentText 조합을 쓴다(2026-07-06, WCAG AA 텍스트 대비 자연 해결).
            color: selected ? AppColors.accentSoft : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
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
