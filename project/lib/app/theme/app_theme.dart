import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 파스텔 큐트 컨셉의 앱 전역 ThemeData.
/// 참고: docs/mockups/01-pastel-cute.html
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.bgCard,
      onSurface: AppColors.ink,
      primary: AppColors.accent,
      onPrimary: AppColors.accentInk,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamilyFallback: const [
        'Apple SD Gothic Neo',
        'Malgun Gothic',
        'Noto Sans KR',
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentInk,
          // 목업(docs/mockups/01-pastel-cute.html)의 `.btn-primary`는 완전히 둥근
          // 알약 모양이 아니라 16px 모서리 반경만 쓴다(2026-07-06 대조 발견).
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          // 목업의 `.btn-primary`는 `box-shadow:0 10px 22px -10px accent(70%)`로
          // 브랜드 색이 은은하게 번지는 그림자를 쓰는데, 지금까지는 그림자 자체가
          // 없었다(2026-07-07 대조 발견) — CSS box-shadow를 픽셀 단위로 그대로
          // 옮길 수는 없지만(Flutter의 elevation 모델은 offset/blur/spread를 따로
          // 못 받음), `shadowColor`를 accent로, `elevation`을 눈에 띄는 값으로 줘서
          // 같은 "브랜드색 은은한 글로우" 느낌을 낸다. "공유하기" 버튼(자체 그라데이션
          // Container로 감싸 elevation:0/shadowColor:transparent를 명시적으로 덮어씀,
          // result_screen.dart 참고)에는 영향 없음.
          elevation: 6,
          shadowColor: AppColors.accent.withValues(alpha: 0.7),
        ),
      ),
      // 2026-07-07: 위젯 테스트로 실제 렌더링 스타일을 직접 확인해 각 항목이 어디에
      // 쓰이는지 검증했다(코드에 `Theme.of(context).textTheme.xxx`로 명시 참조하는 곳이
      // 하나도 없어 이 셋도 자칫 cardTheme처럼 죽은 설정으로 오인하기 쉬웠음) —
      // `titleLarge`는 AppBar 제목(모든 화면 헤더), `bodyLarge`는 TextField 입력 텍스트
      // (birth_input_screen.dart의 이름/출생지 필드), `bodyMedium`은 AlertDialog 본문·
      // 스타일 없는 일반 Text의 기본값으로 Flutter Material 3가 암묵적으로 적용한다.
      // (참고로 원래 있던 `headlineMedium`은 같은 방식으로 확인해보니 이 앱이 쓰는
      // 어떤 위젯의 기본값도 아니라 실제로 죽은 설정이어서 제거함 — AlertDialog 제목은
      // `headlineSmall`을 쓰는데 커스터마이즈하지 않아 그대로 Material 3 기본값임.)
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        bodyLarge: TextStyle(color: AppColors.ink),
        bodyMedium: TextStyle(color: AppColors.inkSoft),
      ),
      // 지금까지 이 항목이 없어서 이름/출생지 TextField(birth_input_screen.dart)가
      // 목업(`.text-input`: border:1.5px solid var(--app-border), border-radius:12px,
      // padding:10px 13px)과 무관하게 Flutter 기본 Material 텍스트 필드 스타일을
      // 그대로 쓰고 있었다(2026-07-06 대조 발견) — 앱 전역에 이 모양을 한 번에 적용.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        hintStyle: const TextStyle(color: AppColors.inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
