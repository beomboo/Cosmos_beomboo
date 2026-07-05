import 'ganzhi.dart';

/// 사주팔자 네 기둥(년주/월주/일주/시주) 계산 결과.
class FourPillars {
  const FourPillars({
    required this.year,
    required this.month,
    required this.day,
    this.hour,
  });

  final GanzhiPillar year;
  final GanzhiPillar month;
  final GanzhiPillar day;

  /// 태어난 시간을 모르면 null (시주 없이 3주만 사용).
  final GanzhiPillar? hour;

  /// 네 기둥(또는 시주 없이 세 기둥)의 오행을 모두 모아 개수를 센다.
  Map<String, int> get ohaengCount {
    final counts = <String, int>{'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};
    for (final pillar in [year, month, day, ?hour]) {
      for (final element in pillar.ohaeng) {
        counts[element] = (counts[element] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// [ohaengCount]에서 가장 개수가 많은 오행 하나(동률이면 먼저 나오는 쪽 — 목화토금수 순).
  /// 결과 화면의 우세 오행 콜아웃·카테고리 풀이, 상세 리포트, 심층 분석 화면이 모두
  /// 이 값을 공유해서 쓴다(전에는 result_screen.dart 안에 이 reduce 로직이 따로 있었는데,
  /// 동률 처리 방식까지 포함해 이미 검증된 로직을 다른 화면에서 중복 구현하지 않도록 이쪽으로 옮김).
  String get dominantOhaeng =>
      ohaengCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// 생년월일시(양력 기준)로 사주팔자 네 기둥을 계산한다.
///
/// **간이 계산 — 정밀도 한계 안내**
/// - 년주는 입춘(立春)을 근사치인 매년 2월 4일로 고정해 처리한다 (실제 입춘 시각은 해마다 2/3~2/5 사이로 미세하게 달라짐).
/// - 월주는 정확한 절기(節氣) 경계 대신 그레고리력 달력의 월(月)을 그대로 사용한다.
/// - 따라서 절기 경계에 걸친 생일(각 달 초순)은 실제 정통 만세력과 최대 며칠 오차가 있을 수 있다.
/// - 정밀한 계산이 필요하면 KASI 절기 데이터 기반 라이브러리(docs/research/07_오픈소스_계산로직 참고, 예: manseryeok) 포팅이 필요하다.
/// - 일주는 1900-01-01(양력)을 갑진일(甲辰)로 하는 60일 주기 계산으로, 날짜 차이만으로 결정되어 절기와 무관하게 정확하다.
///
/// [birthDate]는 양력 날짜. [birthHour]는 0~23시(모르면 null → 시주 없이 계산).
FourPillars calculateFourPillars({
  required DateTime birthDate,
  int? birthHour,
}) {
  final date = DateTime(birthDate.year, birthDate.month, birthDate.day);

  // 1) 년주 — 입춘(2/4 근사) 이전이면 전년도 기준
  final isBeforeIpchun = date.month < 2 || (date.month == 2 && date.day < 4);
  final effectiveYear = isBeforeIpchun ? date.year - 1 : date.year;
  // 1984-02-04 이후 ~ 1985-02-03 이전은 갑자년(甲子年, index 0)
  final yearCycleIndex = ((effectiveYear - 1984) % 60 + 60) % 60;
  final yearStemIndex = yearCycleIndex % 10;
  final yearBranchIndex = yearCycleIndex % 12;

  // 2) 일주 — 1900-01-01 = 갑진일(甲辰, 60갑자 index 40)
  final daysSinceEpoch = date.difference(DateTime(1900, 1, 1)).inDays;
  final dayCycleIndex = ((40 + daysSinceEpoch) % 60 + 60) % 60;
  final dayStemIndex = dayCycleIndex % 10;
  final dayBranchIndex = dayCycleIndex % 12;

  // 3) 월주 — 월지는 그레고리력 월 기준 근사, 월간은 오호둔년기월법(년간 기준 공식)
  final monthBranchIndex = date.month % 12; // 1월→축(1) ... 12월→자(0)
  final traditionalMonthNumber = ((monthBranchIndex - 2 + 12) % 12) + 1; // 인월=1 ~ 축월=12
  final monthStemIndex = (((yearStemIndex % 5) * 2 + 2) + (traditionalMonthNumber - 1)) % 10;

  // 4) 시주 — 오자둔일기시법(일간 기준 공식). 시간을 모르면 계산하지 않음
  GanzhiPillar? hourPillar;
  if (birthHour != null) {
    final hourBranchIndex = ((birthHour + 1) ~/ 2) % 12; // 23~01시→자(0) ...
    final hourStemIndex = ((dayStemIndex % 5) * 2 + hourBranchIndex) % 10;
    hourPillar = GanzhiPillar(stemIndex: hourStemIndex, branchIndex: hourBranchIndex);
  }

  return FourPillars(
    year: GanzhiPillar(stemIndex: yearStemIndex, branchIndex: yearBranchIndex),
    month: GanzhiPillar(stemIndex: monthStemIndex, branchIndex: monthBranchIndex),
    day: GanzhiPillar(stemIndex: dayStemIndex, branchIndex: dayBranchIndex),
    hour: hourPillar,
  );
}
