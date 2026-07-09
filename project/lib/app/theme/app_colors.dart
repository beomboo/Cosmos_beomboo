import 'package:flutter/material.dart';

/// 파스텔 큐트 컨셉 색상 토큰.
/// 출처: docs/mockups/01-pastel-cute.html의 `--app-*` 고정 팔레트
/// (뷰어의 시스템 다크/라이트 모드와 무관하게 앱 자체는 항상 밝은 파스텔 톤을 유지한다).
abstract final class AppColors {
  static const bg = Color(0xFFFFFBF5);
  static const bgCard = Color(0xFFFFFFFF);
  static const ink = Color(0xFF3A2E33);

  /// 목업 원안(#9A8790)에서 `bg`/`bgCard` 위 텍스트로 쓰기엔 WCAG AA(4.5:1) 대비가
  /// 3.3:1 정도로 미달이라(작은 캡션 텍스트 다수에 이 색을 씀), 같은 톤을 유지한 채
  /// `ink` 쪽으로 30% 더 짙게 조정해 4.7~4.9:1을 확보했다. 시각적 톤은 사실상 동일하다.
  static const inkSoft = Color(0xFF7D6C74);
  static const border = Color(0xFFF1E4DC);

  static const accent = Color(0xFFFF6B8A);
  static const accentSoft = Color(0xFFFFE1E8);
  static const accentInk = Color(0xFFFFFFFF);

  /// `accent`를 배경이 아니라 텍스트로 쓸 때(예: 온보딩 워드마크) 대신 쓰는 진한 버전.
  /// `ohaengTextColors`와 같은 방식(ink 쪽으로 48% 블렌드)으로 `bg`/`bgCard`/`accentSoft`
  /// 위에서 모두 WCAG AA 4.5:1을 만족하도록 계산했다. `accent` 자체(브랜드 버튼 배경 등)는
  /// 그대로 둔다 — 버튼 배경 위 흰 텍스트(대비 미달) 문제는 별개로 사람 결정 대기 중.
  static const accentText = Color(0xFFA04E60);

  /// 오행(五行) 포인트 컬러 — 배경/아이콘/그래프 채우기 등 "면적"으로 쓰는 용도.
  /// 작은 글자 색으로 쓰면 WCAG AA(4.5:1) 대비를 못 맞춰서, 텍스트에는 반드시
  /// 아래 `ohaengTextColors`(같은 톤을 유지한 채 더 짙게 조정한 버전)를 대신 쓴다.
  static const wood = Color(0xFF5FA47B);
  static const woodSoft = Color(0xFFD8F0E2);
  static const fire = Color(0xFFF0775F);
  static const fireSoft = Color(0xFFFFE1D8);
  static const earth = Color(0xFFC99A34);
  static const earthSoft = Color(0xFFFBEBCC);
  static const metal = Color(0xFF8F6FD1);
  static const metalSoft = Color(0xFFEAE0FA);
  static const water = Color(0xFF3F8FCB);
  static const waterSoft = Color(0xFFD9ECFA);

  /// 오행 이름(한자 1자) → 포인트 컬러 매핑.
  /// 2026-07-08 확인: 현재 화면 위젯들은 전부 `ohaengSoftColors`/`ohaengTextColors`만
  /// 쓰고 이 원색 맵은 실제 앱 화면 어디서도 참조하지 않는다 — 유일한 소비처는
  /// `test/tool/generate_app_icon.dart`(앱 아이콘 생성 도구)라, `cardTheme`처럼 완전히
  /// 죽은 코드는 아니다(제거하면 아이콘 생성이 깨짐). `wood`/`fire`/`water`도 이 맵을
  /// 통해서만 쓰이는 간접 참조라 마찬가지다(`earth`/`metal`은 이 맵 밖에서도 직접 쓰임).
  static const Map<String, Color> ohaengColors = {
    '목': wood,
    '화': fire,
    '토': earth,
    '금': metal,
    '수': water,
  };

  static const Map<String, Color> ohaengSoftColors = {
    '목': woodSoft,
    '화': fireSoft,
    '토': earthSoft,
    '금': metalSoft,
    '수': waterSoft,
  };

  /// `ohaengColors`를 텍스트(한자/글자 라벨 등)로 쓸 때 대신 쓰는 진한 버전.
  /// `bg`/`bgCard`뿐 아니라 각 오행의 `ohaengSoftColors` 배경 위에서도(더 엄격한 쪽 기준)
  /// WCAG AA 4.5:1을 만족하도록 `ink` 쪽으로 34~49% 블렌드해 계산했다(참고: `inkSoft`와
  /// 같은 방식). 원래 톤은 유지되므로 배경/아이콘 등 면적 용도의 `ohaengColors`는 그대로 둔다.
  static const woodText = Color(0xFF4F705B);
  static const fireText = Color(0xFF99544A);
  static const earthText = Color(0xFF836534);
  static const metalText = Color(0xFF72599B);
  static const waterText = Color(0xFF3D6C94);

  static const Map<String, Color> ohaengTextColors = {
    '목': woodText,
    '화': fireText,
    '토': earthText,
    '금': metalText,
    '수': waterText,
  };
}
