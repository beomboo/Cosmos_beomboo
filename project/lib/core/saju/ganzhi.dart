/// 천간(天干)·지지(地支) 60갑자(甲子) 기본 상수.
/// 참고: docs/research/01_사주팔자_기초개념, docs/research/07_오픈소스_계산로직
library;

/// 천간 10개 (갑을병정무기경신임계)
const heavenlyStems = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];

/// 지지 12개 (자축인묘진사오미신유술해)
const earthlyBranches = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];

/// 천간의 오행 (갑을=목, 병정=화, 무기=토, 경신=금, 임계=수)
const _stemOhaeng = ['목', '목', '화', '화', '토', '토', '금', '금', '수', '수'];

/// 지지의 오행 (자=수, 축=토, 인=목, 묘=목, 진=토, 사=화, 오=화, 미=토, 신=금, 유=금, 술=토, 해=수)
const _branchOhaeng = ['수', '토', '목', '목', '토', '화', '화', '토', '금', '금', '토', '수'];

String stemOhaeng(int stemIndex) => _stemOhaeng[stemIndex % 10];

String branchOhaeng(int branchIndex) => _branchOhaeng[branchIndex % 12];

/// 오행 이름(한글) → 한자. 목업(`.bar-row .tag`, 오행 뜻풀이 배지 등)이 오행을 짧게
/// 표시할 때는 한글이 아니라 한자를 쓰는 관례라, 결과/리포트/공유 카드 화면이 모두
/// 이 상수를 공유해서 참조한다(각자 하드코딩하면 한 곳만 고쳤을 때 화면마다 값이
/// 어긋나는 회귀가 생길 수 있음).
const ohaengHanja = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};

/// 오행 상생(相生) 순환 순서: 목→화→토→금→수→(다시 목으로 순환).
/// [ohaengRelationOf]가 두 오행 사이의 순환 offset을 계산하는 기준이 된다.
const _ohaengGenerateCycle = ['목', '화', '토', '금', '수'];

/// 우세(dominant) 오행과 2순위(sub) 오행 사이의 상생·상극 관계 4종.
/// 결과 화면의 콤보 콜아웃·카테고리 카드 접미사(`features/result/ohaeng_readings.dart`)가
/// 이 값에 따라 문구를 고른다.
enum OhaengRelation {
  /// dominant가 sub를 생(生)한다 (예: 목→화, dominant가 힘을 보태는 흐름).
  dominantGeneratesSub,

  /// sub가 dominant를 생(生)한다 (예: 수→목, sub가 dominant를 뒤에서 받쳐주는 흐름).
  subGeneratesDominant,

  /// dominant가 sub를 극(克)한다 (예: 목→토, dominant가 sub를 다스리는 흐름).
  dominantOvercomesSub,

  /// sub가 dominant를 극(克)한다 (예: 금→목, sub가 dominant에 브레이크를 거는 흐름).
  subOvercomesDominant,
}

/// [dominant]와 [sub] 두 오행 사이의 관계를 판별한다.
///
/// [_ohaengGenerateCycle] 순환에서 dominant→sub까지의 거리(offset, 1~4)로 넷 중 하나로
/// 분류한다 — offset은 (sub 인덱스 − dominant 인덱스)를 5로 나눈 나머지이며, dominant와
/// sub가 서로 다른 오행이기만 하면 항상 1~4 중 하나로 정확히 하나만 떨어진다(전수
/// 커버·상호 배타적):
/// - offset 1: dominant가 순환상 바로 다음 오행을 생(生)한다 → [OhaengRelation.dominantGeneratesSub]
/// - offset 2: dominant가 두 칸 뒤 오행을 극(克)한다 → [OhaengRelation.dominantOvercomesSub]
/// - offset 3: (offset 2의 반대 방향) sub가 dominant를 극(克)한다 → [OhaengRelation.subOvercomesDominant]
/// - offset 4: (offset 1의 반대 방향) sub가 dominant를 생(生)한다 → [OhaengRelation.subGeneratesDominant]
///
/// [dominant]와 [sub]가 같은 오행이면 관계가 정의되지 않아 예외를 던진다 — 호출부(결과
/// 화면 등)는 항상 서로 다른 두 오행(우세·2순위)만 넘겨야 한다.
OhaengRelation ohaengRelationOf(String dominant, String sub) {
  final dominantIndex = _ohaengGenerateCycle.indexOf(dominant);
  final subIndex = _ohaengGenerateCycle.indexOf(sub);
  if (dominantIndex == -1 || subIndex == -1) {
    throw ArgumentError('알 수 없는 오행: dominant=$dominant, sub=$sub');
  }
  if (dominantIndex == subIndex) {
    throw ArgumentError('dominant와 sub가 같은 오행($dominant)이면 관계가 정의되지 않는다');
  }
  final offset = (subIndex - dominantIndex + _ohaengGenerateCycle.length) %
      _ohaengGenerateCycle.length;
  switch (offset) {
    case 1:
      return OhaengRelation.dominantGeneratesSub;
    case 2:
      return OhaengRelation.dominantOvercomesSub;
    case 3:
      return OhaengRelation.subOvercomesDominant;
    default: // 4
      return OhaengRelation.subGeneratesDominant;
  }
}

/// 하나의 기둥(柱) — 천간 1자 + 지지 1자.
class GanzhiPillar {
  const GanzhiPillar({required this.stemIndex, required this.branchIndex});

  final int stemIndex;
  final int branchIndex;

  String get stem => heavenlyStems[stemIndex % 10];
  String get branch => earthlyBranches[branchIndex % 12];

  /// 예: "갑자"
  String get label => '$stem$branch';

  List<String> get ohaeng => [stemOhaeng(stemIndex), branchOhaeng(branchIndex)];

  /// 60갑자 인덱스(0~59) — 천간 인덱스(0~9)·지지 인덱스(0~11) 조합으로부터 역으로
  /// 찾는다(CRT). `calculateFourPillars()`는 각 기둥을 원래 60갑자 인덱스에서
  /// `% 10`/`% 12`로 쪼개 만들지만, `GanzhiPillar` 자체는 stem/branch 인덱스만
  /// 들고 있어(원본 60갑자 인덱스를 따로 저장하지 않음) [nayinFor]가 필요로 하는
  /// 60갑자 인덱스를 여기서 다시 복원한다.
  int get ganzhiIndex60 {
    final s = stemIndex % 10;
    final b = branchIndex % 12;
    for (var i = 0; i < 60; i++) {
      if (i % 10 == s && i % 12 == b) return i;
    }
    // 천간·지지 홀짝이 서로 다르면(예: 양간+음지) 애초에 존재할 수 없는 조합이라
    // 정상적인 사주 계산 결과에서는 이 분기에 도달하지 않는다.
    throw StateError('유효하지 않은 천간·지지 조합: stem=$s, branch=$b');
  }

  @override
  String toString() => label;
}

/// 공망(空亡) 지지 2개의 인덱스(자=0~해=11 기준) — 일간·일지 인덱스만으로 정해지는
/// 고정 배치다(순중공망旬中空亡). 60갑자를 10개씩 묶은 6개 "순(旬)"마다 짝을 이루지
/// 못해 비는 지지 2개가 그 순 전체의 공망이 된다.
///
/// 참고: docs/research/사주팔자/공망.md — `saju`(Dart) 패키지 `core/sinsals.dart`와
/// manseryeok `void-branches.ts` 양쪽 오픈소스 구현이 (겉보기엔 다른 방식이지만 수학적으로
/// 동치임을 확인하며) 교차검증한 공식을 그대로 옮겼다.
List<int> voidBranchIndices({required int dayStemIndex, required int dayBranchIndex}) {
  final diff = (dayBranchIndex % 12 - dayStemIndex % 10 + 12) % 12;
  return [(diff + 10) % 12, (diff + 11) % 12];
}

/// 납음오행(納音五行) 이름 30가지 — 60갑자를 2개씩 묶은 조 이름(한글·한자·오행).
/// 참고: docs/research/사주팔자/납음오행.md — 사자사주abc 블로그·표준국어대사전·
/// `saju`(Dart) 패키지 `core/nayin.dart` 세 출처가 모두 일치함을 확인한 조견표.
/// 인덱스 0은 갑자·을축(해중금), 인덱스 29는 임술·계해(대해수)에 대응한다.
const _nayinNames = [
  '해중금', '노중화', '대림목', '노방토', '검봉금',
  '산두화', '간하수', '성두토', '백랍금', '양류목',
  '천중수', '옥상토', '벽력화', '송백목', '장류수',
  '사중금', '산하화', '평지목', '벽상토', '금박금',
  '복등화', '천하수', '대역토', '채천금', '상자목',
  '대계수', '사중토', '천상화', '석류목', '대해수',
];

const _nayinHanja = [
  '海中金', '爐中火', '大林木', '路傍土', '劍鋒金',
  '山頭火', '澗下水', '城頭土', '白蠟金', '楊柳木',
  '泉中水', '屋上土', '霹靂火', '松柏木', '長流水',
  '砂中金', '山下火', '平地木', '壁上土', '金箔金',
  '覆燈火', '天河水', '大驛土', '釵釧金', '桑柘木',
  '大溪水', '砂中土', '天上火', '石榴木', '大海水',
];

const _nayinOhaeng = [
  '금', '화', '목', '토', '금',
  '화', '수', '토', '금', '목',
  '수', '토', '화', '목', '수',
  '금', '화', '목', '토', '금',
  '화', '수', '토', '금', '목',
  '수', '토', '화', '목', '수',
];

/// [nayinFor]의 반환 타입 — 이름(한글)·한자·오행 3필드.
typedef Nayin = ({String name, String hanja, String ohaeng});

/// [ganzhiIndex60](60갑자 인덱스, 0~59)에 대응하는 납음오행을 조회한다.
/// `~/ 2`로 60개를 30개 조로 묶고(같은 조 2개 간지는 항상 같은 납음), 범위를
/// 벗어난 값이 들어와도 안전하도록 `% 30`으로 한 번 더 접는다.
Nayin nayinFor(int ganzhiIndex60) {
  final idx = (ganzhiIndex60 ~/ 2) % 30;
  return (name: _nayinNames[idx], hanja: _nayinHanja[idx], ohaeng: _nayinOhaeng[idx]);
}
