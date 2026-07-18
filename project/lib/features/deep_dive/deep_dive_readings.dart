import '../../core/saju/ganzhi.dart';
import '../result/ohaeng_readings.dart';
import 'deep_dive_info.dart';

/// 직장운은 기존 결과/리포트 화면(연애·재물·건강·성격 4카테고리)에 없던 항목이라
/// 별도로 둔다. 연애·재물·건강은 `ohaeng_readings.dart`의 `categoryReadingsByOhaeng`를
/// 그대로 재사용한다 — 심층 분석 전용 콘텐츠를 최소화해 유지 부담을 줄이기 위함.
const Map<String, String> _careerReadingByOhaeng = {
  '목': '새 프로젝트나 이직처럼 확장하는 움직임이 잘 맞는 시기예요',
  '화': '적극적으로 어필하면 성과를 인정받기 좋은 타이밍이에요',
  '토': '묵묵히 맡은 역할을 다지면 신뢰를 얻는 타입이에요',
  '금': '원칙과 기준이 분명해서 책임 있는 자리가 잘 어울려요',
  '수': '상황 판단이 빨라 위기 속에서도 기회를 찾는 타입이에요',
};

/// [interest] 관심사에 대한 [dominant](+[sub]) 오행 풀이 한 줄. 알 수 없는 오행이면 '토' 기본값.
///
/// [subCount]가 0이면(2순위 오행이 사실상 없음 — `FourPillars.subDominantOhaeng` doc-comment
/// 참고) 결과 화면과 마찬가지로 dominant 단독 문구를 그대로 반환한다. 그 외에는 연애·재물·
/// 건강(카테고리 카드)과 직장운 모두 [ohaengComboSuffix](`ohaeng_readings.dart`, 결과 화면
/// 카테고리 카드와 공유하는 공용 함수)로 관계 4종에 대응하는 한 문장을 덧붙인다.
String readingFor(
  Interest interest,
  String dominant,
  String sub, {
  required int subCount,
}) {
  if (interest == Interest.career) {
    final base = _careerReadingByOhaeng[dominant] ?? _careerReadingByOhaeng['토']!;
    if (subCount == 0) return base;
    final relation = ohaengRelationOf(dominant, sub);
    return '$base. ${ohaengComboSuffix(relation, sub)}';
  }
  final categories = categoryReadingsForCombo(dominant, sub, subCount: subCount);
  // `Interest.categoryTitle`(deep_dive_info.dart)과 `categoryReadingsByOhaeng`의 제목
  // (ohaeng_readings.dart)은 서로 다른 파일의 문자열 리터럴이라 컴파일 타임 연결이
  // 없다 — 둘 중 하나만 바뀌면(예: 향후 "건강운"을 "건강 운"으로 오타 수정) 여기서
  // `StateError`가 나 심층 분석 결과 화면 전체가 크래시했을 것(2026-07-08 발견,
  // 같은 파일의 다른 조회들은 전부 기본값 폴백이 있는데 이것만 없었음).
  final match = categories.where((c) => c.$2 == interest.categoryTitle);
  return match.isEmpty ? categories.first.$3 : match.first.$3;
}

/// MBTI 16유형별 짧은 코멘트. 오행과 곱하면(5×16=80가지) 손으로 쓰기 어려워,
/// 오행과 무관하게 성향 자체에 대한 설명 한 줄만 독립적으로 얹는 방식으로 시작한다.
const Map<String, String> mbtiComments = {
  'INTJ': '치밀하게 그림을 그리고 움직이는 전략가 타입이에요',
  'INTP': '호기심을 따라가다 보면 남들이 못 본 답을 찾아내는 타입이에요',
  'ENTJ': '목표가 정해지면 거침없이 밀어붙이는 타입이에요',
  'ENTP': '즉흥적인 아이디어로 판을 뒤집는 걸 즐기는 타입이에요',
  'INFJ': '깊이 있는 통찰로 사람 마음을 잘 헤아리는 타입이에요',
  'INFP': '자기만의 가치관이 뚜렷해서 쉽게 흔들리지 않는 타입이에요',
  'ENFJ': '주변을 잘 챙기고 이끄는 데 자연스러운 재능이 있는 타입이에요',
  'ENFP': '에너지가 넘치고 새로운 인연·경험에 적극적인 타입이에요',
  'ISTJ': '한번 정한 원칙은 끝까지 지키는 믿음직한 타입이에요',
  'ISFJ': '조용히 곁을 지키며 챙겨주는 세심한 타입이에요',
  'ESTJ': '체계적으로 일을 정리하고 이끄는 데 능한 타입이에요',
  'ESFJ': '분위기를 살피고 사람들을 잘 챙기는 타입이에요',
  'ISTP': '실전에서 손으로 문제를 해결하는 데 강한 타입이에요',
  'ISFP': '자기만의 속도로 조용히 취향을 다져가는 타입이에요',
  'ESTP': '일단 부딪혀보며 그때그때 상황을 즐기는 타입이에요',
  'ESFP': '분위기 메이커답게 순간을 마음껏 즐길 줄 아는 타입이에요',
};

/// [mbtiCode]("INTJ" 등)에 해당하는 코멘트. null이거나 알 수 없는 코드면 null.
String? mbtiCommentFor(String? mbtiCode) => mbtiCode == null ? null : mbtiComments[mbtiCode];

/// MBTI 16유형별 짧은 별칭 — 목업(`docs/mockups/01-pastel-cute.html`)의 "ENFP · 스파크
/// 메이커"처럼 타입 코드 옆에 붙여 쓰는 2차 라벨이다. 16Personalities의 "형용사+역할
/// 은유" 네이밍(INTJ=Architect, ENFP=Campaigner 등) 관행을 참고하되, 실제 영단어를
/// 그대로 옮기지 않고 우리 앱 톤(캐주얼하되 존댓말·과장 없는 톤)에 맞는 한국어 별칭으로
/// 새로 지었다.
const Map<String, String> mbtiNicknames = {
  'INTJ': '전략가',
  'INTP': '아이디어 뱅크',
  'ENTJ': '추진력 대장',
  'ENTP': '발상 전환러',
  'INFJ': '통찰가',
  'INFP': '감성 소신파',
  'ENFJ': '인싸 리더',
  'ENFP': '스파크 메이커',
  'ISTJ': '원칙주의자',
  'ISFJ': '든든한 버팀목',
  'ESTJ': '실행대장',
  'ESFJ': '분위기 조율사',
  'ISTP': '만능 해결사',
  'ISFP': '마이웨이 아티스트',
  'ESTP': '액션파',
  'ESFP': '무대 체질',
};

/// [mbtiCode]("INTJ" 등)에 해당하는 별칭. null이거나 알 수 없는 코드면 null.
String? mbtiNicknameFor(String? mbtiCode) => mbtiCode == null ? null : mbtiNicknames[mbtiCode];
