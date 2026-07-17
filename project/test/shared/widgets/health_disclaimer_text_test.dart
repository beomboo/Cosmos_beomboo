import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/features/result/ohaeng_readings.dart';
import 'package:cosmos_saju/shared/widgets/health_disclaimer_text.dart';

void main() {
  // 2026-07-17 오버나이트 코드 정리: result_screen.dart(상시)/report_screen.dart(1회성)/
  // deep_dive_result_screen.dart(Interest.health 조건부) 세 화면이 각자 갖고 있던
  // healthReadingDisclaimer Text(스타일까지 동일)를 HealthDisclaimerText로 통합했다.
  // 각 화면의 노출 조건(호출부 로직)과 별개로 이 위젯 자체가 정확한 문구/스타일을
  // 렌더링하는지 직접 겨냥해 검증한다.

  testWidgets('healthReadingDisclaimer 문구가 화면에 그대로 보인다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HealthDisclaimerText()),
      ),
    );

    expect(find.text(healthReadingDisclaimer), findsOneWidget);
  });

  testWidgets('스타일이 inkSoft 색상·11 폰트 크기로 고정된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HealthDisclaimerText()),
      ),
    );

    final text = tester.widget<Text>(find.text(healthReadingDisclaimer));
    expect(text.style?.color, AppColors.inkSoft);
    expect(text.style?.fontSize, 11);
  });
}
