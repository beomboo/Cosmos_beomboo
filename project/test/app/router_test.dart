import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';
import 'package:cosmos_saju/features/calculating/calculating_screen.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_input_screen.dart';
import 'package:cosmos_saju/features/report/report_screen.dart';
import 'package:cosmos_saju/features/result/result_screen.dart';

import '../support/test_viewport.dart';

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

  group('birthInput → calculating → result 실제 체이닝(pushReplacementNamed → pushReplacementNamed)', () {
    // 지금까지의 테스트는 전부 initialRoute로 각 화면에 곧장 도달했을 뿐, 실제 앱처럼
    // birthInput에서 calculating으로, calculating이 다시 result로 이어지는 진짜 스택
    // 모양을 만들어본 적이 없었다. **2026-07-13 변경**: birth_input_screen.dart의
    // `_submit()`이 이전에는 `pushNamed()`를 써서 BirthInputScreen이 스택에 그대로
    // 남아 있었다 — 그 결과 calculating 화면(→result로 교체된 뒤)에서 기기 뒤로가기를
    // 누르면 "다시 입력하기"의 명시적 확인·초기화 없이 곧장 BirthInputScreen(같은 인스턴스,
    // 입력값 그대로)으로 돌아갈 수 있는 실제 버그였다(2026-07-08 발견). `pushNamed()`를
    // `pushReplacementNamed()`로 바꿔 이 화면 자체를 스택에서 제거했으니, 이제 result
    // 화면에서는 뒤로 갈 곳이 없어야 한다 — 아래는 이 수정을 "제거→재현→복원" 방식으로
    // 검증했다(pushNamed로 되돌리면 canPop()이 다시 true가 되고 BackButton이 다시
    // 나타나는 것을 실측으로 확인한 뒤, pushReplacementNamed로 복원해 이 테스트가 통과함).
    testWidgets('실제로 이 경로를 타면 BirthInputScreen이 스택에서 제거돼 ResultScreen에 뒤로 가기 버튼이 없다',
        (tester) async {
      await useTallViewport(tester, height: 1600);

      await tester.pumpWidget(
        MaterialApp(
          // main.dart와 동일한 로케일 설정 — showDatePicker/showTimePicker의 "확인" 버튼
          // 등을 한국어로 띄우기 위함(이 테스트가 실제로 그 버튼을 탭해야 한다).
          locale: const Locale('ko', 'KR'),
          supportedLocales: const [Locale('ko', 'KR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.birthInput,
        ),
      );

      // 2026-07-17 버그 수정 이후 날짜/시간을 실제로 고르기 전까지는 제출 버튼이
      // 비활성화된다 — 먼저 "확인"으로 확정해 활성화시킨다.
      await tester.tap(find.text('날짜를 선택해주세요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시간을 선택해주세요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('사주 보러가기 🔮'));
      // _submit()이 BirthInfoStore.save()/DeepDiveInfoStore.save()를 await한 뒤에야
      // pushReplacementNamed()를 호출하므로, 탭 직후 한 번의 pump()만으로는 그 비동기
      // 저장이 아직 안 끝나 있을 수 있다 — 저장이 끝날 시간을 먼저 흘려보낸다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // calculating 화면 전환 애니메이션 + 3초 타이머 + result 전환 애니메이션까지
      // 궤도 애니메이션(무한 반복)이 있어 pumpAndSettle()은 쓸 수 없다.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CalculatingScreen), findsOneWidget);
      // BirthInputScreen이 pushReplacementNamed로 이미 스택에서 제거됐으니, calculating
      // 화면 자체에도 뒤로 가기 버튼이 없어야 한다.
      expect(find.byType(BackButton), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ResultScreen), findsOneWidget);

      // BirthInputScreen이 스택에서 제거됐으니 canPop()이 false이고, Flutter가 AppBar에
      // 자동으로 뒤로 가기 버튼을 붙이지 않는다.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      expect(navigator.canPop(), isFalse);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(BirthInputScreen), findsNothing);
    });
  });
}
