import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';
import 'package:cosmos_saju/features/calculating/calculating_screen.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_input_screen.dart';
import 'package:cosmos_saju/features/report/report_screen.dart';
import 'package:cosmos_saju/features/result/result_screen.dart';

void main() {
  // 지금까지 각 화면 테스트는 화면 위젯을 직접 생성해서 검증했을 뿐, main.dart가 실제로
  // 쓰는 AppRoutes.routes 맵을 거쳐 이름 기반 네비게이션(pushNamed)으로 도달했을 때도
  // 같은 화면이 뜨는지는 한 번도 검증한 적이 없었다 — 이 파일이 그 빈틈을 메운다.
  group('AppRoutes.routes', () {
    testWidgets('birthInput 경로는 BirthInputScreen을 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(routes: AppRoutes.routes, initialRoute: AppRoutes.birthInput),
      );

      expect(find.byType(BirthInputScreen), findsOneWidget);
    });

    testWidgets('calculating 경로는 CalculatingScreen을 보여주고, 3초 뒤 result로 자동 이동한다',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(routes: AppRoutes.routes, initialRoute: AppRoutes.calculating),
      );

      expect(find.byType(CalculatingScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.byType(ResultScreen), findsOneWidget);
    });

    testWidgets('result 경로는 ResultScreen을 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(routes: AppRoutes.routes, initialRoute: AppRoutes.result),
      );

      expect(find.byType(ResultScreen), findsOneWidget);
    });

    testWidgets('report 경로는 ReportScreen을 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(routes: AppRoutes.routes, initialRoute: AppRoutes.report),
      );

      expect(find.byType(ReportScreen), findsOneWidget);
    });

    testWidgets('deepDiveInput 경로는 DeepDiveInputScreen을 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(routes: AppRoutes.routes, initialRoute: AppRoutes.deepDiveInput),
      );

      expect(find.byType(DeepDiveInputScreen), findsOneWidget);
    });
  });
}
