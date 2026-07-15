import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

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
    final boundary =
        repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null && !boundary.debugNeedsPaint) {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      imageBytes = byteData?.buffer.asUint8List();
    }
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
