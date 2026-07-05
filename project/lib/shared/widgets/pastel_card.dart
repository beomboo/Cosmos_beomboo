import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 파스텔 큐트 컨셉의 기본 카드 컨테이너 (흰 배경 + 옅은 테두리 + 둥근 모서리).
/// 결과 화면의 기둥 카드·카테고리 카드 등 반복되는 카드 스타일을 공용화한 것.
class PastelCard extends StatelessWidget {
  const PastelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
