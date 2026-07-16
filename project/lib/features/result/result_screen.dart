import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/saju/four_pillars.dart';
import '../../core/saju/ganzhi.dart';
import '../../core/storage/birth_info_store.dart';
import '../../core/storage/deep_dive_info_store.dart';
import '../../shared/share/share_capture.dart';
import '../../shared/widgets/gradient_share_button.dart';
import '../../shared/widgets/offscreen_share_capture.dart';
import '../../shared/widgets/pastel_card.dart';
import '../birth_input/birth_info.dart';
import '../birth_input/birth_input_screen.dart';
import 'meta_line.dart';
import 'ohaeng_readings.dart';
import 'share_card.dart';
import 'share_text.dart';

/// 오행 이름 뒤에 붙는 주격 조사(이/가) — 받침 유무에 따라 갈린다(목/금은 받침 있어 "이",
/// 화/토/수는 받침 없어 "가"). [buildOhaengBalanceNarrative]가 "$dominant이(가)"처럼 어색한
/// 표기 대신 자연스러운 한국어 문장을 만들 때 쓴다.
const _ohaengSubjectParticle = {'목': '이', '화': '가', '토': '가', '금': '이', '수': '가'};

/// 오행별 우세(dominant)+2순위(sub) 조합 관계에 대응하는 "오행 밸런스" 서술 문단 문구.
/// 콜아웃 박스(`dominantComboCallout`)와 달리 % 숫자를 함께 보여주는 좀 더 사실 설명형
/// 문장이라 톤을 조금 다르게 쓴다(둘 다 "~요" 캐주얼 톤은 유지).
String _balanceRelationNarrative(OhaengRelation relation, String dominant, String sub) {
  switch (relation) {
    case OhaengRelation.dominantGeneratesSub:
      return '$dominant 기운이 $sub 기운에 힘을 보태는 흐름이라 시너지가 좋아요';
    case OhaengRelation.subGeneratesDominant:
      return '$sub 기운이 $dominant 기운을 든든하게 받쳐주는 흐름이에요';
    case OhaengRelation.dominantOvercomesSub:
      return '$dominant 기운이 $sub 기운을 다스리는 흐름이라 주도권을 쥐는 편이에요';
    case OhaengRelation.subOvercomesDominant:
      return '$sub 기운이 $dominant 기운에 브레이크를 걸어주는 흐름이에요';
  }
}

/// 오행 밸런스 바 차트 아래 서술 문단 — % 숫자 + 우세/2순위 오행 관계 설명을 함께 보여준다.
/// [subCount]가 0이면(2순위 오행이 사실상 없음) 관계 설명 없이 우세 오행 숫자만 안내한다.
String buildOhaengBalanceNarrative({
  required String dominant,
  required String sub,
  required Map<String, int> ohaengCount,
  required int total,
}) {
  final dominantCount = ohaengCount[dominant] ?? 0;
  final dominantPercent = total == 0 ? 0 : (dominantCount / total * 100).round();
  final dominantParticle = _ohaengSubjectParticle[dominant] ?? '이';
  if (total == 0) {
    return '태어난 시간을 포함한 오행 정보가 아직 없어요';
  }
  if (ohaengCount[sub] == null || ohaengCount[sub] == 0) {
    return '전체 $total글자 중 $dominant$dominantParticle $dominantCount개($dominantPercent%)로 가장 많아요';
  }
  final subCount = ohaengCount[sub]!;
  final subPercent = (subCount / total * 100).round();
  final subParticle = _ohaengSubjectParticle[sub] ?? '이';
  final relation = ohaengRelationOf(dominant, sub);
  final narrative = _balanceRelationNarrative(relation, dominant, sub);
  return '전체 $total글자 중 $dominant$dominantParticle $dominantCount개($dominantPercent%)로 가장 많고, '
      '$sub$subParticle $subCount개($subPercent%)로 그다음이에요 — $narrative';
}

/// 사주 결과 화면 — 4기둥 명식 + 오행 밸런스 바 차트 + 영역별 풀이 + 공유.
/// 참고: docs/mockups/01-pastel-cute.html STEP 4
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, this.birthInfo});

  /// 앱 시작 시 저장된 값으로 바로 이 화면을 여는 경우(홈 화면으로 사용) 직접 전달.
  /// 생략하면 라우트 arguments(calculating → result 네비게이션)를 사용한다.
  final BirthInfo? birthInfo;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  /// 화면에는 보이지 않는 공유용 카드(ShareCard)를 캡처하기 위한 키.
  final _shareCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final birthInfo = widget.birthInfo ??
        (ModalRoute.of(context)?.settings.arguments as BirthInfo?) ??
        BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

    final pillars = calculateFourPillars(
      birthDate: birthInfo.date,
      birthHour: birthInfo.hour,
    );
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);
    final dominant = pillars.dominantOhaeng;
    final sub = pillars.subDominantOhaeng;
    // subDominantOhaeng 자체는 항상 어떤 오행 이름을 반환하지만(FourPillars doc-comment
    // 참고), 그 오행이 실제로 사주 8자 중 하나도 없을 수 있다(개수 0) — 그 경우
    // "2순위 오행이 사실상 없음"으로 보고 콤보 함수들이 단일-오행 문구로 폴백한다.
    final subCount = ohaengCount[sub] ?? 0;
    final callout = dominantComboCallout(dominant, sub, subCount: subCount);
    final categories = categoryReadingsForCombo(dominant, sub, subCount: subCount);
    final balanceNarrative = buildOhaengBalanceNarrative(
      dominant: dominant,
      sub: sub,
      ohaengCount: ohaengCount,
      total: total,
    );
    final displayName = displayNameFor(birthInfo);
    final metaLine = buildMetaLine(birthInfo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사주팔자 결과'),
        actions: [
          IconButton(
            tooltip: '다시 입력하기',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _resetAndReenter(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              key: const Key('resultScrollView'),
              // 목업(`.result .screen-body`)은 padding-top:12px 외엔 기본값(가로 20px,
              // 아래 18px)을 그대로 쓰는데 지금까지는 24/8/24/32였다(2026-07-07 대조 발견).
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              children: [
                // 목업(`.result-head h2`)은 font-size:15.5px인데 지금까지는 22px이었다
                // (2026-07-16 대조 발견 — 헤더 블록은 2026-07-05 최초 구현 이후 한 번도
                // 대조된 적이 없었음).
                // TalkBack/VoiceOver의 헤딩 단위 탐색(제목만 골라 건너뛰기)을 지원하려면
                // 섹션 제목에 header 플래그가 필요하다 — 지금까지는 앱 전체에 이 플래그가
                // 한 곳도 없었다(2026-07-16 접근성 감사 발견). 자식 Text가 만드는 자동
                // 라벨을 그대로 병합해 쓰므로 별도 label은 지정하지 않는다.
                Semantics(
                  header: true,
                  child: Text(
                    '$displayName의 사주팔자 ✨',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                // 목업(`.result-head h2`)은 margin:0 0 3px인데 지금까지는 4px이었다
                // (2026-07-16 대조 발견).
                const SizedBox(height: 3),
                // 목업(`.result-head .meta`)은 font-size:10.5px/font-weight:600인데
                // 지금까지는 13px에 굵기 지정이 아예 없었다(2026-07-16 대조 발견).
                Text(
                  metaLine,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '※ 절기 계산 없이 근사치로 계산한 간이 결과예요',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 11),
                ),
                // 입력 온보딩 설계(docs/research/운세/입력_온보딩_설계.md)의 권장안 —
                // 시주를 모르면 3개 기둥으로 계산한 사실과 함께 재입력을 유도하는 넛지
                // 문구를 보여준다. AppBar에 이미 "다시 입력하기" 아이콘이 있어 여기서는
                // 별도 탭 가능한 CTA 없이 안내 문구만 둔다(중복 진입점 방지).
                if (pillars.hour == null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    '태어난 시간을 몰라 시주 없이 3개 기둥(년주·월주·일주)으로 계산했어요. '
                    '태어난 시간을 알면 더 정확한 결과를 볼 수 있어요',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 20),
                // 목업(`.callout`)은 배경/글자색이 고정된 accentSoft/ink가 아니라, 그 화면의
                // 우세 오행 색으로 물든다(데모가 목(木)이 우세라 wood-soft 배경으로 보였을
                // 뿐, 화/토/금/수가 우세면 각각 그 색으로 바뀌어야 함) — 지금까지는 어떤
                // 오행이 우세하든 항상 같은 accentSoft/ink만 써서 이 색 연동을 놓치고
                // 있었다(2026-07-06 대조 발견). ohaengTextColors는 이미 ohaengSoftColors
                // 배경 위에서 WCAG AA를 만족하도록 설계돼 있어 그대로 재사용 가능.
                SizedBox(
                  width: double.infinity,
                  child: PastelCard(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                    borderRadius: 16,
                    color: AppColors.ohaengSoftColors[dominant] ?? AppColors.accentSoft,
                    showBorder: false,
                    child: Text(
                      '$dominant(${callout.$1}) 기운이 강한 타입이에요 ${callout.$2}\n${callout.$3}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ohaengTextColors[dominant] ?? AppColors.ink,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
                // 목업(`.callout`)은 margin-bottom:14px인데 지금까지는 24px이었다
                // (2026-07-07 대조 발견).
                const SizedBox(height: 14),
                Row(
                  children: [
                    _PillarCard(label: '년주', pillar: pillars.year),
                    const SizedBox(width: 8),
                    _PillarCard(label: '월주', pillar: pillars.month),
                    const SizedBox(width: 8),
                    _PillarCard(label: '일주', pillar: pillars.day),
                    const SizedBox(width: 8),
                    _PillarCard(label: '시주', pillar: pillars.hour),
                  ],
                ),
                // 목업(`.pillars`)은 margin-bottom:14px인데 지금까지는 28px이었다
                // (2026-07-07 대조 발견).
                const SizedBox(height: 14),
                // 헤딩 단위 탐색 지원(2026-07-16 접근성 감사 발견, 위 페이지 제목과 같은 이유).
                Semantics(
                  header: true,
                  child: const Text(
                    '오행 밸런스',
                    // 목업(`.bars h3`)은 font-size:11px/color:var(--app-ink-soft)인데
                    // 지금까지는 본문 헤드라인만큼 진한 15px/ink였다(2026-07-15 대조 발견).
                    // letter-spacing:.02em(≈0.22px)도 빠져 있었다(2026-07-16 오버나이트 대조 발견).
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkSoft,
                      fontSize: 11,
                      letterSpacing: 0.22,
                    ),
                  ),
                ),
                // 목업(`.bars h3`)은 margin:0 0 8px인데 지금까지는 12px이었다
                // (2026-07-07 대조 발견).
                const SizedBox(height: 8),
                for (final ohaeng in const ['목', '화', '토', '금', '수'])
                  _OhaengBarRow(
                    ohaeng: ohaeng,
                    percent: total == 0 ? 0 : (ohaengCount[ohaeng]! / total * 100),
                  ),
                const SizedBox(height: 10),
                // 오행 밸런스 바 차트 아래 서술 문단 — 콜아웃 박스와 같은 톤(우세 오행
                // 배경/글자색)을 재사용해 % 숫자 + 우세·2순위 오행 관계 설명을 함께 보여준다.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.ohaengSoftColors[dominant] ?? AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    balanceNarrative,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: AppColors.ohaengTextColors[dominant] ?? AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
                // 목업(`.bars`)은 margin-bottom:14px인데 지금까지는 28px이었다
                // (2026-07-07 대조 발견).
                const SizedBox(height: 14),
                // 헤딩 단위 탐색 지원(2026-07-16 접근성 감사 발견, 위 페이지 제목과 같은 이유).
                Semantics(
                  header: true,
                  child: const Text(
                    '오늘 궁금한 것부터',
                    // 목업(`.cards h3`)은 font-size:11px/color:var(--app-ink-soft)인데
                    // 지금까지는 본문 헤드라인만큼 진한 15px/ink였다(2026-07-15 대조 발견).
                    // letter-spacing:.02em(≈0.22px)도 빠져 있었다(2026-07-16 오버나이트 대조 발견).
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkSoft,
                      fontSize: 11,
                      letterSpacing: 0.22,
                    ),
                  ),
                ),
                // 목업(`.cards h3`)은 margin:0 0 8px인데 지금까지는 12px이었다
                // (2026-07-07 대조 발견).
                const SizedBox(height: 8),
                // 이전엔 GridView.count(childAspectRatio: 1.3)로 셀 높이를 고정했는데,
                // 시스템 글자 크기를 키우면(접근성 큰 텍스트, 일부 기기는 기본 "큼"
                // 설정만으로도 1.3배) 카드 안 텍스트가 고정 높이를 넘겨 RenderFlex
                // overflow가 실제로 재현됐다 — _PillarCard와 같은 Row-of-Expanded
                // 패턴(높이가 내용에 맞춰 늘어남)으로 바꿔 어떤 글자 크기에서도 안 잘리게 한다.
                Column(
                  children: [
                    // IntrinsicHeight로 Row 자체에 유한한 높이를 부여해야
                    // crossAxisAlignment.stretch로 두 카드 높이를 맞출 수 있다
                    // (Row가 ListView 안에서처럼 세로로 무한한 공간에 있으면
                    // stretch만 단독으로 쓸 때 "BoxConstraints forces an infinite
                    // height" 예외가 실제로 발생함).
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _CategoryCard(category: categories[0])),
                          // 목업(`.cat-grid`)은 gap:8px인데 지금까지는 12px이었다
                          // (2026-07-07 대조 발견) — 가로/세로 간격 모두 수정.
                          const SizedBox(width: 8),
                          Expanded(child: _CategoryCard(category: categories[1])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _CategoryCard(category: categories[2])),
                          const SizedBox(width: 8),
                          Expanded(child: _CategoryCard(category: categories[3])),
                        ],
                      ),
                    ),
                  ],
                ),
                // 목업(`.cat-grid`)은 margin-bottom:14px인데 지금까지는 28px이었다
                // (2026-07-07 대조 발견).
                const SizedBox(height: 14),
                // 목업(docs/mockups/01-pastel-cute.html)의 "공유하기" 버튼(`.share-btn`)은
                // 다른 CTA 버튼과 달리 단색이 아니라 accent→metal 그라데이션을 쓴다 —
                // 심층 분석 결과 화면과 완전히 동일한 구조라 공용 위젯(GradientShareButton)으로
                // 통합했다(2026-07-15 리팩터).
                GradientShareButton(
                  onPressed: () => _handleShare(
                    birthInfo: birthInfo,
                    pillars: pillars,
                    dominant: dominant,
                    callout: callout,
                    ohaengCount: ohaengCount,
                    total: total,
                    displayName: displayName,
                    metaLine: metaLine,
                  ),
                ),
                // 목업(`.share-btn`)은 margin-bottom:8px인데 지금까지는 12px이었다
                // (2026-07-07 대조 발견).
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.report,
                      arguments: birthInfo,
                    ),
                    child: const Text(
                      '상세 리포트 보기 (무료)',
                      // 목업(`.report-link`)은 이 문구를 밑줄 있는 링크로 보여주는데,
                      // 지금까지는 밑줄 없는 일반 버튼 텍스트였다(2026-07-06 대조 발견) —
                      // 밑줄을 추가하고 목업 값(11px/700)에 맞춰 크기·굵기도 조정.
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 오프스크린 캡처 래퍼(Positioned+ExcludeSemantics+RepaintBoundary)는
            // `shared/widgets/offscreen_share_capture.dart`의 공용 위젯으로 옮겨졌다.
            OffscreenShareCapture(
              repaintBoundaryKey: _shareCardKey,
              child: ShareCard(
                displayName: displayName,
                metaLine: metaLine,
                pillars: pillars,
                dominant: dominant,
                calloutHanja: callout.$1,
                calloutEmoji: callout.$2,
                calloutText: callout.$3,
                ohaengCount: ohaengCount,
                total: total,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 저장된 생년월일시를 지우고 입력 화면으로 돌아간다 (뒤로 가기로 결과 화면에 못 돌아오게
  /// 스택을 모두 비운다). 실수로 눌러 저장된 정보를 잃지 않도록 먼저 확인을 받는다.
  Future<void> _resetAndReenter(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('다시 입력할까요?'),
        content: const Text('저장된 생년월일시 정보가 삭제되고, 처음부터 다시 입력하게 돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('다시 입력하기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 삭제가 실패해도(플랫폼 채널 오류 등) 사용자가 입력 화면으로 못 돌아가면 안 되므로
    // 화면 전환은 항상 진행한다. "처음부터 다시 입력하게 돼요"라고 안내하면서
    // DeepDiveInfoStore(MBTI·관심사)는 그대로 남겨두면, 완전히 다른 사람이 새로 입력한
    // 뒤 심층 분석에 들어갔을 때 이전 사람의 MBTI·관심사 선택이 그대로 다시 나타나는
    // 실제 버그가 된다 — 다이얼로그의 약속대로 두 저장소를 함께 지운다.
    // **2026-07-08 버그 수정**: 두 clear()를 하나의 try 블록에 같이 넣어뒀었는데,
    // BirthInfoStore.clear()가 실패하면 catch로 바로 건너뛰어 DeepDiveInfoStore.clear()가
    // 아예 호출되지 않아, 바로 위에서 설명한 그 데이터 유실 버그가 이 실패 경로에서만
    // 조용히 재발할 수 있었다 — 각각 독립된 try로 분리해 한쪽이 실패해도 다른 쪽은
    // 그대로 시도되도록 수정.
    try {
      await BirthInfoStore.clear();
    } catch (_) {
      // 무시
    }
    try {
      await DeepDiveInfoStore.clear();
    } catch (_) {
      // 무시
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BirthInputScreen()),
      (route) => false,
    );
  }

  /// 공유용 카드를 이미지로 캡처해 텍스트와 함께 공유한다. 캡처/공유/실패 안내 로직
  /// 자체는 `shared/share/share_capture.dart`의 공용 함수(`shareCapturedCard`)로
  /// 옮겨졌고, 이 화면은 텍스트 빌드(`buildShareText`)와 공유 메타(subject/파일명)만 맡는다.
  Future<void> _handleShare({
    required BirthInfo birthInfo,
    required FourPillars pillars,
    required String dominant,
    required (String, String, String) callout,
    required Map<String, int> ohaengCount,
    required int total,
    required String displayName,
    required String metaLine,
  }) async {
    final text = buildShareText(
      birthInfo: birthInfo,
      pillars: pillars,
      dominant: dominant,
      callout: callout,
      ohaengCount: ohaengCount,
      total: total,
      displayName: displayName,
    );

    await shareCapturedCard(
      context: context,
      repaintBoundaryKey: _shareCardKey,
      text: text,
      subject: '나의 사주팔자',
      fileName: 'saju_result.png',
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.label, required this.pillar});

  final String label;

  /// null이면 "시간 모름"으로 표시 (시주).
  final GanzhiPillar? pillar;

  @override
  Widget build(BuildContext context) {
    final color = pillar == null
        ? AppColors.inkSoft
        : (AppColors.ohaengTextColors[stemOhaeng(pillar!.stemIndex)] ?? AppColors.ink);

    return Expanded(
      // 시각적으로는 값(예: "갑자")이 위, 기둥 이름("년주")이 아래 순서로 보이지만,
      // 스크린 리더가 그 순서 그대로 두 노드를 따로 읽으면 "갑자, 년주"처럼 값을
      // 먼저 들려줘 맥락 없이 혼란스럽다 — "년주 갑자"로 순서를 바로잡아 병합한다.
      child: Semantics(
        label: '$label ${pillar?.label ?? "모름"}',
        excludeSemantics: true,
        // 4기둥 카드가 한 Row 안에 나란히 있어, container 없이는 이웃 카드의
        // 시맨틱스와 하나로 합쳐져 "년주 무인\n월주 경신\n..."처럼 뭉개진다 —
        // 카드마다 독립된 시맨틱스 노드가 되도록 경계를 명시한다.
        container: true,
        child: PastelCard(
          // 목업(`.pillar-card`)은 padding:9px 4px인데 지금까지는 세로만 14(가로 0)였다
          // (2026-07-07 대조 발견) — 앞서 border-width/gap 감사 때는 카드별 패딩 차이를
          // "모바일 터치 영역을 위한 의도적 조정일 가능성"으로 보류했지만, 이후 여러
          // 사이클에서 비슷한 값 차이들이 실제로는 대조 누락이었음이 반복 확인돼 판단을
          // 뒤집고 목업 값 그대로 맞춘다.
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Column(
            children: [
              Text(
                pillar?.label ?? '모름',
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15),
              ),
              // 목업(`.pillar-card .label`)은 margin-top:4px인데 지금까지는 6px이었다
              // (2026-07-16 대조 발견).
              const SizedBox(height: 4),
              // 목업(`.pillar-card .label`)은 9.5px/font-weight 700인데 지금까지는
              // 11px에 기본 굵기였다(2026-07-07 대조 발견).
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OhaengBarRow extends StatelessWidget {
  const _OhaengBarRow({required this.ohaeng, required this.percent});

  final String ohaeng;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    // 목업(오행 밸런스 바 `.bar-row .tag`)은 한글(목/화/토/금/수)이 아니라 한자
    // (木/火/土/金/水)로 표시한다 — report_screen.dart의 오행 뜻풀이 배지도 이미
    // 같은 이유로 한자를 쓰고 있어(뱃지처럼 짧게 보여줄 땐 한자, 풀어 쓰는 문장에는
    // 한글이라는 기존 관례와도 일치함, 2026-07-06 대조 발견) core/saju/ganzhi.dart의
    // 공용 `ohaengHanja` 상수를 그대로 재사용한다(색상/집계 등 실제 로직은 한글
    // `ohaeng`를 그대로 씀).
    final hanja = ohaengHanja[ohaeng] ?? ohaeng;
    return Semantics(
      // 스크린 리더는 한자(木/火/土/金/水)를 발음할 수 없어, 화면에는 한자를
      // 보여주면서도 시맨틱스 라벨은 실제로 읽을 수 있는 한글 오행명(목/화/토/금/수)을
      // 쓴다 — _PillarCard/_CategoryCard와 같은 병합 패턴(2026-07-15 접근성 발견).
      label: '$ohaeng 비중 ${percent.round()}%',
      excludeSemantics: true,
      container: true,
      child: Padding(
        // 목업(`.bar-row`)은 margin-bottom:5px인데 위아래 대칭 패딩으로 구현하다 보니
        // 지금까지는 vertical:4(행 사이 실제 간격 8px)였다(2026-07-15 대조 발견).
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: [
            SizedBox(
              // 목업(`.bar-row .tag`)은 width:14px/font-size:11px인데 지금까지는
              // width:20(폰트 크기 미지정)이었다(2026-07-15 대조 발견).
              width: 14,
              child: Center(
                // 시스템 폰트 확대(접근성 큰 텍스트) 시 고정폭 14px 안에서 한자 1글자가
                // 조용히 잘리는 문제(2026-07-15 접근성 감사 발견) — FittedBox로 감싸
                // 배율이 커지면 박스 폭에 맞춰 축소되게 한다. 기본 배율(1.0)에서는
                // 원래 크기(11px) 그대로라 시각적으로 달라지지 않는다.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hanja,
                    style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  // 목업(`.bar-track`)은 height:8px인데 지금까지는 10이었다
                  // (2026-07-15 대조 발견).
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              // 고정폭 40px 안의 퍼센트 텍스트도 시스템 폰트 확대 시 조용히 잘릴 수 있어
              // FittedBox로 감싼다(2026-07-15 접근성 감사 발견) — 기본 배율에서는
              // 그대로 오른쪽 정렬된 10px 텍스트로 보인다.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${percent.round()}%',
                  textAlign: TextAlign.end,
                  // 목업(`.bar-row .pct`)은 10px/font-weight 700인데 지금까지는 12px에
                  // 기본 굵기였다(2026-07-07 대조 발견).
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final (String, String, String) category;

  @override
  Widget build(BuildContext context) {
    final (icon, title, desc) = category;
    // 같은 파일의 _PillarCard와 같은 이유(2026-07-07 목업 대조 수정 때 남긴 이유 참고) —
    // 지금까지는 아이콘·제목·설명이 각각 별도 Text라 스크린 리더가 세 번 나눠 읽었다
    // (장식용 이모지까지 유니코드 이름으로 읽어 더 헷갈림). "제목. 설명"으로 병합하고
    // 카드 4개가 Row 안에 나란히 있어 container:true로 경계를 명시한다.
    return Semantics(
      label: '$title. $desc',
      excludeSemantics: true,
      container: true,
      child: PastelCard(
        // 목업(`.cat-card`)은 padding:10px 11px인데 지금까지는 PastelCard의 기본값인
        // 14px 균일 패딩을 그대로 썼다(2026-07-07 대조 발견).
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 2),
            // 목업(`.cat-card .d`)은 10.5px/font-weight 600인데 지금까지는 12px에
            // 기본 굵기였다(2026-07-07 대조 발견).
            Text(
              desc,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
