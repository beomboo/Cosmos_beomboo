import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 목업(docs/mockups/01-pastel-cute.html)의 "공유하기" 버튼(`.share-btn`) — 다른 CTA
/// 버튼과 달리 단색이 아니라 accent→metal 그라데이션을 쓴다. 사주 결과 화면과 심층
/// 분석 결과 화면이 `onPressed` 콜백만 다르고 완전히 동일한 위젯 구조(그라데이션
/// Container + 투명 배경 ElevatedButton + 카메라 이모지 Text)를 각자 갖고 있던 걸
/// 공용 위젯으로 통합했다(2026-07-15 리팩터). ElevatedButton 자체는 backgroundColor를
/// 그라데이션으로 못 받아 Container로 감싸 배경을 대신 그린다.
class GradientShareButton extends StatelessWidget {
  const GradientShareButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.accent, AppColors.metal],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.accentInk,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: onPressed,
          child: const Text(
            '📸 공유하기',
            semanticsLabel: '공유하기',
          ),
        ),
      ),
    );
  }
}
