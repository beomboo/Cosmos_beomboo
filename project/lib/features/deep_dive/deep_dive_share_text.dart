import '../birth_input/birth_info.dart';
import '../result/meta_line.dart';
import 'deep_dive_readings.dart';

/// 심층 분석 결과를 텍스트로 요약한다 (OS 공유 시트에 전달할 본문).
/// `deep_dive_result_screen.dart`의 `_handleShare`에서 사용하며, `DeepDiveShareCard`
/// (이미지)와 함께 공유되거나 이미지 캡처가 실패하면 이 텍스트만 단독으로 공유된다.
/// `result_screen.dart`의 `buildShareText`와 같은 패턴.
String buildDeepDiveShareText({
  required BirthInfo birthInfo,
  required String displayName,

  /// (MBTI 코드, 코멘트) — MBTI를 입력하지 않았으면 null.
  (String, String)? mbti,

  /// (아이콘, 제목, 풀이) — 선택된 관심사만.
  required List<(String, String, String)> items,
}) {
  final buffer = StringBuffer()
    ..writeln('✨ $displayName의 심층 분석 ✨')
    ..writeln(buildMetaLine(birthInfo));

  if (mbti != null) {
    final nickname = mbtiNicknameFor(mbti.$1);
    buffer
      ..writeln()
      ..writeln(nickname != null ? '${mbti.$1} · $nickname' : mbti.$1)
      ..writeln(mbti.$2);
  }

  for (final item in items) {
    buffer
      ..writeln()
      ..writeln('${item.$1} ${item.$2}: ${item.$3}');
  }

  buffer
    ..writeln()
    ..write('#사주랑 #심층분석 #MBTI');

  return buffer.toString();
}
