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
  return '$date · $period $hour12시生 · $calendarLabel$genderSuffix$placeSuffix';
}
