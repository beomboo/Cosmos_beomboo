import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 공유하기 기능이 추가된 화면들(결과·심층 분석 결과 등)은 화면 밖(사용자 눈에는
/// 안 보임)에 같은 문구를 가진 캡처용 공유 카드 위젯이 위젯 트리에 함께 존재한다 —
/// `find.text()`를 그대로 쓰면 두 곳이 매치돼 테스트가 실패하므로, 실제로 보이는
/// 스크롤 뷰(그 화면의 `Key`) 안으로 finder 범위를 좁혀야 한다. 여러 화면 테스트가
/// 각자 같은 모양의 클로저를 반복 정의하던 것을 공용 헬퍼로 모았다.
///
/// [scrollViewKey]는 각 화면의 스크롤 뷰에 붙은 `Key`의 문자열 값
/// (예: `'resultScrollView'`, `'deepDiveResultScrollView'`)이다.
Finder findInScrollView(String scrollViewKey, String text) => find.descendant(
      of: find.byKey(Key(scrollViewKey)),
      matching: find.text(text),
    );

/// [findInScrollView]와 같은 이유로, `find.textContaining()` 버전이 필요한 곳에서 쓴다.
Finder findTextContainingInScrollView(String scrollViewKey, String text) => find.descendant(
      of: find.byKey(Key(scrollViewKey)),
      matching: find.textContaining(text),
    );
