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

  /// [ohaengCount]에서 [dominantOhaeng]을 제외한 나머지 오행 중 가장 개수가 많은 오행
  /// (동률이면 [dominantOhaeng]과 같은 규칙대로 먼저 나오는 쪽 — 목화토금수 순서).
  /// `Map.from(ohaengCount)`는 원본의 삽입 순서(목화토금수)를 그대로 보존하고
  /// `remove()`도 나머지 항목의 순서를 건드리지 않으므로, [dominantOhaeng]의 동률
  /// 처리와 자연히 같은 순서 규칙이 유지된다.
  ///
  /// **엣지케이스**: 사주 여덟 글자가 오행 하나(또는 dominant만 빼고 나머지 전부 0)로
  /// 쏠릴 수 있어, 그 경우 [subDominantOhaeng]의 실제 개수(`ohaengCount[subDominantOhaeng]`)가
  /// 0일 수 있다 — 호출부는 이 오행 이름 자체보다 그 개수를 함께 확인해서 "2순위 오행이
  /// 사실상 존재하지 않음"을 판단해야 한다(예: 결과 화면의 콤보 콜아웃은 개수가 0이면
  /// 단일-오행 문구로 폴백한다).
  String get subDominantOhaeng {
    final rest = Map<String, int>.from(ohaengCount)..remove(dominantOhaeng);
    return rest.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

/// 생년월일시(양력 기준)로 사주팔자 네 기둥을 계산한다.
///
/// **간이 계산 — 정밀도 한계 안내**
/// - 년주는 입춘(立春)을 근사치인 매년 2월 4일로 고정해 처리한다 (실제 입춘 시각은 해마다 2/3~2/5 사이로 미세하게 달라짐).
/// - 월주는 정확한 절기(節氣) 경계 대신 그레고리력 달력의 월(月)을 그대로 사용한다.
/// - 따라서 절기 경계에 걸친 생일(각 달 초순)은 실제 정통 만세력과 최대 며칠 오차가 있을 수 있다.
/// - 정밀한 계산이 필요하면 KASI 절기 데이터 기반 라이브러리(docs/research/07_오픈소스_계산로직 참고, 예: manseryeok) 포팅이 필요하다.
/// - 일주는 1900-01-01(양력)을 갑진일(甲辰)로 하는 60일 주기 계산으로, 날짜 차이만으로 결정되어 절기와 무관하게 정확하다.
/// - 자시(子時, 23시~01시) 관법은 가장 단순한 `midnight`(일주·시주 모두 롤오버 없음)을 쓴다 —
///   전통적으로 더 흔한 `splitJasi`(조자시/야자시 분리)와는 이 시간대 출생자의 시주가 달라질 수 있다
///   (docs/research/04_입력정보_요구사항, 07_오픈소스_계산로직 참고, manseryeok/korean-saju 등 실제 앱들도 관법이 갈림).
/// - 진태양시(眞太陽時, 출생지 경도·균시차 보정)를 전혀 반영하지 않는다 — `BirthInfo.birthPlace`는
///   화면 표시에만 쓰이고 이 계산에는 전달되지 않는다. 서울 기준으로도 약 -14분~-48분의 보정 오차가
///   있어(경도 보정 약 30~32분 고정 + 균시차 계절 변동 최대 ±16분), 시진 경계 부근 출생자는 이
///   보정만으로 시주 자체가 바뀔 수 있다(docs/research/07_오픈소스_계산로직 참고).
/// - **음력(陰曆) 입력을 양력으로 변환하지 않는다.** `BirthInfo.isLunar`는 화면 표시(메타 라인 "음력"
///   라벨)에만 쓰이고 이 함수는 [birthDate]를 무조건 양력으로 취급해 그대로 계산한다 — 위 세 항목처럼
///   경계 근처에서만 며칠~몇십 분 어긋나는 근사 오차가 아니라, 음력으로 입력한 모든 사용자의 네 기둥이
///   (변환 없이 엉뚱한 날짜로 계산되어) 통째로 틀릴 수 있는 훨씬 큰 정확도 문제다. 다른 세 항목과
///   마찬가지로 정밀 구현(만세력 데이터 기반 음양력 변환 라이브러리 포팅)은 사람 결정 대기.
///
/// 어떤 정수든 항상 0~59(60갑자 인덱스 범위) 안으로 접어넣는다(음수 나머지 방지).
int _wrap60(int cycleIndex) => (cycleIndex % 60 + 60) % 60;

/// [birthDate]는 양력 날짜로 취급된다(음력 미변환, 위 참고). [birthHour]는 0~23시(모르면 null → 시주 없이 계산).
FourPillars calculateFourPillars({
  required DateTime birthDate,
  int? birthHour,
}) {
  final date = DateTime(birthDate.year, birthDate.month, birthDate.day);

  // 1) 년주 — 입춘(2/4 근사) 이전이면 전년도 기준
  final isBeforeIpchun = date.month < 2 || (date.month == 2 && date.day < 4);
  final effectiveYear = isBeforeIpchun ? date.year - 1 : date.year;
  // 1984-02-04 이후 ~ 1985-02-03 이전은 갑자년(甲子年, index 0)
  final yearCycleIndex = _wrap60(effectiveYear - 1984);
  final yearStemIndex = yearCycleIndex % 10;
  final yearBranchIndex = yearCycleIndex % 12;

  // 2) 일주 — 1900-01-01 = 갑진일(甲辰, 60갑자 index 40)
  // **2026-07-07 버그 수정**: 로컬(non-UTC) `DateTime.difference()`는 두 날짜 사이에
  // 서머타임 오프셋 변경이 끼어 있으면(한국은 1948~1960년·1987~1988년에 서머타임을
  // 실시했음, 위 doc-comment의 "다섯 번째 정확도 이슈" 참고) 실제 달력 일수보다 하루 적게
  // 계산되는 것을 실측으로 확인했다(`TZ=Asia/Seoul`에서 1987-08-15처럼 서머타임 기간에
  // 태어난 날짜는 `.inDays`가 실제보다 하루 작게 나와 일주·시주가 통째로 하루씩 밀림).
  // 이건 이미 알려진 "서머타임 미반영"(사용자가 입력한 시각 자체가 실제보다 빨랐을 수
  // 있다는 문제)과는 다른, 이 함수 자체의 산술 버그다 — UTC로 정규화하면(UTC는 서머타임이
  // 없음) 서머타임 기간과 무관하게 항상 정확한 날짜 차이가 나온다.
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  final daysSinceEpoch = utcDate.difference(DateTime.utc(1900, 1, 1)).inDays;
  final dayCycleIndex = _wrap60(40 + daysSinceEpoch);
  final dayStemIndex = dayCycleIndex % 10;
  final dayBranchIndex = dayCycleIndex % 12;

  // 3) 월주 — 월지는 그레고리력 월 기준 근사, 월간은 오호둔년기월법(년간 기준 공식)
  // **2026-07-07 버그 수정**: 월지가 그레고리력 월만 보고 결정돼(`date.month`), 년주가
  // 이미 입춘 이전으로 판단해 전년도로 롤백한 2/1~2/3에도 월지는 여전히 "2월=인월"로
  // 계산돼 년주·월주가 서로 모순되는 날짜가 있었음(입춘 이전이면 아직 인월이 시작되지
  // 않아 1월과 같은 축월이어야 함) — `isBeforeIpchun`과 같은 판단으로 이 3일간은 1월로
  // 취급해 년주 롤백과 일관되게 맞춘다.
  final effectiveMonthForBranch = (date.month == 2 && date.day < 4) ? 1 : date.month;
  final monthBranchIndex = effectiveMonthForBranch % 12; // 1월→축(1) ... 12월→자(0)
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
