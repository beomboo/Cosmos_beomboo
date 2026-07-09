import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/app/theme/app_theme.dart';

void main() {
  // `textTheme`의 `titleLarge`/`bodyLarge`/`bodyMedium`는 코드 어디에도
  // `Theme.of(context).textTheme.xxx`로 명시 참조되지 않는다 — AppBar 제목·TextField
  // 입력 텍스트·AlertDialog 본문 등에 Flutter Material 3가 암묵적으로 적용해주는
  // 방식이라, 자칫 `cardTheme`(실제로 죽은 설정이라 2026-07-07에 제거됨)처럼 안 쓰이는
  // 설정으로 오인하고 지우기 쉽다 — 실제 렌더링 스타일을 값으로 고정해 이 암묵적
  // 의존을 명시적으로 보호한다.
  group('AppTheme.light의 textTheme이 암묵적으로 적용되는 위치', () {
    testWidgets('AppBar 제목이 titleLarge(진하게, ink색)로 렌더링된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(appBar: AppBar(title: const Text('제목'))),
        ),
      );

      final style =
          tester.renderObject<RenderParagraph>(find.text('제목')).text.style!;
      expect(style.fontWeight, FontWeight.w800);
      expect(style.color, AppColors.ink);
    });

    testWidgets('TextField에 입력한 텍스트가 bodyLarge(ink색)로 렌더링된다', (tester) async {
      final controller = TextEditingController(text: '입력');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.style.color, AppColors.ink);
    });

    testWidgets('AlertDialog 본문이 bodyMedium(inkSoft색)으로 렌더링된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(content: Text('본문')),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      final style =
          tester.renderObject<RenderParagraph>(find.text('본문')).text.style!;
      expect(style.color, AppColors.inkSoft);
    });
  });

  // 목업(`.btn-primary`)의 `box-shadow`(accent 색 은은한 글로우)를 Flutter의
  // elevation/shadowColor로 근사한 것(2026-07-07 대조 발견) — 색상 값을 값으로 고정.
  testWidgets('elevatedButtonTheme의 그림자 색이 accent(70% 불투명도)로 설정된다', (tester) async {
    // ElevatedButton을 스타일 지정 없이 그대로 써야 실제 앱 화면들(birth_input의
    // "사주 보러가기" 등)과 똑같이 `elevatedButtonTheme`이 적용된 스타일을 확인할 수
    // 있다 — 위젯 자신의 `style`은 null이라 `Theme.of(context).elevatedButtonTheme.style`을
    // 직접 읽는다.
    late ButtonStyle themeStyle;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            themeStyle = Theme.of(context).elevatedButtonTheme.style!;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    expect(themeStyle.shadowColor!.resolve({}), AppColors.accent.withValues(alpha: 0.7));
    expect(themeStyle.elevation!.resolve({}), 6);
    // 그림자 색·elevation 외에 같은 스타일 안에 있는 나머지 목업 대조 값(모서리 반경
    // 16px — 2026-07-06 대조 발견, 패딩 28/16 — 목업 `.btn-primary` 그대로)도 지금까지
    // 값으로 확인한 적이 없었다.
    final shape = themeStyle.shape!.resolve({})! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));
    expect(themeStyle.padding!.resolve({}), const EdgeInsets.symmetric(horizontal: 28, vertical: 16));
  });

  // appBarTheme/scaffoldBackgroundColor도 코드 어디에도 `Theme.of(context).appBarTheme`
  // 등으로 명시 참조되지 않고 모든 화면의 `AppBar`/`Scaffold`가 암묵적으로 주워 쓰는
  // 구조라(예: `AppBar(title: Text('...'))`만 쓰고 backgroundColor 등을 직접 지정하는
  // 화면이 하나도 없음), textTheme/inputDecorationTheme과 같은 종류의 위험이 있는데도
  // 지금까지 이 값들을 확인하는 테스트가 없었다.
  testWidgets('appBarTheme·scaffoldBackgroundColor가 파스텔 큐트 배경/글자색으로 설정된다', (tester) async {
    late AppBarThemeData appBarTheme;
    late Color scaffoldBg;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            appBarTheme = Theme.of(context).appBarTheme;
            scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    expect(appBarTheme.backgroundColor, AppColors.bg);
    expect(appBarTheme.foregroundColor, AppColors.ink);
    expect(appBarTheme.elevation, 0);
    expect(appBarTheme.centerTitle, isTrue);
    expect(scaffoldBg, AppColors.bg);
  });

  // 2026-07-06 대조 발견으로 추가된 `inputDecorationTheme`(목업 `.text-input`의
  // border:1.5px solid var(--app-border), border-radius:12px, padding:10px 13px를
  // birth_input_screen.dart의 이름/출생지 TextField에 전역 적용)도, 코드 어디에도
  // `Theme.of(context).inputDecorationTheme`으로 명시 참조되지 않고 TextField가
  // 암묵적으로 주워 쓰는 구조라 위 textTheme 세 항목과 완전히 같은 성격의 위험이
  // 있다 — 지금까지 이 값 자체를 확인하는 테스트가 하나도 없었다(발견 당시 커밋
  // 메시지에도 없었고, 이후 어떤 화면 테스트도 실제 테두리 색/두께를 값으로 검증한
  // 적이 없었음). focusedBorder(accent)까지 포함해 값으로 고정한다.
  testWidgets('inputDecorationTheme이 목업 텍스트 필드 스타일(테두리색·두께·채움색)로 설정된다',
      (tester) async {
    late InputDecorationThemeData decorationTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            decorationTheme = Theme.of(context).inputDecorationTheme;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    expect(decorationTheme.filled, isTrue);
    expect(decorationTheme.fillColor, AppColors.bgCard);

    final enabledBorder = decorationTheme.enabledBorder! as OutlineInputBorder;
    expect(enabledBorder.borderSide.color, AppColors.border);
    expect(enabledBorder.borderSide.width, 1.5);
    expect(enabledBorder.borderRadius, BorderRadius.circular(12));

    final focusedBorder = decorationTheme.focusedBorder! as OutlineInputBorder;
    expect(focusedBorder.borderSide.color, AppColors.accent);
    expect(focusedBorder.borderSide.width, 1.5);
  });
}
