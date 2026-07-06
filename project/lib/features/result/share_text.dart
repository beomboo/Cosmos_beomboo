import '../../core/saju/four_pillars.dart';
import '../birth_input/birth_info.dart';
import 'meta_line.dart';

/// 결과를 텍스트로 요약한다 (OS 공유 시트에 전달할 본문).
/// `result_screen.dart`의 `_handleShare`에서 사용하며, `ShareCard`(이미지)와 함께
/// 공유되거나 이미지 캡처가 실패하면 이 텍스트만 단독으로 공유된다.
String buildShareText({
  required BirthInfo birthInfo,
  required FourPillars pillars,
  required String dominant,
  required (String, String, String) callout,
  required Map<String, int> ohaengCount,
  required int total,
  required String displayName,
}) {
  final pillarLine =
      '年柱 ${pillars.year.label} · 月柱 ${pillars.month.label} · 日柱 ${pillars.day.label}'
      '${pillars.hour != null ? ' · 時柱 ${pillars.hour!.label}' : ''}';
  final balanceLine = const ['목', '화', '토', '금', '수']
      .map((o) => '$o ${total == 0 ? 0 : (ohaengCount[o]! / total * 100).round()}%')
      .join(' · ');

  return '''
✨ $displayName의 사주팔자 ✨
${buildMetaLine(birthInfo)}

$pillarLine

$dominant(${callout.$1}) 기운이 강한 타입이에요 ${callout.$2}
${callout.$3}

오행 밸런스: $balanceLine

#사주랑 #사주팔자 #오행''';
}
