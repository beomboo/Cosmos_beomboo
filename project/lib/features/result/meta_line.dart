import '../birth_input/birth_info.dart';

/// 생년월일시를 한 줄로 요약한다 (예: "1998.08.15 · 오후 2시生 · 양력 · 여성 · 서울특별시").
/// `result_screen.dart`(헤더 아래 메타 라인, 공유 텍스트)와 `report_screen.dart`(헤더)에서
/// 같은 문구를 재사용한다.
String buildMetaLine(BirthInfo info) {
  final date =
      '${info.date.year}.${info.date.month.toString().padLeft(2, '0')}.${info.date.day.toString().padLeft(2, '0')}';
  final calendarLabel = info.isLunar ? '음력' : '양력';
  final genderSuffix = switch (info.gender) {
    Gender.female => ' · 여성',
    Gender.male => ' · 남성',
    null => '',
  };
  final placeSuffix =
      info.birthPlace?.trim().isNotEmpty == true ? ' · ${info.birthPlace!.trim()}' : '';
  if (info.hour == null) {
    return '$date · 시간 모름 · $calendarLabel$genderSuffix$placeSuffix';
  }
  final period = info.hour! < 12 ? '오전' : '오후';
  final hour12 = info.hour! % 12 == 0 ? 12 : info.hour! % 12;
  // 분은 birth_input에서 실제로 고른 값이 있을 때만 붙인다 — minute이 null인
  // 경우(예: 기존 방식으로 만든 BirthInfo)는 지금까지처럼 시(時) 단위까지만 표시한다.
  final minuteSuffix =
      info.minute != null ? ' ${info.minute!.toString().padLeft(2, '0')}분' : '';
  return '$date · $period $hour12시$minuteSuffix生 · $calendarLabel$genderSuffix$placeSuffix';
}

/// 화면 헤더에 표시할 이름을 정한다 — 이름이 비어있거나 공백뿐이면 '회원님'으로
/// 폴백한다. `result_screen.dart`, `report_screen.dart`, `deep_dive_result_screen.dart`
/// 세 화면이 같은 규칙을 공유한다.
String displayNameFor(BirthInfo info) {
  return info.name?.trim().isNotEmpty == true ? info.name!.trim() : '회원님';
}
