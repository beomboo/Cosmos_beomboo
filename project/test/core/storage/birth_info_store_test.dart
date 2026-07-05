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
  });
}
