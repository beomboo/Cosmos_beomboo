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
    expect(decoration.borderRadius, BorderRadius.circular(16));
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
}
