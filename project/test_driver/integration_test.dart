import 'package:integration_test/integration_test_driver.dart';

/// `flutter drive`가 `--release`/`--profile`로 통합 테스트를 구동할 때 필요한 드라이버
/// 진입점. `integration_test/share_capture_release_test.dart`를 실제 assert-제거
/// 조건(release)에서 재현·검증하기 위해 추가했다.
Future<void> main() => integrationDriver();
