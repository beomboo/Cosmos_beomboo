import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/result/result_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ResultScreen에는 화면 밖에 배치된 공유용 ShareCard(동일 문구를 일부 재사용)가
  // 위젯 트리에 함께 존재하므로, 텍스트 파인더는 눈에 보이는 본문(resultScrollView)으로
  // 범위를 좁혀야 정확히 하나만 매치된다.
  Finder findInBody(String text) => find.descendant(
        of: find.byKey(const Key('resultScrollView')),
        matching: find.text(text),
      );

  testWidgets('결과 화면이 4기둥과 오행 밸런스를 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    expect(findInBody('회원님의 사주팔자 ✨'), findsOneWidget);
    expect(findInBody('년주'), findsOneWidget);
    expect(findInBody('월주'), findsOneWidget);
    expect(findInBody('일주'), findsOneWidget);
    expect(findInBody('시주'), findsOneWidget);
    expect(findInBody('오행 밸런스'), findsOneWidget);
    expect(findInBody('※ 절기 계산 없이 근사치로 계산한 간이 결과예요'), findsOneWidget);
  });

  testWidgets('4기둥 명식과 오행 밸런스 퍼센트가 실제 계산값과 정확히 일치하는 값으로 화면에 보인다',
      (WidgetTester tester) async {
    // share_text_test.dart에서는 공유 텍스트의 퍼센트 줄을 정확한 값으로 검증했지만,
    // 정작 사용자가 가장 먼저 보는 화면 본문(4기둥 카드의 한자, 오행 밸런스 바의 %)은
    // 지금까지 "년주"/"오행 밸런스" 같은 라벨 문구만 확인했을 뿐 실제 계산값 자체가
    // 화면에 정확히 반영되는지는 한 번도 확인한 적이 없었다.
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    // 1998-08-15 14시의 4주: 년주 무인, 월주 경신, 일주 갑자, 시주 신미
    // (four_pillars_test.dart의 "ohaengCount는 8글자..." 테스트와 같은 조합).
    expect(findInBody('무인'), findsOneWidget);
    expect(findInBody('경신'), findsOneWidget);
    expect(findInBody('갑자'), findsOneWidget);
    expect(findInBody('신미'), findsOneWidget);

    // ohaengCount 분포 {목:2, 화:0, 토:2, 금:3, 수:1}(총 8) → 25%/0%/25%/38%/13%.
    expect(findInBody('25%'), findsNWidgets(2)); // 목, 토
    expect(findInBody('0%'), findsOneWidget); // 화
    expect(findInBody('38%'), findsOneWidget); // 금
    expect(findInBody('13%'), findsOneWidget); // 수
  });

  testWidgets('우세 오행(dominant) 선정과 그에 맞는 콜아웃·카테고리 풀이가 실제로 정확하다',
      (WidgetTester tester) async {
    // 결과 화면에서 어떤 오행이 "우세하다"고 뽑혀서 콜아웃 문구·카테고리 풀이(연애·재물·
    // 건강·성격) 4장을 결정하는지는 사용자가 실제로 읽는 핵심 콘텐츠인데, 이 선택 로직
    // (result_screen.dart의 `ohaengCount.entries.reduce((a,b) => a.value >= b.value ? a : b)`)
    // 자체는 지금까지 어디서도 실제 값으로 검증된 적이 없었다(share_text/share_card
    // 테스트는 dominant를 '목'으로 그냥 하드코딩해서 넘겼을 뿐, 이 reduce 로직을 거치지
    // 않았음). 1998-08-15 14시의 분포 {목:2,화:0,토:2,금:3,수:1}는 금이 유일한 최댓값이라
    // (목·토는 동률 2로 서로 안 밀리는 것까지 포함해) 최종적으로 금이 선택돼야 한다.
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    expect(
      findInBody('金(금) 기운이 강한 타입이에요\n원칙적이고 결단력 있는 타입이에요 ✨'),
      findsOneWidget,
    );
    expect(findInBody('눈이 높은 편이라 확실한 상대를 알아보는 시기예요'), findsOneWidget); // 금 연애운
    expect(findInBody('계획적으로 관리하면 돈이 잘 모이는 편이에요'), findsOneWidget); // 금 재물운
    expect(findInBody('호흡기·피부 컨디션을 신경 쓰면 좋아요'), findsOneWidget); // 금 건강운
    expect(findInBody('원칙적이고 맺고 끊음이 확실한 타입이에요'), findsOneWidget); // 금 성격
  });

  testWidgets('4기둥 카드는 스크린 리더에 "기둥이름 + 값" 순서로 병합된 시맨틱스를 제공한다',
      (WidgetTester tester) async {
    // _PillarCard는 시각적으로 값("갑자")이 위, 기둥 이름("년주")이 아래로 보이는데,
    // Semantics로 감싸지 않으면 스크린 리더가 그 화면 순서 그대로 "갑자" → "년주"를
    // 따로 읽어 값을 먼저 들려주는 맥락 없는 안내가 된다 — 이 점이 지금까지 한 번도
    // 검증된 적이 없었다. "년주 무인"처럼 이름이 먼저 오는 순서로 병합됐는지 확인한다.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    expect(
      tester.getSemantics(findInBody('무인')),
      matchesSemantics(label: '년주 무인'),
    );
    expect(
      tester.getSemantics(findInBody('신미')),
      matchesSemantics(label: '시주 신미'),
    );

    semantics.dispose();
  });

  testWidgets('시주를 모르면 4기둥 카드 시맨틱스도 "시주 모름"으로 병합된다', (WidgetTester tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    expect(
      tester.getSemantics(findInBody('모름')),
      matchesSemantics(label: '시주 모름'),
    );

    semantics.dispose();
  });

  testWidgets('시간을 모르면 시주 카드가 "모름"으로 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    expect(findInBody('모름'), findsOneWidget);
  });

  testWidgets('이름이 있으면 헤더에 실제 이름이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments:
                BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '민지'),
          ),
        ),
        initialRoute: '/',
      ),
    );

    expect(findInBody('민지의 사주팔자 ✨'), findsOneWidget);
    expect(findInBody('회원님의 사주팔자 ✨'), findsNothing);
  });

  testWidgets('태어난 곳을 입력했으면 메타 라인에 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(
              date: DateTime(1998, 8, 15),
              hour: 14,
              isLunar: false,
              birthPlace: '서울특별시',
            ),
          ),
        ),
        initialRoute: '/',
      ),
    );

    expect(findInBody('1998.08.15 · 오후 2시生 · 양력 · 서울특별시'), findsOneWidget);
  });

  testWidgets('성별을 입력했으면 메타 라인에 출생지보다 먼저 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(
              date: DateTime(1998, 8, 15),
              hour: 14,
              isLunar: false,
              gender: Gender.female,
              birthPlace: '서울특별시',
            ),
          ),
        ),
        initialRoute: '/',
      ),
    );

    expect(findInBody('1998.08.15 · 오후 2시生 · 양력 · 여성 · 서울특별시'), findsOneWidget);
  });

  testWidgets('birthInfo를 생성자로 직접 넘겨도(라우트 arguments 없이) 정상 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '민지'),
        ),
      ),
    );

    expect(findInBody('민지의 사주팔자 ✨'), findsOneWidget);
  });

  testWidgets('"다시 입력하기"를 누르면 저장된 정보를 지우고 생년월일시 입력 화면으로 이동한다',
      (WidgetTester tester) async {
    await SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt('birth_info.date_millis', DateTime(1998, 8, 15).millisecondsSinceEpoch),
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    await tester.tap(find.byTooltip('다시 입력하기'));
    await tester.pumpAndSettle();

    // 확인 다이얼로그가 먼저 뜬다 — 실수로 눌러도 바로 삭제되지 않는다.
    expect(find.text('다시 입력할까요?'), findsOneWidget);
    await tester.tap(find.text('다시 입력하기').last);
    await tester.pumpAndSettle();

    expect(find.text('생년월일시를 알려주세요'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('birth_info.date_millis'), isNull);
  });

  testWidgets('"다시 입력하기" 확인 다이얼로그에서 "취소"를 누르면 아무 것도 지워지지 않는다',
      (WidgetTester tester) async {
    await SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt('birth_info.date_millis', DateTime(1998, 8, 15).millisecondsSinceEpoch),
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    await tester.tap(find.byTooltip('다시 입력하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    // 여전히 결과 화면에 남아있고, 저장된 값도 그대로다.
    expect(findInBody('회원님의 사주팔자 ✨'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('birth_info.date_millis'), isNotNull);
  });
}
