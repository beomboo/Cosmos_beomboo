import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/shared/widgets/page_heading.dart';

void main() {
  // 2026-07-17 오버나이트 코드 정리: report_screen.dart(제목에 이모지 없음)와
  // deep_dive_result_screen.dart(제목에 "✨" 이모지 + semanticsLabel 오버라이드)가
  // 각각 하드코딩하던 페이지 제목 Semantics(header:true) + 스타일 조합을
  // PageHeading으로 통합했다. 두 화면 통합 테스트(report_screen_test.dart/
  // deep_dive_result_screen_test.dart)는 화면 맥락에서 이미 이 조합을 검증하지만,
  // 위젯 자체를 직접 겨냥한 단위 테스트가 없어 semanticsLabel의 두 분기(null/제공)를
  // 여기서 고정한다.

  testWidgets('title 문구가 화면에 그대로 보인다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PageHeading(title: '회원님의 상세 리포트')),
      ),
    );

    expect(find.text('회원님의 상세 리포트'), findsOneWidget);
  });

  testWidgets('스타일이 fontWeight w800/색상 ink/폰트 크기 20으로 고정된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PageHeading(title: '회원님의 상세 리포트')),
      ),
    );

    final text = tester.widget<Text>(find.text('회원님의 상세 리포트'));
    expect(text.style?.fontWeight, FontWeight.w800);
    expect(text.style?.color, AppColors.ink);
    expect(text.style?.fontSize, 20);
  });

  testWidgets('semanticsLabel을 생략하면 title 문자열이 그대로 자동 라벨이 되고 헤딩으로 노출된다', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PageHeading(title: '회원님의 상세 리포트')),
      ),
    );

    expect(
      tester.getSemantics(find.text('회원님의 상세 리포트')),
      matchesSemantics(label: '회원님의 상세 리포트', isHeader: true),
    );

    semantics.dispose();
  });

  testWidgets('semanticsLabel을 제공하면 title 대신 그 라벨로 읽히고(이모지 등 장식 제외) 헤딩은 유지된다', (tester) async {
    // deep_dive_result_screen.dart 케이스 — 화면에는 "회원님의 심층 분석 ✨"가 보이지만
    // 스크린 리더는 이모지 없는 "회원님의 심층 분석"만 읽어야 한다.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PageHeading(
            title: '회원님의 심층 분석 ✨',
            semanticsLabel: '회원님의 심층 분석',
          ),
        ),
      ),
    );

    expect(find.text('회원님의 심층 분석 ✨'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('회원님의 심층 분석 ✨')),
      matchesSemantics(label: '회원님의 심층 분석', isHeader: true),
    );

    semantics.dispose();
  });
}
