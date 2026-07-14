import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../shared/widgets/pastel_card.dart';

/// 심층 분석 결과 공유용 9:16 카드 — `result_screen.dart`의 `ShareCard`와 같은 고정
/// 크기 규격(360x640)을 그대로 재사용한다. 화면에는 보이지 않고(화면 밖에 배치)
/// `RepaintBoundary.toImage()`로만 캡처된다.
///
/// `docs/mockups/01-pastel-cute.html`에는 MBTI/심층 분석 섹션 자체가 없어 새 시각
/// 디자인을 목업에서 직접 대조할 수 없다 — 대신 `ShareCard`/`PastelCard`/`accentSoft` 등
/// 이미 목업에서 파생된 컴포넌트·색 토큰만 재사용한다. MBTI 강조 박스는 오행과 무관한
/// 성향 설명이라 오행색 대신 항상 `accentSoft`를 쓴다(`docs/research/MBTI/현황.md`가
/// 명시적으로 재확인한 원칙 — 오행색을 쓰면 마치 MBTI가 오행에 종속된 값처럼 보일 수 있음).
class DeepDiveShareCard extends StatelessWidget {
  const DeepDiveShareCard({
    super.key,
    required this.displayName,
    required this.metaLine,
    this.mbtiCode,
    this.mbtiComment,
    required this.items,
  });

  final String displayName;
  final String metaLine;

  /// 둘 다 null이 아닐 때만 MBTI 강조 박스를 보여준다.
  final String? mbtiCode;
  final String? mbtiComment;

  /// (아이콘, 제목, 풀이) — 선택된 관심사 카드. 카드 높이가 고정(640)이라 최대 4개만 그린다.
  final List<(String, String, String)> items;

  static const _width = 360.0;
  static const _height = 640.0;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(4).toList();
    final hasMbti = mbtiCode != null && mbtiComment != null;

    // ShareCard와 같은 이유(공유하는 사람의 기기 글자 크기 설정과 무관하게 항상 디자인대로
    // 렌더링해야 고정 높이 640을 넘기는 RenderFlex overflow를 피할 수 있다)로 배율을 고정한다.
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
              '$displayName의 심층 분석 ✨',
              // ShareCard와 같은 이유(이름 최대 20자까지 가능해 줄바꿈 없이 두면 고정 높이를
              // 넘기는 RenderFlex overflow를 실측으로 확인함) — 두 줄까지만 허용한다.
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
            if (hasMbti) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$mbtiCode — $mbtiComment',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (visibleItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              for (final item in visibleItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ItemCard(item: item),
                ),
            ],
            const Spacer(),
            const Center(
              child: Text(
                '#사주랑  #심층분석  #MBTI',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final (String, String, String) item;

  @override
  Widget build(BuildContext context) {
    final (icon, title, desc) = item;
    return PastelCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  // 심층 분석 결과 화면 카드(deep_dive_result_screen.dart)와 달리 이 카드는
                  // 최대 4개가 고정 높이(640) 안에 함께 들어가야 해서 2줄로 더 제한한다.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
