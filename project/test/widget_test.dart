import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/main.dart';

void main() {
  // birth_input 제출 시 BirthInfoStore.save()가 SharedPreferences를 쓴다.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('저장된 정보가 없으면 온보딩 화면이 타이틀과 시작 버튼을 보여준다', (WidgetTester tester) async {
    await tester.pumpWidget(const CosmosSajuApp());

    expect(find.text('사주랑'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });

  testWidgets('저장된 BirthInfo가 있으면 온보딩을 건너뛰고 결과 화면을 바로 보여준다',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      CosmosSajuApp(
        initialBirthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
      ),
    );

    expect(find.text('시작하기'), findsNothing);
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

    await tester.tap(find.text('시작하기'));
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

      await tester.tap(find.text('시작하기'));
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
}
