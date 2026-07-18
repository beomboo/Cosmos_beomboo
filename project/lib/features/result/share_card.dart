import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/saju/four_pillars.dart';
import '../../core/saju/ganzhi.dart';
import '../../shared/widgets/pastel_card.dart';
import '../../shared/widgets/share_card_scaffold.dart';

/// 공유용 9:16 카드 — 실제 화면(스크롤 가능한 ResultScreen)과 별개로,
/// 캡처해서 이미지로 공유하기 위한 고정 크기 요약 카드.
/// 참고: docs/mockups/01-pastel-cute.html STEP 4의 "인스타 스토리로 공유하기" 컨셉.
/// 화면에는 보이지 않고(화면 밖에 배치) `RepaintBoundary.toImage()`로만 캡처된다.
///
/// 고정 크기(360x640)·텍스트 배율 고정·이름/메타라인 헤더·해시태그 푸터는
/// `DeepDiveShareCard`(심층 분석 결과 화면)와 완전히 동일해 공용 `ShareCardScaffold`로
/// 옮겼고, 이 위젯은 그 위에 4기둥+콜아웃+오행 밸런스 바 본문만 채운다.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.displayName,
    required this.metaLine,
    required this.pillars,
    required this.dominant,
    required this.calloutHanja,
    required this.calloutEmoji,
    required this.calloutText,
    required this.ohaengCount,
    required this.total,
  });

  final String displayName;
  final String metaLine;
  final FourPillars pillars;
  final String dominant;
  final String calloutHanja;
  final String calloutEmoji;
  final String calloutText;
  final Map<String, int> ohaengCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ShareCardScaffold(
      title: '$displayName의 사주팔자 ✨',
      metaLine: metaLine,
      hashtags: '#사주랑  #사주팔자  #오행',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              _pillarChip('년주', pillars.year.label, pillars.year.stemIndex),
              // 목업(`.pillars`)은 gap:7px인데 지금까지는 8px이었다
              // (2026-07-18 오버나이트 대조 발견).
              const SizedBox(width: 7),
              _pillarChip('월주', pillars.month.label, pillars.month.stemIndex),
              const SizedBox(width: 7),
              _pillarChip('일주', pillars.day.label, pillars.day.stemIndex),
              const SizedBox(width: 7),
              _pillarChip('시주', pillars.hour?.label ?? '모름', pillars.hour?.stemIndex),
            ],
          ),
          const SizedBox(height: 24),
          // result_screen.dart와 같은 이유(목업 `.callout`은 우세 오행 색으로 물듦)로
          // accentSoft/ink 고정 대신 우세 오행 색을 쓴다(2026-07-06 대조 발견).
          SizedBox(
            width: double.infinity,
            child: PastelCard(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              borderRadius: 16,
              color: AppColors.ohaengSoftColors[dominant] ?? AppColors.accentSoft,
              showBorder: false,
              child: Text(
                '$dominant($calloutHanja) 기운이 강한 타입이에요 $calloutEmoji\n$calloutText',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ohaengTextColors[dominant] ?? AppColors.ink,
                  height: 1.55,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '오행 밸런스',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 14),
          ),
          const SizedBox(height: 10),
          for (final ohaeng in const ['목', '화', '토', '금', '수']) _balanceRow(ohaeng),
        ],
      ),
    );
  }

  Widget _pillarChip(String label, String hanja, int? stemIndex) {
    final color = stemIndex == null
        ? AppColors.inkSoft
        : (AppColors.ohaengTextColors[stemOhaeng(stemIndex)] ?? AppColors.ink);
    return Expanded(
      child: PastelCard(
        padding: const EdgeInsets.symmetric(vertical: 10),
        borderRadius: 12,
        child: Column(
          children: [
            Text(hanja, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13)),
            const SizedBox(height: 4),
            // result_screen.dart의 _PillarCard와 같은 이유(목업 `.pillar-card .label`은
            // 9.5px/font-weight 700)로 맞춘다(2026-07-07 대조 발견).
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
    );
  }

  Widget _balanceRow(String ohaeng) {
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    final percent = total == 0 ? 0.0 : (ohaengCount[ohaeng]! / total * 100);
    // result_screen.dart의 _OhaengBarRow와 같은 이유(목업 `.bar-row .tag`는 한글이 아니라
    // 한자)로 한자를 대신 표시한다(색상/집계는 한글 ohaeng 그대로 사용, 2026-07-06 대조 발견).
    // 한자 값은 core/saju/ganzhi.dart의 공용 상수 `ohaengHanja`를 재사용한다.
    final hanja = ohaengHanja[ohaeng] ?? ohaeng;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 16, child: Text(hanja, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12))),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 7,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 32,
            child: Text(
              '${percent.round()}%',
              textAlign: TextAlign.end,
              // result_screen.dart의 _OhaengBarRow와 같은 이유(목업 `.bar-row .pct`는
              // font-weight 700)로 굵기를 맞춘다(2026-07-07 대조 발견, 크기는 이미
              // 10px로 목업과 일치했음).
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
