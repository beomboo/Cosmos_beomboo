import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/core/saju/four_pillars.dart';
import 'package:cosmos_saju/features/result/share_card.dart';

void main() {
  testWidgets('ShareCard가 이름/기둥/오행 밸런스를 렌더링한다', (tester) async {
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            pillars: pillars,
            dominant: '목',
            calloutHanja: '木',
            calloutEmoji: '🌿',
            calloutText: '새로운 걸 벌이는 힘이 넘쳐요',
            ohaengCount: ohaengCount,
            total: total,
          ),
        ),
      ),
    );

    expect(find.text('민지의 사주팔자 ✨'), findsOneWidget);
    expect(find.text('오행 밸런스'), findsOneWidget);
    expect(find.text('#사주랑  #사주팔자  #오행'), findsOneWidget);
  });

  testWidgets('오행 밸런스 바의 한자 라벨·퍼센트가 실제 계산값과 정확히 일치한다', (tester) async {
    // 2026-07-08 발견한 커버리지 공백: result_screen_test.dart는 `_OhaengBarRow`의
    // 퍼센트 값을 이미 실제 계산값으로 검증해왔는데(1998-08-15/14시 조합의
    // {목:2,화:0,토:2,금:3,수:1}(총 8) → 25%/0%/25%/38%/13%), 자기만의 독립적인
    // 퍼센트 계산(`_balanceRow`의 `ohaengCount[ohaeng]! / total * 100`)과 한자 라벨
    // 매핑(`_ohaengHanja`)을 갖고 있는 `share_card.dart`는 지금까지 이 값 자체를
    // 확인한 적이 한 번도 없었다 — 제목("오행 밸런스")만 확인했을 뿐 실제 숫자·한자는
    // 전혀 검증되지 않고 있었다.
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            pillars: pillars,
            dominant: '금',
            calloutHanja: '金',
            calloutEmoji: '✨',
            calloutText: '원칙적이고 결단력 있어요',
            ohaengCount: ohaengCount,
            total: total,
          ),
        ),
      ),
    );

    expect(find.text('木'), findsOneWidget);
    expect(find.text('火'), findsOneWidget);
    expect(find.text('土'), findsOneWidget);
    // 콜아웃 문구("금(金) 기운이...")는 하나의 보간된 문자열 Text라 별도 "金" 노드가
    // 아니므로, 밸런스 바의 "金" 라벨 하나만 매칭된다.
    expect(find.text('金'), findsOneWidget);
    expect(find.text('水'), findsOneWidget);
    expect(find.text('25%'), findsNWidgets(2)); // 목, 토
    expect(find.text('0%'), findsOneWidget); // 화
    expect(find.text('38%'), findsOneWidget); // 금
    expect(find.text('13%'), findsOneWidget); // 수

    // 위 검증은 한자 5종·퍼센트 4종이 각각 "화면 어딘가에" 존재하는지만 볼 뿐, 특정
    // 한자가 그 오행의 실제 퍼센트와 같은 줄(Row)에 붙어 있는지는 확인하지 않는다 —
    // 예를 들어 `_ohaengHanja`에서 목·화의 한자가 서로 뒤바뀌어도(둘 다 여전히
    // 화면에 하나씩 존재하므로) 위 assertion들은 그대로 통과해버린다. 한자를 감싼
    // Row 안에서 퍼센트 텍스트를 찾아 같은 줄에 있는지까지 확인한다.
    String percentInRowOf(String hanja) {
      final row = find.ancestor(of: find.text(hanja), matching: find.byType(Row)).first;
      final percentFinder = find.descendant(of: row, matching: find.textContaining('%'));
      return tester.widget<Text>(percentFinder).data!;
    }

    expect(percentInRowOf('木'), '25%', reason: '목');
    expect(percentInRowOf('火'), '0%', reason: '화');
    expect(percentInRowOf('土'), '25%', reason: '토');
    expect(percentInRowOf('金'), '38%', reason: '금');
    expect(percentInRowOf('水'), '13%', reason: '수');
  });

  testWidgets('4기둥 칩의 한자가 실제 계산값과 정확히 일치한다', (tester) async {
    // 2026-07-08 발견한 또 다른 비대칭: result_screen_test.dart는 1998-08-15/14시의
    // 4주(년주 무인, 월주 경신, 일주 갑자, 시주 신미)를 실제 텍스트로 확인해왔는데,
    // 같은 `_pillarChip`으로 4기둥을 그대로 복제해 그리는 share_card.dart는
    // "이름/기둥/오행 밸런스를 렌더링한다" 테스트에서 제목류만 확인했을 뿐 실제
    // 기둥 한자 자체는 한 번도 값으로 확인한 적이 없었다.
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            pillars: pillars,
            dominant: '금',
            calloutHanja: '金',
            calloutEmoji: '✨',
            calloutText: '원칙적이고 결단력 있어요',
            ohaengCount: ohaengCount,
            total: total,
          ),
        ),
      ),
    );

    expect(find.text('무인'), findsOneWidget);
    expect(find.text('경신'), findsOneWidget);
    expect(find.text('갑자'), findsOneWidget);
    expect(find.text('신미'), findsOneWidget);

    // `_pillarChip`도 `_PillarCard`와 똑같은 분기(`ohaengTextColors[stemOhaeng(stemIndex)]`,
    // 천간의 오행 기준)를 독립적으로 갖고 있는데, 이 색상 값도 지금까지 확인한 적이
    // 없었다(result_screen.dart 쪽도 같은 사이클에 처음 검증됨).
    expect(tester.widget<Text>(find.text('무인')).style!.color, AppColors.ohaengTextColors['토']);
    expect(tester.widget<Text>(find.text('경신')).style!.color, AppColors.ohaengTextColors['금']);
    expect(tester.widget<Text>(find.text('갑자')).style!.color, AppColors.ohaengTextColors['목']);
    expect(tester.widget<Text>(find.text('신미')).style!.color, AppColors.ohaengTextColors['금']);
  });

  testWidgets('콜아웃 박스가 우세 오행 색으로 실제로 물든다(고정 accentSoft가 아니라)', (tester) async {
    // 2026-07-06에 result_screen.dart의 콜아웃 박스 배경색을 accentSoft 고정에서
    // ohaengSoftColors[dominant]로 고치면서 result_screen_test.dart엔 실제 색상 값을
    // 확인하는 테스트가 추가됐는데, 같은 분기 로직(`ohaengSoftColors[dominant] ?? accentSoft`,
    // 텍스트 색도 `ohaengTextColors[dominant] ?? ink`)을 그대로 복제해 그리는
    // share_card.dart는 지금까지 색상 값 자체를 확인한 적이 한 번도 없었다 — result_screen과
    // 같은 dominant('금')로 맞춰 직접 비교 가능하게 한다.
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 오후 2시生 · 양력',
            pillars: pillars,
            dominant: '금',
            calloutHanja: '金',
            calloutEmoji: '✨',
            calloutText: '원칙적이고 결단력 있어요',
            ohaengCount: ohaengCount,
            total: total,
          ),
        ),
      ),
    );

    final calloutContainer = tester.widget<Container>(
      find.ancestor(
        of: find.text('금(金) 기운이 강한 타입이에요 ✨\n원칙적이고 결단력 있어요'),
        matching: find.byType(Container),
      ).first,
    );
    final calloutDecoration = calloutContainer.decoration! as BoxDecoration;
    expect(calloutDecoration.color, AppColors.ohaengSoftColors['금']);

    final calloutText = tester.widget<Text>(
      find.text('금(金) 기운이 강한 타입이에요 ✨\n원칙적이고 결단력 있어요'),
    );
    expect(calloutText.style!.color, AppColors.ohaengTextColors['금']);
  });

  testWidgets('시주를 모르면(hour: null) 시주 칩이 "모름"으로 표시된다', (tester) async {
    // 2026-07-08 발견한 커버리지 공백: 목업(01-pastel-cute.html)의 "다음으로 다듬을
    // 지점" 1번 항목("시간 모름 체크 시 시주 카드가 어떻게 바뀌는지")은 result_screen.dart/
    // report_screen.dart에서는 이미 값으로 검증돼 있었는데, 같은 시주 표시 로직
    // (`pillars.hour?.label ?? '모름'`, `_pillarChip`의 `stemIndex == null` 분기로
    // inkSoft 색 적용)을 그대로 복제해 그리는 `share_card.dart`는 지금까지 hour: null로
    // 렌더링해본 적이 한 번도 없었다.
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: null);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCard(
            displayName: '민지',
            metaLine: '1998.08.15 · 시간 모름 · 양력',
            pillars: pillars,
            dominant: '목',
            calloutHanja: '木',
            calloutEmoji: '🌿',
            calloutText: '새로운 걸 벌이는 힘이 넘쳐요',
            ohaengCount: ohaengCount,
            total: total,
          ),
        ),
      ),
    );

    expect(find.text('모름'), findsOneWidget);
    expect(pillars.hour, isNull);
  });

  testWidgets('이름/출생지가 입력 제한(20자/30자)을 꽉 채워도 고정 높이 카드가 넘치지 않는다', (tester) async {
    // birth_input은 이름 20자, 출생지 30자까지 허용하는데, 이 카드는 폭 360x높이 640
    // 고정 레이아웃이라 실제로 최대 길이를 넣어보니 RenderFlex overflow가 났던 걸 확인한 적이
    // 있다 — 이름/메타 라인에 maxLines+ellipsis를 넣어 고쳤고, 이 테스트로 회귀를 막는다.
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);
    final longName = '가' * 20;
    final longPlace = '나' * 30;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareCard(
            displayName: longName,
            metaLine: '1998.08.15 · 오후 2시生 · 양력 · 여성 · $longPlace',
            pillars: pillars,
            dominant: '목',
            calloutHanja: '木',
            calloutEmoji: '🌿',
            calloutText: '새로운 걸 벌이는 힘이 넘쳐요',
            ohaengCount: ohaengCount,
            total: total,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('공유하는 사람의 시스템 글자 크기를 키워도(2배) 카드 배율은 1.0으로 고정돼 넘치지 않는다',
      (tester) async {
    // 이 카드는 인스타 스토리 규격(360x640) 고정 픽셀 이미지로 캡처되는 용도라
    // 공유자의 접근성 글자 크기 설정을 그대로 물려받으면 안 되는데, 실제로 앰비언트
    // MediaQuery의 textScaler를 2배로 주고 캡처해보니 RenderFlex overflow(551px)가
    // 재현되는 것을 확인했다 — 받는 사람은 어차피 보내는 사람의 접근성 설정과 무관하게
    // 이미지를 보므로, 카드 내부에서 배율을 1.0으로 고정(`MediaQuery.withClampedTextScaling`)
    // 해 항상 디자인대로 렌더링되도록 고쳤다. 이 테스트는 그 고정이 실제로 동작하는지,
    // 즉 앰비언트 배율이 커져도 오류 없이 렌더링되는지 확인한다.
    final pillars = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          home: Scaffold(
            body: ShareCard(
              displayName: '민지',
              metaLine: '1998.08.15 · 오후 2시生 · 양력',
              pillars: pillars,
              dominant: '목',
              calloutHanja: '木',
              calloutEmoji: '🌿',
              calloutText: '새로운 걸 벌이는 힘이 넘쳐요',
              ohaengCount: ohaengCount,
              total: total,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
