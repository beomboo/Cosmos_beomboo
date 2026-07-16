import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_viewport.dart';

/// `test_viewport.dart`의 `useTallViewport` 공용 헬퍼 자체를 겨냥한 스모크 테스트.
/// 2026-07-16 오버나이트 리팩터링(뷰포트 확장 블록을 여러 화면 테스트에서 이 헬퍼로
/// 통합)이 실제로 뷰포트 크기를 바꾸고, 테스트가 끝나면 원래 값으로 복원하는지 확인한다.
void main() {
  testWidgets('기본값(인자 없이 호출)이면 400x2000, devicePixelRatio 1.0으로 뷰포트가 바뀐다', (tester) async {
    await useTallViewport(tester);

    expect(tester.view.physicalSize, const Size(400, 2000));
    expect(tester.view.devicePixelRatio, 1.0);
  });

  testWidgets('width/height를 지정하면 지정한 값 그대로 뷰포트가 바뀐다', (tester) async {
    await useTallViewport(tester, width: 555, height: 1234);

    expect(tester.view.physicalSize, const Size(555, 1234));
    expect(tester.view.devicePixelRatio, 1.0);
  });

  // 아래 두 테스트는 순서에 의존한다 — flutter test는 기본적으로 한 파일 안의
  // testWidgets를 선언된 순서대로(무작위화 없이) 실행하고, TestWidgetsFlutterBinding은
  // 파일(아이솔레이트) 전체에서 하나의 인스턴스를 공유하므로, 앞 테스트에서
  // addTearDown으로 등록한 복원 콜백이 그 테스트가 끝난 직후·다음 테스트가 시작되기
  // 전에 실행된다. 이 프로젝트의 다른 화면 테스트들도 각 testWidgets마다 뷰포트를
  // 저장·복원하는 전제(CLAUDE.md에 기록된 관례) 위에서 동작하므로, 그 전제 자체가
  // 지켜지는지를 이 순서 의존적 두 테스트로 고정한다.
  //
  // physicalSize의 "기본값"을 800x600처럼 하드코딩하면 테스트 바인딩 버전에 따라
  // 실제 기본 devicePixelRatio(예: 3.0)가 곱해진 물리 픽셀 값(예: 2400x1800)과
  // 어긋날 수 있어(실측으로 확인됨), 앞 테스트에서 useTallViewport 호출 *전*의
  // 원래 값을 직접 캡처해뒀다가 뒤 테스트에서 그 값과 비교한다.
  final originalSizeBeforeOverride = <Size>[];
  final originalRatioBeforeOverride = <double>[];

  testWidgets('[순서 의존 1/2] 구별되는 크기로 뷰포트를 바꿔둔다', (tester) async {
    originalSizeBeforeOverride.add(tester.view.physicalSize);
    originalRatioBeforeOverride.add(tester.view.devicePixelRatio);

    await useTallViewport(tester, width: 321, height: 987);

    expect(tester.view.physicalSize, const Size(321, 987));
  });

  testWidgets('[순서 의존 2/2] 앞 테스트가 끝나면 addTearDown이 실행돼 뷰포트가 원래 값으로 복원돼 있다',
      (tester) async {
    // useTallViewport를 호출하지 않은 상태 — 앞 테스트가 등록한 addTearDown이 제대로
    // 동작했다면 앞 테스트가 override하기 전에 캡처해둔 원래 값으로 돌아와 있어야 한다.
    expect(originalSizeBeforeOverride, hasLength(1));
    expect(tester.view.physicalSize, originalSizeBeforeOverride.single);
    expect(tester.view.devicePixelRatio, originalRatioBeforeOverride.single);
  });
}
