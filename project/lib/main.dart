import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/router.dart';
import 'app/theme/app_theme.dart';
import 'core/storage/birth_info_store.dart';
import 'features/birth_input/birth_info.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/result/result_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 저장된 값을 읽다가 실패해도(플랫폼 채널 오류, 손상된 값 등) 앱 자체가 실행되지 않으면
  // 안 되므로, 실패 시 "저장된 정보 없음"으로 간주하고 온보딩부터 시작한다.
  BirthInfo? savedBirthInfo;
  try {
    savedBirthInfo = await BirthInfoStore.load();
  } catch (_) {
    savedBirthInfo = null;
  }

  runApp(CosmosSajuApp(initialBirthInfo: savedBirthInfo));
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
      // 앱 UI 자체는 한국어 고정이라 다국어 지원 대신, 이 로케일 설정은 showDatePicker/
      // showTimePicker 같은 Flutter 내장 위젯을 한국어로 표시하기 위한 것이다.
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: AppRoutes.routes,
      home: initialBirthInfo != null
          ? ResultScreen(birthInfo: initialBirthInfo)
          : const OnboardingScreen(),
    );
  }
}
