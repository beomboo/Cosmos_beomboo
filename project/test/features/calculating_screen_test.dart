import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/calculating/calculating_screen.dart';

void main() {
  // 이 화면의 궤도 애니메이션은 AnimationController.repeat()로 무한 반복되므로
  // pumpAndSettle()을 쓰면 영원히 끝나지 않는다 — pump()로 프레임을 직접 진행시킨다.

  testWidgets('로딩 문구와 캡션을 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.result) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('RESULT_STUB')),
              settings: settings,
            );
          }
          return MaterialPageRoute(builder: (_) => const CalculatingScreen());
        },
        initialRoute: '/',
      ),
    );
    await tester.pump();

    expect(find.text('사주팔자를 계산하고 있어요...'), findsOneWidget);
    expect(find.text('평균 3초 소요돼요'), findsOneWidget);

    // 화면을 옮기지 않은 채 테스트를 끝내면 내부 Future.delayed(3초) 타이머가
    // pending 상태로 남아 "A Timer is still pending" 오류가 나므로, 미리 3초를
    // 흘려보내 타이머가 발화(→ result로 이동)하도록 만든 뒤 테스트를 마친다.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
  });

  testWidgets('로딩 문구가 1.8초 간격으로 다음 문구로 순환된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.result) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('RESULT_STUB')),
              settings: settings,
            );
          }
          return MaterialPageRoute(builder: (_) => const CalculatingScreen());
        },
        initialRoute: '/',
      ),
    );
    await tester.pump();

    expect(find.text('사주팔자를 계산하고 있어요...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('오행 기운을 분석하는 중...'), findsOneWidget);

    // 3초 뒤 result로 이동하기 전(1.8초 x 2 = 3.6초는 못 채우므로) 두 번째 문구까지만
    // 실제로 보이는 게 정상이다 — 남은 타이머를 흘려보내 테스트를 깔끔히 마친다.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
  });

  testWidgets('"동작 줄이기"를 켠 상태에서는 궤도 회전이 멈춰 있다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        // MaterialApp 자체가 만드는 MediaQuery를 builder에서 덮어써야 CalculatingScreen까지
        // disableAnimations: true가 전달된다(MaterialApp을 감싸는 방식으로는 무시됨).
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.result) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('RESULT_STUB')),
              settings: settings,
            );
          }
          return MaterialPageRoute(builder: (_) => const CalculatingScreen());
        },
        initialRoute: '/',
      ),
    );
    await tester.pump();

    final before = tester.getTopLeft(find.text('🌿'));
    await tester.pump(const Duration(seconds: 1));
    final after = tester.getTopLeft(find.text('🌿'));

    expect(after, equals(before));

    // 남은 타이머(3초 뒤 이동)를 흘려보내 "A Timer is still pending" 오류를 막는다.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });

  testWidgets('3초 후 전달받은 BirthInfo를 그대로 들고 result 화면으로 이동한다', (tester) async {
    final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);
    Object? capturedAtResult;

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.result) {
            capturedAtResult = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('RESULT_STUB')),
              settings: settings,
            );
          }
          return MaterialPageRoute(
            builder: (_) => const CalculatingScreen(),
            settings: RouteSettings(arguments: birthInfo),
          );
        },
        initialRoute: '/',
      ),
    );

    await tester.pump();
    expect(find.text('RESULT_STUB'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('RESULT_STUB'), findsOneWidget);
    expect(capturedAtResult, same(birthInfo));
  });
}
