import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/app/theme/app_colors.dart';
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

  testWidgets('"달"이 목업대로 흰색→earthSoft→earth 방사형 그라데이션을 쓴다', (tester) async {
    // 2026-07-06에 단색 accentSoft 원에서 방사형 그라데이션으로 고쳤는데, 그 뒤로도
    // 실제 그라데이션 색상 값을 확인하는 테스트는 없었다.
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

    final moonContainer = tester.widgetList<Container>(find.byType(Container)).firstWhere(
          (c) => (c.decoration as BoxDecoration?)?.gradient is RadialGradient,
        );
    final gradient = (moonContainer.decoration! as BoxDecoration).gradient! as RadialGradient;
    expect(gradient.colors, [Colors.white, AppColors.earthSoft, AppColors.earth]);

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

    // 궤도 회전뿐 아니라 로딩 문구 순환 타이머(_messageTimer)도 같은
    // disableAnimations 가드를 갖고 있는데, 지금까지는 이 분기를 실제로 통과시켜
    // "1.8초가 지나도 문구가 그대로인지"를 확인한 테스트가 없었다 — 궤도 회전
    // 테스트는 1초만 흘려보내 1.8초 문턱을 아예 넘지 않았고, 문구 순환 테스트는
    // 반대로 disableAnimations를 켜지 않았다. 여기서 0.8초를 더 흘려보내(총 1.8초
    // 경과, 문구 타이머가 처음 발화하는 시점) 문구가 첫 문구 그대로인지 확인한다.
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('사주팔자를 계산하고 있어요...'), findsOneWidget);

    // 남은 타이머(3초 뒤 이동, 지금까지 1.8초 경과)를 흘려보내 "A Timer is still
    // pending" 오류를 막는다.
    await tester.pump(const Duration(milliseconds: 1200));
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

  testWidgets('3초가 되기 전에 화면을 벗어나면(뒤로 가기) 타이머가 지나도 안전하게 무시된다',
      (tester) async {
    // initState()의 Future.delayed(3초) 콜백은 `if (!mounted) return;`으로 방어돼 있는데,
    // 지금까지는 이 방어 코드가 실제로 필요한 상황(타이머가 끝나기 전에 화면이 이미
    // dispose된 경우)을 재현해본 적이 없었다 — 사용자가 계산 중 화면에서 시스템
    // 뒤로 가기를 누르는 건 실제로 충분히 일어날 수 있는 흐름이다. 이 가드가 없었다면
    // dispose된 State에서 Navigator.of(context)를 호출하려다 예외가 났을 것이다.
    final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CalculatingScreen(),
                    settings: RouteSettings(arguments: birthInfo),
                  ),
                ),
                child: const Text('홈'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('홈'));
    await tester.pump();
    // 페이지 전환 애니메이션(기본 300ms)을 흘려보낸다 — CalculatingScreen 자체의
    // 궤도 애니메이션은 무한 반복이라 pumpAndSettle()을 쓸 수 없으므로 pump()로 진행.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CalculatingScreen), findsOneWidget);

    // 3초가 되기 전(1초 시점)에 시스템 뒤로 가기를 흉내내 화면을 pop한다.
    await tester.pump(const Duration(seconds: 1));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    // pop 전환 애니메이션도 흘려보낸다 — CalculatingScreen의 궤도 애니메이션이
    // dispose되기 전까지는 여전히 무한 반복 중이라 pumpAndSettle()을 쓸 수 없다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CalculatingScreen), findsNothing);
    expect(find.text('홈'), findsOneWidget);

    // 남은 시간(2초+)을 흘려보내도 예외 없이 그대로 "홈" 화면에 남아있어야 한다
    // (mounted 가드 덕분에 Navigator.pushReplacementNamed가 호출되지 않음).
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('홈'), findsOneWidget);
  });

  testWidgets('궤도 이모지는 온보딩 마스코트처럼 장식용이라 시맨틱스 트리에서 조회되지 않는다', (tester) async {
    // 온보딩 마스코트(onboarding_screen.dart)와 같은 이유로 ExcludeSemantics로 감쌌는지
    // 확인한다. 위젯 트리에는 여전히 '🌿' Text가 있지만(find.text로는 찾을 수 있음),
    // 시맨틱스 트리에는 아예 노드가 만들어지지 않아야 한다.
    final semantics = tester.ensureSemantics();

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

    expect(find.text('🌿'), findsOneWidget);
    expect(find.bySemanticsLabel('🌿'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    semantics.dispose();
  });

  testWidgets('로딩 문구는 liveRegion으로 감싸져 있어 스크린 리더가 갱신을 자동으로 안내한다', (tester) async {
    final semantics = tester.ensureSemantics();

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

    expect(
      tester.getSemantics(find.text('사주팔자를 계산하고 있어요...')),
      matchesSemantics(label: '사주팔자를 계산하고 있어요...', isLiveRegion: true),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    semantics.dispose();
  });
}
