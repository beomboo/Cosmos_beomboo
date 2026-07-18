import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/core/storage/birth_info_store.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BirthInfoStore', () {
    test('저장된 정보가 없으면 load()는 null을 반환한다', () async {
      expect(await BirthInfoStore.load(), isNull);
    });

    test('저장한 값을 그대로 불러온다 (시간/이름/출생지/성별 포함)', () async {
      final info = BirthInfo(
        date: DateTime(1998, 8, 15),
        hour: 14,
        isLunar: true,
        name: '민지',
        birthPlace: '서울특별시',
        gender: Gender.female,
      );

      await BirthInfoStore.save(info);
      final loaded = await BirthInfoStore.load();

      expect(loaded, isNotNull);
      expect(loaded!.date, DateTime(1998, 8, 15));
      expect(loaded.hour, 14);
      expect(loaded.isLunar, isTrue);
      expect(loaded.name, '민지');
      expect(loaded.birthPlace, '서울특별시');
      expect(loaded.gender, Gender.female);
    });

    test('성별이 male이어도 정확히 저장/복원된다', () async {
      final info = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, gender: Gender.male);

      await BirthInfoStore.save(info);
      final loaded = await BirthInfoStore.load();

      expect(loaded!.gender, Gender.male);
    });

    test('시간을 모르는 경우(hour: null)와 이름/출생지/성별 없음도 정확히 저장/복원된다', () async {
      final info = BirthInfo(date: DateTime(2000, 1, 1), hour: null, isLunar: false);

      await BirthInfoStore.save(info);
      final loaded = await BirthInfoStore.load();

      expect(loaded!.hour, isNull);
      expect(loaded.name, isNull);
      expect(loaded.birthPlace, isNull);
      expect(loaded.gender, isNull);
    });

    test('clear() 이후에는 load()가 다시 null을 반환한다', () async {
      await BirthInfoStore.save(BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false));
      expect(await BirthInfoStore.load(), isNotNull);

      await BirthInfoStore.clear();
      expect(await BirthInfoStore.load(), isNull);
    });

    test('분(minute)도 함께 저장/복원된다', () async {
      final info = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, minute: 37, isLunar: false);

      await BirthInfoStore.save(info);
      final loaded = await BirthInfoStore.load();

      expect(loaded!.minute, 37);
    });

    test('minute을 넘기지 않으면(hour만 있음) null로 저장/복원된다', () async {
      final info = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

      await BirthInfoStore.save(info);
      final loaded = await BirthInfoStore.load();

      expect(loaded!.hour, 14);
      expect(loaded.minute, isNull);
    });

    test('다시 저장하면 이전 값을 덮어쓴다 (시간 있음 → 없음)', () async {
      await BirthInfoStore.save(BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false));
      await BirthInfoStore.save(BirthInfo(date: DateTime(2000, 1, 1), hour: null, isLunar: true));

      final loaded = await BirthInfoStore.load();
      expect(loaded!.date, DateTime(2000, 1, 1));
      expect(loaded.hour, isNull);
      expect(loaded.isLunar, isTrue);
    });

    test('혈액형(BloodType)도 Gender와 같은 방식으로 정확히 저장/복원된다 (round-trip)', () async {
      // 2026-07-19 추가: BloodType이 BirthInfo에 새로 생긴 필드(W1) — Gender와
      // 나란한 enum-name 기반 저장 방식을 그대로 따르는지 값으로 확인한다. 네 값
      // 모두(A/B/AB/O) 저장 → 로드 후 정확히 같은 값으로 돌아오는지 확인한다.
      for (final bloodType in BloodType.values) {
        final info = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, bloodType: bloodType);

        await BirthInfoStore.save(info);
        final loaded = await BirthInfoStore.load();

        expect(loaded!.bloodType, bloodType, reason: '$bloodType round-trip');
      }
    });

    test('혈액형을 지정하지 않으면(null) 저장/복원 후에도 null이다', () async {
      final info = BirthInfo(date: DateTime(2000, 1, 1), hour: null, isLunar: false);

      await BirthInfoStore.save(info);
      final loaded = await BirthInfoStore.load();

      expect(loaded!.bloodType, isNull);
    });

    test('clear() 이후에는 혈액형도 함께 지워진다', () async {
      await BirthInfoStore.save(
        BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, bloodType: BloodType.ab),
      );
      expect((await BirthInfoStore.load())!.bloodType, BloodType.ab);

      await BirthInfoStore.clear();
      expect(await BirthInfoStore.load(), isNull);
    });

    test('저장된 혈액형 문자열이 현재 BloodType enum 값과 일치하지 않으면 예외 없이 null로 복원된다', () async {
      // 위 "저장된 성별 문자열이..." 테스트와 같은 이유(Gender.asNameMap과 동일한
      // 안전한 조회 방식을 BloodType에도 그대로 적용했는지 확인).
      SharedPreferences.setMockInitialValues({
        'birth_info.date_millis': DateTime(1998, 8, 15).millisecondsSinceEpoch,
        'birth_info.is_lunar': false,
        'birth_info.blood_type': 'legacy_value_not_in_enum',
      });

      final loaded = await BirthInfoStore.load();

      expect(loaded, isNotNull);
      expect(loaded!.bloodType, isNull);
    });

    test('저장된 성별 문자열이 현재 Gender enum 값과 일치하지 않으면 예외 없이 null로 복원된다', () async {
      // load()는 `Gender.values.asNameMap()[genderName]`로 성별을 복원하는데, 이건
      // Map 조회라 못 찾으면 null을 돌려줄 뿐 예외를 던지지 않는다 — 만약 나중에 누군가
      // `Gender.values.byName(genderName)`(값이 없으면 ArgumentError를 던짐)으로 무심코
      // 바꾸면 이 안전성이 조용히 깨질 수 있다. 실제로 이런 상황이 생기는 현실적 경로는
      // Gender enum 값 이름 자체가 나중에 바뀌는 경우(예: 'female' → 다른 이름)인데, 그러면
      // 이전에 저장돼 있던 기기의 값("female")은 새 enum과 이름이 안 맞게 된다 — 이 테스트는
      // 실제 enum을 바꾸는 대신, SharedPreferences에 저장소가 쓰는 것과 같은 키로 존재하지
      // 않는 이름을 직접 넣어 같은 상황을 재현한다.
      SharedPreferences.setMockInitialValues({
        'birth_info.date_millis': DateTime(1998, 8, 15).millisecondsSinceEpoch,
        'birth_info.is_lunar': false,
        'birth_info.gender': 'nonbinary_legacy_value_not_in_enum',
      });

      final loaded = await BirthInfoStore.load();

      expect(loaded, isNotNull);
      expect(loaded!.gender, isNull);
    });
  });
}
