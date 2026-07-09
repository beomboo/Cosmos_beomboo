import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
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

  testWidgets('스크린 리더의 탭 액션(SemanticsAction.tap)을 직접 실행해도 onTap이 호출된다', (tester) async {
    // 위 테스트는 matchesSemantics의 hasTapAction만 확인했을 뿐, 스크린 리더가 실제로
    // 보내는 SemanticsAction.tap이 onTap까지 이어지는지는 검증한 적이 없었다. 이 위젯도
    // PastelToggleRow/_InterestChip과 똑같이 Semantics(excludeSemantics: true)로 InkWell의
    // 자동 탭 액션을 대체하는 구조라, onTap:을 다시 선언하는 걸 빠뜨려도 hasTapAction 자체는
    // (다른 원인으로) true로 남을 수 있고 tester.tap()도 InkWell을 직접 히트테스트해 통과해버려
    // 이 회귀를 못 잡는다 — 실제 액션 실행까지 확인해야 한다.
    final semantics = tester.ensureSemantics();
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelPillButton(label: '2024.01.01', onTap: () => tapped = true),
        ),
      ),
    );

    final node = tester.getSemantics(find.text('2024.01.01'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(tapped, isTrue);

    semantics.dispose();
  });

  testWidgets('활성/비활성 배경색이 실제로 다르다(onTap이 null이면 옅어진 border색을 쓴다)', (tester) async {
    // 지금까지 활성/비활성 여부는 시맨틱스(enabled 플래그)로만 확인했을 뿐, 목업의
    // 비활성 `.pill`(옅게 죽은 느낌)을 반영한 실제 배경색 값(`border.withValues(alpha: 0.4)`
    // vs `bgCard`) 자체는 한 번도 값으로 검증한 적이 없었다.
    BoxDecoration decorationOf(String text) =>
        tester.widget<Container>(find.ancestor(of: find.text(text), matching: find.byType(Container)).first).decoration!
            as BoxDecoration;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PastelPillButton(label: '2024.01.01', onTap: () {}),
        ),
      ),
    );
    expect(decorationOf('2024.01.01').color, AppColors.bgCard);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PastelPillButton(label: '시간 모름', onTap: null),
        ),
      ),
    );
    expect(decorationOf('시간 모름').color, AppColors.border.withValues(alpha: 0.4));
  });
}
