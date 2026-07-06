import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/core/storage/deep_dive_info_store.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_input_screen.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_result_screen.dart';

void main() {
  // 화면이 열릴 때 DeepDiveInfoStore.load()가 SharedPreferences를 읽고, 제출 시에는
  // DeepDiveInfoStore.save()가 쓴다 — 목(mock) 초기값을 설정해둔다.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // 관심사 칩(Wrap) + MBTI 체크박스까지 켜면 기본 뷰포트보다 콘텐츠가 길어질 수 있어
  // 다른 입력 화면 테스트와 같은 방식으로 세로로 넉넉하게 키운다.
  Future<void> useTallViewport(WidgetTester tester) async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });
  }

  final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

  testWidgets('관심사 4개가 기본으로 전부 선택된 상태로 보인다', (tester) async {
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    for (final label in const ['💘 연애운', '💰 재물운', '💼 직장운', '🌱 건강운']) {
      expect(
        tester.getSemantics(find.text(label)).flagsCollection.isSelected,
        Tristate.isTrue,
      );
    }

    semantics.dispose();
  });

  testWidgets('관심사 칩을 탭하면 선택이 해제된다', (tester) async {
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    await tester.tap(find.text('💼 직장운'));
    await tester.pump();

    expect(
      tester.getSemantics(find.text('💼 직장운')).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    // 다른 칩은 그대로 선택된 채 남아있어야 한다(전체가 같이 꺼지는 회귀 방지).
    expect(
      tester.getSemantics(find.text('💘 연애운')).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    semantics.dispose();
  });

  testWidgets('"MBTI를 알고 있어요"를 체크하기 전에는 축 토글이 보이지 않는다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    expect(find.text('E · 외향'), findsNothing);
  });

  testWidgets('"MBTI를 알고 있어요"를 체크하면 네 축 토글이 나타난다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    expect(find.text('E · 외향'), findsOneWidget);
    expect(find.text('S · 감각'), findsOneWidget);
    expect(find.text('T · 사고'), findsOneWidget);
    expect(find.text('J · 판단'), findsOneWidget);
  });

  testWidgets('MBTI를 체크하지 않고 제출하면 심층 분석 화면에 MBTI 코멘트가 없다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    expect(find.byType(DeepDiveResultScreen), findsOneWidget);
    expect(find.textContaining('INTJ'), findsNothing);
  });

  testWidgets('"심층 분석 보기"를 빠르게 두 번 연속 눌러도 결과 화면으로 한 번만 이동한다', (tester) async {
    // birth_input_screen.dart의 "사주 보러가기"와 같은 이유로 겪은 실제 버그 —
    // _saveAndContinue()가 DeepDiveInfoStore.save()를 await하는 동안 버튼을 한 번
    // 더 누르면 DeepDiveResultScreen이 Navigator.push()로 중복 push된다. tester.tap()은
    // 내부적으로 프레임을 진행시키는 타이밍이 화면마다 달라 이 화면에서는 재현이
    // 불안정했다(await 횟수가 birth_input보다 적어 두 번째 tap() 전에 첫 호출이 이미
    // 끝나버리는 경우가 있었음) — onPressed 콜백을 직접 두 번 동기적으로 호출해
    // "완전히 같은 시점에 두 번 눌림"을 결정적으로 재현한다.
    final pushedRoutes = <Route<void>>[];
    final observer = _CountingNavigatorObserver(pushedRoutes);
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: DeepDiveInputScreen(birthInfo: birthInfo),
      ),
    );

    final button =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '심층 분석 보기'));
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();

    expect(pushedRoutes.length, 1);
    expect(find.byType(DeepDiveResultScreen), findsOneWidget);
  });

  testWidgets('한 번 제출한 뒤 뒤로가기로 돌아와도 "심층 분석 보기"를 다시 누를 수 있다', (tester) async {
    // birth_input_screen.dart에서 실제로 겪은 것과 같은 버그: 위 더블탭 가드를
    // 추가하면서 _isSubmitting을 true로 바꾸는 지점만 있고 다시 false로 되돌리는
    // 지점이 없었다. push()는 화면을 교체하는 게 아니라 그 위에 쌓기만 해서
    // DeepDiveInputScreen이 스택에 그대로 남는데, 사용자가 결과 화면에서 뒤로가기로
    // 돌아오면 그 인스턴스의 _isSubmitting이 true로 남아 "심층 분석 보기"가 계속
    // 먹통이 되는 실제 버그였다 — push()가 반환하는 Future가 완료되는 시점(뒤로가기로
    // 돌아왔을 때)에 맞춰 플래그를 되돌리도록 고쳤다.
    final pushedRoutes = <Route<void>>[];
    final observer = _CountingNavigatorObserver(pushedRoutes);
    await useTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: DeepDiveInputScreen(birthInfo: birthInfo),
      ),
    );

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();
    expect(pushedRoutes.length, 1);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('심층 분석 보기'), findsOneWidget);

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    expect(pushedRoutes.length, 2);
  });

  testWidgets('MBTI 축 하나만 바꿔 제출하면 나머지 기본값(E·S·T·J)이 그대로 반영된 코드가 보인다',
      (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    // 기본값(E·S·T·J)을 그대로 두고 S만 N으로 바꾸면 "ENTJ"가 된다.
    await tester.tap(find.text('N · 직관'));
    await tester.pump();

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ENTJ'), findsOneWidget);
  });

  testWidgets('MBTI 네 축을 전부 바꿔 제출하면 그 조합 그대로 코드가 반영된다', (tester) async {
    // 위 테스트는 S/N 축 하나만 바꿨을 뿐이라, 나머지 세 축(E/I·T/F·J/P)의
    // onChanged 콜백 자체는 지금까지 한 번도 실제로 발동된 적이 없었다 — 커버리지로
    // 확인해 발견한 빈틈이다. 네 축을 전부 반대로 뒤집어 "INFP"가 되는지 확인한다.
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    await tester.tap(find.text('I · 내향'));
    await tester.pump();
    await tester.tap(find.text('N · 직관'));
    await tester.pump();
    await tester.tap(find.text('F · 감정'));
    await tester.pump();
    await tester.tap(find.text('P · 인식'));
    await tester.pump();

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('INFP'), findsOneWidget);
  });

  testWidgets('"MBTI를 알고 있어요"를 껐다가 다시 켜도 그 사이에 고른 축 선택은 그대로 유지된다',
      (tester) async {
    // birth_input의 "태어난 시간을 몰라요" 체크박스도 껐다 켜도 이미 고른 시간을 잃지
    // 않는 것과 같은 관례다 — 체크박스는 축 토글을 보여줄지만 결정할 뿐, 축 값
    // 자체(_ei/_sn/_tf/_jp)는 별개 상태라 체크 해제만으로 초기화되지 않는다. 지금까지는
    // 이 "껐다 켜도 안 잃어버림" 자체를 직접 확인한 테스트가 없었다 — 나중에 누군가
    // onChanged에 "체크 해제 시 기본값으로 리셋" 로직을 실수로 추가하면 이 테스트가
    // 잡아준다.
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    await tester.tap(find.text('I · 내향'));
    await tester.pump();
    await tester.tap(find.text('N · 직관'));
    await tester.pump();

    // 체크 해제 → 축 토글이 안 보임
    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();
    expect(find.text('I · 내향'), findsNothing);

    // 다시 체크 → 방금 고른 I·N이 그대로 남아있어야 한다(기본값 E·S로 되돌아가지 않음).
    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    // 기본값(E·S·T·J)에서 I·N만 바꿨으니 "INTJ"가 나와야 한다 — 체크 해제로
    // 기본값(E·S)으로 되돌아갔다면 "ESTJ"가 나왔을 것이다.
    expect(find.textContaining('INTJ'), findsOneWidget);
  });

  testWidgets('관심사 칩을 껐다가 다시 탭하면 재선택된다', (tester) async {
    // _toggleInterest의 "다시 선택" 분기(제거된 상태에서 다시 추가하는 쪽)는
    // 지금까지 테스트에서 한 번도 거치지 않았다 — 껐다 켜는 흐름을 그대로 재현한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    await tester.tap(find.text('💼 직장운'));
    await tester.pump();
    expect(
      tester.getSemantics(find.text('💼 직장운')).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    await tester.tap(find.text('💼 직장운'));
    await tester.pump();
    expect(
      tester.getSemantics(find.text('💼 직장운')).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    semantics.dispose();
  });

  testWidgets('이전에 저장된 관심사·MBTI가 있으면 화면을 열 때 그대로 반영된다', (tester) async {
    // DeepDiveInfoStore에 미리 저장해두고 화면을 열어, initState의 비동기 로드가
    // 기본값(전체 선택·MBTI 모름)이 아니라 저장된 값으로 화면을 채우는지 확인한다.
    const saved = DeepDiveInfo(
      mbti: Mbti(ei: MbtiEi.i, sn: MbtiSn.n, tf: MbtiTf.t, jp: MbtiJp.j),
      interests: {Interest.health},
    );
    await DeepDiveInfoStore.save(saved);

    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));
    await tester.pumpAndSettle();

    // 저장된 관심사(건강운)만 선택돼 있고, 나머지는 꺼져 있어야 한다.
    expect(
      tester.getSemantics(find.text('🌱 건강운')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(find.text('💘 연애운')).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    // MBTI를 알고 있었으므로 체크박스가 켜져 있고, 저장된 축(I·N·T·J)이 그대로 보인다.
    expect(find.text('I · 내향'), findsOneWidget);
    expect(find.text('N · 직관'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('제출하면 선택한 관심사·MBTI가 저장되어 다음에 열 때 이어서 보인다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    // 기본 전체 선택에서 재물운만 남기고 나머지 셋을 끈다.
    await tester.tap(find.text('💘 연애운'));
    await tester.pump();
    await tester.tap(find.text('💼 직장운'));
    await tester.pump();
    await tester.tap(find.text('🌱 건강운'));
    await tester.pump();

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    final saved = await DeepDiveInfoStore.load();
    expect(saved, isNotNull);
    expect(saved!.interests, {Interest.wealth});
    expect(saved.mbti, isNull);
  });

  testWidgets('관심사 4개를 전부 해제하고 제출해도(빈 Set) 다음에 열 때 다시 전체 선택으로 되돌아가지 않는다',
      (tester) async {
    // deep_dive_info_store_test.dart에는 "관심사를 전부 꺼서 저장해도(빈 Set) — 첫
    // 방문(null)과 구분된다"는 저장소 단위 테스트가 이미 있지만, 그건 DeepDiveInfoStore를
    // 직접 호출한 것이었을 뿐 실제 화면에서 사용자가 칩 4개를 전부 탭으로 꺼서 제출하는
    // 경로로는 한 번도 검증된 적이 없었다 — 위 테스트("제출하면 선택한 관심사·MBTI가
    // 저장되어...")도 재물운 하나는 남겨둔 채라 이 "전부 해제" 경계값을 화면 단으로는
    // 못 잡는다. 화면을 새로 열었을 때 _loadSaved()가 "저장된 적 없음(null)"과
    // "빈 Set으로 저장됨"을 헷갈려 기본값(전체 선택)으로 되돌리는 회귀가 없는지 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    for (final label in ['💘 연애운', '💰 재물운', '💼 직장운', '🌱 건강운']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    // 결과 화면에는 관심사를 하나도 안 고른 경우의 안내 문구가 보여야 한다.
    expect(find.text('관심사를 고르지 않아 보여드릴 심층 풀이가 없어요. 뒤로 가서 관심 있는 영역을 골라보세요.'),
        findsOneWidget);

    final saved = await DeepDiveInfoStore.load();
    expect(saved, isNotNull);
    expect(saved!.interests, isEmpty);

    // 화면을 다시 열었을 때도 저장된 빈 Set이 그대로 반영돼야 한다(기본값인
    // 전체 선택으로 되돌아가면 안 된다). 지금 위젯 트리는 여전히 DeepDiveResultScreen이
    // Navigator 스택 맨 위에 push된 채라, 같은 MaterialApp(home:)을 그대로 다시
    // pumpWidget해도 Navigator가 그 push 상태를 유지해버려 DeepDiveInputScreen이 다시
    // 안 보인다 — 빈 위젯을 한 번 끼워 넣어 완전히 새로 마운트되게 한다.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));
    await tester.pumpAndSettle();

    for (final label in ['💘 연애운', '💰 재물운', '💼 직장운', '🌱 건강운']) {
      expect(
        tester.getSemantics(find.text(label)).flagsCollection.isSelected,
        Tristate.isFalse,
      );
    }

    semantics.dispose();
  });

  testWidgets('스크린 리더의 탭 액션(SemanticsAction.tap)을 직접 실행해도 관심사 칩 선택이 토글된다',
      (tester) async {
    // 위의 "관심사 칩을 탭하면 선택이 해제된다" 테스트를 포함해 이 화면의 모든 테스트는
    // tester.tap()(실제 히트테스트, InkWell을 직접 타서 통과)만 썼을 뿐, 스크린 리더가
    // 실제로 보내는 SemanticsAction.tap이 _toggleInterest까지 이어지는지는 검증한 적이
    // 없었다. _InterestChip은 PastelToggleRow와 똑같이 Semantics(excludeSemantics: true)로
    // InkWell의 자동 탭 액션을 대체하는 구조라(pastel_toggle_row_test.dart에서 실제로
    // 재현해 확인한 것과 같은 종류의 회귀), onTap:을 다시 선언하는 걸 빠뜨려도
    // tester.tap()은 여전히 통과해버려 이 회귀를 못 잡는다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    final node = tester.getSemantics(find.text('💼 직장운'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(
      tester.getSemantics(find.text('💼 직장운')).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    semantics.dispose();
  });

  testWidgets('시스템 글자 크기를 크게(2배) 키워도 RenderFlex overflow가 나지 않는다', (tester) async {
    // result_screen.dart(카테고리 그리드)·share_card.dart에서 실제로 겪었던 고정
    // 높이+큰 글자 조합 RenderFlex overflow가 이 화면에도 있는지 지금까지 확인한
    // 적이 없었다 — 관심사 칩은 Wrap(내용에 맞춰 줄바꿈), MBTI 토글은 PastelToggleRow
    // (고정 높이 없음)라 실제로는 재현되지 않음을 확인(코드 변경 없이 회귀 방지용으로 고정).
    await useTallViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

/// push된 라우트를 그대로 기록하는 관찰자 — `Navigator.push()`가 몇 번 호출됐는지
/// (이름 없는 `MaterialPageRoute`라 `onGenerateRoute` 카운팅 방식을 못 쓰는 화면에서)
/// 정확히 세기 위함.
class _CountingNavigatorObserver extends NavigatorObserver {
  _CountingNavigatorObserver(this.pushedRoutes);

  final List<Route<void>> pushedRoutes;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      pushedRoutes.add(route as Route<void>);
    }
  }
}
