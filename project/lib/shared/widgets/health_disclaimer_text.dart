import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/result/ohaeng_readings.dart';

/// 건강운 면책 문구(`healthReadingDisclaimer`) — 사주 결과·상세 리포트·심층 분석
/// 세 화면이 각자 조건(상시/1회성/`Interest.health` 조건부)은 다르게 노출하지만
/// 문구 자체와 스타일은 완전히 동일하게 반복하고 있던 걸(2026-07-17 오버나이트 코드
/// 정리 발견) `GradientShareButton`과 같은 결로 공용 위젯화했다. 무인자
/// `StatelessWidget`이라 각 화면의 조건부 노출 로직은 호출하는 쪽에 그대로 둔다.
class HealthDisclaimerText extends StatelessWidget {
  const HealthDisclaimerText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      healthReadingDisclaimer,
      style: TextStyle(color: AppColors.inkSoft, fontSize: 11),
    );
  }
}
