/// 오행(五行)별 영역 풀이(연애·재물·건강·성격) 규칙 텍스트 + 우세(dominant)/2순위(sub)
/// 오행 조합 콜아웃·카테고리 접미사.
///
/// 실제 AI 해석 연동 전까지 쓰는 결정론적 placeholder — 사주 8자 전체를 분석하는 것이 아니라
/// 가장 우세한 오행(과 그다음으로 우세한 오행 하나)에 따라 미리 써둔 문구를 고르는 간단한
/// 규칙 기반이다. 참고: docs/mockups/01-pastel-cute.html STEP 4 카테고리 카드,
/// docs/research/02_경쟁앱_분석(캐주얼한 톤이 반응이 좋다는 성공 공식)
library;

import '../../core/saju/ganzhi.dart';

const Map<String, List<(String icon, String title, String desc)>> categoryReadingsByOhaeng = {
  '목': [
    ('💘', '연애운', '적극적으로 다가가면 좋은 인연이 생기는 시기예요'),
    ('💰', '재물운', '새로운 시도가 돈이 되는 타이밍이에요'),
    ('🌱', '건강운', '활동량이 많아지는 만큼 충분히 쉬어주세요'),
    ('🎭', '성격', '추진력 갑, 시작은 빠르고 화끈해요'),
  ],
  '화': [
    ('💘', '연애운', '매력이 넘쳐서 자연스럽게 인기가 많아져요'),
    ('💰', '재물운', '표현력을 살린 부업이나 홍보가 잘 통해요'),
    ('🌱', '건강운', '텐션이 높은 만큼 방전되지 않게 페이스 조절이 필요해요'),
    ('🎭', '성격', '밝고 열정적인 분위기 메이커 타입이에요'),
  ],
  '토': [
    ('💘', '연애운', '천천히 신뢰를 쌓는 관계가 잘 맞아요'),
    ('💰', '재물운', '무리한 투자보다 꾸준한 저축이 유리해요'),
    ('🌱', '건강운', '소화기 계통 컨디션을 특히 잘 챙기면 좋아요'),
    ('🎭', '성격', '믿음직하고 중심을 잘 잡아주는 타입이에요'),
  ],
  '금': [
    ('💘', '연애운', '눈이 높은 편이라 확실한 상대를 알아보는 시기예요'),
    ('💰', '재물운', '계획적으로 관리하면 돈이 잘 모이는 편이에요'),
    ('🌱', '건강운', '호흡기·피부 컨디션을 신경 쓰면 좋아요'),
    ('🎭', '성격', '원칙적이고 맺고 끊음이 확실한 타입이에요'),
  ],
  '수': [
    ('💘', '연애운', '은근한 매력으로 다가오는 인연이 있어요'),
    ('💰', '재물운', '정보력을 활용하면 좋은 기회를 잡을 수 있어요'),
    ('🌱', '건강운', '컨디션 기복이 있는 편이니 수분 섭취를 챙기세요'),
    ('🎭', '성격', '유연하고 눈치가 빠른 지략가 타입이에요'),
  ],
};

/// [dominantOhaeng]에 맞는 4개 영역 풀이를 반환한다. 알 수 없는 값이면 '토'를 기본값으로 쓴다.
/// **주의**: report_screen.dart의 "오행별 오늘의 풀이 모음"(백과사전 섹션)이 이 함수를 직접
/// 쓰므로, 콤보(2순위 오행 반영) 로직을 여기 얹지 말 것 — 그건 [categoryReadingsForCombo].
List<(String icon, String title, String desc)> categoryReadingsFor(String dominantOhaeng) =>
    categoryReadingsByOhaeng[dominantOhaeng] ?? categoryReadingsByOhaeng['토']!;

/// 오행 한자 + 이모지 + 단독-우세 콜아웃 문구.
/// 2순위(sub) 오행이 사실상 없을 때(`subCount == 0`) [dominantComboCallout]이 이쪽으로
/// 폴백한다. 원래 result_screen.dart 안에 있던 `_ohaengCallout`을 콤보 함수와 같은 파일에서
/// 함께 관리하도록 옮겨왔다(여러 파일에 흩어지면 한쪽만 고쳤을 때 어긋나는 회귀가 생기기 쉬움).
final Map<String, (String hanja, String emoji, String text)> _singleOhaengCallout = {
  '목': (ohaengHanja['목']!, '🌿', '새로운 걸 벌이는 힘이 넘쳐요'),
  '화': (ohaengHanja['화']!, '🔥', '표현력과 인기운이 좋아요'),
  '토': (ohaengHanja['토']!, '🪵', '안정감 있고 신뢰를 줘요'),
  '금': (ohaengHanja['금']!, '✨', '원칙적이고 결단력 있어요'),
  '수': (ohaengHanja['수']!, '💧', '유연하고 통찰력이 뛰어나요'),
};

/// 우세(dominant) × 2순위(sub) 오행 조합별 콜아웃 문구 20가지(5 dominant × 4 관계).
/// [OhaengRelation]이 dominant 기준으로 sub와의 관계를 4종으로 분류하는데, dominant가
/// 고정되면 관계 4종은 서로 다른 sub 4개(나머지 오행 전부)에 정확히 하나씩 대응하므로
/// 이 맵은 5×4=20개 (dominant, sub) 조합 전부를 커버한다.
final Map<String, Map<String, (String hanja, String emoji, String text)>> _comboCallout = {
  '목': {
    '화': (ohaengHanja['목']!, '🌿', '화 기운이 화르르 옮겨붙어서 아이디어가 곧장 행동으로 이어져요. 시작한 일에 속도가 붙는 타입이에요'),
    '토': (ohaengHanja['목']!, '🌿', '목 기운이 토 기운을 다잡아서 하고 싶은 대로 밀어붙이는 힘이 세요. 다만 주변 페이스까지 살피면 더 좋아요'),
    '금': (ohaengHanja['목']!, '🌿', '금 기운이 앞서가려는 마음에 살짝 브레이크를 걸어줘요. 그 덕에 무모한 결정은 줄어드는 편이에요'),
    '수': (ohaengHanja['목']!, '🌿', '수 기운이 물을 대주듯 뒤를 받쳐줘서 아이디어가 마르지 않고 계속 샘솟아요. 뿌리가 튼튼해 오래가는 힘이에요'),
  },
  '화': {
    '토': (ohaengHanja['화']!, '🔥', '화 기운이 토 기운을 데워줘서 열정이 안정적인 결과로 차곡차곡 쌓여가요'),
    '수': (ohaengHanja['화']!, '🔥', '수 기운이 화 기운을 차분히 식혀줘서 욱하는 마음이 한 박자 늦게 터져요. 감정 기복이 조절되는 편이에요'),
    '금': (ohaengHanja['화']!, '🔥', '화 기운이 금 기운을 녹여내는 힘이 있어서 원칙적인 상대도 결국 내 페이스로 끌어들여요'),
    '목': (ohaengHanja['화']!, '🔥', '목 기운이 계속 불씨를 지펴줘서 열정이 쉽게 꺼지지 않고 오래 타올라요'),
  },
  '토': {
    '금': (ohaengHanja['토']!, '🪵', '토 기운이 금 기운을 다져줘서 안정감 속에서도 결단력이 은근히 빛나요'),
    '목': (ohaengHanja['토']!, '🪵', '목 기운이 토 기운을 흔들어서 안정만 좇던 마음에 새로운 자극이 생겨요. 변화가 나쁘지만은 않아요'),
    '수': (ohaengHanja['토']!, '🪵', '토 기운이 수 기운을 다잡아서 흔들리는 마음도 결국 안정적으로 정리해내요'),
    '화': (ohaengHanja['토']!, '🪵', '화 기운이 은은하게 힘을 보태서 묵묵한 안정감에 생기가 더해져요'),
  },
  '금': {
    '수': (ohaengHanja['금']!, '✨', '금 기운이 수 기운에 힘을 실어줘서 원칙 위에 유연한 지혜까지 더해져요'),
    '화': (ohaengHanja['금']!, '✨', '화 기운이 금 기운을 살짝 녹여줘서 딱딱하던 태도에 뜻밖의 부드러움이 생겨요'),
    '목': (ohaengHanja['금']!, '✨', '금 기운이 목 기운을 정리해줘서 벌여둔 일을 야무지게 마무리 짓는 힘이 있어요'),
    '토': (ohaengHanja['금']!, '✨', '토 기운이 든든하게 받쳐줘서 원칙이 흔들리지 않고 오래가요'),
  },
  '수': {
    '목': (ohaengHanja['수']!, '💧', '수 기운이 목 기운을 키워줘서 통찰력이 새로운 시도로 술술 이어져요'),
    '화': (ohaengHanja['수']!, '💧', '수 기운이 화 기운을 가라앉혀줘서 순간의 감정보다 차분한 판단이 앞서요'),
    '토': (ohaengHanja['수']!, '💧', '토 기운이 수 기운을 붙잡아줘서 이리저리 흔들리던 마음에 중심이 생겨요'),
    '금': (ohaengHanja['수']!, '💧', '금 기운이 원천이 되어줘서 유연함 속에 단단한 원칙까지 갖추게 돼요'),
  },
};

/// [dominant] 단독 또는 [dominant]+[sub] 조합에 맞는 콜아웃 문구(한자·이모지·설명)를 고른다.
///
/// [subCount]가 0이면(2순위 오행이 사실상 없는 엣지케이스, [FourPillars.subDominantOhaeng]
/// doc-comment 참고) [_singleOhaengCallout]로 폴백한다. 그 외에는 [_comboCallout]에서
/// (dominant, sub) 조합 전용 문구를 찾고, 혹시라도 못 찾으면(알 수 없는 오행값 등) 역시
/// 단독 문구로, 그마저 없으면 '토'로 순서대로 폴백한다.
(String hanja, String emoji, String text) dominantComboCallout(
  String dominant,
  String sub, {
  required int subCount,
}) {
  if (subCount > 0) {
    final combo = _comboCallout[dominant]?[sub];
    if (combo != null) return combo;
  }
  return _singleOhaengCallout[dominant] ?? _singleOhaengCallout['토']!;
}

/// 관계 4종([OhaengRelation])에 대응하는 공용 접미사. dominant/sub 오행 이름만 문자열로
/// 채워 넣어 문장 뒤에 이어붙이는 범용 함수다. 이 파일 안에서는 카테고리 카드 4개(연애·재물·
/// 건강·성격) 설명 뒤에, `deep_dive_readings.dart`에서는 심층 분석 직장운 설명 뒤에 각각
/// 이어붙이는 식으로 두 곳에서 공유해서 쓴다.
String ohaengComboSuffix(OhaengRelation relation, String sub) {
  switch (relation) {
    case OhaengRelation.dominantGeneratesSub:
      return '$sub 기운까지 힘을 보태서 이 흐름이 한층 살아나요';
    case OhaengRelation.subGeneratesDominant:
      return '$sub 기운이 뒤에서 든든하게 받쳐줘서 이 흐름이 오래 유지돼요';
    case OhaengRelation.dominantOvercomesSub:
      return '$sub 기운을 잘 다스리는 편이라 중심을 잃지 않아요';
    case OhaengRelation.subOvercomesDominant:
      return '$sub 기운이 브레이크가 되어줘서 과하지 않게 조절이 돼요';
  }
}

/// [dominant] 단독 또는 [dominant]+[sub] 조합에 맞는 4개 영역(연애·재물·건강·성격) 풀이를
/// 반환한다.
///
/// [subCount]가 0이면 [categoryReadingsFor]의 결과를 그대로 반환한다(기존 단일-오행 동작과
/// 완전히 동일). 그 외에는 각 카드 설명 뒤에 관계 4종([OhaengRelation])에 대응하는 공용
/// 접미사 한 문장을 이어붙인다.
List<(String icon, String title, String desc)> categoryReadingsForCombo(
  String dominant,
  String sub, {
  required int subCount,
}) {
  final base = categoryReadingsFor(dominant);
  if (subCount == 0) return base;

  final relation = ohaengRelationOf(dominant, sub);
  final suffix = ohaengComboSuffix(relation, sub);
  return [
    for (final (icon, title, desc) in base) (icon, title, '$desc. $suffix'),
  ];
}
