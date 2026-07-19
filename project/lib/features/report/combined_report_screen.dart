import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/saju/four_pillars.dart';
import '../../core/saju/ganzhi.dart';
import '../../shared/share/share_capture.dart';
import '../../shared/widgets/gradient_share_button.dart';
import '../../shared/widgets/health_disclaimer_text.dart';
import '../../shared/widgets/offscreen_share_capture.dart';
import '../../shared/widgets/page_heading.dart';
import '../../shared/widgets/pastel_card.dart';
import '../birth_input/birth_info.dart';
import '../deep_dive/deep_dive_info.dart';
import '../deep_dive/deep_dive_readings.dart';
import '../result/meta_line.dart';
import '../result/ohaeng_readings.dart';
import '../result/share_card.dart';
import '../result/share_text.dart';
import 'report_readings.dart';

/// 오행별 의미. report_screen.dart의 같은 이름 상수를 그대로 옮겨왔다(그쪽은 private
/// top-level이라 import로 재사용할 수 없어 이 파일에도 동일하게 둔다 — 두 화면이 당분간
/// 함께 존재하는 과도기이므로 W8에서 report_screen.dart를 정리할 때 한쪽으로 합칠 수 있다).
final _ohaengMeaning = {
  '목': (ohaengHanja['목']!, '성장 · 시작 · 추진력', '새싹이 자라나는 이미지'),
  '화': (ohaengHanja['화']!, '열정 · 표현력 · 인기운', '따뜻한 온기의 이미지'),
  '토': (ohaengHanja['토']!, '안정 · 신뢰 · 중재', '땅에 발붙인 이미지'),
  '금': (ohaengHanja['금']!, '원칙 · 결단력 · 완성도', '정제된 금속의 이미지'),
  '수': (ohaengHanja['수']!, '지혜 · 유연함 · 통찰', '흐르는 물의 이미지'),
};

/// 통합 상세 리포트 화면(STEP 6) — 광고 게이트(관심사 선택 화면) 다음에 오는 최종
/// 화면으로, 기존 상세 리포트(report_screen.dart)와 심층 분석(deep_dive_result_screen.dart)
/// 두 화면의 내용을 하나로 합쳤다.
///
/// 참고: docs/mockups/01-pastel-cute.html STEP 6("통합 결과"). 2026-07-19 `/grill-me`
/// 합의로 승인된 W7 백로그 — 아직 이 화면으로 라우팅을 바꾸지 않았다(W8에서 처리 예정),
/// 지금은 화면 자체만 완성해둔다.
///
/// **범위 한계**: report_screen.dart와 마찬가지로 무료/유료 경계선은 아직 실제 결제/구독
/// 로직으로 구현하지 않았다 — 지금은 전체를 무료로 보여주는 MVP다.
class CombinedReportScreen extends StatefulWidget {
  const CombinedReportScreen({super.key, required this.birthInfo, required this.deepDiveInfo});

  final BirthInfo birthInfo;
  final DeepDiveInfo deepDiveInfo;

  @override
  State<CombinedReportScreen> createState() => _CombinedReportScreenState();
}

class _CombinedReportScreenState extends State<CombinedReportScreen> {
  /// 화면에는 보이지 않는 공유용 카드(ShareCard)를 캡처하기 위한 키.
  /// result_screen.dart의 ResultScreen과 같은 패턴 — 공유 카드 자체도 그대로 재사용한다.
  final _shareCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final birthInfo = widget.birthInfo;
    final deepDiveInfo = widget.deepDiveInfo;
    final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);
    final dominant = pillars.dominantOhaeng;
    final sub = pillars.subDominantOhaeng;
    final subCount = ohaengCount[sub] ?? 0;
    final callout = dominantComboCallout(dominant, sub, subCount: subCount);
    final displayName = displayNameFor(birthInfo);
    final metaLine = buildMetaLine(birthInfo);
    final mbtiComment = mbtiCommentFor(deepDiveInfo.mbti?.code);
    final mbtiNickname = mbtiNicknameFor(deepDiveInfo.mbti?.code);

    // Interest.values 선언 순서(연애·직장·재물·건강·성격)를 고정해 카드 순서가 항상
    // 일관되게 한다 — deepDiveInfo.interests는 Set이라 삽입 순서를 보장하지 않는다
    // (deep_dive_result_screen.dart와 같은 이유).
    final selectedItems = [
      for (final interest in Interest.values)
        if (deepDiveInfo.interests.contains(interest))
          (interest.icon, interest.categoryTitle, readingFor(interest, dominant, sub, subCount: subCount)),
    ];

    // 오행별 "대표 기둥"을 찾기 위한 년→월→일→시 순회 목록. 시주를 모르면(시간 미입력)
    // 목록에서 아예 빠져, 그 오행이 시주에서만 등장하는 경우엔 대표 기둥 없음으로 처리된다.
    final pillarRows = [
      ('년주', pillars.year),
      ('월주', pillars.month),
      ('일주', pillars.day),
      if (pillars.hour != null) ('시주', pillars.hour!),
    ];

    // [ohaeng]이 년→월→일→시 순서 중 처음 등장하는 기둥 이름. 한 기둥은 천간·지지
    // 두 글자를 가지므로 두 글자 중 하나라도 이 오행이면 그 기둥을 대표로 삼는다
    // (GanzhiPillar.ohaeng == [stemOhaeng, branchOhaeng], core/saju/ganzhi.dart 참고).
    // 사주 8자(또는 6자) 어디에도 그 오행이 없으면 null(목업의 "수(水) · 10%"처럼
    // 대표 기둥 표시 없이 퍼센트만 보여준다).
    String? representativePillarLabel(String ohaeng) {
      for (final row in pillarRows) {
        if (row.$2.ohaeng.contains(ohaeng)) return row.$1;
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('상세 리포트')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              key: const Key('combinedReportScrollView'),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                // 1) 페이지 제목 + 메타라인.
                PageHeading(title: '$displayName의 상세 리포트'),
                const SizedBox(height: 4),
                Text(
                  metaLine,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 20),
                // 2) 4기둥 breakdown 표 — report_screen.dart의 _PillarBreakdownTable
                // 그대로 이식(절기 정확도 안내, 납음오행·공망 배지 전부 유지).
                const _SectionHeading('명식 한 글자씩 뜯어보기'),
                const SizedBox(height: 4),
                const Text(
                  '사주는 총 4개의 기둥, 각 기둥은 천간(위)과 지지(아래) 두 글자로 이루어져요.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _PillarBreakdownTable(pillars: pillars),
                const SizedBox(height: 10),
                const Text(
                  '※ 계산 정확도 안내: 년주는 입춘을 2월 4일로 고정해 근사하고, 월주는 정확한 절기 대신 '
                  '달력상의 월을 기준으로 계산해요. 일주는 날짜 차이만으로 계산돼 절기와 무관하게 정확하지만, '
                  '절기 경계에 걸친 생일은 정통 만세력과 며칠 차이가 날 수 있어요. 또한 진태양시(출생지 경도·균시차 '
                  '보정)는 반영하지 않고 입력한 시각을 그대로 사용하며, 자시(밤 11시~새벽 1시) 출생은 일주를 '
                  '정하는 방식이 유파마다 달라 저희 결과와 차이가 날 수 있어요. 음력으로 입력한 경우에도 '
                  '지금은 양력으로 변환하지 않고 입력한 날짜를 그대로 계산에 사용해요. 그리고 한국이 '
                  '서머타임(일광절약시간제)을 시행했던 1948~1960년·1987~1988년에 태어났다면, 그 보정은 '
                  '아직 반영하지 않아 실제 시각과 최대 1시간까지 차이가 날 수 있어요.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 11, height: 1.5),
                ),
                const SizedBox(height: 32),
                // 3) MBTI 박스 — deep_dive_result_screen.dart에서 이식. birth_input에서
                // MBTI를 선택하지 않았으면(deepDiveInfo.mbti == null → mbtiComment도 null)
                // 이 섹션 자체를 표시하지 않는다.
                if (mbtiComment != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: PastelCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      color: AppColors.accentSoft,
                      showBorder: false,
                      child: Semantics(
                        label:
                            '${deepDiveInfo.mbti!.code}'
                            '${mbtiNickname != null ? ' · $mbtiNickname' : ''}. $mbtiComment',
                        excludeSemantics: true,
                        container: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mbtiNickname != null
                                  ? '${deepDiveInfo.mbti!.code} · $mbtiNickname'
                                  : deepDiveInfo.mbti!.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentText,
                                fontSize: 12,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mbtiComment,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // 4) 오행 5개 카드 — report_screen.dart의 _OhaengMeaningCard/_AllReadingsSection
                // 내용(퍼센트, 풀이 텍스트)은 그대로 두고, 목업(STEP 6 `.oheang-report-card`)처럼
                // 각 카드에 "대표 기둥"(년→월→일→시 순회 중 그 오행이 처음 등장하는 기둥)을 덧붙인다.
                const _SectionHeading('오행 五行 완전 정복'),
                const SizedBox(height: 12),
                for (final ohaeng in const ['목', '화', '토', '금', '수'])
                  _OhaengMeaningCard(
                    ohaeng: ohaeng,
                    percent: total == 0 ? 0 : (ohaengCount[ohaeng]! / total * 100).round(),
                    pillarLabel: representativePillarLabel(ohaeng),
                  ),
                const SizedBox(height: 32),
                const _SectionHeading('오행별 오늘의 풀이 모음'),
                const SizedBox(height: 4),
                const Text(
                  '다섯 가지 오행의 풀이를 모두 볼 수 있어요.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final ohaeng in const ['목', '화', '토', '금', '수'])
                  _AllReadingsSection(ohaeng: ohaeng),
                // 5) 건강운 면책 문구 — 관심사로 건강운을 골랐을 때만 노출(deep_dive_result_screen.dart와
                // 같은 조건부 로직 재사용). 위 "오행별 오늘의 풀이 모음"은 관심사 선택과 무관하게
                // 5개 오행의 4개 영역(건강 포함) 풀이를 항상 보여주지만, 면책 문구는 사용자가 실제로
                // 건강운에 관심을 표시했을 때만 보여주면 충분하다는 판단.
                if (deepDiveInfo.interests.contains(Interest.health)) ...[
                  const HealthDisclaimerText(),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 12),
                // 6) "고른 관심사부터" 섹션 — deep_dive_result_screen.dart에서 이식. 선택된
                // 관심사만(최대 5개), Interest.values 선언 순서대로 카드로 보여준다.
                const _SectionHeading('고른 관심사부터'),
                const SizedBox(height: 12),
                if (selectedItems.isEmpty)
                  const Text(
                    '관심사를 고르지 않아 보여드릴 심층 풀이가 없어요.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  )
                else
                  for (final item in selectedItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Semantics(
                        label: '${item.$2}. ${item.$3}',
                        excludeSemantics: true,
                        container: true,
                        child: PastelCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$1, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.$2,
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.$3,
                                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 10),
                // 7) 공유 버튼 — Q5 결정대로 result_screen.dart가 쓰던 오행 바 중심 ShareCard를
                // 그대로 재사용한다(DeepDiveShareCard는 이번엔 쓰지 않음).
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
              ],
            ),
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

  /// 공유용 카드를 이미지로 캡처해 텍스트와 함께 공유한다. result_screen.dart와 완전히
  /// 같은 텍스트 빌드(`buildShareText`)·캡처 로직(`shareCapturedCard`)을 그대로 재사용한다.
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

/// report_screen.dart의 `_PillarBreakdownTable`을 그대로 옮겨왔다(private top-level이라
/// import로 재사용 불가, 두 화면이 당분간 함께 존재하는 과도기라 W8 정리 때 정돈 예정).
class _PillarBreakdownTable extends StatelessWidget {
  const _PillarBreakdownTable({required this.pillars});

  final FourPillars pillars;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('년주', pillars.year, false),
      ('월주', pillars.month, false),
      // 공망(空亡)은 일주(일간·일지) 기준으로 다른 기둥의 지지를 판별하는
      // 개념이라 일주 자신은 공망 여부를 따지지 않는다 — isDayPillar만 true.
      ('일주', pillars.day, true),
      ('시주', pillars.hour, false),
    ];
    // 일주 기준으로 딱 한 번만 계산하면 되는 고정 배치(순중공망) — 년/월/시주 각
    // 지지가 이 2개 중 하나와 같으면 공망 배지를 붙인다.
    final voidBranches = voidBranchIndices(
      dayStemIndex: pillars.day.stemIndex,
      dayBranchIndex: pillars.day.branchIndex,
    );

    return PastelCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 24, color: AppColors.border),
            _pillarRow(rows[i].$1, rows[i].$2, isDayPillar: rows[i].$3, voidBranches: voidBranches),
          ],
        ],
      ),
    );
  }

  Widget _pillarRow(
    String label,
    GanzhiPillar? pillar, {
    required bool isDayPillar,
    required List<int> voidBranches,
  }) {
    if (pillar == null) {
      return Semantics(
        label: '$label. 태어난 시간을 몰라 계산하지 않았어요. '
            '태어난 시간을 알면 더 정확한 결과를 볼 수 있어요.',
        excludeSemantics: true,
        container: true,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
              ),
            ),
            const Expanded(
              child: Text(
                '태어난 시간을 몰라 시주는 계산하지 않았어요. 태어난 시간을 알면 더 정확한 결과를 볼 수 있어요',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final semanticLabel = '$label. 천간 ${pillar.stem}, 오행 ${stemOhaeng(pillar.stemIndex)}. '
        '지지 ${pillar.branch}, 오행 ${branchOhaeng(pillar.branchIndex)}.';

    final nayin = nayinFor(pillar.ganzhiIndex60);
    final isVoid = !isDayPillar && voidBranches.contains(pillar.branchIndex % 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: semanticLabel,
          excludeSemantics: true,
          container: true,
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
              ),
              Expanded(child: _charCell('천간', pillar.stem, stemOhaeng(pillar.stemIndex))),
              const SizedBox(width: 8),
              Expanded(child: _charCell('지지', pillar.branch, branchOhaeng(pillar.branchIndex))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _PillarExtras(label: label, nayin: nayin, isVoid: isVoid),
      ],
    );
  }

  Widget _charCell(String kind, String hanja, String ohaeng) {
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ohaengSoftColors[ohaeng],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(hanja, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
          const SizedBox(height: 2),
          Text('$kind · $ohaeng', style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

/// report_screen.dart의 `_PillarExtras`를 그대로 옮겨왔다(같은 이유 — 위 참고).
class _PillarExtras extends StatelessWidget {
  const _PillarExtras({required this.label, required this.nayin, required this.isVoid});

  final String label;
  final Nayin nayin;
  final bool isVoid;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ohaengTextColors[nayin.ohaeng] ?? AppColors.ink;
    final caption = isVoid
        ? '${nayinReadingFor(nayin.name)} $gongmangReadingCaption'
        : nayinReadingFor(nayin.name);

    final semanticLabel = StringBuffer('$label 납음오행 ${nayin.name}(${nayin.hanja}).');
    if (isVoid) {
      semanticLabel.write(' 공망(空亡)에 해당해요.');
    }
    semanticLabel.write(' $caption');

    return Semantics(
      label: semanticLabel.toString(),
      excludeSemantics: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ohaengSoftColors[nayin.ohaeng],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$label · ${nayin.name}(${nayin.hanja})',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              if (isVoid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '공망',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// report_screen.dart의 `_OhaengMeaningCard`를 이식하되, 목업 STEP 6(`.oheang-report-card`
/// `<h4>목(木) · 40% · 년주</h4>`)처럼 제목 줄에 퍼센트+대표 기둥을 덧붙인다. 기존 두 줄
/// (`meaning.$2` 짧은 의미, `meaning.$3` 이미지 연상 문장)은 그대로 유지한다.
class _OhaengMeaningCard extends StatelessWidget {
  const _OhaengMeaningCard({required this.ohaeng, required this.percent, required this.pillarLabel});

  final String ohaeng;
  final int percent;

  /// 대표 기둥 이름("년주" 등). 사주 8자 어디에도 이 오행이 없으면 null.
  final String? pillarLabel;

  @override
  Widget build(BuildContext context) {
    final meaning = _ohaengMeaning[ohaeng]!;
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    final pillarSuffix = pillarLabel != null ? ' · $pillarLabel' : '';
    final titleLine = '$ohaeng($percent%$pillarSuffix)';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: '$ohaeng · $percent%${pillarLabel != null ? ' · $pillarLabel' : ''}. '
            '${meaning.$2}. ${meaning.$3}',
        excludeSemantics: true,
        container: true,
        child: PastelCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ohaengSoftColors[ohaeng],
                  shape: BoxShape.circle,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(meaning.$1, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleLine, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      meaning.$2,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 2),
                    Text(meaning.$3, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// report_screen.dart의 `_AllReadingsSection`을 그대로 옮겨왔다(같은 이유 — 위 참고).
class _AllReadingsSection extends StatelessWidget {
  const _AllReadingsSection({required this.ohaeng});

  final String ohaeng;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    final readings = categoryReadingsFor(ohaeng);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$ohaeng(${_ohaengMeaning[ohaeng]!.$1}) 기운이 강할 때',
            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13),
          ),
          const SizedBox(height: 6),
          for (final reading in readings)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Semantics(
                label: '${reading.$2}: ${reading.$3}',
                excludeSemantics: true,
                container: true,
                child: Text(
                  '${reading.$1} ${reading.$2}: ${reading.$3}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// report_screen.dart의 `_SectionHeading`을 그대로 옮겨왔다(같은 이유 — 위 참고).
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16),
      ),
    );
  }
}
