import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 여러 화면 테스트가 각자 바이트 단위로 복제해 정의하던 뷰포트 확장 헬퍼를
/// 하나로 모은 공용 함수 — 리스트가 긴 화면(입력 폼·결과·상세 리포트 등)은 기본
/// 테스트 화면(800x600)보다 콘텐츠가 커서, 뷰포트를 세로로 넉넉하게 키우지 않으면
/// 하단 요소가 화면 밖에서 지연 빌드되거나 렌더 크기가 잘려 보인다.
///
/// 화면마다 필요한 높이가 달라(2000~3000 등) [height]로 조절할 수 있게 하고,
/// 테스트가 끝나면 [addTearDown]으로 원래 값으로 자동 복원한다.
Future<void> useTallViewport(
  WidgetTester tester, {
  double width = 400,
  double height = 2000,
}) async {
  final originalSize = tester.view.physicalSize;
  final originalRatio = tester.view.devicePixelRatio;
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalRatio;
  });
}
