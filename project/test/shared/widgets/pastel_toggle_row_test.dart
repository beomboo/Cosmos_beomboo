import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  testWidgets('semanticLabel을 주면 그룹 라벨이 추가되고 개별 버튼의 selected 상태는 그대로 유지된다',
      (tester) async {
    // 목업(01-pastel-cute.html)의 양력/음력·성별 토글은 각각 `role="group"
    // aria-label="..."`을 갖고 있는데, 지금까지 Flutter 구현은 이 그룹 라벨이
    // 없었다 — 화면에 보이는 _FieldLabel(예: "성별")이 바로 앞에 있어 순서대로
    // 읽으면 맥락이 이어지지만, 스크린 리더가 화면을 훑다가 버튼으로 곧장
    // 이동하면 "여성/남성"이 뭘 고르는 건지 알 수 없었다. semanticLabel을
    // 옵션으로 추가해, 그룹 자체에도 별도 라벨이 붙는지 확인한다.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelToggleRow<_Option>(
            value: _Option.a,
            options: const {_Option.a: '양력', _Option.b: '음력'},
            onChanged: (_) {},
            semanticLabel: '양력 또는 음력',
          ),
        ),
      ),
    );

    final selected = tester.getSemantics(find.text('양력'));
    final unselected = tester.getSemantics(find.text('음력'));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(unselected.flagsCollection.isSelected, Tristate.isFalse);

    expect(
      find.bySemanticsLabel('양력 또는 음력'),
      findsOneWidget,
      reason: '그룹 전체를 아우르는 "양력 또는 음력" 라벨 노드가 있어야 한다',
    );

    semantics.dispose();
  });

  testWidgets('semanticLabel을 안 주면 기존과 동일하게 그룹 라벨 없이 개별 버튼만 렌더링된다', (tester) async {
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

    expect(find.bySemanticsLabel('양력 또는 음력'), findsNothing);

    semantics.dispose();
  });

  testWidgets('스크린 리더의 탭 액션(SemanticsAction.tap)을 직접 실행해도 onChanged가 호출된다', (tester) async {
    // 위의 다른 테스트들은 tester.tap()(실제 히트테스트)이나 flagsCollection(선택 상태)만
    // 확인했을 뿐, "화면 훑기 후 두 번 탭"처럼 스크린 리더가 실제로 보내는
    // SemanticsAction.tap 자체를 실행해서 onChanged까지 이어지는지는 검증한 적이
    // 없었다. 이 위젯은 Semantics(excludeSemantics: true)로 InkWell의 자동 탭 액션을
    // 대체하는 구조라(CLAUDE.md에도 남겨둔 실제 회귀 사례), onTap:을 다시 선언하는 걸
    // 빠뜨려도 tester.tap()은 InkWell을 직접 히트테스트해 여전히 통과해버려 이
    // 회귀를 못 잡는다 — 시맨틱 액션 경로를 별도로 검증해야 한다.
    final semantics = tester.ensureSemantics();
    _Option? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelToggleRow<_Option>(
            value: _Option.a,
            options: const {_Option.a: '양력', _Option.b: '음력'},
            onChanged: (v) => tapped = v,
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.text('음력'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(tapped, _Option.b);

    semantics.dispose();
  });
}
