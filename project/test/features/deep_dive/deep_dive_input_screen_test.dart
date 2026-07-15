import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
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

  testWidgets(
      '안내 문구+관심사 칩 Wrap 그룹에 스크린 리더용 그룹 라벨이 정확히 1개 붙고, 개별 칩의 selected 상태는 그대로 유지된다',
      (tester) async {
    // pastel_toggle_row_test.dart의 "semanticLabel을 주면 그룹 라벨이 추가되고..." 테스트와
    // 같은 이유(2026-07-13 발견) — deep_dive_input_screen.dart만 유일하게 안내 Text+칩
    // Wrap 구간에 그룹 시맨틱스가 빠져 있었다. explore-by-touch로 안내 문구를 건너뛰고
    // 칩으로 곧장 이동해도 이 영역이 무엇을 고르는 그룹인지 알 수 있는지 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    expect(
      find.bySemanticsLabel('관심 있는 영역 선택'),
      findsOneWidget,
      reason: '안내 Text+칩 Wrap 그룹 전체를 아우르는 그룹 라벨 노드가 하나 있어야 한다',
    );

    // 그룹 라벨이 추가됐다고 해서 각 칩의 개별 selected/button 상태가 사라지면 안 된다
    // (excludeSemantics를 주면 안 되는 이유) — 기존 칩 상태 검증과 동일하게 확인한다.
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

  testWidgets('MBTI를 미리 저장해두지 않고 제출하면 심층 분석 화면에 MBTI 코멘트가 없다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    expect(find.byType(DeepDiveResultScreen), findsOneWidget);
    expect(find.textContaining('INTJ'), findsNothing);
  });

  testWidgets('생성자 birthInfo도 라우트 arguments도 없으면 하드코딩된 기본값(1998-08-15 14시)이 다음 화면까지 그대로 전달된다',
      (tester) async {
    // build()의 `widget.birthInfo ?? (라우트 arguments) ?? BirthInfo(1998-08-15, 14시)`
    // 3단 폴백은 result_screen.dart/report_screen.dart와 완전히 같은 패턴인데, 이
    // 화면은 그 birthInfo를 자기 화면에 직접 표시하지 않고 "심층 분석 보기"를 누를 때
    // 다음 화면(DeepDiveResultScreen)에 그대로 넘기기만 한다 — 그래서 지금까지 이
    // 화면의 어떤 테스트도 이 폴백이 실제로 타는지 확인한 적이 없었다(전부 birthInfo를
    // 생성자로 명시적으로 넘겼음). 값 자체가 하드코딩된 기본값(1998-08-15 14시)인 채로
    // 다음 화면까지 이어지는지 메타 라인으로 확인한다.
    await useTallViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: DeepDiveInputScreen()));

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    // 2026-07-15: 심층 분석 결과 화면에 공유 카드(DeepDiveShareCard)가 추가되면서,
    // 화면 밖(사용자 눈에는 안 보임)에 같은 텍스트를 가진 캡처용 위젯이 함께 존재할 수
    // 있다 — 실제로 보이는 스크롤 뷰(deepDiveResultScrollView) 안으로 범위를 좁힌다.
    expect(
      find.descendant(
        of: find.byKey(const Key('deepDiveResultScrollView')),
        matching: find.text('1998.08.15 · 오후 2시生 · 양력'),
      ),
      findsOneWidget,
    );
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

  testWidgets(
      '2026-07-07: birth_input_screen.dart에서 미리 저장해둔 MBTI가 있으면 이 화면엔 '
      '따로 보이지 않지만 제출 시 그대로 이어져 심층 분석 화면에 반영된다', (tester) async {
    // MBTI 질문 자체가 birth_input_screen.dart로 옮겨가면서, 이 화면은 더 이상 MBTI
    // 축을 직접 입력받지 않는다(체크박스·토글 자체가 없음) — birth_input에서 저장해둔
    // 값을 조용히 이어받아(`_mbti`) 제출 시 그대로 실어 보내는지 확인한다.
    await DeepDiveInfoStore.save(
      const DeepDiveInfo(
        mbti: Mbti(ei: MbtiEi.i, sn: MbtiSn.n, tf: MbtiTf.t, jp: MbtiJp.j),
        interests: {...Interest.values},
      ),
    );

    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));
    await tester.pumpAndSettle();

    // 이 화면 자체에는 MBTI 관련 텍스트가 전혀 없다(체크박스·토글 모두 삭제됨).
    expect(find.textContaining('MBTI'), findsNothing);

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    // 위 테스트와 같은 이유(2026-07-15, 공유 카드 추가로 화면 밖에 같은 텍스트가 하나
    // 더 생김)로 실제로 보이는 스크롤 뷰 안으로 범위를 좁힌다.
    expect(
      find.descendant(
        of: find.byKey(const Key('deepDiveResultScrollView')),
        matching: find.textContaining('INTJ'),
      ),
      findsOneWidget,
    );

    final saved = await DeepDiveInfoStore.load();
    expect(saved!.mbti?.code, 'INTJ');
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

  testWidgets('이전에 저장된 관심사가 있으면 화면을 열 때 그대로 반영된다', (tester) async {
    // DeepDiveInfoStore에 미리 저장해두고 화면을 열어, initState의 비동기 로드가
    // 기본값(전체 선택)이 아니라 저장된 값으로 화면을 채우는지 확인한다.
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

    semantics.dispose();
  });

  testWidgets('저장된 관심사를 불러오는 도중 사용자가 칩을 탭하면, 로드가 늦게 끝나도 탭이 이긴다',
      (tester) async {
    // 2026-07-11 버그 수정: initState()가 _loadSaved()를 기다리지 않고(fire-and-forget)
    // 바로 반환한다 — 이미 저장된 관심사가 있는 상태(재방문)에서 그 비동기 로드가
    // 아직 끝나기 전에 사용자가 칩을 탭하면, _toggleInterest()의 setState 직후에
    // 뒤늦게 도착하는 _loadSaved()의 setState(저장된 값으로 무조건 덮어씀)가 방금
    // 누른 탭을 조용히 되돌리는 실제 버그였다.
    //
    // (구현 노트) 처음엔 pumpWidget() 직후 pump() 없이 바로 탭해서 재현하려 했으나,
    // 목(mock) SharedPreferences는 실제 지연이 없어 pumpWidget() 자체가 이미 마이크로
    // 태스크 큐를 다 비워버려 로드가 탭보다 먼저 끝나버리는 것을 실측으로 확인했다 —
    // 경쟁을 결정적으로 재현하려면 로드 완료 시점을 직접 통제해야 해서, getAll()이
    // 수동으로 완료시키는 Completer를 기다리는 가짜 스토어로 바꿔치기한다.
    final loadGate = Completer<void>();
    final store = _GatedLoadStore(
      {'flutter.deep_dive_info.interests': ['health']},
      loadGate.future,
    );
    final originalStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = store;
    addTearDown(() => SharedPreferencesStorePlatform.instance = originalStore);

    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));
    await tester.pump();
    // 로드가 아직 loadGate에 막혀 안 끝난 시점 — 기본값(전체 선택)이 보여야 한다.
    expect(
      tester.getSemantics(find.text('💰 재물운')).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.text('💰 재물운'));
    await tester.pump();

    // 이제서야 로드가 끝나도록 놓아준다.
    loadGate.complete();
    await tester.pumpAndSettle();

    // 사용자가 직접 끈 재물운은 꺼진 채로 유지돼야 하고(로드된 값에 덮이면 안 됨),
    // 다른 관심사(연애운)도 로드된 값({건강운}만)에 덮이지 않고 탭 시점의 기본값
    // (전체 선택)이 그대로 유지돼야 한다.
    expect(
      tester.getSemantics(find.text('💰 재물운')).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    expect(
      tester.getSemantics(find.text('💘 연애운')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets(
      '2026-07-15 버그 수정: 로드가 끝나기 전에 곧바로 "심층 분석 보기"를 눌러도 birth_input에서 '
      '저장해둔 MBTI가 유실되지 않는다', (tester) async {
    // initState()가 _loadSaved()를 기다리지 않고(fire-and-forget) 반환하는데,
    // birth_input_screen.dart에서 이미 저장해둔 MBTI가 SharedPreferences에서 아직
    // 읽히기 전에 사용자가 곧바로 제출하면 _mbti의 초기값(null)이 그대로 저장돼
    // MBTI가 조용히 사라지는 실제 버그였다 — 이 화면엔 MBTI를 보여주는 UI가 없어
    // 사용자가 눈치챌 방법도 없었다. 위 "저장된 관심사를 불러오는 도중..." 테스트와
    // 같은 방식으로 _GatedLoadStore로 로드 완료 시점을 직접 통제해, 로드가 끝나기
    // 전에 제출을 시도해도 그 제출이 로드 완료를 기다렸다가 반영하는지 확인한다.
    final loadGate = Completer<void>();
    final store = _GatedLoadStore(
      {
        'flutter.deep_dive_info.mbti_ei': 'i',
        'flutter.deep_dive_info.mbti_sn': 'n',
        'flutter.deep_dive_info.mbti_tf': 't',
        'flutter.deep_dive_info.mbti_jp': 'j',
        'flutter.deep_dive_info.interests': ['health', 'love', 'wealth', 'work'],
      },
      loadGate.future,
    );
    final originalStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = store;
    addTearDown(() => SharedPreferencesStorePlatform.instance = originalStore);

    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));
    await tester.pump();

    // 로드가 아직 loadGate에 막혀 안 끝난 시점에 곧바로 제출 버튼을 누른다.
    final button =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '심층 분석 보기'));
    button.onPressed!();
    await tester.pump();

    // 이제서야 로드가 끝나도록 놓아준다 — 수정 전이었다면 이 시점 이전에 이미
    // null MBTI로 저장이 끝나버렸을 것이다.
    loadGate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(DeepDiveResultScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('deepDiveResultScrollView')),
        matching: find.textContaining('INTJ'),
      ),
      findsOneWidget,
    );

    final saved = await DeepDiveInfoStore.load();
    expect(saved!.mbti?.code, 'INTJ');
  });

  testWidgets(
      '저장된 값을 불러오다가 플랫폼 채널 오류가 나도 크래시하지 않고 기본값으로 제출까지 정상 진행된다',
      (tester) async {
    // widget_test.dart의 `_FailingGetAllStore`와 같은 이유로, `_loadSaved()`의
    // `try { await DeepDiveInfoStore.load(); } catch (_) { saved = null; }`가 실제로
    // 예외를 삼키는지(즉 `_loadFuture`가 에러로 완료되지 않는지) 지금까지 이 화면에서는
    // 한 번도 확인한 적이 없었다 — `_saveAndContinue()`의 `await _loadFuture;`를 감싼
    // try/catch가 "혹시 모를 예외"라고 방어하는 지점이 실제로 발동하는 경로인지도 함께
    // 확인한다.
    final originalStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = _FailingGetAllStore();
    addTearDown(() => SharedPreferencesStorePlatform.instance = originalStore);

    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));
    await tester.pumpAndSettle();

    // 로드 실패는 조용히 흡수돼 기본값(전체 선택)이 그대로 유지돼야 한다.
    for (final label in const ['💘 연애운', '💰 재물운', '💼 직장운', '🌱 건강운']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('심층 분석 보기'));
    await tester.pumpAndSettle();

    // 로드 실패든 아니든 제출 자체는 정상적으로 결과 화면까지 이어져야 하고, 테스트
    // 프레임워크가 잡아내는 미처리 예외가 없어야 한다(로드 실패가 조용히 전파돼
    // 화면이 멈추거나 크래시하면 안 된다).
    expect(tester.takeException(), isNull);
    expect(find.byType(DeepDiveResultScreen), findsOneWidget);
  });

  testWidgets(
      '"심층 분석 보기"를 누른 뒤 로드가 끝나기 전에 화면이 사라지면(빠른 뒤로가기), 이미 저장돼 있던 값을 훼손하지 않고 조용히 멈춘다',
      (tester) async {
    // 위 "MBTI가 유실되지 않는다" 테스트와 같은 뿌리의 버그지만 트리거 경로가 다르다:
    // `_saveAndContinue()`가 `await _loadFuture`로 로드 완료를 기다리는 도중 사용자가
    // 화면을 완전히 벗어나면(위젯 자체가 dispose됨), `_loadSaved()`는 dispose 이후
    // setState를 건너뛰어(72행 `!mounted` 체크) `_mbti`가 여전히 초기값(null)인 채로
    // 멈춘다 — 이때 `_saveAndContinue()`의 106행 `if (!mounted) return;` 가드가 없으면
    // 그 null `_mbti`로 `DeepDiveInfoStore.save()`가 그대로 호출돼, birth_input에서
    // 이미 저장해둔 MBTI·관심사가 화면이 사라진 뒤에도 조용히 null/기본값으로
    // 덮어써지는 또 다른 경로의 데이터 유실이 생길 수 있다.
    final loadGate = Completer<void>();
    final store = _GatedLoadStore(
      {
        'flutter.deep_dive_info.mbti_ei': 'i',
        'flutter.deep_dive_info.mbti_sn': 'n',
        'flutter.deep_dive_info.mbti_tf': 't',
        'flutter.deep_dive_info.mbti_jp': 'j',
        'flutter.deep_dive_info.interests': ['health'],
      },
      loadGate.future,
    );
    final originalStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = store;
    addTearDown(() => SharedPreferencesStorePlatform.instance = originalStore);

    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));
    await tester.pump();

    // 로드가 아직 안 끝난 시점에 제출을 누른다 — _saveAndContinue가 _loadFuture를
    // 기다리기 시작한다.
    final button =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '심층 분석 보기'));
    button.onPressed!();
    await tester.pump();

    // 저장/화면 전환이 끝나기 전에 사용자가 화면을 완전히 벗어난다(빠른 뒤로가기를
    // 흉내 — 위젯 트리를 완전히 교체해 State.dispose()를 강제로 유발한다. 위 "관심사
    // 4개를 전부 해제하고..." 테스트와 같은 방식).
    await tester.pumpWidget(const SizedBox.shrink());

    // 그제서야 로드가 끝나도록 놓아준다 — 이 시점에 화면은 이미 dispose된 뒤다.
    loadGate.complete();
    await tester.pumpAndSettle();

    // 크래시(예: dispose된 context로 Navigator.push 시도) 없이 조용히 멈춰야 한다.
    expect(tester.takeException(), isNull);

    // 화면이 사라지기 전에 이미 저장돼 있던 값(INTJ·건강운만)이 그대로 남아있어야
    // 한다 — null MBTI·기본값(전체 선택) 관심사로 덮어써지면 안 된다.
    final saved = await DeepDiveInfoStore.load();
    expect(saved!.mbti?.code, 'INTJ');
    expect(saved.interests, {Interest.health});
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

  testWidgets('선택된/선택 안 된 관심사 칩의 배경·테두리·글자색이 목업(.pill.is-active)값과 정확히 일치한다',
      (tester) async {
    // _InterestChip은 PastelToggleRow(pastel_toggle_row_test.dart 참고)와 완전히 같은
    // accentSoft+accentText 선택 색 조합을 독립적으로 재구현하는데, 이 화면 쪽은 지금까지
    // 선택 여부(isSelected 시맨틱스)만 확인했을 뿐 실제 색 값 자체는 검증한 적이 없었다 —
    // 두 위젯이 각자 같은 로직을 중복 구현하면서 한쪽만 값이 잠겨있던 비대칭 공백.
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    // 기본으로 전체 선택 상태이니 하나만 꺼서 선택/비선택 대조군을 만든다.
    await tester.tap(find.text('💼 직장운'));
    await tester.pump();

    BoxDecoration decorationOf(String text) =>
        tester.widget<Container>(find.ancestor(of: find.text(text), matching: find.byType(Container)).first).decoration!
            as BoxDecoration;

    final selectedDecoration = decorationOf('💘 연애운');
    expect(selectedDecoration.color, AppColors.accentSoft);
    expect(selectedDecoration.border!.top.color, AppColors.accent);
    expect(selectedDecoration.border!.top.width, 1.5);
    expect(tester.widget<Text>(find.text('💘 연애운')).style!.color, AppColors.accentText);

    final unselectedDecoration = decorationOf('💼 직장운');
    expect(unselectedDecoration.color, AppColors.bgCard);
    expect(unselectedDecoration.border!.top.color, AppColors.border);
    expect(tester.widget<Text>(find.text('💼 직장운')).style!.color, AppColors.ink);
  });

  testWidgets('관심사 칩의 스크린 리더 라벨에는 이모지가 포함되지 않는다', (tester) async {
    // result_screen.dart의 _CategoryCard/_OhaengMeaningCard는 장식용 이모지까지
    // 스크린 리더가 유니코드 이름으로 읽어 혼란스러운 문제를 2026-07-07에 이미
    // 고쳤는데(라벨에서 이모지 제외, 시각적 텍스트에는 그대로 유지), 정작 관심사
    // 목록의 "원본"인 이 칩만 라벨에 이모지("💘 연애운")를 그대로 포함하고 있어서
    // 지금까지 검증한 적이 없었다.
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    final node = tester.getSemantics(find.text('💘 연애운'));
    expect(node.label, '연애운');
  });

  testWidgets('리스트 컨테이너 여백이 목업 공통 토큰(20/14/20/18, birth_input_screen.dart와 동일)과 정확히 일치한다',
      (tester) async {
    // 2026-07-14 커밋(975c132)에서 이 화면의 옛 여백(24/8/24/24)을 목업
    // `.screen-body`(padding:14px 20px 18px) 값으로 맞췄다 — 수치 자체를 잠그는
    // 테스트가 없어 다음에 실수로 옛 값으로 되돌아가도 못 잡는 공백이 있었다.
    await useTallViewport(tester);
    await tester.pumpWidget(MaterialApp(home: DeepDiveInputScreen(birthInfo: birthInfo)));

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.padding, const EdgeInsets.fromLTRB(20, 14, 20, 18));
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

/// `getAll()`이 즉시 끝나지 않고 [gate]가 완료될 때까지 기다리는 가짜 저장소 —
/// initState()의 비동기 로드 완료 시점을 테스트에서 직접 통제하기 위함(실제
/// SharedPreferences는 지연이 없어 로드가 사용자 탭보다 항상 먼저 끝나버려
/// 경쟁 상태를 재현할 수 없었다).
class _GatedLoadStore extends InMemorySharedPreferencesStore {
  _GatedLoadStore(super.data, this.gate) : super.withData();

  final Future<void> gate;

  @override
  Future<Map<String, Object>> getAll() async {
    await gate;
    return super.getAll();
  }
}

/// widget_test.dart의 `_FailingGetAllStore`와 같은 이유(플랫폼 채널 오류 흉내) — 이 화면
/// 전용으로 하나 더 두는 이유는, birth_input과 달리 이 화면은 로드 실패 시 저장을
/// 막지 않고 기본값으로 계속 진행해야 하는 화면별 요구사항을 별도로 확인하기 위함이다.
class _FailingGetAllStore extends InMemorySharedPreferencesStore {
  _FailingGetAllStore() : super.empty();

  @override
  Future<Map<String, Object>> getAll() =>
      throw Exception('시뮬레이션된 플랫폼 채널 오류');
}
