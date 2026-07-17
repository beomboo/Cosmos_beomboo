import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';

import '../support/test_viewport.dart';

void main() {
  // main.dart의 MaterialApp 로케일 설정을 그대로 재현해, 생년월일 선택 다이얼로그
  // (showDatePicker)가 실제로 한국어로 뜨는지 확인한다. 로케일 설정 전에는 이 다이얼로그가
  // 기본값(영어)로 떴었다.
  //
  // 2026-07-16 오버나이트 리팩터: 원래 이 파일만 `resetPhysicalSize()/resetDevicePixelRatio()`
  // (override를 완전히 제거해 테스트 바인딩의 기본값으로 되돌림)를 썼고, 공용 헬퍼
  // `useTallViewport`는 "원래 값을 저장했다가 그 값으로 되돌리는" 방식이라 동작이 다르다
  // — 하지만 이 파일은 테스트가 이 지점 이전에 physicalSize/devicePixelRatio를 건드린 적이
  // 없는 단일 테스트라, "원래 값"으로 캡처되는 값이 곧 테스트 바인딩의 기본값과 같아서
  // 두 방식이 실제로 같은 크기로 되돌아간다(직접 재현 확인: 두 방식 모두로 이 테스트를
  // 실행했을 때 결과가 동일했다). 안전하게 공용 헬퍼로 통합한다.
  testWidgets('생년월일 선택 다이얼로그가 한국어(확인/취소)로 표시된다', (tester) async {
    await useTallViewport(tester);

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

    // 2026-07-17 버그 수정 이후 _birthDate가 처음엔 null이라 pill에 플레이스홀더
    // 문구("날짜를 선택해주세요")가 보인다 — 예전엔 이 자리가 "1998.08.15"였다.
    await tester.tap(find.text('날짜를 선택해주세요'));
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
  });
}
