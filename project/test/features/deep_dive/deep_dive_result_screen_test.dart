import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_readings.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_result_screen.dart';
import 'package:cosmos_saju/features/result/meta_line.dart';

void main() {
  Future<void> useTallViewport(WidgetTester tester) async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });
  }

  // 1998-08-15 14시 조합은 이미 four_pillars_test.dart에서 우세 오행이 '금'으로
  // 검증돼 있다(목:2,화:0,토:2,금:3,수:1) — 이 값을 그대로 재사용한다.
  final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

  testWidgets('선택한 관심사만 우세 오행 기준 풀이로 화면에 보인다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: birthInfo,
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.career, Interest.love}),
        ),
      ),
    );

    expect(find.text('직장운'), findsOneWidget);
    expect(find.text(readingFor(Interest.career, '금')), findsOneWidget);
    expect(find.text('연애운'), findsOneWidget);
    expect(find.text(readingFor(Interest.love, '금')), findsOneWidget);

    // 고르지 않은 관심사(재물·건강)는 표시되지 않아야 한다.
    expect(find.text('재물운'), findsNothing);
    expect(find.text('건강운'), findsNothing);
  });

  testWidgets('관심사를 하나도 안 고르면 안내 문구가 뜨고 카드는 하나도 없다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: birthInfo,
          deepDiveInfo: const DeepDiveInfo(),
        ),
      ),
    );

    expect(find.textContaining('관심사를 고르지 않아'), findsOneWidget);
    expect(find.text('연애운'), findsNothing);
  });

  testWidgets('MBTI를 입력했으면 코드와 코멘트가 함께 보인다', (tester) async {
    await useTallViewport(tester);
    const mbti = Mbti(ei: MbtiEi.i, sn: MbtiSn.n, tf: MbtiTf.t, jp: MbtiJp.j);
    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: birthInfo,
          deepDiveInfo: const DeepDiveInfo(mbti: mbti, interests: {}),
        ),
      ),
    );

    expect(find.textContaining('INTJ'), findsOneWidget);
    expect(find.textContaining(mbtiComments['INTJ']!), findsOneWidget);
  });

  testWidgets('MBTI를 입력하지 않았으면 MBTI 코멘트 영역이 아예 없다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: birthInfo,
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.health}),
        ),
      ),
    );

    for (final comment in mbtiComments.values) {
      expect(find.textContaining(comment), findsNothing);
    }
  });

  testWidgets('이름이 있으면 헤더에 실제 이름이 표시된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '민지'),
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.love}),
        ),
      ),
    );

    expect(find.text('민지의 심층 분석 ✨'), findsOneWidget);
  });

  testWidgets('메타 라인(날짜·시간·성별·출생지)이 실제 buildMetaLine 값 그대로 화면에 보인다', (tester) async {
    // result_screen_test.dart/report_screen_test.dart는 메타 라인 렌더링을 이미
    // 값으로 검증해뒀는데, 같은 buildMetaLine을 재사용하는 이 화면만 지금까지
    // "이름"만 확인했을 뿐 메타 라인 자체(날짜·시간·양음력·성별·출생지)가 실제로
    // 화면에 보이는지는 검증한 적이 없었다.
    await useTallViewport(tester);
    final infoWithAll = BirthInfo(
      date: DateTime(1998, 8, 15),
      hour: 14,
      isLunar: false,
      gender: Gender.female,
      birthPlace: '서울특별시',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: infoWithAll,
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.love}),
        ),
      ),
    );

    expect(find.text(buildMetaLine(infoWithAll)), findsOneWidget);
    expect(find.text('1998.08.15 · 오후 2시生 · 양력 · 여성 · 서울특별시'), findsOneWidget);
  });
}
