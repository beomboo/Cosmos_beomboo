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

/// [interest] 관심사에 대한 [ohaeng] 오행 풀이 한 줄. 알 수 없는 오행이면 '토' 기본값.
String readingFor(Interest interest, String ohaeng) {
  if (interest == Interest.career) {
    return _careerReadingByOhaeng[ohaeng] ?? _careerReadingByOhaeng['토']!;
  }
  final categories = categoryReadingsByOhaeng[ohaeng] ?? categoryReadingsByOhaeng['토']!;
  return categories.firstWhere((c) => c.$2 == interest.categoryTitle).$3;
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
