import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/core/saju/four_pillars.dart';
import 'package:cosmos_saju/features/result/share_card.dart';

void main() {
  testWidgets('ShareCard가 이름/기둥/오행 밸런스를 렌더링한다', (tester) async {
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            pillars: pillars,
            dominant: '목',
            calloutHanja: '木',
            calloutText: '새로운 걸 벌이는 힘이 넘치는 타입이에요 🌿',
            ohaengCount: ohaengCount,
            total: total,
          ),
        ),
      ),
    );

    expect(find.text('민지의 사주팔자 ✨'), findsOneWidget);
    expect(find.text('오행 밸런스'), findsOneWidget);
    expect(find.text('#사주랑  #사주팔자  #오행'), findsOneWidget);
  });

  testWidgets('이름/출생지가 입력 제한(20자/30자)을 꽉 채워도 고정 높이 카드가 넘치지 않는다', (tester) async {
    // birth_input은 이름 20자, 출생지 30자까지 허용하는데, 이 카드는 폭 360x높이 640
    // 고정 레이아웃이라 실제로 최대 길이를 넣어보니 RenderFlex overflow가 났던 걸 확인한 적이
    // 있다 — 이름/메타 라인에 maxLines+ellipsis를 넣어 고쳤고, 이 테스트로 회귀를 막는다.
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);
    final longName = '가' * 20;
    final longPlace = '나' * 30;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCard(
            displayName: longName,
            metaLine: '1998.08.15 · 오후 2시生 · 양력 · 여성 · $longPlace',
            pillars: pillars,
            dominant: '목',
            calloutHanja: '木',
            calloutText: '새로운 걸 벌이는 힘이 넘치는 타입이에요 🌿',
            ohaengCount: ohaengCount,
            total: total,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
