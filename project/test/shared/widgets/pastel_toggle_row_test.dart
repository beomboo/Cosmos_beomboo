import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/shared/widgets/pastel_toggle_row.dart';

enum _Option { a, b }

void main() {
  testWidgets('선택된 옵션에 스크린 리더용 selected 시맨틱스가 붙는다', (tester) async {
    // addTearDown은 testWidgets 콜백이 끝난 뒤 실행되는데, 시맨틱스 핸들이 열려있는지
    // 검사하는 시점은 그보다 먼저(콜백이 return하는 순간)이므로, 여기서 직접 dispose한다.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelToggleRow<_Option>(
            value: _Option.a,
            options: const {_Option.a: '양력', _Option.b: '음력'},
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final selected = tester.getSemantics(find.text('양력'));
    final unselected = tester.getSemantics(find.text('음력'));

    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(unselected.flagsCollection.isSelected, Tristate.isFalse);
    expect(selected.flagsCollection.isButton, isTrue);

    semantics.dispose();
  });
}
