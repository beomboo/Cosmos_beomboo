import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/core/storage/deep_dive_info_store.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_info.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeepDiveInfoStore', () {
    test('저장된 정보가 없으면(첫 방문) load()는 null을 반환한다', () async {
      expect(await DeepDiveInfoStore.load(), isNull);
    });

    test('관심사만 저장해도(MBTI 없이) 그대로 불러온다', () async {
      const info = DeepDiveInfo(interests: {Interest.love, Interest.career});

      await DeepDiveInfoStore.save(info);
      final loaded = await DeepDiveInfoStore.load();

      expect(loaded, isNotNull);
      expect(loaded!.interests, {Interest.love, Interest.career});
      expect(loaded.mbti, isNull);
    });

    test('MBTI 네 축을 포함해 저장하면 정확히 복원된다', () async {
      const mbti = Mbti(ei: MbtiEi.i, sn: MbtiSn.n, tf: MbtiTf.t, jp: MbtiJp.j);
      const info = DeepDiveInfo(mbti: mbti, interests: {Interest.health});

      await DeepDiveInfoStore.save(info);
      final loaded = await DeepDiveInfoStore.load();

      expect(loaded!.mbti, isNotNull);
      expect(loaded.mbti!.code, 'INTJ');
      expect(loaded.interests, {Interest.health});
    });

    test('관심사를 전부 꺼서 저장해도(빈 Set) — 첫 방문(null)과 구분된다', () async {
      // load()가 null(첫 방문)과 "저장은 됐지만 관심사가 비어 있음"을 구분하지
      // 못하면, 사용자가 의도적으로 전부 해제한 선택이 다음 방문 때 "전체 선택"
      // 기본값으로 되돌아가 버리는 실제 버그가 된다.
      const info = DeepDiveInfo();

      await DeepDiveInfoStore.save(info);
      final loaded = await DeepDiveInfoStore.load();

      expect(loaded, isNotNull);
      expect(loaded!.interests, isEmpty);
    });

    test('clear() 이후에는 load()가 다시 null을 반환한다', () async {
      await DeepDiveInfoStore.save(const DeepDiveInfo(interests: {Interest.wealth}));
      expect(await DeepDiveInfoStore.load(), isNotNull);

      await DeepDiveInfoStore.clear();
      expect(await DeepDiveInfoStore.load(), isNull);
    });

    test('다시 저장하면 이전 값을 덮어쓴다(MBTI 있음 → 없음)', () async {
      const withMbti = DeepDiveInfo(
        mbti: Mbti(ei: MbtiEi.e, sn: MbtiSn.s, tf: MbtiTf.t, jp: MbtiJp.j),
        interests: {Interest.love},
      );
      const withoutMbti = DeepDiveInfo(interests: {Interest.health, Interest.career});

      await DeepDiveInfoStore.save(withMbti);
      await DeepDiveInfoStore.save(withoutMbti);

      final loaded = await DeepDiveInfoStore.load();
      expect(loaded!.mbti, isNull);
      expect(loaded.interests, {Interest.health, Interest.career});
    });
  });
}
