import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';

/// 앱 아이콘 PNG를 생성하는 일회성 스크립트.
///
/// 목업을 SVG→PNG로 변환해 줄 도구가 이 환경엔 없지만, `share_card.dart`에서 이미
/// 쓰고 있는 `RenderRepaintBoundary.toImage()` 캡처 기법을 그대로 재사용하면
/// Flutter 위젯만으로 파스텔 큐트 톤 아이콘을 직접 그려 PNG로 뽑아낼 수 있다.
///
/// `Icon`(Material Icons 폰트)은 쓰지 않는다 — `flutter test`는 결정론적 렌더링을 위해
/// 모든 폰트 글리프를 네모 박스로 치환(`--use-test-fonts`)하므로, 실제 스크린샷과
/// 달리 아이콘 폰트가 빈 사각형으로만 찍히는 것을 실제로 확인했다. 대신 `calculating_screen.dart`의
/// "달 주위를 도는 오행 알갱이" 모티프를 `CustomPainter`로 순수 벡터 도형만 그려 재현한다.
///
/// 파일명에 `_test` 접미사를 일부러 붙이지 않아 일반 `flutter test` 실행 시
/// 자동으로 수집되지 않는다 — 아이콘을 다시 생성해야 할 때만
/// `flutter test test/tool/generate_app_icon.dart`로 직접 실행한다.
void main() {
  testWidgets('assets/icon/icon.png 생성', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: 1024,
            height: 1024,
            child: CustomPaint(painter: _AppIconPainter()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // toImage()/toByteData()는 실제 엔진 콜백을 기다려야 해서, testWidgets의 기본
    // FakeAsync 존 안에서 직접 await하면 영원히 끝나지 않는다 — runAsync()로 감싸야 한다.
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File('assets/icon/icon.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    });
  });
}

/// `calculating_screen.dart`의 궤도 모티프(달 + 오행 알갱이)를 정적 아이콘으로 재구성한다.
class _AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 배경 — 코너까지 꽉 채워야 안드로이드 적응형 아이콘이 원형으로 마스킹해도 비지 않는다.
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.accentSoft);

    // 달 — 큰 원(accent) 위에 배경색 원을 오른쪽 위로 겹쳐 그려 초승달 실루엣을 만든다.
    // 안드로이드 적응형 아이콘은 중앙 약 66%만 안전 영역이라, 모든 도형을 그 안에 넣는다.
    // 초승달은 원래 중심에서 왼쪽 아래로 시각적 무게가 쏠리므로, 원 중심을 오른쪽 위로
    // 살짝 옮겨 눈에 보이는 결과물이 캔버스 중앙에 오도록 보정한다.
    final moonCenter = center + Offset(size.width * 0.03, -size.height * 0.02);
    final moonRadius = size.width * 0.22;
    canvas.drawCircle(moonCenter, moonRadius, Paint()..color = AppColors.accent);
    canvas.drawCircle(
      moonCenter + Offset(moonRadius * 0.62, -moonRadius * 0.42),
      moonRadius * 0.86,
      Paint()..color = AppColors.accentSoft,
    );

    // 오행 알갱이 — 달 주위에 다섯 오행 색 점을 고르게 배치한다.
    const ohaengOrder = ['목', '화', '토', '금', '수'];
    final orbitRadius = size.width * 0.34;
    final dotRadius = size.width * 0.04;
    for (var i = 0; i < ohaengOrder.length; i++) {
      final angle = -math.pi / 2 + i * (2 * math.pi / ohaengOrder.length);
      final dotCenter = center + Offset(math.cos(angle), math.sin(angle)) * orbitRadius;
      canvas.drawCircle(
        dotCenter,
        dotRadius,
        Paint()..color = AppColors.ohaengColors[ohaengOrder[i]]!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
