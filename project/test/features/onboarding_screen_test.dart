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
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('어떻게 계산되나요?'), findsOneWidget);
  });

  testWidgets('"시작하기"를 누르면 생년월일시 입력 화면으로 이동한다', (tester) async {
    var navigated = false;
    await tester.pumpWidget(buildApp(onBirthInputRoute: (_) => navigated = true));

    await tester.tap(find.text('시작하기'));
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

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('어떻게 계산되나요?'), findsOneWidget);
    expect(find.textContaining('60갑자(간지)로 변환해'), findsNothing);
  });
}
