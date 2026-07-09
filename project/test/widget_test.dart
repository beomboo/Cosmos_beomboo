import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_readings.dart';
import 'package:cosmos_saju/main.dart';

void main() {
  // birth_input 제출 시 BirthInfoStore.save()가 SharedPreferences를 쓴다.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('저장된 정보가 없으면 온보딩 화면이 타이틀과 시작 버튼을 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(const CosmosSajuApp());

    expect(find.text('사주랑'), findsOneWidget);
    expect(find.text('시작하기 →'), findsOneWidget);
  });

  test('저장된 정보를 읽다가 실패해도(플랫폼 채널 오류 등) null로 간주해 앱이 계속 실행된다', () async {
    // main()은 runApp()으로 실제 엔진 바인딩에 붙어서 flutter test로 직접 실행할 수
    // 없다 — `flutter test --coverage`로 main.dart를 확인해보니 이 try/catch 폴백
    // 로직 자체가 지금까지 값으로 검증된 적이 없었다(라인 커버리지가 비어 있었음).
    // BirthInfoStore.load()가 실제로 던지는 상황(플랫폼 채널 오류)을 재현하기 위해
    // SharedPreferences.getInstance() 내부가 쓰는 getAllWithParameters()가 실패하는
    // 가짜 저장소로 바꿔치기한다.
    final originalStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = _FailingGetAllStore();
    addTearDown(() => SharedPreferencesStorePlatform.instance = originalStore);

    expect(await loadInitialBirthInfo(), isNull);
  });

  testWidgets('기기가 다크 모드여도 항상 파스텔 큐트 라이트 테마를 그대로 쓴다 (2026-07-08, 사용자 요청)',
      (WidgetTester tester) async {
    // MaterialApp 자체가 만드는 MediaQuery를 builder에서 덮어써야 시스템 다크 모드가
    // 실제로 앱 트리에 전달된다(온보딩 등 개별 화면 테스트에서도 쓰는 패턴).
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(platformBrightness: Brightness.dark),
          child: child!,
        ),
        home: const CosmosSajuApp(),
      ),
    );

    // CosmosSajuApp 내부에서 실제로 쓰이는 Theme(darkTheme/themeMode를 명시해도,
    // 라우트가 이 MaterialApp을 한 겹 더 씌운 구조라 안쪽 CosmosSajuApp의 Theme이
    // 실제로 적용되는지 확인해야 한다).
    final context = tester.element(find.text('사주랑'));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.bg);
    expect(Theme.of(context).colorScheme.brightness, Brightness.light);

    // AppBar 없는 화면(온보딩)에서도 상태 표시줄 아이콘이 시스템 다크 모드를 따라가지
    // 않고 항상 밝은 배경 기준(어두운 아이콘)으로 강제되는지 확인한다.
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    expect(region.value.statusBarIconBrightness, Brightness.dark);
    expect(region.value.statusBarBrightness, Brightness.light);
    expect(region.value.systemNavigationBarColor, AppColors.bg);
    expect(region.value.systemNavigationBarIconBrightness, Brightness.dark);
  });

  testWidgets('저장된 BirthInfo가 있으면 온보딩을 건너뛰고 결과 화면을 바로 보여준다',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CosmosSajuApp(
        initialBirthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
      ),
    );

    expect(find.text('시작하기 →'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('resultScrollView')),
        matching: find.text('회원님의 사주팔자 ✨'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('온보딩의 "시작하기"를 누르면 생년월일시 입력 화면으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const CosmosSajuApp());

    await tester.tap(find.text('시작하기 →'));
    await tester.pumpAndSettle();

    expect(find.text('생년월일시를 알려주세요'), findsOneWidget);
  });

  testWidgets(
    '온보딩부터 상세 리포트까지 실제 라우트로 이어서 진행하면 입력한 생년월일시가 그대로 반영된다',
    (WidgetTester tester) async {
      // 지금까지의 테스트는 각 화면을 개별적으로(또는 스텁 라우트로) 검증했을 뿐, 실제
      // CosmosSajuApp의 라우트 배선을 그대로 타고 온보딩 → 입력 → 계산 중 → 결과 → 상세
      // 리포트까지 한 번에 이어서 통과한 적은 없었다 — 이 테스트가 그 빈틈을 메운다.
      //
      // birth_input의 ListView가 기본 테스트 뷰포트(800x600)보다 길어 제출 버튼이
      // 화면 밖에서 지연 빌드된다 — 뷰포트를 세로로 넉넉하게 키운다.
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      await tester.pumpWidget(const CosmosSajuApp());

      await tester.tap(find.text('시작하기 →'));
      await tester.pumpAndSettle();
      expect(find.text('생년월일시를 알려주세요'), findsOneWidget);

      // 기본값(1998.08.15 · 오후 2시 30분 · 양력) 그대로 제출한다.
      await tester.tap(find.text('사주 보러가기 🔮'));
      // CalculatingScreen은 궤도 애니메이션이 AnimationController.repeat()로 무한
      // 반복되므로, 이 지점부터는 pumpAndSettle()을 쓰면 절대 끝나지 않는다 —
      // pump()로 프레임을 직접 진행시킨다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('사주팔자를 계산하고 있어요...'), findsOneWidget);

      // 3초 뒤 result로 자동 이동한다.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      // 입력했던 생년월일시가 실제 계산·표시까지 그대로 이어졌는지 확인한다.
      Finder findInResult(String text) => find.descendant(
            of: find.byKey(const Key('resultScrollView')),
            matching: find.text(text),
          );
      expect(findInResult('회원님의 사주팔자 ✨'), findsOneWidget);
      // birth_input의 성별 기본값은 여성이고 timePicker 기본값은 오후 2시 30분이라
      // (둘 다 실제로 제출되는 값), 메타 라인에도 분까지 그대로 반영된다.
      expect(findInResult('1998.08.15 · 오후 2시 30분生 · 양력 · 여성'), findsOneWidget);
      expect(findInResult('년주'), findsOneWidget);
      expect(findInResult('시주'), findsOneWidget);

      // 마지막 구간(결과 → 상세 리포트)까지 실제 라우트로 이어간다. ReportScreen에는
      // 반복 애니메이션이 없어 여기서부터는 다시 pumpAndSettle()을 써도 안전하다.
      await tester.tap(find.text('상세 리포트 보기 (무료)'));
      await tester.pumpAndSettle();

      expect(find.text('회원님의 상세 리포트'), findsOneWidget);
      expect(find.text('1998.08.15 · 오후 2시 30분生 · 양력 · 여성'), findsOneWidget);
      expect(find.text('명식 한 글자씩 뜯어보기'), findsOneWidget);
    },
  );

  testWidgets(
    '저장된 값에서 "다시 입력하기"로 실제 재입력 화면까지 갔다가 새로 제출하면 이전 값이 아닌 새 값이 결과에 반영된다',
    (WidgetTester tester) async {
      // result_screen_test.dart는 스텁 라우트로 "다시 입력하기"만 검증했고, widget_test.dart의
      // 여정 테스트는 처음 한 번 입력하는 경로만 다뤘다 — 저장된 값이 있는 상태에서 시작해
      // 실제로 재입력하고 그 결과 "이전 값이 새 값으로 완전히 교체"되는지는 아직 아무 테스트도
      // 실제 라우트로 확인한 적이 없었다.
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      await tester.pumpWidget(
        CosmosSajuApp(
          initialBirthInfo: BirthInfo(date: DateTime(1990, 3, 1), hour: 9, isLunar: false),
        ),
      );

      Finder findInResult(String text) => find.descendant(
            of: find.byKey(const Key('resultScrollView')),
            matching: find.text(text),
          );
      // 이 BirthInfo는 테스트에서 직접 만든 값이라 gender를 지정하지 않았으므로
      // (birth_input 실제 제출과 달리) 메타 라인에 "· 여성" 접미사가 붙지 않는다.
      expect(findInResult('1990.03.01 · 오전 9시生 · 양력'), findsOneWidget);

      await tester.tap(find.byTooltip('다시 입력하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다시 입력하기').last);
      await tester.pumpAndSettle();

      expect(find.text('생년월일시를 알려주세요'), findsOneWidget);

      // birth_input의 기본값(1998.08.15)을 그대로 제출한다 — 이전 값(1990.03.01)과는 다르다.
      await tester.tap(find.text('사주 보러가기 🔮'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      expect(findInResult('1998.08.15 · 오후 2시 30분生 · 양력 · 여성'), findsOneWidget);
      expect(findInResult('1990.03.01 · 오전 9시生 · 양력'), findsNothing);
    },
  );

  testWidgets(
    '결과 화면 → 상세 리포트 → 심층 분석 결과까지 실제 라우트로 이어서 진행하면 우세 오행 기준 풀이가 반영된다',
    (WidgetTester tester) async {
      // 지금까지 심층 분석 관련 테스트는 전부 개별 화면을 스텁 라우트나 직접 생성으로만
      // 검증했을 뿐, CosmosSajuApp의 실제 AppRoutes.routes 배선을 그대로 타고
      // 결과 화면 → 상세 리포트 → 심층 분석 입력 → 심층 분석 결과까지 이어서 통과한 적은
      // 없었다 — 각 구간이 개별로는 통과해도 실제 라우트 배선이나 인자 전달이 깨지는
      // 회귀는 이런 전체 여정 테스트가 아니면 못 잡는다(온보딩→상세 리포트 여정 테스트와
      // 같은 이유). **2026-07-07 변경(사용자 요청)**: "MBTI·관심사로 심층 분석 받기"
      // 진입점이 결과 화면에서 상세 리포트 화면으로 옮겨져, 이 여정도 상세 리포트를
      // 한 번 거치도록 갱신됨.
      // 상세 리포트 화면의 콘텐츠(오행 5종 설명+전체 풀이 등)가 아주 길어
      // report_screen_test.dart와 같은 400x3000 뷰포트가 필요하다(2000으로는
      // 맨 아래 "MBTI·관심사로 심층 분석 받기" 버튼이 지연 빌드돼 탭할 수 없었음).
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      // 1998-08-15/14시는 이미 four_pillars_test.dart에서 우세 오행이 '금'으로
      // 검증돼 있는 조합이라(목:2,화:0,토:2,금:3,수:1) 그대로 재사용한다.
      await tester.pumpWidget(
        CosmosSajuApp(
          initialBirthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      );

      await tester.tap(find.text('상세 리포트 보기 (무료)'));
      await tester.pumpAndSettle();
      expect(find.text('회원님의 상세 리포트'), findsOneWidget);

      await tester.tap(find.text('MBTI·관심사로 심층 분석 받기 →'));
      await tester.pumpAndSettle();
      expect(find.text('조금 더 깊이 볼까요?'), findsOneWidget);

      // 관심사는 기본 전체 선택, MBTI는 birth_input에서 입력하지 않았으니(테스트가
      // BirthInfoStore를 직접 넘겨 시작해 birth_input 자체를 거치지 않음) 그대로 제출한다.
      await tester.tap(find.text('심층 분석 보기'));
      await tester.pumpAndSettle();

      expect(find.text('회원님의 심층 분석 ✨'), findsOneWidget);
      // 관심사 4개(연애·재물·직장·건강) 전부 우세 오행(금) 기준 풀이가 실제로 보인다.
      for (final interest in Interest.values) {
        expect(find.text(interest.categoryTitle), findsOneWidget);
        expect(find.text(readingFor(interest, '금')), findsOneWidget);
      }
      // MBTI를 입력하지 않았으니 코멘트 영역은 없다.
      for (final comment in mbtiComments.values) {
        expect(find.textContaining(comment), findsNothing);
      }
    },
  );

  testWidgets(
    '온보딩 → 생년월일시 입력(MBTI 포함) → 결과 → 상세 리포트 → 심층 분석까지 이어지면 '
    'birth_input에서 고른 MBTI가 심층 분석 결과에 그대로 반영된다',
    (WidgetTester tester) async {
      // 2026-07-07(사용자 요청): MBTI 질문이 심층 분석 입력 화면에서 birth_input_screen.dart로
      // 옮겨졌다 — 온보딩부터 시작해 birth_input에서 MBTI를 실제로 체크·선택하고, 그 값이
      // 결과→상세 리포트→심층 분석 입력(화면엔 안 보임)을 거쳐 심층 분석 결과 화면의 MBTI
      // 코멘트로 정확히 이어지는지 실제 라우트로 검증한다.
      // 상세 리포트 화면 콘텐츠가 길어 위 테스트와 같은 이유로 3000까지 키운다.
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(400, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      await tester.pumpWidget(const CosmosSajuApp());

      await tester.tap(find.text('시작하기 →'));
      await tester.pumpAndSettle();
      expect(find.text('생년월일시를 알려주세요'), findsOneWidget);

      await tester.tap(find.text('MBTI를 알고 있어요'));
      await tester.pump();
      await tester.tap(find.text('I · 내향'));
      await tester.pump();
      await tester.tap(find.text('N · 직관'));
      await tester.pump();

      await tester.tap(find.text('사주 보러가기 🔮'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('상세 리포트 보기 (무료)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MBTI·관심사로 심층 분석 받기 →'));
      await tester.pumpAndSettle();
      // 심층 분석 입력 화면 자체에는 MBTI 관련 UI가 전혀 없다(이미 birth_input에서 받음).
      expect(find.textContaining('MBTI'), findsNothing);

      await tester.tap(find.text('심층 분석 보기'));
      await tester.pumpAndSettle();

      // 기본값(E·S·T·J)에서 I·N만 바꿨으니 "INTJ"로 반영돼야 한다.
      expect(find.textContaining('INTJ'), findsOneWidget);
    },
  );
}

/// `SharedPreferences.getInstance()`가 내부적으로 쓰는 `getAll()`이 항상 실패하는
/// 가짜 저장소 — 플랫폼 채널 오류를 흉내 낸다.
class _FailingGetAllStore extends InMemorySharedPreferencesStore {
  _FailingGetAllStore() : super.empty();

  @override
  Future<Map<String, Object>> getAll() =>
      throw Exception('시뮬레이션된 플랫폼 채널 오류');
}
