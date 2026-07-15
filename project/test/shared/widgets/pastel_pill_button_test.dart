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

  group('fieldLabel/semanticValue 조합', () {
    // 2026-07-15 리팩터: birth_input_screen.dart가 바깥 Semantics로 직접 조합하던
    // "필드 맥락 + 값" 라벨을 PastelPillButton 내부(fieldLabel/semanticValue)로
    // 옮겼다. 이 위젯을 재사용하는 다른 화면이 생겨도 조합 로직이 옳게 동작하는지
    // birth_input_screen 통합 테스트와 별개로 이 위젯만 떼어 직접 검증한다.

    testWidgets('fieldLabel도 semanticValue도 없으면 라벨은 label 그대로다 (하위 호환)', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PastelPillButton(label: '1998.08.15', onTap: () {}),
          ),
        ),
      );

      expect(tester.getSemantics(find.text('1998.08.15')).label, '1998.08.15');

      semantics.dispose();
    });

    testWidgets('fieldLabel만 있으면 "fieldLabel label" 형태로 조합된다', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PastelPillButton(label: '1998.08.15', fieldLabel: '태어난 날짜', onTap: () {}),
          ),
        ),
      );

      expect(tester.getSemantics(find.text('1998.08.15')).label, '태어난 날짜 1998.08.15');

      semantics.dispose();
    });

    testWidgets('fieldLabel과 semanticValue가 모두 있으면 semanticValue가 label 대신 쓰인다', (tester) async {
      // birth_input_screen의 "시간 모름" 케이스 — 화면에 보이는 label은 "시간 모름"인데
      // 시맨틱 조합에는 "모름"만 써서 "태어난 시간 시간 모름"처럼 "시간"이 중복되지
      // 않게 한다.
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PastelPillButton(
              label: '시간 모름',
              fieldLabel: '태어난 시간',
              semanticValue: '모름',
              onTap: null,
            ),
          ),
        ),
      );

      expect(tester.getSemantics(find.text('시간 모름')).label, '태어난 시간 모름');

      semantics.dispose();
    });

    testWidgets('semanticValue만 있고 fieldLabel이 없으면 semanticValue는 무시되고 label 그대로 쓰인다', (tester) async {
      // 위젯 문서 주석("fieldLabel이 null이면 semanticValue는 아예 쓰이지 않는다")이
      // 실제로 지켜지는지 확인한다.
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PastelPillButton(label: '1998.08.15', semanticValue: '무시되어야 함', onTap: () {}),
          ),
        ),
      );

      expect(tester.getSemantics(find.text('1998.08.15')).label, '1998.08.15');

      semantics.dispose();
    });

    testWidgets('fieldLabel이 있어도 버튼 역할·활성 상태·탭 액션은 그대로 유지된다', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PastelPillButton(label: '1998.08.15', fieldLabel: '태어난 날짜', onTap: () {}),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('1998.08.15')),
        matchesSemantics(
          label: '태어난 날짜 1998.08.15',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      semantics.dispose();
    });
  });
}
