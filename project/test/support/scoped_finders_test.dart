import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scoped_finders.dart';

/// `scoped_finders.dart`의 `findInScrollView`/`findTextContainingInScrollView`
/// 공용 헬퍼 자체를 겨냥한 스모크 테스트. 여러 화면(결과·심층 분석 결과 등)에서
/// "화면 밖 캡처용 위젯 때문에 같은 텍스트가 두 곳에 존재" 상황을 흉내 낸 트리로,
/// key로 스코프를 좁히는 동작이 실제로 맞는 key만 매치하고 틀린 key는 매치하지
/// 않는지 확인한다.
void main() {
  // 두 스크롤 뷰(scrollA/scrollB)에 같은 텍스트가 하나씩 존재하는 트리 —
  // find.text()만 쓰면 두 곳이 매치돼(findsNWidgets(2)) 테스트가 실패하는 상황을
  // 재현한다.
  Widget buildTree() {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: 100,
              child: ListView(
                key: const Key('scrollA'),
                children: const [Text('안녕하세요 반갑습니다')],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView(
                key: const Key('scrollB'),
                children: const [Text('안녕하세요 반갑습니다')],
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('스코프 없이 find.text()만 쓰면 두 스크롤 뷰 모두에서 매치된다(문제 상황 재현)', (tester) async {
    await tester.pumpWidget(buildTree());

    expect(find.text('안녕하세요 반갑습니다'), findsNWidgets(2));
  });

  testWidgets('findInScrollView는 지정한 key의 스크롤 뷰 안에서만 정확히 하나를 찾는다', (tester) async {
    await tester.pumpWidget(buildTree());

    expect(findInScrollView('scrollA', '안녕하세요 반갑습니다'), findsOneWidget);
    expect(findInScrollView('scrollB', '안녕하세요 반갑습니다'), findsOneWidget);
  });

  testWidgets('findInScrollView에 존재하지 않는 key를 넘기면 findsNothing이다', (tester) async {
    await tester.pumpWidget(buildTree());

    expect(findInScrollView('scrollNotExist', '안녕하세요 반갑습니다'), findsNothing);
  });

  testWidgets('findTextContainingInScrollView도 지정한 key 안에서만 부분 일치를 찾는다', (tester) async {
    await tester.pumpWidget(buildTree());

    expect(findTextContainingInScrollView('scrollA', '반갑'), findsOneWidget);
    expect(findTextContainingInScrollView('scrollNotExist', '반갑'), findsNothing);
  });
}
