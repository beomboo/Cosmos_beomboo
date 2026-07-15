import 'package:flutter/material.dart';

/// 공유용 카드를 화면 밖(왼쪽 멀리)에 배치해 사용자 눈에는 보이지 않지만,
/// `RepaintBoundary`는 여전히 레이아웃·페인트되므로 `shareCapturedCard`로 캡처는 가능하다.
/// `Positioned`는 페인트·히트테스트만 제외할 뿐 시맨틱스 트리에는 그대로 남아있어,
/// 스크린 리더가 방금 읽은 내용을 라벨 없이 중복해서 다시 읽어주는 문제가 있었다 —
/// `ExcludeSemantics`로 이 서브트리 전체를 시맨틱스에서 제외한다(2026-07-15 접근성 발견).
///
/// `result_screen.dart`/`deep_dive_result_screen.dart`가 각자 `Stack` 안에 복제하던
/// `Positioned(left: -4000) + ExcludeSemantics + RepaintBoundary` 래퍼를 하나로 모은 것.
/// `Stack`의 자식으로 바로 써야 `Positioned`가 실제로 위치를 잡는다(`Positioned`가
/// `StatelessWidget` 안에서 build()의 최상위로 반환돼도 `Stack`은 element 트리를 통해
/// 이를 인식한다).
class OffscreenShareCapture extends StatelessWidget {
  const OffscreenShareCapture({
    super.key,
    required this.repaintBoundaryKey,
    required this.child,
  });

  /// `shareCapturedCard`가 이미지 캡처에 쓸 `RepaintBoundary` 키.
  final GlobalKey repaintBoundaryKey;

  /// 캡처될 공유 카드 위젯(예: `ShareCard`/`DeepDiveShareCard`).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -4000,
      top: 0,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          key: repaintBoundaryKey,
          child: child,
        ),
      ),
    );
  }
}
