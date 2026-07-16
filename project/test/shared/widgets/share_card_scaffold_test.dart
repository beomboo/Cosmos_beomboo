import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/shared/widgets/share_card_scaffold.dart';

import '../../support/test_viewport.dart';

/// `share_card_test.dart`/`deep_dive_share_card_test.dart`가 `ShareCard`/
/// `DeepDiveShareCard`를 통해서만 간접 검증하던 `ShareCardScaffold` 공용 위젯 자체를
/// 직접 겨냥한 테스트. 2026-07-15 리팩터링으로 두 카드가 복제하던 고정 크기(360x640)·
/// 텍스트 배율 고정(1.0)·제목/메타라인 헤더(maxLines+ellipsis)·해시태그 푸터가 이
/// 스캐폴드 하나로 모였다.
void main() {
  testWidgets('고정 크기(360x640)로 렌더링하고 제목/메타라인/본문 슬롯/해시태그를 배치한다', (tester) async {
    // 스캐폴드의 고정 높이(640)가 기본 테스트 뷰포트(800x600)보다 커서, 뷰포트를
    // 세로로 키우지 않으면 실제 렌더 크기가 600으로 잘려 보인다(CLAUDE.md에 기록된
    // 기존 함정과 동일한 이유).
    await useTallViewport(tester, height: 700);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCardScaffold(
            title: '제목',
            metaLine: '메타라인',
            hashtags: '#해시태그',
            body: const Text('본문 슬롯'),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ShareCardScaffold)), const Size(360, 640));
    expect(find.text('제목'), findsOneWidget);
    expect(find.text('메타라인'), findsOneWidget);
    expect(find.text('본문 슬롯'), findsOneWidget);
    expect(find.text('#해시태그'), findsOneWidget);
  });

  testWidgets('제목은 최대 2줄, 메타라인은 최대 1줄까지만 허용하고 넘치면 말줄임표로 자른다', (tester) async {
    // ShareCard/DeepDiveShareCard 둘 다 birth_input의 입력 제한(이름 20자/출생지 30자)을
    // 꽉 채워도 고정 높이(640) 카드가 넘치지 않아야 하는데, 그 방어(maxLines+ellipsis)가
    // 실제로 스캐폴드 쪽에 있는지 직접 확인한다.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCardScaffold(
            title: '제목',
            metaLine: '메타라인',
            hashtags: '#해시태그',
            body: const SizedBox(),
          ),
        ),
      ),
    );

    final titleText = tester.widget<Text>(find.text('제목'));
    expect(titleText.maxLines, 2);
    expect(titleText.overflow, TextOverflow.ellipsis);

    final metaText = tester.widget<Text>(find.text('메타라인'));
    expect(metaText.maxLines, 1);
    expect(metaText.overflow, TextOverflow.ellipsis);
  });

  testWidgets('공유하는 사람의 시스템 글자 배율(3배)과 무관하게 본문 슬롯은 항상 배율 1.0을 물려받는다',
      (tester) async {
    // 이 카드는 인스타 스토리 규격 고정 픽셀 이미지로 캡처되는 용도라 공유자의 접근성
    // 글자 크기 설정을 그대로 물려받으면 안 된다 — `MediaQuery.withClampedTextScaling`이
    // 실제로 본문 슬롯까지 배율 1.0을 강제하는지 직접 확인한다(간접 검증인 overflow
    // 부재 확인과 달리, 물려받는 배율 값 자체를 잡아낸다).
    TextScaler? capturedScaler;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: MaterialApp(
          home: Scaffold(
            body: ShareCardScaffold(
              title: '제목',
              metaLine: '메타라인',
              hashtags: '#해시태그',
              body: Builder(
                builder: (context) {
                  capturedScaler = MediaQuery.of(context).textScaler;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(capturedScaler, const TextScaler.linear(1.0));
  });
}
