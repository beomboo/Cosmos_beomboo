import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_share_card.dart';
import 'package:cosmos_saju/shared/widgets/pastel_card.dart';

/// `share_card_test.dart`(사주 결과 화면의 ShareCard)와 같은 관점으로
/// `DeepDiveShareCard`(심층 분석 결과 화면의 공유 카드)를 검증한다 —
/// 특히 그쪽에서 실제로 겪었던 결함(긴 이름/출생지 오버플로우, 접근성 배율 2배
/// 레이아웃 붕괴)이 이 카드에도 재현되지 않는지, 그리고 MBTI/관심사 콘텐츠가
/// 서로 다른 슬롯에 정확히 들어가는지(콘텐츠 스왑 취약점)를 확인한다.
void main() {
  final items = [
    ('💘', '연애운', '연애운 설명입니다'),
    ('💰', '재물운', '재물운 설명입니다'),
    ('💼', '직장운', '직장운 설명입니다'),
    ('🌱', '건강운', '건강운 설명입니다'),
  ];

  testWidgets('이름/메타라인/관심사 카드/해시태그를 렌더링한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeepDiveShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            items: items,
          ),
        ),
      ),
    );

    expect(find.text('민지의 심층 분석 ✨'), findsOneWidget);
    expect(find.text('1998.08.15 · 오후 2시生 · 양력'), findsOneWidget);
    expect(find.text('연애운'), findsOneWidget);
    expect(find.text('재물운'), findsOneWidget);
    expect(find.text('직장운'), findsOneWidget);
    expect(find.text('건강운'), findsOneWidget);
    expect(find.text('#사주랑  #심층분석  #MBTI'), findsOneWidget);
  });

  testWidgets('MBTI 코드/코멘트가 둘 다 있어야만 강조 박스가 accentSoft 배경으로 나타난다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeepDiveShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            mbtiCode: 'INTJ',
            mbtiComment: '치밀하게 그림을 그리고 움직이는 전략가 타입이에요',
            items: items,
          ),
        ),
      ),
    );

    // 콘텐츠 스왑 점검: 코드-코멘트 순서가 뒤바뀌면 이 정확한 문자열은 매칭되지 않는다.
    expect(find.text('INTJ — 치밀하게 그림을 그리고 움직이는 전략가 타입이에요'), findsOneWidget);

    final box = tester.widget<Container>(
      find.ancestor(
        of: find.textContaining('INTJ —'),
        matching: find.byType(Container),
      ).first,
    );
    // MBTI 강조 박스는 오행과 무관해 항상 accentSoft 고정이어야 한다(오행색 사용 금지 원칙).
    expect((box.decoration! as BoxDecoration).color, AppColors.accentSoft);
  });

  testWidgets('MBTI 코드만 있고 코멘트가 없으면(비정상 조합) 강조 박스가 나타나지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeepDiveShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            mbtiCode: 'INTJ',
            items: items,
          ),
        ),
      ),
    );

    expect(find.textContaining('INTJ —'), findsNothing);
  });

  testWidgets('MBTI를 입력하지 않았으면(둘 다 null) 강조 박스 자체가 없다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeepDiveShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            items: items,
          ),
        ),
      ),
    );

    expect(find.textContaining(' — '), findsNothing);
  });

  testWidgets('관심사가 5개를 넘겨도 최대 4개까지만 그린다(카드 높이 640 고정)', (tester) async {
    final fiveItems = [
      ...items,
      ('🎯', '다섯번째관심사', '다섯번째관심사 설명입니다'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeepDiveShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            items: fiveItems,
          ),
        ),
      ),
    );

    expect(find.text('연애운'), findsOneWidget);
    expect(find.text('재물운'), findsOneWidget);
    expect(find.text('직장운'), findsOneWidget);
    expect(find.text('건강운'), findsOneWidget);
    // take(4)로 잘려서 5번째는 화면(캡처 대상)에 없어야 한다.
    expect(find.text('다섯번째관심사'), findsNothing);
  });

  testWidgets('관심사가 하나도 없으면 관심사 카드 영역 자체가 비어 있다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DeepDiveShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            items: [],
          ),
        ),
      ),
    );

    expect(find.byType(PastelCard), findsNothing);
  });

  testWidgets('각 관심사 카드는 자신의 아이콘·제목·풀이만 같은 카드 안에 담고 다른 관심사와 뒤섞이지 않는다',
      (tester) async {
    // 콘텐츠 스왑 취약점 점검: title/desc가 서로 다른 카드로 어긋나게 배치돼도(둘 다
    // 화면 어딘가에는 여전히 존재하므로) find.text() 단독 검증으로는 못 잡는다 —
    // 같은 PastelCard(=_ItemCard) 안에서만 짝이 맞는 제목·설명·아이콘을 찾는다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeepDiveShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            items: items,
          ),
        ),
      ),
    );

    for (final (icon, title, desc) in items) {
      final card = find.ancestor(of: find.text(title), matching: find.byType(PastelCard)).first;
      expect(find.descendant(of: card, matching: find.text(desc)), findsOneWidget, reason: title);
      expect(find.descendant(of: card, matching: find.text(icon)), findsOneWidget, reason: title);

      // 같은 카드 안에 있더라도 제목·풀이 문구 자체가 서로 자리(스타일)를 바꿔 나올 수
      // 있다(예: desc가 title 자리의 굵은 스타일로 나오는 식) — 위 존재 여부 검증만으론
      // 못 잡으므로, 제목은 항상 굵은 강조 스타일(w800)로, 풀이는 항상 보조 스타일
      // (w600)로 렌더링되는지까지 확인한다.
      final titleStyle = tester
          .widget<Text>(find.descendant(of: card, matching: find.text(title)))
          .style!;
      final descStyle = tester
          .widget<Text>(find.descendant(of: card, matching: find.text(desc)))
          .style!;
      expect(titleStyle.fontWeight, FontWeight.w800, reason: '$title (제목)');
      expect(descStyle.fontWeight, FontWeight.w600, reason: '$desc (풀이)');
    }
  });

  testWidgets('이름/출생지가 입력 제한(20자/30자)을 꽉 채워도 고정 높이 카드가 넘치지 않는다', (tester) async {
    // ShareCard(share_card_test.dart)에서 실제로 RenderFlex overflow를 겪었던 것과
    // 같은 이유(360x640 고정 레이아웃) — 이 카드도 같은 방어(maxLines+ellipsis)가
    // 실제로 동작하는지 회귀 테스트로 고정한다.
    final longName = '가' * 20;
    final longPlace = '나' * 30;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeepDiveShareCard(
            displayName: longName,
            metaLine: '1998.08.15 · 오후 2시生 · 양력 · 여성 · $longPlace',
            mbtiCode: 'INTJ',
            mbtiComment: '치밀하게 그림을 그리고 움직이는 전략가 타입이에요',
            items: items,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('공유하는 사람의 시스템 글자 크기를 키워도(2배) 카드 배율은 1.0으로 고정돼 넘치지 않는다',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          home: Scaffold(
            body: DeepDiveShareCard(
              displayName: '민지',
              metaLine: '1998.08.15 · 오후 2시生 · 양력',
              mbtiCode: 'INTJ',
              mbtiComment: '치밀하게 그림을 그리고 움직이는 전략가 타입이에요',
              items: items,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
