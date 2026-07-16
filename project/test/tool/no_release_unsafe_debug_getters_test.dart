import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/` 운영 코드 어디에도 `debug*` 접두사가 붙은 프레임워크 게터/메서드(예:
/// `RenderObject.debugNeedsPaint`)가 `assert()` 밖에서 조건문/로직에 다시 등장하지
/// 않는지 정적으로 확인하는 가드 테스트다.
///
/// ## 배경
/// `RenderObject.debugNeedsPaint`는 Flutter 프레임워크 소스(`rendering/object.dart`)에
/// 이렇게 정의돼 있다(요지만 발췌):
/// ```dart
/// bool get debugNeedsPaint {
///   late bool result;
///   assert(() {
///     result = _needsPaint;
///     return true;
///   }());
///   return result; // release/profile 빌드는 assert가 제거되므로 result가 절대
///                   // 대입되지 않아 LateInitializationError를 던진다.
/// }
/// ```
/// `debug*` 접두사가 붙은 다른 다수의 프레임워크 게터도 동일한 패턴을 쓴다. 이런
/// 게터를 운영 코드의 `if`/`assert가 아닌 조건식`에서 참조하면 release/profile
/// 빌드에서만 조용히 터지는(디버그 빌드·`flutter test`에서는 절대 재현되지 않는)
/// 버그가 생긴다 — 2026-07-16, `share_capture.dart`의 `!boundary.debugNeedsPaint`
/// 조건문이 실제로 이 버그였다.
///
/// ## 이 테스트가 `flutter test`로 검증 가능한 이유
/// `flutter test`는 항상 assert가 켜진 채로 실행되므로 "release에서만 터진다"는
/// 버그 자체는 위젯 테스트로 재현할 수 없다(`integration_test/share_capture_release_test.dart`가
/// 실제 --profile 빌드로 그 부분을 담당한다). 하지만 이 테스트는 런타임 동작이 아니라
/// **소스 코드 문자열**을 스캔하므로 assert 여부와 무관하게 항상 동일하게 동작한다 —
/// `lib/` 코드에 위험한 패턴이 있는지 없는지는 assert on/off와 상관없는 정적 사실이기
/// 때문이다. `share_capture.dart`에서 `!boundary.debugNeedsPaint` 조건문을 되살리면
/// (수정 전 코드로 되돌리면) 이 테스트가 실제로 실패하는 것을 확인했다.
void main() {
  test('lib/ 운영 코드에 assert() 밖에서 참조된 debug* 프레임워크 게터/메서드가 없다', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'test/tool/에서 project/ 루트 기준으로 실행돼야 한다');

    // debugPrint류는 release에서도 안전하게 동작하도록 설계된 "정상 사용" API라 허용 목록에 둔다.
    // (release 빌드에서 자동으로 no-op 처리되며, assert 안에서만 값이 채워지는
    // late-in-assert 패턴과 무관하다.)
    const allowedDebugIdentifiers = {'debugPrint', 'debugPrintStack'};

    final debugIdentifierPattern = RegExp(r'\bdebug[A-Z]\w*');
    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final rawLine = lines[i];
        // 라인 주석(`//`, doc comment `///` 포함) 이후는 실제 실행되는 코드가 아니므로
        // 잘라내고 검사한다. 문자열 리터럴 안의 우연한 `//`는 이 코드베이스의 실제
        // 사용 패턴상 위험 부담이 낮아 단순 처리로 충분하다.
        final commentIndex = rawLine.indexOf('//');
        final codeLine = commentIndex >= 0 ? rawLine.substring(0, commentIndex) : rawLine;

        for (final match in debugIdentifierPattern.allMatches(codeLine)) {
          final identifier = match.group(0)!;
          if (allowedDebugIdentifiers.contains(identifier)) continue;

          // `assert(...)` 호출 안에서의 사용은 프레임워크가 의도한 정상 패턴이므로
          // 허용한다 — 같은 줄에서 매치 위치보다 앞에 `assert(`가 있으면 그 안이라고
          // 본다(여러 줄에 걸친 assert까지는 보수적으로 다루지 않는다. 이 코드베이스에는
          // 아직 그런 패턴이 없다).
          final beforeMatch = codeLine.substring(0, match.start);
          if (beforeMatch.contains('assert(')) continue;

          violations.add('${entity.path}:${i + 1}: `$identifier` (assert 밖에서 사용)');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'release/profile 빌드에서 LateInitializationError를 던질 수 있는 debug* 게터가 '
          'assert() 밖에서 발견됐다 — 아래 위치를 assert() 안으로 옮기거나 다른 방식으로 '
          '바꿔야 한다:\n${violations.join('\n')}',
    );
  });
}
