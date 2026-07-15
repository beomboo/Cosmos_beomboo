import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/shared/widgets/offscreen_share_capture.dart';

/// `result_screen_test.dart`/`deep_dive_result_screen_test.dart`가 각 화면을 통째로
/// 렌더링해 간접적으로만 검증하던 `OffscreenShareCapture` 공용 위젯 자체를 직접 겨냥한
/// 테스트. 2026-07-15 리팩터링으로 두 화면이 복제하던
/// `Positioned(left: -4000) + ExcludeSemantics + RepaintBoundary` 패턴이 이 위젯 하나로
/// 모였는데, 지금까지는 이 위젯만 단독으로 검증하는 테스트가 없어 향후 누군가 이 공용
/// 위젯을 잘못 고치면 두 화면 테스트가 동시에 깨지는 형태로만 원인이 드러났다.
void main() {
  testWidgets('Positioned(-4000, 0)로 화면 밖에 배치하고, 전달한 키로 RepaintBoundary를 감싼다',
      (tester) async {
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              OffscreenShareCapture(
                repaintBoundaryKey: key,
                child: const Text('캡처 대상'),
              ),
            ],
          ),
        ),
      ),
    );

    final positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.left, -4000);
    expect(positioned.top, 0);

    // 전달한 키가 실제로 RepaintBoundary에 붙어야 shareCapturedCard가 캡처할 수 있다.
    expect(key.currentContext?.findRenderObject(), isA<RenderRepaintBoundary>());

    // 화면 밖(오프스크린)에 있어도 위젯 트리·페인트에는 여전히 존재해야 캡처가 가능하다
    // — Positioned는 페인트·히트테스트만 제외할 뿐 위젯 자체를 없애지 않는다.
    expect(find.text('캡처 대상'), findsOneWidget);
  });

  testWidgets('ExcludeSemantics로 자식의 시맨틱스가 스크린 리더 트리에서 완전히 제외된다', (tester) async {
    final key = GlobalKey();
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              OffscreenShareCapture(
                repaintBoundaryKey: key,
                child: const Text('캡처 대상 시맨틱스'),
              ),
            ],
          ),
        ),
      ),
    );

    // 위젯 트리에는 여전히 존재하지만(텍스트로 찾을 수 있음)
    expect(find.text('캡처 대상 시맨틱스'), findsOneWidget);
    // 시맨틱스 트리에서는 완전히 빠져 스크린 리더가 중복 낭독하지 않아야 한다.
    expect(find.bySemanticsLabel('캡처 대상 시맨틱스'), findsNothing);

    semantics.dispose();
  });
}
