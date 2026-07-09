import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';
import 'package:cosmos_saju/features/calculating/calculating_screen.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_input_screen.dart';
import 'package:cosmos_saju/features/report/report_screen.dart';
import 'package:cosmos_saju/features/result/result_screen.dart';

void main() {
  // birthInput→calculating 체이닝 테스트가 실제로 BirthInfoStore.save()/
  // DeepDiveInfoStore.save()(둘 다 SharedPreferences 사용)를 거치므로 목 값 초기화가
  // 필요하다 — 기존 그룹(각 화면에 initialRoute로 곧장 도달)은 저장을 거치지 않아
  // 지금까지 필요 없었다.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  group('birthInput → calculating → result 실제 체이닝(pushNamed → pushReplacementNamed)', () {
    // 지금까지의 테스트는 전부 initialRoute로 각 화면에 곧장 도달했을 뿐, 실제 앱처럼
    // birthInput에서 pushNamed로 calculating을 "쌓고" calculating이 pushReplacementNamed로
    // result로 "교체"하는 진짜 스택 모양(BirthInputScreen이 그 아래 그대로 남음)을
    // 만들어본 적이 없었다 — 2026-07-08에 발견한 실제 버그(BirthInputScreen이 스택에
    // 남아 있어 ResultScreen에 자동 뒤로 가기 버튼이 생기고, 이 버튼이 "다시 입력하기"의
    // 명시적 초기화를 건너뛰는 경로가 됨, birth_input_screen.dart 행 참고)를 일으킨
    // 바로 그 스택 모양이라 별도로 명시적 테스트를 남겨둔다.
    testWidgets('실제로 이 경로를 타면 BirthInputScreen이 스택에 남아 ResultScreen에 자동 뒤로 가기 버튼이 생긴다',
        (tester) async {
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      await tester.pumpWidget(
        MaterialApp(routes: AppRoutes.routes, initialRoute: AppRoutes.birthInput),
      );

      await tester.tap(find.text('사주 보러가기 🔮'));
      // _submit()이 BirthInfoStore.save()/DeepDiveInfoStore.save()를 await한 뒤에야
      // pushNamed()를 호출하므로, 탭 직후 한 번의 pump()만으로는 그 비동기 저장이
      // 아직 안 끝나 있을 수 있다 — 저장이 끝날 시간을 먼저 흘려보낸다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // calculating 화면 전환 애니메이션 + 3초 타이머 + result 전환 애니메이션까지
      // 궤도 애니메이션(무한 반복)이 있어 pumpAndSettle()은 쓸 수 없다.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CalculatingScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ResultScreen), findsOneWidget);

      // BirthInputScreen이 여전히 스택에 살아있어 canPop()이 true이고, 그래서
      // Flutter가 AppBar에 자동으로 뒤로 가기 버튼을 붙인다.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(navigator.canPop(), isTrue);
      expect(find.byType(BackButton), findsOneWidget);

      // 그 버튼을 누르면 "다시 입력하기"의 확인 다이얼로그 없이 곧장 BirthInputScreen
      // (같은 인스턴스, 필드값 그대로)으로 돌아간다 — 정확히 이 경로가 위 버그의 원인이었다.
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BirthInputScreen), findsOneWidget);
      expect(find.byType(ResultScreen), findsNothing);
    });
  });
}
