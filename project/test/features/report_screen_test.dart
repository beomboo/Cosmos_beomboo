import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
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

  testWidgets('이름이 없으면 헤더에 "회원님"으로 표시된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(find.text('회원님의 상세 리포트'), findsOneWidget);
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
}
