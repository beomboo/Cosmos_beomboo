/// MBTI·관심사 기반 심층 분석 입력 데이터.
/// 참고: PROGRESS.md의 "심층 분석(1단계)" 항목 — 오행 × MBTI × 관심사를 전부 곱한
/// 조합(수백 가지)을 손으로 쓰는 대신, MBTI는 오행과 무관한 독립 코멘트 한 줄로,
/// 관심사는 기존 오행별 카테고리 풀이를 재사용하는 조합형 방식으로 시작한다.
library;

/// MBTI 외향/내향 축.
enum MbtiEi { e, i }

/// MBTI 감각/직관 축.
enum MbtiSn { s, n }

/// MBTI 사고/감정 축.
enum MbtiTf { t, f }

/// MBTI 판단/인식 축.
enum MbtiJp { j, p }

/// 네 축을 모두 알아야 의미가 있으므로 하나로 묶는다. 입력 화면에서
/// "MBTI를 알고 있어요" 체크가 꺼져 있으면 [DeepDiveInfo.mbti] 자체가 null이 된다.
class Mbti {
  const Mbti({required this.ei, required this.sn, required this.tf, required this.jp});

  final MbtiEi ei;
  final MbtiSn sn;
  final MbtiTf tf;
  final MbtiJp jp;

  /// 예: "INTJ"
  String get code => '${ei.name}${sn.name}${tf.name}${jp.name}'.toUpperCase();
}

/// 심층 분석에서 우선 보고 싶은 관심 영역.
/// '성격'은 항상 기본으로 보여주는 특성 설명이라 관심사 선택지에는 포함하지 않는다.
enum Interest {
  love('연애운', '💘'),
  wealth('재물운', '💰'),
  career('직장운', '💼'),
  health('건강운', '🌱');

  const Interest(this.categoryTitle, this.icon);

  /// `ohaeng_readings.dart`의 카테고리 제목과 매칭하기 위한 키(직장운은 별도 콘텐츠).
  final String categoryTitle;
  final String icon;
}

/// MBTI·관심사 입력 화면 → 심층 분석 결과 화면으로 넘기는 데이터.
class DeepDiveInfo {
  const DeepDiveInfo({this.mbti, this.interests = const {}});

  final Mbti? mbti;
  final Set<Interest> interests;
}
