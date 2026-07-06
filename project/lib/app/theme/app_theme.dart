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
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border),
        ),
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
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
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
