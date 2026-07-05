import 'package:flutter/material.dart';

import '../features/birth_input/birth_input_screen.dart';
import '../features/calculating/calculating_screen.dart';
import '../features/deep_dive/deep_dive_input_screen.dart';
import '../features/report/report_screen.dart';
import '../features/result/result_screen.dart';

/// 화면 간 네비게이션 정의. 새 화면을 추가하면 이 표에도 등록한다.
///
/// 온보딩 화면은 여기 포함하지 않는다 — 앱 최초 진입 화면(`home:`)은
/// main.dart에서 저장된 생년월일시 유무에 따라 온보딩 또는 결과 화면 중 하나로
/// 직접 결정하며, `routes` 맵에 `'/'`(기본 경로)를 넣으면 `home:`과 충돌한다.
abstract final class AppRoutes {
  static const birthInput = '/birth-input';
  static const calculating = '/calculating';
  static const result = '/result';
  static const report = '/report';
  static const deepDiveInput = '/deep-dive-input';

  static Map<String, WidgetBuilder> get routes => {
        birthInput: (_) => const BirthInputScreen(),
        calculating: (_) => const CalculatingScreen(),
        result: (_) => const ResultScreen(),
        report: (_) => const ReportScreen(),
        deepDiveInput: (_) => const DeepDiveInputScreen(),
      };
}
