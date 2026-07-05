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

    final eiName = prefs.getString(_keyMbtiEi);
    final snName = prefs.getString(_keyMbtiSn);
    final tfName = prefs.getString(_keyMbtiTf);
    final jpName = prefs.getString(_keyMbtiJp);
    final mbti = (eiName != null && snName != null && tfName != null && jpName != null)
        ? Mbti(
            ei: MbtiEi.values.asNameMap()[eiName]!,
            sn: MbtiSn.values.asNameMap()[snName]!,
            tf: MbtiTf.values.asNameMap()[tfName]!,
            jp: MbtiJp.values.asNameMap()[jpName]!,
          )
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
