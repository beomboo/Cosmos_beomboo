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

  @override
  String toString() => label;
}
