/// 성별. 현재는 계산에 쓰지 않지만, 명리학에서 대운(大運)의 순행/역행 방향을 정할 때
/// 필요해 입력받아둔다 (참고: docs/research/07_오픈소스_계산로직).
enum Gender { female, male }

/// 혈액형. 사주 계산과는 무관한 순수 저장/참고 필드 — 2026-07-19 입력 화면 필수값
/// 확장(목업 `.field-required` "혈액형")에 맞춰 추가됐다.
enum BloodType { a, b, ab, o }

/// 생년월일시 입력 화면에서 다음 화면(계산 중 → 결과)으로 전달하는 입력 데이터.
class BirthInfo {
  const BirthInfo({
    required this.date,
    required this.hour,
    required this.isLunar,
    this.minute,
    this.name,
    this.birthPlace,
    this.gender,
    this.bloodType,
  });

  final DateTime date;

  /// 0~23시. 태어난 시간을 모르면 null.
  final int? hour;

  /// 0~59분. `hour`가 null(시간 모름)이면 이 값도 항상 null이다. `hour`는 알지만
  /// `minute`이 null인 경우(예: 예전에 저장된 값, 직접 만든 테스트용 BirthInfo)도
  /// 있을 수 있다 — 이럴 땐 분 없이 시(時) 단위까지만 표시한다.
  final int? minute;

  final bool isLunar;

  /// 선택 입력. 비어 있으면 결과 화면에서 "회원님"으로 표시한다.
  final String? name;

  /// 선택 입력(예: "서울특별시"). 현재는 계산에 쓰지 않고 결과/공유 화면에 참고 정보로만 표시한다.
  final String? birthPlace;

  /// birth_input 화면에서는 항상 값이 선택돼 있지만(기본값 female), 다른 곳에서
  /// BirthInfo를 만들 때(예: 데모 기본값, 테스트) 생략할 수 있도록 nullable로 둔다.
  /// 현재는 계산에 쓰지 않고 결과 화면에 참고 정보로만 표시한다.
  final Gender? gender;

  /// 2026-07-19 입력 화면에서 필수값으로 추가됐지만, Gender와 마찬가지로 사주 계산과는
  /// 무관한 순수 저장 필드라 다른 곳에서 BirthInfo를 만들 때(데모 기본값, 테스트) 생략할
  /// 수 있도록 nullable로 둔다.
  final BloodType? bloodType;
}
