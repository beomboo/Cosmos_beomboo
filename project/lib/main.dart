import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/router.dart';
import 'app/theme/app_colors.dart';
import 'app/theme/app_theme.dart';
import 'core/storage/birth_info_store.dart';
import 'features/birth_input/birth_info.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/result/result_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(CosmosSajuApp(initialBirthInfo: await loadInitialBirthInfo()));
}

/// 앱 시작 시 이전에 저장된 생년월일시를 불러온다.
/// 저장된 값을 읽다가 실패해도(플랫폼 채널 오류, 손상된 값 등) 앱 자체가 실행되지
/// 않으면 안 되므로, 실패 시 "저장된 정보 없음"(null)으로 간주하고 온보딩부터
/// 시작한다. `main()`은 `runApp()`을 호출해 실제 엔진 바인딩에 붙기 때문에
/// `flutter test`로는 직접 실행할 수 없다 — 이 폴백 로직 자체를 값으로 검증할 수
/// 있도록 별도 함수로 분리해뒀다(2026-07-08, `flutter test --coverage`로 main.dart의
/// 이 부분만 커버리지가 비어있는 것을 발견).
Future<BirthInfo?> loadInitialBirthInfo() async {
  try {
    return await BirthInfoStore.load();
  } catch (_) {
    return null;
  }
}

class CosmosSajuApp extends StatelessWidget {
  const CosmosSajuApp({super.key, this.initialBirthInfo});

  /// 이전에 저장된 생년월일시. 있으면 온보딩을 건너뛰고 바로 결과 화면을 보여준다.
  final BirthInfo? initialBirthInfo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '사주랑',
      theme: AppTheme.light,
      // 기기의 다크/라이트 모드 설정과 무관하게 항상 파스텔 큐트 라이트 테마만 쓴다
      // (2026-07-08, 사용자 요청) — darkTheme을 별도로 안 주면 Flutter가 기본적으로
      // 시스템이 다크여도 theme을 그대로 쓰긴 하지만, 그 암묵적 동작에 기대지 않고
      // themeMode까지 명시해 의도를 분명히 하고 향후 실수로 darkTheme이 추가돼도
      // 안전하게 막는다.
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      // 앱 UI 자체는 한국어 고정이라 다국어 지원 대신, 이 로케일 설정은 showDatePicker/
      // showTimePicker 같은 Flutter 내장 위젯을 한국어로 표시하기 위한 것이다.
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // AppBar가 있는 화면은 appBarTheme에서 상태 표시줄 아이콘 색을 자동으로 계산해
      // 주지만, AppBar가 없는 화면(예: 온보딩)은 OS가 시스템 다크/라이트 설정에 따라
      // 상태 표시줄 아이콘 색을 자체 판단해버릴 수 있다 — 여기서 앱 전체에 밝은 배경
      // 기준(어두운 아이콘) 스타일을 강제해, 시스템 설정과 무관하게 항상 일관되게 만든다.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.bg,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: child!,
      ),
      routes: AppRoutes.routes,
      home: initialBirthInfo != null ? ResultScreen(birthInfo: initialBirthInfo) : const OnboardingScreen(),
    );
  }
}
