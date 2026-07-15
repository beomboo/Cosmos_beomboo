import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/shared/widgets/gradient_share_button.dart';

void main() {
  // 2026-07-15 리팩터: result_screen.dart/deep_dive_result_screen.dart가 각자 갖고
  // 있던 accent→metal 그라데이션 공유 버튼(Container+ElevatedButton+Text) 구조를
  // GradientShareButton으로 통합했다. 두 화면 통합 테스트와 별개로 이 위젯 자체를
  // 직접 겨냥해 시각적 라벨/스크린 리더 라벨 분리, 탭 콜백 연결, 비활성 상태를
  // 검증한다.

  testWidgets('카메라 이모지가 포함된 "📸 공유하기"가 화면에 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientShareButton(onPressed: () {}),
        ),
      ),
    );

    expect(find.text('📸 공유하기'), findsOneWidget);
  });

  testWidgets('스크린 리더 라벨에는 이모지 없이 "공유하기"만 읽힌다', (tester) async {
    // 목업 카피에 이모지가 있지만, 장식용 이모지가 스크린 리더에 그대로 읽히면
    // 소음이 된다 — semanticsLabel로 "공유하기"만 남긴 값이 그대로 유지되는지 확인.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientShareButton(onPressed: () {}),
        ),
      ),
    );

    expect(tester.getSemantics(find.text('📸 공유하기')).label, '공유하기');

    semantics.dispose();
  });

  testWidgets('버튼을 탭하면 onPressed 콜백이 호출된다', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientShareButton(onPressed: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('onPressed가 null이면 버튼이 비활성 상태가 된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientShareButton(onPressed: null),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
