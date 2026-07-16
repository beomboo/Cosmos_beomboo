import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 파스텔 큐트 컨셉의 기본 카드 컨테이너 (흰 배경 + 옅은 테두리 + 둥근 모서리).
/// 결과 화면의 기둥 카드·카테고리 카드 등 반복되는 카드 스타일을 공용화한 것.
class PastelCard extends StatelessWidget {
  const PastelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    // 목업(docs/mockups/01-pastel-cute.html)의 `.pillar-card`/`.cat-card`는 실제로
    // 13px 모서리 반경을 쓰는데, 이 위젯을 쓰는 4기둥 카드·카테고리 카드·심층 분석
    // 카드·상세 리포트 카드 전부 지금까지 이 기본값을 그대로 써서 16px이었다
    // (2026-07-07 대조 발견).
    this.borderRadius = 13,
    this.color = AppColors.bgCard,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// 카드 배경색. 기본값은 기존 흰 배경(`AppColors.bgCard`)과 동일 — 우세 오행
  /// 콜아웃/MBTI 강조 박스처럼 배경색이 다른 톤 박스도 이 위젯 하나로 표현하기 위해 추가.
  final Color color;

  /// 옅은 테두리 표시 여부. 기본값 `true`(기존 동작과 동일). 톤 박스처럼 테두리 없이
  /// 배경색만으로 구분하는 카드는 `false`로 끈다.
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder ? Border.all(color: AppColors.border) : null,
      ),
      child: child,
    );
  }
}
