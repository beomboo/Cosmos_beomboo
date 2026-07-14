import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_input_screen.dart';
import 'package:cosmos_saju/features/report/report_screen.dart';
import 'package:cosmos_saju/features/result/result_screen.dart';

void main() {
  // 리포트/결과 화면 모두 리스트가 길어 기본 테스트 화면(800x600)보다 콘텐츠가 크다 —
  // 뷰포트를 세로로 넉넉하게 키워 하단 콘텐츠까지 스크롤 없이 다 보이게 한다.
  Future<void> useTallViewport(WidgetTester tester) async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });
  }

  testWidgets('상세 리포트 화면이 오행 5종 설명과 명식 breakdown을 모두 보여준다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(find.text('상세 리포트'), findsOneWidget);
    expect(find.text('명식 한 글자씩 뜯어보기'), findsOneWidget);
    expect(find.text('오행 五行 완전 정복'), findsOneWidget);
    expect(find.textContaining('계산 정확도 안내'), findsOneWidget);
    // 2026-07-06 리서치로 자시 관법(splitJasi 등과 다른 midnight 관법 채택)과 진태양시
    // 미보정(출생지 경도·균시차 보정 없음)이라는 두 가지 추가 정확도 한계를 새로 문서화했는데,
    // 지금까지 절기 근사만 안내하고 이 두 가지는 사용자에게 전혀 알리지 않고 있었다 —
    // 실제 안내 문구에 반영됐는지 확인한다.
    expect(find.textContaining('진태양시'), findsOneWidget);
    expect(find.textContaining('자시'), findsOneWidget);
    // 2026-07-06 추가 발견: 음력 입력을 양력으로 변환하지 않고 그대로 계산에 쓴다는
    // 한계도 상세 리포트 안내 문구에 함께 반영됐는지 확인한다.
    expect(find.textContaining('음력'), findsOneWidget);
    // 2026-07-07에 "사주 계산 로직" 행에 다섯 번째 정확도 이슈(한국의 역사적 서머타임
    // 미반영)를 리서치로 새로 문서화했는데, 계산 로직 자체의 산술 버그(날짜 차이 계산의
    // DST 오프셋 문제)만 고쳤을 뿐 이 한계 자체는 다른 네 가지(절기·자시·진태양시·음력)와
    // 달리 사용자 안내 문구에 반영된 적이 없었던 공백을 2026-07-08에 발견 — 안내 문구에
    // 반영됐는지 확인한다.
    expect(find.textContaining('서머타임'), findsOneWidget);
    // 오행 5종 의미 카드가 모두 렌더링되는지 (결과 화면과 달리 우세 오행 하나가 아니라 5개 전부)
    expect(find.textContaining('목 · 성장'), findsOneWidget);
    expect(find.textContaining('화 · 열정'), findsOneWidget);
    expect(find.textContaining('토 · 안정'), findsOneWidget);
    expect(find.textContaining('금 · 원칙'), findsOneWidget);
    expect(find.textContaining('수 · 지혜'), findsOneWidget);
  });

  testWidgets('명식 breakdown 표가 실제 계산값(천간·지지 각 글자와 오행)과 정확히 일치한다', (tester) async {
    // result_screen_test.dart에서 결과 화면의 4기둥 한자·퍼센트를 값으로 검증했는데,
    // report_screen.dart는 그보다 더 자세히(천간/지지를 따로, 각각의 오행 라벨까지)
    // 보여주면서도 지금까지 "년주"/"월주" 같은 라벨만 확인했을 뿐 실제 글자·오행 값
    // 자체는 검증한 적이 없었다. 1998-08-15 14시의 4주(년주 무인·월주 경신·일주 갑자·
    // 시주 신미)를 그대로 재사용한다.
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    // 천간: 무(토), 경(금), 갑(목), 신(금, 시주) — 지지: 인(목), 신(금, 월주), 자(수), 미(토)
    // '신'은 시주 천간(辛)과 월주 지지(申)가 우연히 같은 한글로 표기돼 2번 나타난다.
    expect(find.text('무'), findsOneWidget);
    expect(find.text('경'), findsOneWidget);
    expect(find.text('갑'), findsOneWidget);
    expect(find.text('신'), findsNWidgets(2));
    expect(find.text('인'), findsOneWidget);
    expect(find.text('자'), findsOneWidget);
    expect(find.text('미'), findsOneWidget);

    // 천간/지지 · 오행 라벨 — "천간 · 금"은 월주 지지가 아니라 월주 천간(경)과
    // 시주 천간(신) 둘 다 금이라 2번 나타난다.
    expect(find.text('천간 · 토'), findsOneWidget); // 년주 무
    expect(find.text('지지 · 목'), findsOneWidget); // 년주 인
    expect(find.text('천간 · 금'), findsNWidgets(2)); // 월주 경, 시주 신
    expect(find.text('지지 · 금'), findsOneWidget); // 월주 신
    expect(find.text('천간 · 목'), findsOneWidget); // 일주 갑
    expect(find.text('지지 · 수'), findsOneWidget); // 일주 자
    expect(find.text('지지 · 토'), findsOneWidget); // 시주 미

    // _charCell은 글자색(ohaengTextColors)뿐 아니라 칸 배경색(ohaengSoftColors)도
    // 오행별로 물들이는데, 지금까지 한자·라벨 문자열만 확인했을 뿐 이 두 색 값 자체는
    // 검증한 적이 없었다 — result_screen/share_card의 기둥 칩과 같은 성격의 공백.
    Color textColorOf(String hanja) => tester.widget<Text>(find.text(hanja).first).style!.color!;
    Color bgColorOf(String hanja) => (tester
            .widget<Container>(find.ancestor(of: find.text(hanja).first, matching: find.byType(Container)).first)
            .decoration! as BoxDecoration)
        .color!;

    expect(textColorOf('무'), AppColors.ohaengTextColors['토']);
    expect(bgColorOf('무'), AppColors.ohaengSoftColors['토']);
    expect(textColorOf('경'), AppColors.ohaengTextColors['금']);
    expect(bgColorOf('경'), AppColors.ohaengSoftColors['금']);
    expect(textColorOf('갑'), AppColors.ohaengTextColors['목']);
    expect(bgColorOf('갑'), AppColors.ohaengSoftColors['목']);
    expect(textColorOf('인'), AppColors.ohaengTextColors['목']);
    expect(bgColorOf('인'), AppColors.ohaengSoftColors['목']);
    expect(textColorOf('자'), AppColors.ohaengTextColors['수']);
    expect(bgColorOf('자'), AppColors.ohaengSoftColors['수']);
    expect(textColorOf('미'), AppColors.ohaengTextColors['토']);
    expect(bgColorOf('미'), AppColors.ohaengSoftColors['토']);
    // '신'은 시주 천간(辛)·월주 지지(申) 둘 다 금이라 두 인스턴스 모두 같은 색이어야 한다.
    for (final w in tester.widgetList<Text>(find.text('신'))) {
      expect(w.style!.color, AppColors.ohaengTextColors['금']);
    }
  });

  testWidgets('명식 breakdown 행이 스크린 리더에 "기둥 · 천간/지지 · 오행"이 하나로 병합된 문장으로 들린다',
      (tester) async {
    // _pillarRow가 년주 라벨 + 천간 칸(글자+오행) + 지지 칸(글자+오행)을 시각적으로는
    // 나란히 보여주지만, Semantics로 묶지 않으면 스크린 리더가 4개 텍스트 노드를
    // 따로따로 읽어 어느 기둥의 어느 글자인지 맥락이 끊긴다 — 지금까지 이 표의 실제
    // 계산값(한자·오행 라벨)은 검증했지만 스크린 리더 접근성은 검증한 적이 없었다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    // 년주 무인(戊寅) — 천간 무(토), 지지 인(목)
    expect(
      tester.getSemantics(find.text('무')),
      matchesSemantics(label: '년주. 천간 무, 오행 토. 지지 인, 오행 목.'),
    );

    semantics.dispose();
  });

  testWidgets('시간을 모르면 시주 breakdown 행도 하나의 안내 문장으로 병합된다', (tester) async {
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('시주')),
      matchesSemantics(label: '시주. 태어난 시간을 몰라 계산하지 않았어요.'),
    );

    semantics.dispose();
  });

  testWidgets('오행 5종 의미 카드도 스크린 리더에 "오행 · 제목. 설명"으로 병합된 시맨틱스를 제공한다',
      (tester) async {
    // _OhaengMeaningCard가 배지 한자·"오행 · 의미" 제목·설명을 시각적으로는 한 카드
    // 안에 나란히 보여주지만, _pillarRow와 달리 지금까지 Semantics로 묶여 있지 않아
    // 스크린 리더가 세 노드로 따로 읽었다(2026-07-07 발견) — 카드 5개가 나란히 있어도
    // 서로 안 섞이고 "목 · 성장 · 시작 · 추진력. 새싹이 자라나는 이미지"처럼 하나로
    // 들리는지 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.textContaining('목 · 성장')),
      matchesSemantics(label: '목 · 성장 · 시작 · 추진력. 새싹이 자라나는 이미지'),
    );

    semantics.dispose();
  });

  testWidgets('오행 5종 의미 카드의 원형 배지 배경·글자색이 각 오행 색과 정확히 일치한다', (tester) async {
    // _OhaengMeaningCard의 40x40 원형 배지(木/火/土/金/水 한자)는 태어난 정보와 무관하게
    // 늘 5개 전부 렌더링되는데도, 지금까지 색상 값(ohaengSoftColors 배경·ohaengTextColors
    // 글자색) 자체는 한 번도 검증한 적이 없었다 — _pillarRow/_charCell(위 테스트) 색상
    // 검증과 같은 성격의 공백.
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    const hanjaToOhaeng = {'木': '목', '火': '화', '土': '토', '金': '금', '水': '수'};
    for (final entry in hanjaToOhaeng.entries) {
      final badgeContainer = tester.widget<Container>(
        find.ancestor(of: find.text(entry.key), matching: find.byType(Container)).first,
      );
      final decoration = badgeContainer.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.ohaengSoftColors[entry.value], reason: '${entry.key} 배지 배경');
      expect(
        tester.widget<Text>(find.text(entry.key)).style!.color,
        AppColors.ohaengTextColors[entry.value],
        reason: '${entry.key} 배지 글자색',
      );
    }
  });

  testWidgets('오행 5종 의미 카드의 제목·설명 문구가 5개 전부 실제 값과 정확히 일치한다', (tester) async {
    // 기존 테스트는 '목'만 "목 · 성장 · 시작 · 추진력. 새싹이 자라나는 이미지"처럼
    // 제목+설명 전체를 시맨틱 라벨로 확인했고, 나머지 4개(화·토·금·수)는
    // "화 · 열정"처럼 제목의 접두어만 textContaining으로 확인했을 뿐 설명 문구
    // ("따뜻한 온기의 이미지" 등)는 단 한 번도 값으로 확인한 적이 없었다 —
    // ohaeng_readings.dart/deep_dive_readings.dart의 문구에서 반복 발견된 것과
    // 같은 종류의 공백(2026-07-08/2026-07-11). find.text()로 문구가 "어딘가에"
    // 존재하는지만 보면 두 오행의 설명이 통째로 맞바뀌어도 둘 다 화면 어딘가에는
    // 여전히 존재해 못 잡는다(실제로 이렇게 짰다가 화-토 설명을 맞바꿔도 통과하는
    // 것을 발견해 재작성함) — `_OhaengMeaningCard`가 이미 "$ohaeng · 제목. 설명"을
    // 하나의 병합 시맨틱 라벨로 제공하므로, 그 병합 라벨 전체가 정확히 일치하는지
    // 확인해야 특정 오행의 설명이 맞는 카드에 붙어 있는지 확실히 검증된다.
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    const expected = {
      '목 · 성장 · 시작 · 추진력': '목 · 성장 · 시작 · 추진력. 새싹이 자라나는 이미지',
      '화 · 열정 · 표현력 · 인기운': '화 · 열정 · 표현력 · 인기운. 따뜻한 온기의 이미지',
      '토 · 안정 · 신뢰 · 중재': '토 · 안정 · 신뢰 · 중재. 땅에 발붙인 이미지',
      '금 · 원칙 · 결단력 · 완성도': '금 · 원칙 · 결단력 · 완성도. 정제된 금속의 이미지',
      '수 · 지혜 · 유연함 · 통찰': '수 · 지혜 · 유연함 · 통찰. 흐르는 물의 이미지',
    };
    for (final entry in expected.entries) {
      expect(
        tester.getSemantics(find.textContaining(entry.key)),
        matchesSemantics(label: entry.value),
        reason: entry.key,
      );
    }
  });

  testWidgets('오행별 오늘의 풀이 모음 섹션이 5개 오행 전부의 실제 풀이 내용·제목 색을 그대로 보여준다',
      (tester) async {
    // "오행별 오늘의 풀이 모음"(_AllReadingsSection, ohaeng_readings.dart의
    // categoryReadingsByOhaeng 5개 전부를 for 루프로 순회) 섹션은 지금까지 어떤
    // 테스트에서도 존재 자체가 언급된 적이 없었다 — 5개 오행 × 4개 영역(연애·재물·
    // 건강·성격) = 20줄의 실제 풀이 문구, 제목 5개의 글자색 전부 미검증 상태였다.
    // categoryReadingsFor()는 알 수 없는 키가 들어오면 조용히 '토' 풀이로 폴백하므로,
    // 루프 변수가 잘못 전달돼도 화면이 깨지지 않고 그냥 틀린(엉뚱한 오행) 내용을
    // 보여줄 수 있어 실제 문구까지 값으로 대조해야 이런 회귀를 잡을 수 있다.
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(find.text('오행별 오늘의 풀이 모음'), findsOneWidget);

    // 제목 문구·색상 — 5개 오행 전부.
    const ohaengHanja = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    for (final ohaeng in ohaengHanja.keys) {
      final hanja = ohaengHanja[ohaeng]!;
      final titleFinder = find.text('$ohaeng($hanja) 기운이 강할 때');
      expect(titleFinder, findsOneWidget, reason: '$ohaeng 제목 문구');
      expect(
        tester.widget<Text>(titleFinder).style!.color,
        AppColors.ohaengTextColors[ohaeng],
        reason: '$ohaeng 제목 글자색',
      );
    }

    // 실제 풀이 내용 — ohaeng_readings.dart의 categoryReadingsByOhaeng와 값이 정확히
    // 일치하는지, 5개 오행이 서로 뒤섞이거나 '토'로 폴백되지 않았는지 확인한다.
    expect(find.text('💘 연애운: 적극적으로 다가가면 좋은 인연이 생기는 시기예요'), findsOneWidget); // 목
    expect(find.text('🎭 성격: 밝고 열정적인 분위기 메이커 타입이에요'), findsOneWidget); // 화
    expect(find.text('💰 재물운: 무리한 투자보다 꾸준한 저축이 유리해요'), findsOneWidget); // 토
    expect(find.text('🌱 건강운: 호흡기·피부 컨디션을 신경 쓰면 좋아요'), findsOneWidget); // 금
    expect(find.text('💘 연애운: 은근한 매력으로 다가오는 인연이 있어요'), findsOneWidget); // 수
  });

  testWidgets('오행별 오늘의 풀이 모음 항목의 스크린 리더 라벨에는 장식용 이모지가 빠져 있다', (tester) async {
    // reading.$1(💘/💰/🌱/🎭)은 시각적 장식용 이모지일 뿐인데, 이 섹션만 같은 파일의
    // _pillarRow/_OhaengMeaningCard(위 테스트들 참고)와 달리 Semantics 병합 처리가
    // 안 돼 있어 스크린 리더가 이모지를 유니코드 이름으로 그대로 읽어 혼란을 줬다
    // (2026-07-14 발견). 시각적 텍스트(이모지 포함)는 위 테스트에서 이미 확인했으므로,
    // 여기서는 라벨에서 이모지가 빠졌는지만 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('💘 연애운: 적극적으로 다가가면 좋은 인연이 생기는 시기예요')),
      matchesSemantics(label: '연애운: 적극적으로 다가가면 좋은 인연이 생기는 시기예요'),
    );
    expect(
      tester.getSemantics(find.text('💰 재물운: 무리한 투자보다 꾸준한 저축이 유리해요')),
      matchesSemantics(label: '재물운: 무리한 투자보다 꾸준한 저축이 유리해요'),
    );

    semantics.dispose();
  });

  testWidgets('이름과 메타 라인이 결과 화면과 같은 형식으로 헤더에 표시된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(
            date: DateTime(1998, 8, 15),
            hour: 14,
            isLunar: false,
            name: '민지',
            gender: Gender.female,
            birthPlace: '서울특별시',
          ),
        ),
      ),
    );

    expect(find.text('민지의 상세 리포트'), findsOneWidget);
    expect(find.text('1998.08.15 · 오후 2시生 · 양력 · 여성 · 서울특별시'), findsOneWidget);
  });

  testWidgets('음력으로 입력했으면 메타 라인에 "음력"으로 표시된다', (tester) async {
    // 2026-07-08 발견한 커버리지 공백: `buildMetaLine`의 isLunar 분기 자체는
    // meta_line_test.dart에서 이미 검증돼 있고 result_screen_test.dart/
    // share_text_test.dart도 isLunar: true로 실제 렌더링/조립을 확인해왔는데,
    // 이 화면(report_screen.dart도 같은 `buildMetaLine(info)`를 그대로 호출)만
    // isLunar: true로 렌더링해본 적이 한 번도 없었던 비대칭을 발견 — share_card.dart의
    // hour: null 공백(바로 위 "사주 결과 화면" 행 참고)과 같은 종류의 발견.
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: true),
        ),
      ),
    );

    expect(find.text('1998.08.15 · 오후 2시生 · 음력'), findsOneWidget);
  });

  testWidgets('이름이 없거나 공백뿐이면 헤더에 "회원님"으로 표시된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );
    expect(find.text('회원님의 상세 리포트'), findsOneWidget);

    // 이름이 아예 없는(null) 경우는 위에서 확인했는데, 공백뿐인 이름(trim하면 빈
    // 문자열)도 같은 폴백을 타는지는 지금까지 값으로 확인한 적이 없었다 —
    // result_screen.dart/deep_dive_result_screen.dart의 같은 로직 검증과 대칭을 맞춘다.
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '   '),
        ),
      ),
    );
    expect(find.text('회원님의 상세 리포트'), findsOneWidget);
    expect(find.text('   의 상세 리포트'), findsNothing);
  });

  testWidgets('시간을 모르면 시주 자리에 안내 문구가 표시된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false),
        ),
      ),
    );

    expect(find.textContaining('태어난 시간을 몰라'), findsOneWidget);
  });

  testWidgets('결과 화면의 "상세 리포트 보기" 버튼을 누르면 상세 리포트 화면으로 이동한다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.report) {
            return MaterialPageRoute(
              builder: (_) => ReportScreen(birthInfo: settings.arguments as BirthInfo?),
            );
          }
          return MaterialPageRoute(
            builder: (_) => const ResultScreen(),
            settings: RouteSettings(
              arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
            ),
          );
        },
        initialRoute: '/',
      ),
    );

    await tester.tap(find.text('상세 리포트 보기 (무료)'));
    await tester.pumpAndSettle();

    expect(find.text('상세 리포트'), findsOneWidget);
  });

  testWidgets('"MBTI·관심사로 심층 분석 받기"를 누르면 심층 분석 입력 화면으로 이동한다', (tester) async {
    // 2026-07-07: 결과 화면에 있던 이 진입점을 상세 리포트 화면으로 옮겼다(사용자 요청).
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.deepDiveInput) {
            return MaterialPageRoute(
              builder: (_) => DeepDiveInputScreen(
                birthInfo: settings.arguments as BirthInfo?,
              ),
            );
          }
          return MaterialPageRoute(
            builder: (_) => ReportScreen(
              birthInfo: settings.arguments as BirthInfo?,
            ),
            settings: RouteSettings(
              arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
            ),
          );
        },
        initialRoute: '/',
      ),
    );

    await tester.tap(find.text('MBTI·관심사로 심층 분석 받기 →'));
    await tester.pumpAndSettle();

    expect(find.byType(DeepDiveInputScreen), findsOneWidget);
  });

  testWidgets('시스템 글자 크기를 크게(2배) 키워도 RenderFlex overflow가 나지 않는다', (tester) async {
    // result_screen.dart(카테고리 그리드)·share_card.dart에서 실제로 겪었던 고정
    // 높이+큰 글자 조합 RenderFlex overflow가 이 화면에도 있는지 지금까지 확인한
    // 적이 없었다 — _OhaengMeaningCard의 40x40 고정 크기 원형 배지처럼 눈여겨볼
    // 만한 고정 크기 요소가 있어 검증해봤으나, Container는 Row/Column과 달리
    // 내용이 넘쳐도 조용히 잘릴 뿐 RenderFlex 예외를 던지지 않아 실제로는
    // 재현되지 않음을 확인(코드 변경 없이 회귀 방지용으로 고정).
    await useTallViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('생성자 birthInfo도 라우트 arguments도 없으면 하드코딩된 기본값(1998-08-15 14시)으로 표시된다',
      (tester) async {
    // build()의 `birthInfo ?? (라우트 arguments) ?? BirthInfo(1998-08-15, 14시)` 3단
    // 폴백 중 마지막 분기(result_screen.dart와 완전히 같은 패턴)는 지금까지 이 화면
    // 테스트에서도 한 번도 타본 적이 없었다 — result_screen_test.dart에 같은 회귀
    // 테스트를 추가하며 발견한 비대칭. 실제 앱 흐름에서는 도달하지 않아야 정상이지만
    // (결과 화면의 "상세 리포트 보기"가 항상 birthInfo를 넘김), 라우트 배선이 실수로
    // 깨지면 크래시 대신 조용히 엉뚱한 기본값을 보여줄 수 있어 값으로 고정해둔다.
    await useTallViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: ReportScreen()));

    expect(find.text('회원님의 상세 리포트'), findsOneWidget);
    expect(find.text('무'), findsOneWidget);
    expect(find.text('경'), findsOneWidget);
    expect(find.text('갑'), findsOneWidget);
  });
}
