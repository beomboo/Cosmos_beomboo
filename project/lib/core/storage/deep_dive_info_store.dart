import 'package:shared_preferences/shared_preferences.dart';

import '../../features/deep_dive/deep_dive_info.dart';

/// 마지막으로 입력한 심층 분석 정보(MBTI·관심사)를 기기에 저장/조회/삭제한다.
/// `BirthInfoStore`와 같은 패턴 — 심층 분석 화면을 다시 열었을 때 매번 처음부터
/// 다시 고르지 않고 이전 선택을 이어서 볼 수 있게 하기 위함.
abstract final class DeepDiveInfoStore {
  static const _keyInterests = 'deep_dive_info.interests';
  static const _keyMbtiEi = 'deep_dive_info.mbti_ei';
  static const _keyMbtiSn = 'deep_dive_info.mbti_sn';
  static const _keyMbtiTf = 'deep_dive_info.mbti_tf';
  static const _keyMbtiJp = 'deep_dive_info.mbti_jp';

  static Future<void> save(DeepDiveInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyInterests,
      info.interests.map((i) => i.name).toList(),
    );
    final mbti = info.mbti;
    if (mbti != null) {
      await prefs.setString(_keyMbtiEi, mbti.ei.name);
      await prefs.setString(_keyMbtiSn, mbti.sn.name);
      await prefs.setString(_keyMbtiTf, mbti.tf.name);
      await prefs.setString(_keyMbtiJp, mbti.jp.name);
    } else {
      await prefs.remove(_keyMbtiEi);
      await prefs.remove(_keyMbtiSn);
      await prefs.remove(_keyMbtiTf);
      await prefs.remove(_keyMbtiJp);
    }
  }

  /// 저장된 정보가 한 번도 없으면 null(첫 방문). 관심사를 전부 껐다가 저장한
  /// 경우처럼 "저장은 됐지만 관심사가 비어 있는" 상태와는 구분된다.
  static Future<DeepDiveInfo?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final interestNames = prefs.getStringList(_keyInterests);
    if (interestNames == null) return null;

    final interestsByName = Interest.values.asNameMap();
    final interests = interestNames
        .map((name) => interestsByName[name])
        .whereType<Interest>()
        .toSet();

    // interests와 마찬가지로 asNameMap()[]로 조회하되 `!`(null 단언)는 쓰지 않는다 —
    // 저장된 문자열이 현재 enum 값 이름과 하나라도 안 맞으면(예: 향후 MBTI 축 이름이
    // 바뀌는 경우) null-check 예외를 던지는 대신 mbti 전체를 null(모름)로 취급해
    // BirthInfoStore.load()의 성별 복원과 같은 방식으로 안전하게 무시한다.
    final ei = MbtiEi.values.asNameMap()[prefs.getString(_keyMbtiEi)];
    final sn = MbtiSn.values.asNameMap()[prefs.getString(_keyMbtiSn)];
    final tf = MbtiTf.values.asNameMap()[prefs.getString(_keyMbtiTf)];
    final jp = MbtiJp.values.asNameMap()[prefs.getString(_keyMbtiJp)];
    final mbti = (ei != null && sn != null && tf != null && jp != null)
        ? Mbti(ei: ei, sn: sn, tf: tf, jp: jp)
        : null;

    return DeepDiveInfo(mbti: mbti, interests: interests);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInterests);
    await prefs.remove(_keyMbtiEi);
    await prefs.remove(_keyMbtiSn);
    await prefs.remove(_keyMbtiTf);
    await prefs.remove(_keyMbtiJp);
  }
}
