import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cosmos_saju/shared/share/share_capture.dart';

/// `share_capture.dart`의 release/profile 전용 회귀(`RenderRepaintBoundary.debugNeedsPaint`를
/// 조건문으로 참조하면 assert가 제거된 빌드에서 `LateInitializationError`가 던져지던 버그)를
/// 실제 release/profile 조건에서 검증하기 위한 테스트다.
///
/// `flutter test`(위젯 테스트 러너)는 항상 assert가 켜진 상태로만 실행되므로
/// `test/shared/share/share_capture_test.dart`만으로는 이 버그를 재현할 수 없다 — 원래
/// 버그 코드(`!boundary.debugNeedsPaint` 조건)로 되돌려도 일반 `flutter test`에서는 통과해
/// 버린다. 이 파일은 `integration_test` 패키지로 실제 앱 바이너리를 빌드해 검증하므로,
/// 정상적인 개발 환경에서 아래처럼 profile 모드로 실행하면 진짜 assert-제거 조건을
/// 재현할 수 있다(`flutter drive`는 release 모드 자체를 지원하지 않는다 — release에서는
/// VM 서비스가 꺼져 드라이버가 앱과 통신할 수 없기 때문. 하지만 profile 모드도 release와
/// 동일하게 assert가 제거되므로 이 버그를 재현하는 데는 충분하다):
///
///   dart pub global activate flutter_driver # 최초 1회, 필요 시
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/share_capture_release_test.dart \
///     -d <기기ID> --profile
///
/// ## 이 사이클(2026-07-16)에서 실제로 확인한 것과 못한 것
/// `saju-tester`가 이 명령을 macOS 데스크톱과 iOS 시뮬레이터(iPhone 15 Pro) 양쪽에서
/// 실제로 실행 시도했다. 두 경우 모두 **이 코드베이스와 무관한 샌드박스 환경 문제로
/// 빌드 자체가 실패**했다: `xcodebuild`가 `Command CodeSign failed`(resource fork /
/// Finder information 관련 오류)를 던졌고, 이는 `--debug` 모드로 빌드해도 동일하게
/// 재현돼(`flutter build macos --debug`로 직접 확인) profile/release 여부와 무관한
/// 이 개발 샌드박스의 코드사이닝/확장속성(xattr) 제약임이 확인됐다 — 저장소 코드나
/// 이 테스트 자체의 결함이 아니다. 따라서 이 테스트가 실제로 버그를 잡아내는지
/// (mutation 검증)는 **이 사이클에서는 실행해 확인하지 못했다** — 코드사이닝이 정상
/// 동작하는 일반 개발 머신이나 CI(예: macOS GitHub Actions 러너)에서 위 명령으로
/// 직접 실행해 검증해야 한다. `test/tool/no_release_unsafe_debug_getters_test.dart`가
/// (정적 소스 스캔 방식으로) 실제로 mutation 검증까지 완료한 대체/보완 장치다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'release 빌드(assert 제거)에서도 페인트된 RepaintBoundary를 PNG로 정상 캡처한다',
    (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.pink,
                child: const Text('공유 카드'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bytes = await captureRepaintBoundaryPng(key);

      // release 빌드에서 `debugNeedsPaint`를 조건문으로 참조하는 버그가 되살아나면
      // `LateInitializationError`가 던져지고, 그 예외는 이 함수 바깥의 try/catch가
      // 없는 이 테스트에서 곧바로 실패로 드러난다(운영 코드 `shareCapturedCard`에서는
      // try/catch로 감싸여 있어 "이미지 없이 텍스트만 공유"로 조용히 폴백하므로,
      // 사용자 눈에는 예외 없이 그냥 이미지가 빠진 것처럼만 보였던 것과 대비된다).
      expect(bytes, isNotNull, reason: '페인트가 끝난 RepaintBoundary는 release에서도 캡처에 성공해야 한다');
      expect(bytes, isNotEmpty);
    },
  );
}
