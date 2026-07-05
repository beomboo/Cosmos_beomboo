import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
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
}
