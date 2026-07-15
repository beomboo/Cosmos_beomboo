import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/shared/share/share_capture.dart';

/// `result_screen_test.dart`/`deep_dive_result_screen_test.dart`가 각 화면의
/// "공유하기" 버튼을 통해서만 간접 검증하던 `shareCapturedCard` 공용 함수 자체를
/// 직접 겨냥한 테스트. 2026-07-15 리팩터링으로 두 화면이 복제하던
/// "RepaintBoundary 캡처→SharePlus 공유→실패 스낵바" 로직이 이 함수 하나로 모였다.
///
/// 테스트 환경에는 share_plus 플랫폼 채널 목(mock)이 없어 `SharePlus.instance.share()`
/// 호출은 항상 MissingPluginException으로 실패한다 — 이는 우리가 대비하려는 "공유 시트
/// 자체 실패" 상황과 동일해서 실제로 재현·검증이 가능하다
/// (result_screen_test.dart의 기존 발견과 동일).
void main() {
  testWidgets('RepaintBoundary가 페인트된 상태(캡처 성공)에서도 공유 시트 자체가 실패하면 스낵바로 알려준다',
      (tester) async {
    final key = GlobalKey();
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return RepaintBoundary(
                key: key,
                child: const Text('공유 대상'),
              );
            },
          ),
        ),
      ),
    );

    // 실제 이미지 캡처(RenderRepaintBoundary.toImage())가 엔진 콜백을 기다려야 해서
    // runAsync로 감싼다(result_screen_test.dart와 동일한 이유).
    await tester.runAsync(() async {
      await shareCapturedCard(
        context: capturedContext,
        repaintBoundaryKey: key,
        text: '공유 텍스트',
        subject: '테스트 제목',
        fileName: 'test.png',
      );
    });
    await tester.pump();

    expect(
      find.text('공유하는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.'),
      findsOneWidget,
    );
  });

  testWidgets('RepaintBoundary가 아직 페인트되지 않았으면 캡처를 건너뛰고 텍스트만으로 공유를 시도한다',
      (tester) async {
    // boundary.debugNeedsPaint가 true인 상태(paint 되기 전)를 재현하려면
    // EnginePhase.layout까지만 pump해서 build·layout만 하고 paint는 돌리지 않는다.
    final key = GlobalKey();
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return RepaintBoundary(
                key: key,
                child: const Text('공유 대상'),
              );
            },
          ),
        ),
      ),
      phase: EnginePhase.layout,
    );

    await tester.runAsync(() async {
      await shareCapturedCard(
        context: capturedContext,
        repaintBoundaryKey: key,
        text: '공유 텍스트',
        subject: '테스트 제목',
        fileName: 'test.png',
      );
    });
    await tester.pump();

    // 이 경로도 share() 자체는 여전히 플랫폼 채널이 없어 실패하므로 사용자에게 보이는
    // 결과(스낵바)는 위 테스트와 동일하다 — 이 테스트가 확인하려는 건 이미지 캡처를
    // 건너뛰는 else 분기가 예외 없이 텍스트 전용 공유로 자연스럽게 이어지는지다.
    expect(
      find.text('공유하는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.'),
      findsOneWidget,
    );
  });

  testWidgets('repaintBoundaryKey가 아직 어떤 위젯에도 붙지 않았어도(currentContext가 null) 예외 없이 처리한다',
      (tester) async {
    // result_screen.dart/deep_dive_result_screen.dart는 _shareCardKey를 항상
    // RepaintBoundary에 붙여 쓰기 때문에 이 경로는 기존 화면 테스트로는 검증된 적이
    // 없었다 — `repaintBoundaryKey.currentContext?.findRenderObject()`의 null-safe
    // 방어가 실제로 예외 없이 동작하는지 직접 확인한다.
    final key = GlobalKey(); // 아무 위젯에도 붙지 않음
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const Text('캡처 대상 없음');
            },
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await shareCapturedCard(
        context: capturedContext,
        repaintBoundaryKey: key,
        text: '공유 텍스트',
        subject: '테스트 제목',
        fileName: 'test.png',
      );
    });
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.text('공유하는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.'),
      findsOneWidget,
    );
  });
}
