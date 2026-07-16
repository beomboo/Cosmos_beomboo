import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/shared/widgets/pastel_card.dart';

void main() {
  testWidgets('자식 위젯을 그대로 렌더링한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PastelCard(child: Text('카드 내용')),
        ),
      ),
    );

    expect(find.text('카드 내용'), findsOneWidget);
  });

  testWidgets('기본 배경색·테두리·모서리 반경을 적용한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PastelCard(child: SizedBox()),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, AppColors.bgCard);
    expect(decoration.border, Border.all(color: AppColors.border));
    // 목업(.pillar-card/.cat-card)의 실제 값인 13px (2026-07-07 대조 발견, 이전엔 16px).
    expect(decoration.borderRadius, BorderRadius.circular(13));
  });

  testWidgets('padding/borderRadius를 커스텀하면 반영된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PastelCard(
            padding: EdgeInsets.all(30),
            borderRadius: 8,
            child: SizedBox(),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;

    expect(container.padding, const EdgeInsets.all(30));
    expect(decoration.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('showBorder를 false로 주면 테두리가 사라진다', (tester) async {
    // 우세 오행 콜아웃/MBTI 강조 박스 같은 톤 박스는 테두리 없이 배경색만으로
    // 구분되므로, showBorder:false가 실제로 border를 null로 만드는지 직접 확인한다.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PastelCard(showBorder: false, child: SizedBox()),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.border, isNull);
  });

  testWidgets('color를 지정하면 기본 흰 배경 대신 그 색이 배경으로 반영된다', (tester) async {
    // 우세 오행 콜아웃은 오행별 색(AppColors.ohaengSoftColors)을, MBTI 박스는
    // AppColors.accentSoft를 넘긴다 — 커스텀 color가 기본값(bgCard)을 실제로
    // 덮어쓰는지 확인한다.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PastelCard(color: AppColors.accentSoft, child: SizedBox()),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, AppColors.accentSoft);
    expect(decoration.color, isNot(AppColors.bgCard));
  });

  testWidgets('color와 showBorder를 함께 커스텀해도 서로 간섭하지 않는다', (tester) async {
    // color/showBorder 두 파라미터가 서로 다른 결정을 내려야 하는데, 한쪽이
    // 다른 쪽 기본값에 영향을 주지 않는지(예: color를 바꿨는데 border가 같이
    // 사라지거나, showBorder를 껐는데 color가 기본값으로 되돌아가는 회귀) 조합으로 확인한다.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PastelCard(
            color: AppColors.accentSoft,
            showBorder: false,
            child: SizedBox(),
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, AppColors.accentSoft);
    expect(decoration.border, isNull);
  });
}
