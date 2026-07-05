import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';

void main() {
  // main.dart의 MaterialApp 로케일 설정을 그대로 재현해, 생년월일 선택 다이얼로그
  // (showDatePicker)가 실제로 한국어로 뜨는지 확인한다. 로케일 설정 전에는 이 다이얼로그가
  // 기본값(영어)로 떴었다.
  testWidgets('생년월일 선택 다이얼로그가 한국어(확인/취소)로 표시된다', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko', 'KR'),
        supportedLocales: [Locale('ko', 'KR')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BirthInputScreen(),
      ),
    );

    await tester.tap(find.text('1998.08.15'));
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
  });
}
