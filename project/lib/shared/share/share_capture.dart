import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// `GlobalKey`가 가리키는 `RepaintBoundary`를 PNG 바이트로 캡처한다.
///
/// 주의: `debug*` 접두사가 붙은 게터/메서드(예: `debugNeedsPaint`)는 프레임워크
/// 내부에서 `assert()` 블록 안에서만 값을 대입하는 구조라 release/profile 빌드에서는
/// (assert가 제거되므로) `LateInitializationError`를 던진다. 절대 운영 코드 경로에서
/// `debug*` 게터/메서드를 조건문으로 호출하지 않는다. `toImage()` 내부의
/// `assert(!debugNeedsPaint)`는 release에서 자동으로 사라지므로 안전하고, 정말 레이아웃
/// 전이라 실패하면 일반 예외가 던져져 호출부의 catch에서 텍스트 폴백으로 처리된다.
///
/// `shareCapturedCard`에서 분리해 `@visibleForTesting`으로 노출한 이유: `flutter test`는
/// 항상 assert가 켜진 상태로만 실행되어 위 release 전용 회귀(assert 제거 시
/// `LateInitializationError`)를 재현할 수 없다. `integration_test/share_capture_release_test.dart`가
/// (정상적인 개발 환경/CI에서) 실제 profile/release 빌드(assert 제거)로 이 함수만
/// 단독 호출해 진짜 release 조건에서 검증하도록 설계됐다(`shareCapturedCard` 전체를
/// 호출하면 실제 OS 공유 시트가 떠서 자동화 테스트가 멈추므로, 공유 시트 호출 없는 이
/// 캡처 전용 함수만 따로 뗀다). 이 함수에 `debug*` 게터/메서드가 다시 등장하지 않는지는
/// `test/tool/no_release_unsafe_debug_getters_test.dart`가 정적 소스 스캔으로 별도 확인한다.
@visibleForTesting
Future<Uint8List?> captureRepaintBoundaryPng(
  GlobalKey repaintBoundaryKey, {
  double pixelRatio = 3,
}) async {
  final boundary =
      repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}

/// 공유용 카드(`RepaintBoundary`로 감싼 오프스크린 위젯)를 이미지로 캡처해 텍스트와
/// 함께 공유한다. `result_screen.dart`/`deep_dive_result_screen.dart`의 `_handleShare`가
/// 거의 동일하게 복제하고 있던 "캡처→공유→실패 스낵바" 로직을 하나로 모은 공용 함수.
///
/// - 캡처가 실패하면(레이아웃 전이거나 플랫폼 문제 등) 이미지 없이 텍스트만이라도 공유한다.
/// - 공유 시트 자체가 실패하면(플랫폼 채널 오류 등) 버튼이 아무 반응 없이 조용히 실패하는
///   것처럼 보이지 않도록 스낵바로 안내한다.
Future<void> shareCapturedCard({
  required BuildContext context,
  required GlobalKey repaintBoundaryKey,
  required String text,
  required String subject,
  required String fileName,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final sharePositionOrigin = box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

  Uint8List? imageBytes;
  try {
    imageBytes = await captureRepaintBoundaryPng(repaintBoundaryKey);
  } catch (_) {
    // 캡처 실패 시 아래에서 텍스트만 공유한다.
    imageBytes = null;
  }

  try {
    if (imageBytes != null) {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          files: [XFile.fromData(imageBytes, mimeType: 'image/png', name: fileName)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유하는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.')),
    );
  }
}
