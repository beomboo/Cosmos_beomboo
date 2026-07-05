import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/shared/widgets/pastel_pill_button.dart';

void main() {
  testWidgets('활성 버튼은 button+enabled+tap 가능 시맨틱스를 갖는다', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelPillButton(label: '2024.01.01', onTap: () {}),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('2024.01.01')),
      matchesSemantics(
        label: '2024.01.01',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('onTap이 null이면 비활성이고 탭 액션이 없다', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PastelPillButton(label: '시간 모름', onTap: null),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('시간 모름')),
      matchesSemantics(
        label: '시간 모름',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: false,
      ),
    );

    semantics.dispose();
  });
}
