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
