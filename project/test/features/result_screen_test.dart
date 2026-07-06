import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_input_screen.dart';
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

  testWidgets('"공유하기" 버튼이 목업대로 accent→metal 그라데이션 배경을 쓴다', (WidgetTester tester) async {
    // 2026-07-06에 이 버튼을 단색 accent에서 accent→metal 그라데이션으로 고쳤는데,
    // 그 뒤로도 실제 그라데이션 색상 값을 확인하는 테스트는 없었다 — 버튼 문구·onPressed
    // 동작은 안 바뀌므로 그런 테스트들은 그라데이션이 실수로 다시 단색으로 되돌아가도
    // 못 잡는다. 버튼이 긴 리스트 아래쪽에 있어(기본 뷰포트로는 지연 빌드돼 못 찾음)
    // 뷰포트를 세로로 키운다.
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
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

    final shareButtonContainer = tester.widget<Container>(
      find.ancestor(
        of: find.widgetWithText(ElevatedButton, '📸 공유하기'),
        matching: find.byType(Container),
      ).first,
    );
    final gradient = (shareButtonContainer.decoration! as BoxDecoration).gradient! as LinearGradient;
    expect(gradient.colors, [AppColors.accent, AppColors.metal]);
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
      findInBody('금(金) 기운이 강한 타입이에요 ✨\n원칙적이고 결단력 있어요'),
      findsOneWidget,
    );
    expect(findInBody('눈이 높은 편이라 확실한 상대를 알아보는 시기예요'), findsOneWidget); // 금 연애운
    expect(findInBody('계획적으로 관리하면 돈이 잘 모이는 편이에요'), findsOneWidget); // 금 재물운
    expect(findInBody('호흡기·피부 컨디션을 신경 쓰면 좋아요'), findsOneWidget); // 금 건강운
    expect(findInBody('원칙적이고 맺고 끊음이 확실한 타입이에요'), findsOneWidget); // 금 성격

    // 2026-07-06에 콜아웃 박스가 우세 오행 색(ohaengSoftColors[dominant])으로 물들도록
    // 고쳤는데, 그 뒤로도 실제 배경색 값 자체를 확인한 테스트는 없었다 — 텍스트 내용만
    // 맞고 색이 우연히 다시 accentSoft로 되돌아가도(줄 커버리지만으로는) 못 잡는다.
    final calloutContainer = tester.widget<Container>(
      find.ancestor(
        of: findInBody('금(金) 기운이 강한 타입이에요 ✨\n원칙적이고 결단력 있어요'),
        matching: find.byType(Container),
      ).first,
    );
    final calloutDecoration = calloutContainer.decoration! as BoxDecoration;
    expect(calloutDecoration.color, AppColors.ohaengSoftColors['금']);
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
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
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
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
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

  testWidgets('"MBTI·관심사로 심층 분석 받기"를 누르면 심층 분석 입력 화면으로 이동한다',
      (WidgetTester tester) async {
    // 새로 추가한 버튼이 "상세 리포트 보기" 버튼보다도 더 아래에 있어 기본
    // 테스트 뷰포트(800x600)에서는 지연 빌드되어 탭할 수 없다 — 세로로 키운다.
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });

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
            builder: (_) => const ResultScreen(),
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

  testWidgets('시스템 글자 크기를 크게(2배) 키워도 카테고리 카드에서 RenderFlex overflow가 나지 않는다',
      (WidgetTester tester) async {
    // "오늘 궁금한 것부터" 2x2 카드가 원래 GridView.count(childAspectRatio: 1.3)로
    // 셀 높이가 고정돼 있었는데, 시스템 글자 크기를 키우면(접근성 큰 텍스트 — 일부
    // 기기는 기본 제공 "큼" 설정만으로도 1.3배) 카드 안 텍스트가 그 고정 높이를
    // 넘겨 RenderFlex overflow가 실제로 재현되는 것을 확인했다 — 지금까지는 어떤
    // 테스트도 기본 배율(1.0) 외의 글자 크기로 이 화면을 렌더링해본 적이 없어서
    // 이 회귀를 못 잡고 있었다. Row-of-Expanded(_PillarCard와 같은 패턴)로 고친
    // 뒤 2배 배율에서도 예외 없이 렌더링되는지 확인한다.
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });

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
}
