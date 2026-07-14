import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/features/onboarding/onboarding_screen.dart';

void main() {
  Widget buildApp({Object? Function(RouteSettings)? onBirthInputRoute}) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.birthInput) {
          onBirthInputRoute?.call(settings);
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('BIRTH_INPUT_STUB')),
          );
        }
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      },
      initialRoute: '/',
    );
  }

  testWidgets('헤드라인과 설명 문구, 워드마크를 보여준다', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('사주랑'), findsOneWidget);
    expect(find.text('내 안의 오행,\n3분이면 알 수 있어요'), findsOneWidget);
    expect(find.text('생년월일시만 입력하면 끝!\n어려운 명리학 용어 없이 쉽게 풀어드려요'), findsOneWidget);
    expect(find.text('시작하기 →'), findsOneWidget);
    expect(find.text('어떻게 계산되나요?'), findsOneWidget);
  });

  testWidgets('"시작하기"를 누르면 생년월일시 입력 화면으로 이동한다', (tester) async {
    var navigated = false;
    await tester.pumpWidget(buildApp(onBirthInputRoute: (_) => navigated = true));

    await tester.tap(find.text('시작하기 →'));
    await tester.pumpAndSettle();

    expect(navigated, isTrue);
    expect(find.text('BIRTH_INPUT_STUB'), findsOneWidget);
  });

  testWidgets('"어떻게 계산되나요?"를 누르면 계산 방식 설명 다이얼로그가 뜨고, "확인"으로 닫힌다', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('어떻게 계산되나요?'), findsOneWidget);
    await tester.tap(find.text('어떻게 계산되나요?'));
    await tester.pumpAndSettle();

    // 다이얼로그가 뜨면 제목("어떻게 계산되나요?")이 화면에 2번(링크 버튼 + 다이얼로그 타이틀) 나타난다.
    expect(find.text('어떻게 계산되나요?'), findsNWidgets(2));
    expect(find.textContaining('60갑자(간지)로 변환해'), findsOneWidget);
    // report_screen.dart의 정확도 안내와 같은 취지로, 자시(23시~1시)·지역 시차 보정 한계도
    // 온보딩 시점에 미리 알려준다 — 2026-07-06에 이 두 항목을 새로 추가했다.
    expect(find.textContaining('자시'), findsOneWidget);
    // 2026-07-06 추가 발견: 음력 입력이 양력으로 변환되지 않고 그대로 계산에 쓰인다는
    // 한계도 지금까지 온보딩에서 전혀 알리지 않고 있었다 — 함께 안내하도록 추가.
    expect(find.textContaining('음력'), findsOneWidget);
    // 2026-07-08 발견: 2026-07-07에 문서화된 다섯 번째 정확도 이슈(한국의 역사적
    // 서머타임 미반영)가 report_screen.dart 안내 문구엔 지금까지 빠져 있었던 것과
    // 같은 이유로 온보딩에서도 전혀 알리지 않고 있었다 — 함께 안내하도록 추가.
    expect(find.textContaining('서머타임'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('어떻게 계산되나요?'), findsOneWidget);
    expect(find.textContaining('60갑자(간지)로 변환해'), findsNothing);
  });

  testWidgets('시스템 글자 크기를 크게(2배) 키워도 RenderFlex overflow가 나지 않는다', (tester) async {
    // result_screen.dart(카테고리 그리드)·share_card.dart에서 실제로 겪었던 고정
    // 높이+큰 글자 조합 RenderFlex overflow가 이 화면에도 있는지 지금까지 확인한
    // 적이 없었다 — 온보딩은 세로로 쌓이는 단순 Column 레이아웃이라 실제로는
    // 재현되지 않음을 확인(코드 변경 없이 회귀 방지용으로 고정).
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: buildApp(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('랜드스케이프처럼 세로 폭이 좁은 뷰포트에서도 RenderFlex overflow가 나지 않는다', (
    tester,
  ) async {
    // 실제 랜드스케이프 기기 뷰포트(예: 812x375)에서 고정 Column(Spacer 2개 포함)이
    // "RenderFlex overflowed by 62 pixels" 예외를 냈다(2026-07-14 발견). 온보딩은
    // 앱의 첫 진입 화면이라 기기가 이미 가로 방향이면 사용자가 바로 이 오버플로우
    // 경고를 보게 된다 — 스크롤 가능하도록 고친 뒤에도 재발하지 않는지 고정한다.
    final originalSize = tester.view.physicalSize;
    final originalDpr = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(812, 375);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalDpr;
    });

    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('저가/폴더블 기기 수준의 더 좁은 랜드스케이프(568x320)에서도 overflow가 나지 않고 스크롤된다', (
    tester,
  ) async {
    // 812x375보다도 세로 폭이 더 좁은 극단적인 랜드스케이프(예: 저가 안드로이드 기기나
    // 폴더블 커버 화면)에서 콘텐츠가 뷰포트보다 커도 LayoutBuilder+SingleChildScrollView
    // 조합이 오버플로우 없이 스크롤로 흡수하는지 확인한다.
    final originalSize = tester.view.physicalSize;
    final originalDpr = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalDpr;
    });

    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(tester.takeException(), isNull);

    // 스크롤로 흡수된 상태라면 "시작하기" 버튼까지 스크롤해서 실제로 탭할 수 있어야 한다
    // (오버플로우 예외만 없고 조작 불가능한 상태로 남는 회귀를 막기 위함).
    await tester.scrollUntilVisible(
      find.text('시작하기 →'),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('시작하기 →'));
    await tester.pumpAndSettle();

    expect(find.text('BIRTH_INPUT_STUB'), findsOneWidget);
  });
}
