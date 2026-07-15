import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/shared/widgets/pastel_checkbox_row.dart';

void main() {
  // 2026-07-15 리팩터: birth_input_screen.dart의 "태어난 시간을 몰라요"/"MBTI를
  // 알고 있어요" 체크박스가 반복하던 CheckboxListTile 스타일을 PastelCheckboxRow로
  // 통합했다. 화면 통합 테스트와 별개로 이 위젯 자체의 라벨 표시·탭 반응·체크
  // 상태 반영을 직접 검증한다.

  testWidgets('label 텍스트가 그대로 표시된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelCheckboxRow(label: '태어난 시간을 몰라요', value: false, onChanged: (_) {}),
        ),
      ),
    );

    expect(find.text('태어난 시간을 몰라요'), findsOneWidget);
  });

  testWidgets('체크박스뿐 아니라 라벨 글자를 탭해도 onChanged가 호출된다 (CheckboxListTile 터치 영역)', (tester) async {
    bool? received;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelCheckboxRow(
            label: 'MBTI를 알고 있어요',
            value: false,
            onChanged: (v) => received = v,
          ),
        ),
      ),
    );

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    expect(received, isTrue);
  });

  testWidgets('value가 true면 체크된 시맨틱 상태로 표시된다', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelCheckboxRow(label: '태어난 시간을 몰라요', value: true, onChanged: (_) {}),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('태어난 시간을 몰라요')),
      matchesSemantics(
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
        hasFocusAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        // CheckboxListTile은 selected 여부와 무관하게 ListTile 자체가 항상 이
        // 플래그를 노출한다(selected 값은 지정하지 않아 기본 false).
        hasSelectedState: true,
        isSelected: false,
      ),
    );

    semantics.dispose();
  });

  testWidgets('value가 false면 체크 해제된 시맨틱 상태로 표시된다', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelCheckboxRow(label: '태어난 시간을 몰라요', value: false, onChanged: (_) {}),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('태어난 시간을 몰라요')),
      matchesSemantics(
        hasCheckedState: true,
        isChecked: false,
        hasTapAction: true,
        hasFocusAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: false,
      ),
    );

    semantics.dispose();
  });

  testWidgets('같은 화면에 두 개를 동시에 써도 서로 독립적으로 동작한다 (재사용성)', (tester) async {
    bool timeUnknown = false;
    bool knowsMbti = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PastelCheckboxRow(
                  label: '태어난 시간을 몰라요',
                  value: timeUnknown,
                  onChanged: (v) => setState(() => timeUnknown = v ?? false),
                ),
                PastelCheckboxRow(
                  label: 'MBTI를 알고 있어요',
                  value: knowsMbti,
                  onChanged: (v) => setState(() => knowsMbti = v ?? false),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    expect(knowsMbti, isTrue);
    expect(timeUnknown, isFalse);
    // "태어난 시간을 몰라요"가 그대로인지(체크되지 않은 상태의 시각 요소)도 함께 확인.
    expect(find.text('태어난 시간을 몰라요'), findsOneWidget);
  });
}
