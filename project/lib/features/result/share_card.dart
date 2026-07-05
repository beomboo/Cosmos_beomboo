import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/saju/four_pillars.dart';
import '../../core/saju/ganzhi.dart';

/// 공유용 9:16 카드 — 실제 화면(스크롤 가능한 ResultScreen)과 별개로,
/// 캡처해서 이미지로 공유하기 위한 고정 크기 요약 카드.
/// 참고: docs/mockups/01-pastel-cute.html STEP 4의 "인스타 스토리로 공유하기" 컨셉.
/// 화면에는 보이지 않고(화면 밖에 배치) `RepaintBoundary.toImage()`로만 캡처된다.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.displayName,
    required this.metaLine,
    required this.pillars,
    required this.dominant,
    required this.calloutHanja,
    required this.calloutText,
    required this.ohaengCount,
    required this.total,
  });

  final String displayName;
  final String metaLine;
  final FourPillars pillars;
  final String dominant;
  final String calloutHanja;
  final String calloutText;
  final Map<String, int> ohaengCount;
  final int total;

  static const _width = 360.0;
  static const _height = 640.0;

  @override
  Widget build(BuildContext context) {
    // 이 카드는 인스타 스토리 규격(9:16)에 맞춘 고정 픽셀 크기 이미지로 캡처되는
    // 용도라, 공유하는 사람의 기기 글자 크기 설정을 그대로 물려받으면 안 된다 —
    // 실제로 시스템 글자 크기를 키운 상태에서 캡처하면 이 Column이 고정 높이(640)를
    // 크게 넘겨(RenderFlex overflow) 잘린 이미지가 공유되는 것을 확인했다. 받는
    // 사람은 어차피 보내는 사람의 접근성 설정과 무관하게 이미지를 보므로, 이 카드
    // 안에서는 항상 배율 1.0으로 고정해 디자인대로 렌더링한다.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.0,
      child: Container(
        width: _width,
        height: _height,
        color: AppColors.bg,
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$displayName의 사주팔자 ✨',
              // 이름은 최대 20자(birth_input의 입력 제한)까지 가능해서 줄바꿈 없이 두면
              // 이 카드의 고정 높이(640)를 넘겨 RenderFlex overflow가 나는 걸 실측으로 확인함
              // — 두 줄까지만 허용하고 그래도 넘치면 말줄임표로 자른다.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              metaLine,
              // 출생지가 최대 30자까지 들어갈 수 있어(birth_input 입력 제한) 한 줄로
              // 제한해두지 않으면 이름과 마찬가지로 카드 높이를 넘길 수 있다.
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _pillarChip('년주', pillars.year.label, pillars.year.stemIndex),
                const SizedBox(width: 8),
                _pillarChip('월주', pillars.month.label, pillars.month.stemIndex),
                const SizedBox(width: 8),
                _pillarChip('일주', pillars.day.label, pillars.day.stemIndex),
                const SizedBox(width: 8),
                _pillarChip('시주', pillars.hour?.label ?? '모름', pillars.hour?.stemIndex),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$calloutHanja($dominant) 기운이 강한 타입이에요\n$calloutText',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '오행 밸런스',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 14),
            ),
            const SizedBox(height: 10),
            for (final ohaeng in const ['목', '화', '토', '금', '수']) _balanceRow(ohaeng),
            const Spacer(),
            const Center(
              child: Text(
                '#사주랑  #사주팔자  #오행',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillarChip(String label, String hanja, int? stemIndex) {
    final color = stemIndex == null
        ? AppColors.inkSoft
        : (AppColors.ohaengTextColors[stemOhaeng(stemIndex)] ?? AppColors.ink);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(hanja, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _balanceRow(String ohaeng) {
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    final percent = total == 0 ? 0.0 : (ohaengCount[ohaeng]! / total * 100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 16, child: Text(ohaeng, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12))),
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
              style: const TextStyle(fontSize: 10, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
