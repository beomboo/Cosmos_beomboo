import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/core/saju/four_pillars.dart';
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

  // 2026-07-15: 공유하기 기능이 추가되면서 화면 밖(사용자 눈에는 안 보임)에 같은
  // 텍스트를 가진 캡처용 DeepDiveShareCard가 함께 존재할 수 있게 됐다 —
  // result_screen_test.dart의 findInResult와 같은 이유로, 실제로 보이는 스크롤 뷰
  // (deepDiveResultScrollView) 안으로 finder 범위를 좁혀 중복 매칭을 피한다.
  Finder findInDeepDiveResult(String text) => find.descendant(
        of: find.byKey(const Key('deepDiveResultScrollView')),
        matching: find.text(text),
      );
  Finder findContainingInDeepDiveResult(String text) => find.descendant(
        of: find.byKey(const Key('deepDiveResultScrollView')),
        matching: find.textContaining(text),
      );

  // deep_dive_result_screen.dart가 실제로 하는 것과 똑같이 dominant/sub/subCount를
  // 계산해 readingFor()에 넘긴다 — readingFor의 시그니처가 (interest, ohaeng)에서
  // (interest, dominant, sub, {subCount})로 바뀐 뒤에도 화면이 실제로 렌더링하는 문구와
  // 정확히 같은 값을 기대하도록 각 테스트의 birthInfo로부터 직접 계산한다.
  String reading(Interest interest, BirthInfo info) {
    final pillars = calculateFourPillars(birthDate: info.date, birthHour: info.hour);
    final dominant = pillars.dominantOhaeng;
    final sub = pillars.subDominantOhaeng;
    final subCount = pillars.ohaengCount[sub] ?? 0;
    return readingFor(interest, dominant, sub, subCount: subCount);
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

    expect(findInDeepDiveResult('직장운'), findsOneWidget);
    expect(findInDeepDiveResult(reading(Interest.career, birthInfo)), findsOneWidget);
    expect(findInDeepDiveResult('연애운'), findsOneWidget);
    expect(findInDeepDiveResult(reading(Interest.love, birthInfo)), findsOneWidget);

    // 고르지 않은 관심사(재물·건강)는 표시되지 않아야 한다.
    expect(findInDeepDiveResult('재물운'), findsNothing);
    expect(findInDeepDiveResult('건강운'), findsNothing);

    // build()는 `deepDiveInfo.interests`(Set, 순서 보장 없음)를 직접 순회하는 대신
    // `for (final interest in Interest.values) if (...contains(interest))`로 항상
    // Interest.values 선언 순서(연애·재물·직장·건강)를 따르도록 의도돼 있다 —
    // 사용자가 화면에서 어떤 순서로 칩을 탭했든 카드 순서가 항상 같아야 하는데,
    // 지금까지 이 화면 순서 자체를 확인한 테스트가 없었다. 이 테스트는 일부러
    // Interest.values와 반대 순서(직장→연애)로 Set에 넣어뒀으므로, 만약 코드가
    // Set을 직접 순회하도록 퇴보하면(모든 기존 존재/부재 assert는 그대로 통과하는
    // 채로) 이 순서만 뒤집혀 조용히 깨질 수 있다.
    final loveTop = tester.getTopLeft(findInDeepDiveResult('연애운')).dy;
    final careerTop = tester.getTopLeft(findInDeepDiveResult('직장운')).dy;
    expect(loveTop, lessThan(careerTop), reason: 'Set 삽입 순서(직장→연애)와 무관하게 연애운이 위에 와야 한다');
  });

  testWidgets('관심사 카드도 스크린 리더에 "제목. 설명"으로 병합된 시맨틱스를 제공한다', (tester) async {
    // result_screen.dart의 _CategoryCard와 같은 이유(2026-07-07 발견) — 아이콘·제목·
    // 설명이 각각 별도 Text라 지금까지 스크린 리더가 세 번 나눠 읽었다.
    await useTallViewport(tester);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: birthInfo,
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.love}),
        ),
      ),
    );

    expect(
      tester.getSemantics(findInDeepDiveResult('연애운')),
      matchesSemantics(label: '연애운. ${reading(Interest.love, birthInfo)}'),
    );

    semantics.dispose();
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

    expect(findContainingInDeepDiveResult('INTJ'), findsOneWidget);
    expect(findContainingInDeepDiveResult(mbtiComments['INTJ']!), findsOneWidget);
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

    expect(findInDeepDiveResult('민지의 심층 분석 ✨'), findsOneWidget);
  });

  testWidgets('이름이 없으면 헤더에 "회원님"으로 표시된다', (tester) async {
    // 같은 폴백 로직(`birthInfo.name?.trim().isNotEmpty == true ? ... : '회원님'`)을
    // result_screen.dart/report_screen.dart도 각자 복제해 썼었는데, 이 화면은 "이름이
    // 있는" 경우만 테스트돼 있었고 이름이 없거나 공백뿐인 경우는 확인한 적이 없었다
    // (2026-07-06 발견 당시엔 이 화면만의 공백이었으나, 2026-07-08에 확인해보니
    // 정작 이 로직이 처음 만들어진 원본인 result_screen.dart 쪽도 null/공백뿐인
    // 경우를 전용으로 검증하는 테스트가 없었음을 발견해 그쪽에도 같은 테스트를
    // 추가했다 — 위 "사주 결과 화면"/"상세 리포트 화면" 행 참고). 2026-07-14에는 세
    // 화면의 복제 삼항식이 `meta_line.dart`의 공용 함수 `displayNameFor()`로
    // 통합됐고(`meta_line_test.dart`에 전용 유닛 테스트도 추가됨), 이 화면은
    // `displayNameFor()`를 호출한다 — 이 테스트는 이제 그 폴백이 화면 헤더에
    // 실제로 반영되는지 확인하는 통합 테스트 성격이다.
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '   '),
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.love}),
        ),
      ),
    );

    expect(findInDeepDiveResult('회원님의 심층 분석 ✨'), findsOneWidget);
    expect(findInDeepDiveResult('   의 심층 분석 ✨'), findsNothing);
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

    expect(findInDeepDiveResult(buildMetaLine(infoWithAll)), findsOneWidget);
    expect(findInDeepDiveResult('1998.08.15 · 오후 2시生 · 양력 · 여성 · 서울특별시'), findsOneWidget);
  });

  testWidgets('음력으로 입력했으면 메타 라인에 "음력"으로 표시된다', (tester) async {
    // 2026-07-08 발견한 커버리지 공백: 같은 buildMetaLine(birthInfo)를 직접 호출하는
    // report_screen.dart는 isLunar: true로 렌더링해본 적이 없던 비대칭을 이미 발견해
    // 고쳤는데(위 report_screen_test.dart 참고), 이 화면도 정확히 같은 패턴(같은 함수를
    // 직접 호출)이라 똑같이 isLunar: true로 렌더링해본 적이 한 번도 없었다.
    await useTallViewport(tester);
    final lunarInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: true);

    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: lunarInfo,
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.love}),
        ),
      ),
    );

    expect(findInDeepDiveResult('1998.08.15 · 오후 2시生 · 음력'), findsOneWidget);
  });

  testWidgets('태어난 시간을 몰라도(시주 없이) 3기둥만으로 우세 오행 풀이가 정확히 반영된다',
      (tester) async {
    // 지금까지 이 화면의 모든 테스트는 birthHour: 14(시간을 아는 경우)만 썼다 —
    // birth_input에서 "태어난 시간을 몰라요"를 선택할 수 있고 결과/상세 리포트
    // 화면은 이미 이 경로를 검증해뒀는데, 심층 분석 화면만 시간 미상 케이스를
    // 한 번도 실제로 통과시켜본 적이 없었다. 같은 1998-08-15 생일이라도 시주가
    // 빠지면 우세 오행이 '금'(8글자 기준)에서 '목'(6글자 기준)으로 실제로
    // 바뀐다는 것까지 값으로 확인한다(계산은 test/core/saju/four_pillars_test.dart의
    // 분포값을 근거로 삼음: 시주 신미=금+토가 빠지면 금 3→2, 토 2→1).
    await useTallViewport(tester);
    final noHourInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false);

    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: noHourInfo,
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.career}),
        ),
      ),
    );

    expect(findInDeepDiveResult(reading(Interest.career, noHourInfo)), findsOneWidget);
    expect(findInDeepDiveResult(reading(Interest.career, birthInfo)), findsNothing);
  });

  testWidgets('시스템 글자 크기를 크게(2배) 키워도 RenderFlex overflow가 나지 않는다', (tester) async {
    // result_screen.dart(카테고리 그리드)·share_card.dart에서 실제로 겪었던 고정
    // 높이+큰 글자 조합 RenderFlex overflow가 이 화면에도 있는지 지금까지 확인한
    // 적이 없었다(다른 화면들은 전부 이 회귀 테스트가 있는데 이 화면만 빠져 있었음) —
    // 관심사 카드는 Row(icon + Expanded(Column))가 ListView 안에 있어 고정 높이
    // 제약이 없으므로 실제로는 재현되지 않음을 확인(코드 변경 없이 회귀 방지용으로 고정).
    await useTallViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          home: DeepDiveResultScreen(
            birthInfo: birthInfo,
            deepDiveInfo: const DeepDiveInfo(
              mbti: Mbti(ei: MbtiEi.i, sn: MbtiSn.n, tf: MbtiTf.t, jp: MbtiJp.j),
              interests: {Interest.love, Interest.wealth, Interest.career, Interest.health},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('리스트 컨테이너 여백이 목업 공통 토큰(20/14/20)에 맞춰져 있고, 하단에 CTA가 없어 18보다 여유를 둔 24다',
      (tester) async {
    // 2026-07-14 커밋(975c132)에서 이 화면의 옛 여백(24/8/24/32)을 다른 화면들과
    // 같은 목업 공통 토큰(좌우 20, 위 14)으로 맞추고, 하단만 이 화면 특유의 이유
    // (리스트 끝에 별도 CTA 버튼이 없음, deep_dive_input_screen.dart/result_screen.dart
    // 등 CTA로 끝나는 화면은 18을 씀)로 24를 유지했다 — 수치 자체를 테스트로 잠가둔
    // 적이 없어 다음에 실수로 옛 값으로 되돌아가도 못 잡는 공백이 있었다.
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: DeepDiveResultScreen(
          birthInfo: birthInfo,
          deepDiveInfo: const DeepDiveInfo(interests: {Interest.love}),
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byKey(const Key('deepDiveResultScrollView')));
    expect(listView.padding, const EdgeInsets.fromLTRB(20, 14, 20, 24));
  });
}
