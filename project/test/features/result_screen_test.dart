import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';
import 'package:cosmos_saju/features/result/result_screen.dart';

import '../support/scoped_finders.dart';
import '../support/test_viewport.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ResultScreen에는 화면 밖에 배치된 공유용 ShareCard(동일 문구를 일부 재사용)가
  // 위젯 트리에 함께 존재하므로, 텍스트 파인더는 눈에 보이는 본문(resultScrollView)으로
  // 범위를 좁혀야 정확히 하나만 매치된다.
  Finder findInBody(String text) => findInScrollView('resultScrollView', text);

  Finder findInBodyContaining(String text) =>
      findTextContainingInScrollView('resultScrollView', text);

  group('buildOhaengBalanceNarrative', () {
    // 2026-07-14 추가: `flutter test --coverage` 실측 결과 2순위 오행이 사실상 없을 때
    // (`ohaengCount[sub]`가 null이거나 0)의 단독 폴백 문구 분기가 위젯 테스트 어디서도
    // 실행된 적이 없었다 — four_pillars.dart의 subDominantOhaeng 독스트링에 명시된 대로
    // 사주 8글자가 오행 하나로 완전히 쏠리는 경우 실제로 발생 가능한 정상 시나리오라
    // 위젯 트리 없이 함수를 직접 호출해 커버한다.

    test('total이 0이면 dominant/sub/ohaengCount 값과 무관하게 안내 문구를 반환한다', () {
      expect(
        buildOhaengBalanceNarrative(
          dominant: '목',
          sub: '화',
          ohaengCount: const {'목': 0, '화': 0, '토': 0, '금': 0, '수': 0},
          total: 0,
        ),
        '태어난 시간을 포함한 오행 정보가 아직 없어요',
      );
    });

    test('ohaengCount에 sub 키 자체가 없으면(null) 우세 오행 단독 폴백 문구를 반환한다', () {
      expect(
        buildOhaengBalanceNarrative(
          dominant: '금',
          sub: '수',
          ohaengCount: const {'금': 8},
          total: 8,
        ),
        '전체 8글자 중 금이 8개(100%)로 가장 많아요',
      );
    });

    test('ohaengCount에 sub 키는 있지만 값이 0이어도 같은 단독 폴백 문구를 반환한다', () {
      expect(
        buildOhaengBalanceNarrative(
          dominant: '화',
          sub: '수',
          ohaengCount: const {'목': 0, '화': 8, '토': 0, '금': 0, '수': 0},
          total: 8,
        ),
        '전체 8글자 중 화가 8개(100%)로 가장 많아요',
      );
    });

    test('받침 있는 오행(목·금)은 단독 폴백 문구에서도 조사 "이"가 붙는다', () {
      expect(
        buildOhaengBalanceNarrative(
          dominant: '목',
          sub: '수',
          ohaengCount: const {'목': 8},
          total: 8,
        ),
        '전체 8글자 중 목이 8개(100%)로 가장 많아요',
      );
      expect(
        buildOhaengBalanceNarrative(
          dominant: '금',
          sub: '수',
          ohaengCount: const {'금': 8},
          total: 8,
        ),
        '전체 8글자 중 금이 8개(100%)로 가장 많아요',
      );
    });

    test('받침 없는 오행(화·토·수)은 단독 폴백 문구에서도 조사 "가"가 붙는다', () {
      expect(
        buildOhaengBalanceNarrative(
          dominant: '화',
          sub: '금',
          ohaengCount: const {'화': 8},
          total: 8,
        ),
        '전체 8글자 중 화가 8개(100%)로 가장 많아요',
      );
      expect(
        buildOhaengBalanceNarrative(
          dominant: '토',
          sub: '금',
          ohaengCount: const {'토': 8},
          total: 8,
        ),
        '전체 8글자 중 토가 8개(100%)로 가장 많아요',
      );
      expect(
        buildOhaengBalanceNarrative(
          dominant: '수',
          sub: '금',
          ohaengCount: const {'수': 8},
          total: 8,
        ),
        '전체 8글자 중 수가 8개(100%)로 가장 많아요',
      );
    });
  });

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

  testWidgets('헤더 타이틀·메타 라인 글자 크기가 목업 값(15.5px/10.5px)과 일치한다', (WidgetTester tester) async {
    // 2026-07-16 목업(.result-head h2/.result-head .meta) 정밀 대조 수정: 헤더 블록은
    // 2026-07-05 최초 구현 이후 한 번도 대조된 적이 없어 타이틀이 22px(목업 15.5px),
    // 메타 라인이 13px에 굵기 미지정(목업 10.5px/font-weight:600)이었다 — 이 값들
    // 자체를 확인하는 테스트가 지금까지 없었다.
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

    final titleText = tester.widget<Text>(findInBody('회원님의 사주팔자 ✨'));
    expect(titleText.style!.fontSize, 15.5, reason: '헤더 타이틀 fontSize');
    expect(titleText.style!.fontWeight, FontWeight.w800, reason: '헤더 타이틀 fontWeight');

    final metaText = tester.widget<Text>(
      findInBodyContaining('1998.08.15'),
    );
    expect(metaText.style!.fontSize, 10.5, reason: '메타 라인 fontSize');
    expect(metaText.style!.fontWeight, FontWeight.w600, reason: '메타 라인 fontWeight');
  });

  testWidgets('_PillarCard 한자와 라벨 사이 간격이 목업 값(4px)과 일치한다', (WidgetTester tester) async {
    // 2026-07-16 목업(.pillar-card .label margin-top:4px) 정밀 대조 수정: 지금까지는
    // SizedBox(height: 6)이었다 — 이 값 자체를 확인하는 테스트가 지금까지 없었다.
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

    // 4기둥 카드 안 한자("무인") 바로 다음 SizedBox가 height:4여야 한다. 여러 SizedBox
    // 후보가 있으니, "무인" Text의 부모 Column 자식 목록에서 두 번째 위치(한자 Text
    // 다음)를 확인한다.
    final column = tester.widget<Column>(
      find.ancestor(of: findInBody('무인'), matching: find.byType(Column)).first,
    );
    final sizedBox = column.children[1] as SizedBox;
    expect(sizedBox.height, 4, reason: '_PillarCard 한자↔라벨 간격');
  });

  testWidgets('"공유하기" 버튼이 목업대로 accent→metal 그라데이션 배경을 쓴다', (WidgetTester tester) async {
    // 2026-07-06에 이 버튼을 단색 accent에서 accent→metal 그라데이션으로 고쳤는데,
    // 그 뒤로도 실제 그라데이션 색상 값을 확인하는 테스트는 없었다 — 버튼 문구·onPressed
    // 동작은 안 바뀌므로 그런 테스트들은 그라데이션이 실수로 다시 단색으로 되돌아가도
    // 못 잡는다. 버튼이 긴 리스트 아래쪽에 있어(기본 뷰포트로는 지연 빌드돼 못 찾음)
    // 뷰포트를 세로로 키운다.
    await useTallViewport(tester);

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

    final shareButtonContainer = tester.widget<Container>(
      find.ancestor(
        of: find.widgetWithText(ElevatedButton, '📸 공유하기'),
        matching: find.byType(Container),
      ).first,
    );
    final gradient = (shareButtonContainer.decoration! as BoxDecoration).gradient! as LinearGradient;
    expect(gradient.colors, [AppColors.accent, AppColors.metal]);
  });

  testWidgets('"📸 공유하기" 버튼의 스크린 리더 라벨은 이모지 없이 "공유하기"만 읽힌다', (WidgetTester tester) async {
    // 2026-07-15 접근성 정리: 📸 이모지는 시각적 장식일 뿐인데 semanticsLabel 없이
    // Text 그대로 두면 스크린 리더가 이모지를 유니코드 이름으로 읽어 혼란을 준다 —
    // semanticsLabel: '공유하기'로 라벨을 깨끗하게 교체했는지 확인한다. 버튼이 긴
    // 리스트 아래쪽에 있어(기본 뷰포트로는 지연 빌드돼 못 찾음) 뷰포트를 세로로 키운다.
    await useTallViewport(tester);
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

    expect(tester.getSemantics(find.text('📸 공유하기')).label, '공유하기');

    semantics.dispose();
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

    // 2026-07-08 발견한 커버리지 공백: `_PillarCard`는 시맨틱스(라벨+값 병합)는 이미
    // 검증돼 있지만, 정작 그 카드의 글자색 자체(`ohaengTextColors[stemOhaeng(stemIndex)]`,
    // 천간의 오행에 따라 달라짐)가 실제로 맞는 색으로 렌더링되는지는 한 번도 확인한
    // 적이 없었다 — 년주 무인(戊)은 토, 월주 경신(庚)은 금, 일주 갑자(甲)는 목,
    // 시주 신미(辛)는 금(천간 기준, 지지는 무시).
    expect(tester.widget<Text>(findInBody('무인')).style!.color, AppColors.ohaengTextColors['토']);
    expect(tester.widget<Text>(findInBody('경신')).style!.color, AppColors.ohaengTextColors['금']);
    expect(tester.widget<Text>(findInBody('갑자')).style!.color, AppColors.ohaengTextColors['목']);
    expect(tester.widget<Text>(findInBody('신미')).style!.color, AppColors.ohaengTextColors['금']);

    // ohaengCount 분포 {목:2, 화:0, 토:2, 금:3, 수:1}(총 8) → 25%/0%/25%/38%/13%.
    expect(findInBody('25%'), findsNWidgets(2)); // 목, 토
    expect(findInBody('0%'), findsOneWidget); // 화
    expect(findInBody('38%'), findsOneWidget); // 금
    expect(findInBody('13%'), findsOneWidget); // 수
  });

  testWidgets('오행 밸런스 바 차트 아래 서술 문단이 % 숫자 + 우세·2순위 오행 관계를 정확히 보여준다',
      (WidgetTester tester) async {
    // 2026-07-13 추가: 오행 밸런스 바 차트만으로는 %와 우세/2순위 오행의 관계(상생·상극)를
    // 말로 풀어주지 않아, 그 아래 서술 문단(buildOhaengBalanceNarrative)을 새로 추가했다.
    // 1998-08-15/14시 분포({목:2,화:0,토:2,금:3,수:1}, 총 8)는 금이 dominant(3개,38%),
    // 목이 sub(2개,25%)이고 관계는 금극목(dominantOvercomesSub)이다.
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
      findInBody(
        '전체 8글자 중 금이 3개(38%)로 가장 많고, 목이 2개(25%)로 그다음이에요 — '
        '금 기운이 목 기운을 다스리는 흐름이라 주도권을 쥐는 편이에요',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      '2026-07-06 발견: 음력으로 입력해도 양력 변환 없이 같은 날짜로 계산돼 4기둥이 동일하다 (알려진 한계, 회귀 고정용)',
      (WidgetTester tester) async {
    // four_pillars.dart의 calculateFourPillars()는 isLunar 파라미터 자체를 받지 않고
    // birthDate를 무조건 양력으로 취급한다 — 지금까지 이 프로젝트의 모든 위젯 테스트가
    // isLunar: false만 써왔기 때문에, 음력을 선택해도 결과 화면의 4기둥이 (변환되지 않고)
    // 양력으로 입력했을 때와 완전히 똑같이 나온다는 것을 값으로 확인한 적이 한 번도 없었다.
    // 이 테스트는 버그를 고치는 게 아니라 "지금 이렇게 동작한다"는 것을 고정해두는 것 —
    // 실제 음력→양력 변환 포팅은 절기 근사·자시 관법·진태양시 미보정과 같은 사람 결정 대기 항목.
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: true),
          ),
        ),
        initialRoute: '/',
      ),
    );

    // isLunar: false일 때와 정확히 같은 4주(년주 무인, 월주 경신, 일주 갑자, 시주 신미).
    expect(findInBody('무인'), findsOneWidget);
    expect(findInBody('경신'), findsOneWidget);
    expect(findInBody('갑자'), findsOneWidget);
    expect(findInBody('신미'), findsOneWidget);

    // 메타 라인에는 "음력" 라벨만 반영되고(표시상의 차이), 계산 자체는 바뀌지 않는다.
    expect(
      find.descendant(
        of: find.byKey(const Key('resultScrollView')),
        matching: find.textContaining('음력'),
      ),
      findsOneWidget,
    );
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
    // **2026-07-13 변경**: 우세 오행(금) 단독이 아니라 2순위 오행(목, 개수 2)까지 반영한
    // 콤보 콜아웃·카테고리 접미사(dominantComboCallout/categoryReadingsForCombo, 금극목
    // 관계)로 문구가 바뀌었다. 접미사가 늘어난 만큼(밸런스 서술 문단도 새로 추가됨) 카테고리
    // 카드가 기본 뷰포트(800x600) 아래로 밀려 ListView가 지연 빌드해버려 못 찾는 걸
    // 실측으로 확인했다 — 뷰포트를 세로로 키운다.
    await useTallViewport(tester);

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

    const calloutText = '금(金) 기운이 강한 타입이에요 ✨\n'
        '금 기운이 목 기운을 정리해줘서 벌여둔 일을 야무지게 마무리 짓는 힘이 있어요';
    expect(findInBody(calloutText), findsOneWidget);
    expect(
      findInBody(
        '눈이 높은 편이라 확실한 상대를 알아보는 시기예요. 목 기운을 잘 다스리는 편이라 중심을 잃지 않아요',
      ),
      findsOneWidget,
    ); // 금 연애운 + 금극목 접미사
    expect(
      findInBody(
        '계획적으로 관리하면 돈이 잘 모이는 편이에요. 목 기운을 잘 다스리는 편이라 중심을 잃지 않아요',
      ),
      findsOneWidget,
    ); // 금 재물운 + 접미사
    expect(
      findInBody(
        '호흡기·피부 컨디션을 신경 쓰면 좋아요. 목 기운을 잘 다스리는 편이라 중심을 잃지 않아요',
      ),
      findsOneWidget,
    ); // 금 건강운 + 접미사
    expect(
      findInBody(
        '원칙적이고 맺고 끊음이 확실한 타입이에요. 목 기운을 잘 다스리는 편이라 중심을 잃지 않아요',
      ),
      findsOneWidget,
    ); // 금 성격 + 접미사

    // 2026-07-06에 콜아웃 박스가 우세 오행 색(ohaengSoftColors[dominant])으로 물들도록
    // 고쳤는데, 그 뒤로도 실제 배경색 값 자체를 확인한 테스트는 없었다 — 텍스트 내용만
    // 맞고 색이 우연히 다시 accentSoft로 되돌아가도(줄 커버리지만으로는) 못 잡는다.
    final calloutContainer = tester.widget<Container>(
      find.ancestor(
        of: findInBody(calloutText),
        matching: find.byType(Container),
      ).first,
    );
    final calloutDecoration = calloutContainer.decoration! as BoxDecoration;
    expect(calloutDecoration.color, AppColors.ohaengSoftColors['금']);
  });

  testWidgets('메인 콜아웃 박스가 목업 값대로 padding(15/13)·글자 크기(12.5)·줄 간격(1.55)을 유지한다',
      (WidgetTester tester) async {
    // 2026-07-15 목업(.callout) 정밀 대조 수정: padding이 EdgeInsets.all(20) 균일값에서
    // symmetric(horizontal:15, vertical:13)으로, 텍스트에 fontSize 12.5·height 1.55가
    // 새로 명시됐다 — 이 값들 자체를 확인하는 테스트가 지금까지 없어서, 누군가 실수로
    // 원래 값(all(20)/height 1.4/fontSize 미지정)으로 되돌려도 잡아낼 방법이 없었다.
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

    // 1998-08-15 14시 → 우세 오행 '금'(2순위 '목', 금극목 관계) 콜아웃 문구.
    const calloutText = '금(金) 기운이 강한 타입이에요 ✨\n'
        '금 기운이 목 기운을 정리해줘서 벌여둔 일을 야무지게 마무리 짓는 힘이 있어요';

    final calloutContainer = tester.widget<Container>(
      find.ancestor(
        of: findInBody(calloutText),
        matching: find.byType(Container),
      ).first,
    );
    expect(calloutContainer.padding, const EdgeInsets.symmetric(horizontal: 15, vertical: 13));

    final calloutTextStyle = tester.widget<Text>(findInBody(calloutText)).style!;
    expect(calloutTextStyle.fontSize, 12.5);
    expect(calloutTextStyle.height, 1.55);
  });

  testWidgets('카테고리 카드(연애·재물·건강·성격) 아이콘·제목 글자 크기가 목업 값(15px/11px)과 일치한다',
      (WidgetTester tester) async {
    // 2026-07-15 목업(.cat-card) 정밀 대조 수정: 아이콘 fontSize 20→15, 제목에 fontSize
    // 11 신규 명시 — 카드 시맨틱스(제목+설명 병합 문구)는 이미 검증돼 있었지만 정작
    // 시각적 글자 크기 자체는 한 번도 값으로 확인된 적이 없었다.
    // 접미사·밸런스 서술 문단이 늘어난 만큼 카드가 기본 뷰포트(800x600) 아래로 밀려
    // ListView가 지연 빌드해버리는 걸 다른 카테고리 카드 테스트에서와 같은 이유로
    // 뷰포트를 세로로 키운다.
    await useTallViewport(tester);

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

    // 1998-08-15 14시 → 우세 오행 '금'의 연애운 카드는 아이콘 '💘', 제목 '연애운'.
    final iconText = tester.widget<Text>(findInBody('💘'));
    expect(iconText.style!.fontSize, 15);

    final titleText = tester.widget<Text>(findInBody('연애운'));
    expect(titleText.style!.fontSize, 11);
  });

  testWidgets('우세 오행 콜아웃 문구가 나머지 4개 오행(목·화·토·수)에서도 실제 값과 정확히 일치한다',
      (WidgetTester tester) async {
    // 위 테스트는 '금'(+2순위 목)만 확인했다 — 콤보 콜아웃(`dominantComboCallout`)은
    // dominant 5종 × 관계 4종 = 20가지 문구를 갖는데, 나머지 조합은 지금까지 어떤
    // birthInfo로도 실제로 우세/2순위 오행이 되게 만들어 값으로 확인한 적이 없었다 —
    // 오행별 영역 풀이·직장운·MBTI 코멘트·오행 5종 의미에서 반복 발견된 것과 같은
    // 종류의 공백. 이 문구는 "$dominant($한자) 기운이 강한 타입이에요 $이모지\n$설명"처럼
    // 오행 이름 자체가 문자열 안에 포함된 하나의 Text이므로, 그대로 값을 대조하면
    // 오행끼리 문구가 뒤바뀌어도 자동으로 잡힌다. 실제 우세/2순위 오행 조합이 되는
    // 생년월일을 미리 찾아(core/saju/four_pillars_test.dart 분포 계산과 같은 방식)
    // 각각 pumpWidget한다.
    const fixtures = {
      // (생년월일, dominant 한자, 이모지, 콤보 콜아웃 설명) — 2순위 오행·관계는 주석 참고.
      '목': (
        '1980-02-18',
        '木',
        '🌿',
        '금 기운이 앞서가려는 마음에 살짝 브레이크를 걸어줘요. 그 덕에 무모한 결정은 줄어드는 편이에요',
      ), // dominant=목, sub=금(3, 금극목)
      '화': (
        '1980-01-15',
        '火',
        '🔥',
        '화 기운이 토 기운을 데워줘서 열정이 안정적인 결과로 차곡차곡 쌓여가요',
      ), // dominant=화, sub=토(4, 화생토)
      '토': (
        '1980-01-01',
        '土',
        '🪵',
        '목 기운이 토 기운을 흔들어서 안정만 좇던 마음에 새로운 자극이 생겨요. 변화가 나쁘지만은 않아요',
      ), // dominant=토, sub=목(1, 목극토)
      '수': (
        '1980-06-01',
        '水',
        '💧',
        '금 기운이 원천이 되어줘서 유연함 속에 단단한 원칙까지 갖추게 돼요',
      ), // dominant=수, sub=금(2, 금생수)
    };

    for (final entry in fixtures.entries) {
      final (dateStr, hanja, emoji, desc) = entry.value;
      final parts = dateStr.split('-').map(int.parse).toList();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (_) => const ResultScreen(),
            settings: RouteSettings(
              arguments: BirthInfo(
                date: DateTime(parts[0], parts[1], parts[2]),
                hour: 14,
                isLunar: false,
              ),
            ),
          ),
          initialRoute: '/',
        ),
      );

      expect(
        findInBody('${entry.key}($hanja) 기운이 강한 타입이에요 $emoji\n$desc'),
        findsOneWidget,
        reason: '${entry.key} 콜아웃 문구',
      );
    }
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
    // 2026-07-15 발견한 콘텐츠 스왑 취약점 보강: 년주·시주 두 개만 값으로 고정돼
    // 있어 _PillarCard 4번 호출(년/월/일/시) 중 가운데 두 줄(월주↔일주)의 pillars
    // 인자가 실수로 뒤바뀌어도(예: 월주 카드에 pillars.day, 일주 카드에 pillars.month)
    // 양 끝(년주·시주)만 맞으면 이 테스트가 그대로 통과해버렸다 — 월주 경신,
    // 일주 갑자도 값으로 고정해 스왑 시 반드시 실패하도록 한다.
    expect(
      tester.getSemantics(findInBody('경신')),
      matchesSemantics(label: '월주 경신'),
    );
    expect(
      tester.getSemantics(findInBody('갑자')),
      matchesSemantics(label: '일주 갑자'),
    );
    expect(
      tester.getSemantics(findInBody('신미')),
      matchesSemantics(label: '시주 신미'),
    );

    semantics.dispose();
  });

  testWidgets('오행 밸런스 바 각 행도 스크린 리더에 "오행명 비중 %"로 병합된 시맨틱스를 제공한다',
      (WidgetTester tester) async {
    // 2026-07-15 접근성 발견: _OhaengBarRow는 화면에는 한자(木/火/土/金/水) 태그를
    // 보여주는데, 스크린 리더는 한자를 발음할 수 없어 그대로 두면 "목, 화, 토, 금,
    // 수"라는 실제 뜻을 전혀 알려주지 못했다 — _PillarCard/_CategoryCard와 같은
    // 병합 패턴으로 한글 오행명 라벨을 확인한다.
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

    // ohaengCount 분포 {목:2, 화:0, 토:2, 금:3, 수:1}(총 8) → 25%/0%/25%/38%/13%
    // (위 "4기둥 명식과 오행 밸런스 퍼센트가..." 테스트와 같은 조합). 화면에는 오행이
    // 한자(金/水)로 표시되지만, 시맨틱스 라벨은 발음 가능한 한글(금/수)이어야 하므로
    // 각 행의 유일한 값인 퍼센트 텍스트로 노드를 찾는다(38%는 금, 13%는 수 하나뿐).
    expect(
      tester.getSemantics(findInBody('38%')),
      matchesSemantics(label: '금 비중 38%'),
    );
    expect(
      tester.getSemantics(findInBody('13%')),
      matchesSemantics(label: '수 비중 13%'),
    );

    semantics.dispose();
  });

  testWidgets('오행 밸런스 바 5행 전부가 서로 라벨이 뒤바뀌어도(콘텐츠 스왑) 잡아낼 수 있다',
      (WidgetTester tester) async {
    // 위 테스트는 38%/13%처럼 값이 유일한 두 행만 확인했다 — 목(2)/토(2)처럼 개수가
    // 같은 오행끼리는 퍼센트 텍스트만으로 찾으면 어느 노드가 어느 오행인지 구분이 안 돼,
    // 예를 들어 목/토 행의 라벨이 서로 뒤바뀌어도(둘 다 "25%"라 값 자체는 똑같이 보임)
    // 퍼센트 기반 조회로는 절대 못 잡는다. 화면에 한자(木/火/土/金/水)는 오행별로
    // 유일하게 하나씩만 나타나므로, 이 한자 Text를 앵커로 삼아 그 행의 병합 시맨틱스
    // 라벨을 확인하면 값이 겹치는 행도 포함해 5행 전부를 검증할 수 있다.
    //
    // 1970-01-02 13시 생일은 ohaengCount {목:0, 화:2, 토:3, 금:1, 수:2}(총 8)로 목≠토라,
    // 기존 조합(1998-08-15)에서는 못 갈랐던 목/토 쌍을 이 조합으로 보강한다(화/수는 둘 다
    // 25%로 겹치지만, 한자 앵커 방식은 값이 겹쳐도 상관없다).
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1970, 1, 2), hour: 13, isLunar: false),
          ),
        ),
        initialRoute: '/',
      ),
    );

    const expectedLabelByHanja = {
      '木': '목 비중 0%',
      '火': '화 비중 25%',
      '土': '토 비중 38%',
      '金': '금 비중 13%',
      '水': '수 비중 25%',
    };

    for (final entry in expectedLabelByHanja.entries) {
      final rowSemantics = find.ancestor(
        of: findInBody(entry.key),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label?.contains('비중') == true,
        ),
      );
      expect(
        tester.widget<Semantics>(rowSemantics).properties.label,
        entry.value,
        reason: '한자 ${entry.key} 행의 병합 시맨틱스 라벨',
      );
    }

    semantics.dispose();
  });

  testWidgets('오행 밸런스 바 한자 태그가 목업 값대로 SizedBox(width:14)/fontSize 11/가운데 정렬로 렌더링된다',
      (WidgetTester tester) async {
    // 2026-07-15 목업(.bar-row .tag) 정밀 대조 수정: 태그 width가 20(폰트 크기
    // 미지정)에서 14로 좁아지고 fontSize 11이 새로 명시됐다(Center로 감싸 가운데
    // 정렬도 추가) — 이 값들 자체를 확인하는 테스트가 지금까지 없어서, 누군가 실수로
    // 원래 값(width 20/fontSize 미지정)으로 되돌려도 잡아낼 방법이 없었다.
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

    // 한자 태그를 감싸는 SizedBox(width:14)가 오행 5행 전부에 있는지 확인한다.
    final tagBoxes = tester.widgetList<SizedBox>(
      find.byWidgetPredicate((widget) => widget is SizedBox && widget.width == 14),
    );
    expect(tagBoxes.length, 5);

    // 한자 태그 자체(가운데 정렬 + fontSize 11)도 5개(목/화/토/금/수) 전부 확인한다.
    for (final hanja in const ['木', '火', '土', '金', '水']) {
      final tagText = tester.widget<Text>(findInBody(hanja));
      expect(tagText.style!.fontSize, 11, reason: '$hanja 태그 fontSize');
      expect(tagText.textAlign, TextAlign.center, reason: '$hanja 태그 textAlign');
    }
  });

  testWidgets('오행 밸런스 바의 한자 태그·퍼센트 텍스트가 FittedBox로 감싸져 폰트 확대 시 잘리지 않는다',
      (WidgetTester tester) async {
    // 2026-07-15 접근성 감사 발견: 한자 태그(SizedBox width:14)와 퍼센트 텍스트
    // (SizedBox width:40)는 고정폭인데, 시스템 폰트 확대 배율이 커지면
    // Container/SizedBox 특성상 예외 없이 조용히 잘린다 — 기존 `takeException()`
    // 방식 테스트로는 이 조용한 잘림을 못 잡는다. FittedBox로 감싸 고쳤는데, 이
    // 구조 자체가 남아있는지(누군가 실수로 FittedBox를 걷어내도) 확인한다.
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

    for (final hanja in const ['木', '火', '土', '金', '水']) {
      final fittedBoxAncestor = find.ancestor(
        of: findInBody(hanja),
        matching: find.byType(FittedBox),
      );
      expect(fittedBoxAncestor, findsOneWidget, reason: '"$hanja" 태그가 FittedBox로 감싸져 있어야 함');
    }

    // ohaengCount 분포 {목:2, 화:0, 토:2, 금:3, 수:1}(총 8) → 25%/0%/25%/38%/13%
    // (위 한자 태그 테스트와 같은 조합). 퍼센트 텍스트 5개 전부 FittedBox로
    // 감싸져 있는지 확인한다.
    for (final percent in const ['25%', '0%', '38%', '13%']) {
      final fittedBoxAncestor = find.ancestor(
        of: findInBody(percent).first,
        matching: find.byType(FittedBox),
      );
      expect(fittedBoxAncestor, findsOneWidget, reason: '"$percent" 텍스트가 FittedBox로 감싸져 있어야 함');
    }
  });

  testWidgets(
      '시스템 폰트 확대 배율 2.0~3.0에서도 오행 한자 태그·퍼센트 텍스트가 실제로 잘리지 않고 '
      '온전한 크기로 그려진다(FittedBox 구조 존재만이 아니라 실제 렌더링 검증)',
      (WidgetTester tester) async {
    // 2026-07-15 접근성 감사 발견 + 재검증(오버나이트 QA): 위 테스트는 FittedBox
    // "구조가 존재하는지"만 확인한다 — 그런데 FittedBox를 넣고도 fit을 잘못
    // 쓰거나 엉뚱한 곳에 넣는 실수는 구조 존재 확인만으로는 못 잡는다. 진짜 구별
    // 기준은 "글자가 실제로 잘렸는가"다 — FittedBox는 자식에게 무제한 제약을 준 뒤
    // 그 결과(제약 없는 자연 크기)를 축소 변환으로 보여주므로, 텍스트 위젯 자신의
    // 로컬 렌더 크기(tester.getSize, 변환 적용 전)는 항상 TextPainter로 직접 계산한
    // "제약 없는 자연 크기"와 같아야 한다. FittedBox가 없으면 고정폭 제약 때문에
    // 자연 크기보다 작게(=잘려서) 렌더링된다.
    await useTallViewport(tester, height: 3000);

    for (final scale in const [2.0, 3.0]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (_) => const ResultScreen(),
              settings: RouteSettings(
                arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
              ),
            ),
            initialRoute: '/',
          ),
        ),
      );
      await tester.pump();

      void expectNotClipped(Finder finder, String label) {
        final textWidget = tester.widget<Text>(finder);
        final naturalPainter = TextPainter(
          text: TextSpan(text: textWidget.data, style: textWidget.style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(scale),
        )..layout();
        final naturalSize = naturalPainter.size;
        final renderedSize = tester.getSize(finder);
        expect(
          renderedSize.width,
          greaterThanOrEqualTo(naturalSize.width - 0.5),
          reason: '배율 $scale, "$label"이 가로로 잘림 — '
              '실제 렌더 폭=${renderedSize.width}, 제약 없는 자연 폭=${naturalSize.width}',
        );
        expect(
          renderedSize.height,
          greaterThanOrEqualTo(naturalSize.height - 0.5),
          reason: '배율 $scale, "$label"이 세로로 잘림 — '
              '실제 렌더 높이=${renderedSize.height}, 제약 없는 자연 높이=${naturalSize.height}',
        );
      }

      // 한자 태그(SizedBox width:14).
      for (final hanja in const ['木', '火', '土', '金', '水']) {
        expectNotClipped(findInBody(hanja), hanja);
      }

      // 퍼센트 텍스트(SizedBox width:40).
      for (final percent in const ['25%', '0%', '38%', '13%']) {
        expectNotClipped(findInBody(percent).first, percent);
      }
    }
  });

  testWidgets('오행 밸런스 바 두께(minHeight)가 목업 값(8px)과 일치한다', (WidgetTester tester) async {
    // 2026-07-15 목업(.bar-track) 정밀 대조 수정: height가 10px에서 8px로 좁아졌다 —
    // 이 값 자체를 확인하는 테스트가 지금까지 없었다.
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

    // 화면 밖 공유용 ShareCard도 자체 오행 바(minHeight 7, 이 화면 값과 다름)를
    // 가지고 있어(share_card.dart), 범위를 resultScrollView 안으로 좁히지 않으면
    // 서로 다른 값이 섞여 개수·값 검증이 어긋난다.
    final bars = tester.widgetList<LinearProgressIndicator>(
      find.descendant(
        of: find.byKey(const Key('resultScrollView')),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(bars.length, 5);
    for (final bar in bars) {
      expect(bar.minHeight, 8);
    }
  });

  testWidgets('오행 밸런스 바 행 사이 간격이 목업 값(margin-bottom 5px, padding vertical 2.5)과 일치한다',
      (WidgetTester tester) async {
    // 2026-07-15 목업(.bar-row) 정밀 대조 수정: margin-bottom:5px를 위아래 대칭
    // 패딩으로 구현하다 보니 vertical:4(행 사이 실제 간격 8px)였던 걸 vertical:2.5
    // (행 사이 실제 간격 5px)로 좁혔다 — 이 값 자체를 확인하는 테스트가 지금까지 없었다.
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

    final rowPaddings = tester.widgetList<Padding>(
      find.byWidgetPredicate(
        (widget) => widget is Padding && widget.padding == const EdgeInsets.symmetric(vertical: 2.5),
      ),
    );
    expect(rowPaddings.length, 5);
  });

  testWidgets(
      '"오행 밸런스"/"오늘 궁금한 것부터" 소제목이 목업 eyebrow 라벨 톤(fontSize 11/inkSoft/letterSpacing 0.22)으로 렌더링된다',
      (WidgetTester tester) async {
    // 2026-07-15 목업(.bars h3/.cards h3) 정밀 대조 수정: 두 소제목이 본문 헤드라인만큼
    // 진한 fontSize 15/AppColors.ink였던 걸 목업 스펙인 fontSize 11/AppColors.inkSoft로
    // 바꿨다 — 이 값 자체를 확인하는 테스트가 지금까지 없었다. "오늘 궁금한 것부터"는
    // 화면 아래쪽이라 기본 뷰포트로는 지연 빌드돼 못 찾으므로 뷰포트를 세로로 키운다.
    // 2026-07-16 오버나이트 대조 추가 수정: 목업(`.bars h3`/`.cards h3`)의
    // letter-spacing:.02em(≈0.22px)이 빠져 있던 것도 새로 확인한다 — fontSize/color만
    // 확인하던 기존 테스트로는 letterSpacing 누락(또는 회귀)을 잡을 수 없었다.
    await useTallViewport(tester);

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

    final balanceTitle = tester.widget<Text>(findInBody('오행 밸런스'));
    expect(balanceTitle.style!.fontSize, 11, reason: '오행 밸런스 소제목 fontSize');
    expect(balanceTitle.style!.color, AppColors.inkSoft, reason: '오행 밸런스 소제목 color');
    expect(balanceTitle.style!.letterSpacing, 0.22, reason: '오행 밸런스 소제목 letterSpacing');

    final cardsTitle = tester.widget<Text>(findInBody('오늘 궁금한 것부터'));
    expect(cardsTitle.style!.fontSize, 11, reason: '오늘 궁금한 것부터 소제목 fontSize');
    expect(cardsTitle.style!.color, AppColors.inkSoft, reason: '오늘 궁금한 것부터 소제목 color');
    expect(cardsTitle.style!.letterSpacing, 0.22, reason: '오늘 궁금한 것부터 소제목 letterSpacing');
  });

  testWidgets('화면 밖 공유용 카드는 위젯 트리에는 남아있지만 스크린 리더 시맨틱스에서는 제외된다',
      (WidgetTester tester) async {
    // 2026-07-15 접근성 발견: ShareCard는 Positioned(left: -4000)로 화면 밖에 배치돼
    // 페인트·히트테스트만 제외될 뿐, ExcludeSemantics로 감싸지 않으면 시맨틱스
    // 트리에는 그대로 남아 스크린 리더가 방금 읽은 본문 내용을 라벨 없이 중복해서
    // 다시 읽어준다 — ShareCard 전용 워터마크 문구("#사주랑 #사주팔자 #오행")로
    // 위젯 자체는 여전히 존재하되(오프스크린 캡처를 위해 레이아웃·페인트는 필요)
    // 시맨틱스 트리에서는 완전히 빠졌는지 확인한다.
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

    expect(find.text('#사주랑  #사주팔자  #오행'), findsOneWidget);
    expect(find.bySemanticsLabel('#사주랑  #사주팔자  #오행'), findsNothing);

    semantics.dispose();
  });

  testWidgets('카테고리 카드(연애·재물·건강·성격)도 스크린 리더에 "제목. 설명"으로 병합된 시맨틱스를 제공한다',
      (WidgetTester tester) async {
    // _CategoryCard는 _PillarCard와 같은 파일에 있지만 지금까지 병합 시맨틱스가
    // 없었다(2026-07-07 발견) — 아이콘·제목·설명이 각각 별도 Text라 스크린 리더가
    // 세 번 나눠 읽었고, 장식용 이모지까지 유니코드 이름으로 읽어 혼란스러웠다.
    // 1998-08-15/14시 생일의 우세 오행은 '금'(2순위 '목', 금극목 관계)이라
    // categoryReadingsForCombo('금', '목', subCount: 2)의 첫 항목("연애운. 눈이 높은...
    // + 접미사")으로 병합됐는지 확인한다.
    // 접미사·밸런스 서술 문단이 늘어난 만큼 카드가 기본 뷰포트(800x600) 아래로 밀려
    // ListView가 지연 빌드해버리는 걸 실측으로 확인했다 — 뷰포트를 세로로 키운다.
    await useTallViewport(tester);

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
      tester.getSemantics(findInBody('연애운')),
      matchesSemantics(
        label: '연애운. 눈이 높은 편이라 확실한 상대를 알아보는 시기예요. '
            '목 기운을 잘 다스리는 편이라 중심을 잃지 않아요',
      ),
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

  testWidgets('"공유하기"를 눌렀을 때 공유 시트가 실패하면 스낵바로 알려준다', (WidgetTester tester) async {
    // _handleShare는 이미지 캡처 실패는 try/catch로 잡아 텍스트 폴백을 하고,
    // SharePlus.instance.share() 자체가 실패해도 스낵바를 띄우도록 구현돼 있다.
    // 하지만 지금까지는 "SharePlus가 싱글턴이라 자동 테스트 범위 밖(수동 검증만
    // 가능)"이라고 판단해 실제로 버튼을 눌러보는 테스트가 하나도 없었다 — 실제로
    // 위젯 테스트 환경에서 share_plus의 플랫폼 채널에 목(mock) 핸들러가 없으면
    // MissingPluginException이 발생하는데, 이게 바로 우리가 대비하려던 "공유 시트
    // 자체 실패" 상황과 동일해서 실제로 재현·검증이 가능하다는 걸 이번에 확인했다.
    // 화면 하단 버튼을 찾으려면(긴 리스트라 기본 뷰포트보다 큼) 뷰포트를 세로로
    // 키워야 하고, RenderRepaintBoundary.toImage() 캡처가 실제 엔진 콜백을
    // 기다려야 해서 tester.runAsync()로 감싸야 한다(둘 다 CLAUDE.md에 기록된
    // 기존 함정과 동일한 이유).
    await useTallViewport(tester);

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

    // 실제 이미지 캡처(RenderRepaintBoundary.toImage()) + 실패하는 플랫폼 채널
    // 왕복까지 실제 시간(wall-clock)이 걸리는 작업이라, 시스템 부하가 높을 때
    // 300ms로는 부족해 스낵바가 아직 안 뜬 상태에서 검사해버리는 걸 실제로
    // 확인했다(고정된 짧은 지연은 느린 환경에서 간헐적 실패를 유발함) — 여유 있게
    // 늘려서 실제 작업이 끝날 시간을 넉넉히 확보한다.
    await tester.runAsync(() async {
      await tester.tap(find.text('📸 공유하기'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(
      find.text('공유하는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.'),
      findsOneWidget,
    );
  });

  testWidgets(
      '2026-07-06 발견: 공유 카드 이미지 캡처 자체가 실패하면(레이아웃 전 등) 텍스트만으로 폴백한다 (커버리지로 확인)',
      (WidgetTester tester) async {
    // 위 테스트는 SharePlus.instance.share() 자체가 실패하는 경로("공유 시트 자체
    // 실패")만 검증했는데, `flutter test --coverage`로 lcov.info를 직접 분석해보니
    // _handleShare()의 이미지 캡처 실패 시 텍스트 전용으로 폴백하는 else 분기(카드
    // 캡처에 성공하면 도는 if 분기와 갈라지는 지점)는 지금까지 단 한 번도 실행된 적이
    // 없었다는 걸 발견했다 — 위 테스트에서는 매번 카드 캡처 자체는 성공하고
    // (`imageBytes != null`) share() 호출만 실패했기 때문이다.
    // 이미지 캡처 실패(`boundary.debugNeedsPaint`가 true거나 boundary를 못 찾는
    // 경우)를 재현하려면, RepaintBoundary가 실제로 paint 단계까지 거치기 전에
    // 버튼을 눌러야 한다 — `pumpWidget`에 `EnginePhase.layout`을 줘서 build·layout만
    // 하고 paint는 아직 안 돈 상태로 멈춘 뒤(탭 좌표 계산 없이) 버튼의 onPressed를
    // 직접 동기 호출하면, `_handleShare`가 읽는 `boundary.debugNeedsPaint`가 아직
    // true라 캡처를 건너뛰고 텍스트 전용 분기(else)를 타게 된다.
    await useTallViewport(tester);

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
      phase: EnginePhase.layout,
    );

    final button =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '📸 공유하기'));

    await tester.runAsync(() async {
      button.onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // SharePlus.instance.share() 자체는 여전히 플랫폼 채널이 없어 실패하므로,
    // 이 분기를 타도 사용자에게 보이는 결과(스낵바)는 위 테스트와 동일하다 —
    // 이 테스트가 검증하려는 건 화면에 보이는 결과가 아니라 else 분기 자체의 실행
    // 여부이며, 그건 이 테스트 실행 후 `coverage/lcov.info`에서 348~349번 줄이
    // 실제로 히트로 바뀌는지로 확인했다(코드 자체에는 그 사실을 드러내는 관찰 가능한
    // 차이가 없어 런타임 assertion만으로는 증명할 수 없음).
    expect(
      find.text('공유하는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.'),
      findsOneWidget,
    );
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

  testWidgets('시간을 몰라 시주가 없을 때만 재입력 유도 넛지 문구가 보이고, 시간을 알면 보이지 않는다',
      (WidgetTester tester) async {
    // docs/research/운세/입력_온보딩_설계.md 권장안 반영: "모름" 선택 시 시주만 제외한
    // 3주를 보여주고 재입력을 유도하는 넛지 문구를 붙인다 — hour가 있을 때는 이 문구가
    // 전혀 없어야 한다(AppBar의 "다시 입력하기" 아이콘과 중복 진입점이 되지 않도록
    // 여기서는 탭 가능한 CTA 없이 안내 문구만 둔다).
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
    expect(findInBodyContaining('태어난 시간을 알면 더 정확한 결과를 볼 수 있어요'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
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
    expect(findInBodyContaining('태어난 시간을 알면 더 정확한 결과를 볼 수 있어요'), findsNothing);
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

  testWidgets('이름이 없거나 공백뿐이면 헤더에 "회원님"으로 표시된다', (WidgetTester tester) async {
    // report_screen.dart/deep_dive_result_screen.dart도 이 화면과 똑같은 이름 폴백을
    // 쓰는데(2026-07-14 `meta_line.dart`의 공용 함수 `displayNameFor()`로 통합됨 —
    // 예전엔 세 화면이 `name?.trim().isNotEmpty == true ? ... : '회원님'` 삼항식을
    // 각자 복제해 갖고 있었다), 그쪽 테스트들은 이미 null/공백뿐인 이름 둘 다 값으로
    // 검증돼 있었다(그중 deep_dive_result_screen_test.dart의 주석은 심지어
    // "result_screen_test.dart는 이미 검증해뒀다"고 적어뒀을 정도) — 그런데 정작 이
    // 로직이 처음 만들어진 원본 화면인 이 파일에는 "이름이 있는" 경우만 테스트돼
    // 있었을 뿐, null/공백뿐인 경우를 값으로 확인하는 전용 테스트가 없었던 실제
    // 공백이었다. 지금은 세 화면 모두 `displayNameFor()`를 호출하므로 이 테스트가
    // 사실상 공용 함수를 검증하는 셈이지만, 화면 헤더에 실제로 반영되는지는 위젯
    // 테스트로 별도 확인할 가치가 있어 남겨둔다.
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

    // 같은 구조의 MaterialApp을 그대로 다시 pumpWidget하면 Flutter가 기존 엘리먼트를
    // 재사용해버려(같은 위젯 트리 형태) 새 라우트 arguments가 실제로 반영되지 않는
    // 것을 실측으로 확인했다(deep_dive_input_screen_test.dart에서 겪은 것과 같은
    // 종류의 함정) — 완전히 언마운트한 뒤 다시 pumpWidget해야 한다.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => const ResultScreen(),
          settings: RouteSettings(
            arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '   '),
          ),
        ),
        initialRoute: '/',
      ),
    );
    expect(findInBody('회원님의 사주팔자 ✨'), findsOneWidget);
    expect(findInBody('   의 사주팔자 ✨'), findsNothing);
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

  testWidgets(
      '생성자 birthInfo도 라우트 arguments도 없으면 결과 대신 입력 화면으로 되돌아간다 (2026-07-17 버그 수정)',
      (WidgetTester tester) async {
    // **2026-07-17 버그 수정**: 이전에는 build()의
    // `widget.birthInfo ?? (라우트 arguments) ?? BirthInfo(1998-08-15, 14시)` 3단 폴백
    // 중 마지막(둘 다 없을 때의 하드코딩된 기본값) 분기에서 조용히 엉뚱한 남의
    // 생년월일시(1998-08-15 14시)를 자기 결과인 것처럼 보여줬다 — "아무 데이터도
    // 입력하지 않은 상태에서는 결과 화면으로 넘어가면 안 됨" 버그 리포트의 원인 중
    // 하나였다. 이제는 birthInfo가 없으면 결과를 그리지 않고 addPostFrameCallback으로
    // BirthInputScreen까지 pushAndRemoveUntil 리다이렉트한다.
    await tester.pumpWidget(const MaterialApp(home: ResultScreen()));

    // 리다이렉트가 일어나는 프레임 사이에는 결과 콘텐츠 대신 로딩 스피너만 보인다.
    expect(find.text('회원님의 사주팔자 ✨'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // 리다이렉트 후에는 입력 화면이 보이고, 결과 콘텐츠는 트리에 남아있지 않아야 한다.
    expect(find.byType(BirthInputScreen), findsOneWidget);
    expect(find.text('생년월일시를 알려주세요'), findsOneWidget);
    expect(find.text('회원님의 사주팔자 ✨'), findsNothing);

    // pushAndRemoveUntil((route) => false)로 스택을 완전히 비웠으므로 뒤로 가기로
    // 결과 화면(ResultScreen)으로 돌아갈 수 없어야 한다.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isFalse);
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

  testWidgets('"다시 입력하기"를 누르면 이전 사람의 심층 분석(MBTI·관심사) 선택도 함께 지워진다',
      (WidgetTester tester) async {
    // "저장된 생년월일시 정보가 삭제되고, 처음부터 다시 입력하게 돼요"라는 다이얼로그
    // 안내와 달리, 지금까지는 BirthInfoStore만 지우고 DeepDiveInfoStore(MBTI·관심사)는
    // 그대로 남겨두고 있었다 — 완전히 다른 사람이 새로 입력한 뒤 심층 분석 화면에
    // 들어가면 이전 사람이 골랐던 MBTI·관심사가 그대로 다시 나타나는 실제 버그였다.
    await SharedPreferences.getInstance().then((prefs) async {
      await prefs.setInt('birth_info.date_millis', DateTime(1998, 8, 15).millisecondsSinceEpoch);
      await prefs.setStringList('deep_dive_info.interests', ['love']);
      await prefs.setString('deep_dive_info.mbti_ei', 'i');
      await prefs.setString('deep_dive_info.mbti_sn', 'n');
      await prefs.setString('deep_dive_info.mbti_tf', 't');
      await prefs.setString('deep_dive_info.mbti_jp', 'j');
    });

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
    await tester.tap(find.text('다시 입력하기').last);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('deep_dive_info.interests'), isNull);
    expect(prefs.getString('deep_dive_info.mbti_ei'), isNull);
    expect(prefs.getString('deep_dive_info.mbti_sn'), isNull);
    expect(prefs.getString('deep_dive_info.mbti_tf'), isNull);
    expect(prefs.getString('deep_dive_info.mbti_jp'), isNull);
  });

  testWidgets('BirthInfoStore 삭제가 실패해도(플랫폼 채널 오류 등) DeepDiveInfoStore는 그대로 지워진다',
      (WidgetTester tester) async {
    // 2026-07-08 버그 수정: `_resetAndReenter()`가 두 clear() 호출을 하나의 try 블록
    // 안에 같이 넣어뒀었다 — BirthInfoStore.clear()가 실패하면 catch로 바로 건너뛰어
    // DeepDiveInfoStore.clear()가 아예 호출되지 않아, 바로 위 테스트가 고쳤던 그
    // "이전 사람의 MBTI·관심사가 다음 사람에게 그대로 보이는" 데이터 유실 버그가 이
    // 실패 경로에서만 조용히 재발할 수 있었다. 실제 플랫폼 채널 오류를 재현하기 위해
    // `SharedPreferencesStorePlatform.instance`를 birth_info 키만 remove() 시
    // 예외를 던지는 가짜 구현으로 바꿔치기한다.
    final failingStore = _BirthInfoRemoveFailingStore({
      'flutter.birth_info.date_millis': DateTime(1998, 8, 15).millisecondsSinceEpoch,
      'flutter.deep_dive_info.interests': ['love'],
      'flutter.deep_dive_info.mbti_ei': 'i',
    });
    final originalStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = failingStore;
    addTearDown(() => SharedPreferencesStorePlatform.instance = originalStore);

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
    await tester.tap(find.text('다시 입력하기').last);
    await tester.pumpAndSettle();

    // 핵심 확인: BirthInfoStore 삭제가 실패했어도 DeepDiveInfoStore는 그대로 지워져야 한다.
    // (BirthInfoStore 쪽 값 자체가 실제로 지속 저장소에 남아있는지는 SharedPreferences의
    // 로컬 캐시가 플랫폼 호출 성공 여부와 무관하게 즉시 지워지는 구현 세부사항 때문에
    // 이 테스트 방식으로는 신뢰성 있게 확인할 수 없어— 이 테스트의 관심사도 아니다.)
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('deep_dive_info.interests'), isNull);
    expect(prefs.getString('deep_dive_info.mbti_ei'), isNull);
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

  testWidgets('"다시 입력하기" 다이얼로그를 "취소"가 아니라 바깥(바리어) 탭이나 뒤로 가기로 닫아도 아무 것도 지워지지 않는다',
      (WidgetTester tester) async {
    // 2026-07-08 발견한 커버리지 공백: `showDialog<bool>()`는 `barrierDismissible`를
    // 명시하지 않아 기본값 true다 — 즉 "취소" 버튼을 누르지 않고 다이얼로그 바깥을
    // 탭하거나 안드로이드 뒤로 가기를 눌러도 닫히고, 이때는 `pop(false)`가 아니라
    // `pop()`(인자 없음, null)으로 닫힌다. `_resetAndReenter`의 가드가 `confirmed != true`
    // 라 null도 "취소"와 똑같이 안전하게 처리되긴 하지만, 지금까지 "취소" 버튼을 직접
    // 누르는 경로만 테스트돼 있었을 뿐 이 null 경로 자체는 한 번도 값으로 확인된 적이
    // 없었다 — `Navigator.pop()`을 직접 호출해 바리어 닫기를 재현한다.
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
    expect(find.text('다시 입력할까요?'), findsOneWidget);

    // "취소"를 누르는 대신, 다이얼로그 안의 BuildContext로 얻은 Navigator에 인자
    // 없이 pop() — 바리어 탭·뒤로 가기와 똑같이 null을 반환하며 닫히는 경로를
    // 그대로 재현한다.
    final dialogContext = tester.element(find.text('다시 입력할까요?'));
    Navigator.of(dialogContext).pop();
    await tester.pumpAndSettle();

    expect(find.text('다시 입력할까요?'), findsNothing);
    expect(findInBody('회원님의 사주팔자 ✨'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('birth_info.date_millis'), isNotNull);
  });

  testWidgets('시스템 글자 크기를 크게(2배) 키워도 카테고리 카드에서 RenderFlex overflow가 나지 않는다',
      (WidgetTester tester) async {
    // "오늘 궁금한 것부터" 2x2 카드가 원래 GridView.count(childAspectRatio: 1.3)로
    // 셀 높이가 고정돼 있었는데, 시스템 글자 크기를 키우면(접근성 큰 텍스트 — 일부
    // 기기는 기본 제공 "큼" 설정만으로도 1.3배) 카드 안 텍스트가 그 고정 높이를
    // 넘겨 RenderFlex overflow가 실제로 재현되는 것을 확인했다 — 지금까지는 어떤
    // 테스트도 기본 배율(1.0) 외의 글자 크기로 이 화면을 렌더링해본 적이 없어서
    // 이 회귀를 못 잡고 있었다. Row-of-Expanded(_PillarCard와 같은 패턴)로 고친
    // 뒤 2배 배율에서도 예외 없이 렌더링되는지 확인한다.
    await useTallViewport(tester, height: 2400);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (_) => const ResultScreen(),
            settings: RouteSettings(
              arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
            ),
          ),
          initialRoute: '/',
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  group('섹션 제목의 header 시맨틱스(TalkBack/VoiceOver 헤딩 단위 탐색)', () {
    // 2026-07-16 접근성 감사로 페이지 제목·소제목 3곳에 Semantics(header: true)가
    // 추가됐는데, 그 header 플래그 자체를 검증하는 테스트가 없었다 — Semantics 래핑이
    // 걷히거나 header: true가 실수로 지워져도 잡아낼 방법이 없는 공백이었다.
    // share_card.dart(오프스크린 공유 카드)에 같은 문구("$displayName의 사주팔자 ✨",
    // "오행 밸런스")가 중복 존재하므로, resultScrollView 안으로 범위를 좁힌
    // findInBody를 그대로 재사용한다(그렇지 않으면 find.text()가 두 위젯을 찾아
    // getSemantics 호출 자체가 실패한다).

    testWidgets('페이지 제목 "회원님의 사주팔자 ✨"가 헤딩(isHeader)으로 노출된다', (WidgetTester tester) async {
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
        tester.getSemantics(findInBody('회원님의 사주팔자 ✨')),
        matchesSemantics(label: '회원님의 사주팔자', isHeader: true),
      );

      semantics.dispose();
    });

    testWidgets('소제목 "오행 밸런스"가 헤딩(isHeader)으로 노출된다', (WidgetTester tester) async {
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
        tester.getSemantics(findInBody('오행 밸런스')),
        matchesSemantics(label: '오행 밸런스', isHeader: true),
      );

      semantics.dispose();
    });

    testWidgets('소제목 "오늘 궁금한 것부터"가 헤딩(isHeader)으로 노출된다', (WidgetTester tester) async {
      // 화면 아래쪽이라 기본 뷰포트로는 지연 빌드돼 못 찾으므로 뷰포트를 세로로 키운다
      // (위 카테고리 카드 테스트들과 같은 이유).
      await useTallViewport(tester);
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
        tester.getSemantics(findInBody('오늘 궁금한 것부터')),
        matchesSemantics(label: '오늘 궁금한 것부터', isHeader: true),
      );

      semantics.dispose();
    });
  });

  testWidgets('카테고리 카드(연애·재물·건강·성격) 아래 건강운 면책 문구가 항상 노출된다',
      (WidgetTester tester) async {
    // 2026-07-17 오버나이트 리서치 반영: 오행별 건강운 문구가 "소화기 계통 컨디션을 특히
    // 잘 챙기면 좋아요", "호흡기·피부 컨디션을 신경 쓰면 좋아요"처럼 특정 신체 부위를 콕
    // 짚어 말하는데도 안내 문구가 전혀 없었다 — 카테고리 카드 4개는 조건 없이 항상
    // 노출되므로 면책 문구도 상시 노출돼야 한다. 카드가 화면 아래쪽에 있어(기본 뷰포트로는
    // 지연 빌드돼 못 찾음) 뷰포트를 세로로 키운다.
    await useTallViewport(tester);

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

    expect(findInBodyContaining('건강운 내용은 참고용이에요'), findsOneWidget);
  });
}

/// `birth_info.`가 포함된 키를 지우려 하면 실제 플랫폼 채널 오류를 흉내 내 예외를
/// 던지는 가짜 저장소 — 다른 키(DeepDiveInfoStore 등)는 평소처럼 정상 동작한다.
class _BirthInfoRemoveFailingStore extends InMemorySharedPreferencesStore {
  _BirthInfoRemoveFailingStore(super.data) : super.withData();

  @override
  Future<bool> remove(String key) {
    if (key.contains('birth_info')) {
      throw Exception('시뮬레이션된 플랫폼 채널 오류');
    }
    return super.remove(key);
  }
}
