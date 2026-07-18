import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/shared/widgets/pastel_toggle_row.dart';

enum _Option { a, b }

enum _Option3 { a, b, c }

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

  testWidgets('선택된/선택 안 된 옵션의 배경·테두리·글자색이 목업(.pill.is-active)값과 정확히 일치한다', (tester) async {
    // 2026-07-06에 accent+흰 글자(WCAG 미달) 대신 accentSoft+accentText 조합으로
    // 고친 뒤로, 그 근거가 된 실제 색 값 자체는 이 위젯 테스트에서도(그리고
    // 같은 조합을 독립적으로 재구현한 deep_dive_input_screen.dart의 _InterestChip
    // 쪽에서도) 한 번도 값으로 확인한 적이 없었다 — 시맨틱스만 검증돼 있었다.
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

    BoxDecoration decorationOf(String text) =>
        tester.widget<Container>(find.ancestor(of: find.text(text), matching: find.byType(Container)).first).decoration!
            as BoxDecoration;

    final activeDecoration = decorationOf('양력');
    expect(activeDecoration.color, AppColors.accentSoft);
    expect(activeDecoration.border!.top.color, AppColors.accent);
    expect(activeDecoration.border!.top.width, 1.5);
    expect(tester.widget<Text>(find.text('양력')).style!.color, AppColors.accentText);

    final inactiveDecoration = decorationOf('음력');
    expect(inactiveDecoration.color, AppColors.bgCard);
    expect(inactiveDecoration.border!.top.color, AppColors.border);
    expect(tester.widget<Text>(find.text('음력')).style!.color, AppColors.ink);
  });

  testWidgets('인접한 pill 사이의 실제 렌더 간격이 목업 값(gap:8px)과 일치하고 마지막 pill 뒤에는 여백이 남지 않는다',
      (tester) async {
    // 2026-07-18: `Row`+`Padding(right: 10)` 방식(마지막 항목 뒤에도 10px 트레일링
    // 여백이 남고 사이 간격도 10px)을 `Wrap(spacing/runSpacing: 8)`로 교체한 수정
    // (fbeabda) — 지금까지 이 위젯의 어떤 테스트도 실제 렌더 좌표(픽셀 간격)를 확인한
    // 적이 없었다. `decorationOf`처럼 텍스트 색·배경만 값으로 확인하는 테스트로는
    // 간격이 8px이 아니라 10px이어도, 혹은 트레일링 여백이 남아있어도 잡을 수 없다.
    // 옵션 3개로 인접 쌍 2개(가↔나, 나↔다)를 모두 확인한다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelToggleRow<_Option3>(
            value: _Option3.a,
            options: const {_Option3.a: '가', _Option3.b: '나', _Option3.c: '다'},
            onChanged: (_) {},
          ),
        ),
      ),
    );

    // 각 pill의 실제 시각적 경계는 padding/decoration을 가진 Container 자신이다
    // (위 색상 검증 테스트의 `decorationOf`와 같은 방식으로 찾는다).
    Rect pillRectOf(String text) => tester.getRect(
          find.ancestor(of: find.text(text), matching: find.byType(Container)).first,
        );

    final rectA = pillRectOf('가');
    final rectB = pillRectOf('나');
    final rectC = pillRectOf('다');

    expect(
      rectB.left - rectA.right,
      closeTo(8, 0.5),
      reason: '가↔나 pill 사이 간격은 목업(.pill-row gap:8px)과 같이 8px이어야 한다',
    );
    expect(
      rectC.left - rectB.right,
      closeTo(8, 0.5),
      reason: '나↔다 pill 사이 간격은 목업(.pill-row gap:8px)과 같이 8px이어야 한다',
    );

    // Wrap은 (Row와 달리) 남는 공간을 채우지 않고 콘텐츠 폭만큼만 차지하므로, 마지막
    // pill 뒤에 불필요한 트레일링 여백이 없다면 Wrap 전체의 오른쪽 끝과 마지막 pill('다')의
    // 오른쪽 끝이 거의 일치해야 한다 — 과거 Padding(right:10) 방식이었다면 그 10px만큼
    // Wrap(당시엔 Row) 오른쪽 끝이 '다' pill보다 더 멀리 있었을 것이다.
    final wrapRect = tester.getRect(find.byType(Wrap));
    expect(
      wrapRect.right - rectC.right,
      closeTo(0, 0.5),
      reason: '마지막 pill 뒤에 불필요한 트레일링 여백이 남지 않아야 한다',
    );
  });
}
