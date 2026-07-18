import 'package:shared_preferences/shared_preferences.dart';

import '../../features/birth_input/birth_info.dart';

/// 마지막으로 입력한 생년월일시(BirthInfo)를 기기에 저장/조회/삭제한다.
/// 앱을 다시 열었을 때 온보딩부터 다시 하지 않고 바로 결과 화면으로 갈 수 있게 하기 위함.
abstract final class BirthInfoStore {
  static const _keyDate = 'birth_info.date_millis';
  static const _keyHour = 'birth_info.hour';
  static const _keyMinute = 'birth_info.minute';
  static const _keyIsLunar = 'birth_info.is_lunar';
  static const _keyName = 'birth_info.name';
  static const _keyBirthPlace = 'birth_info.birth_place';
  static const _keyGender = 'birth_info.gender';
  static const _keyBloodType = 'birth_info.blood_type';

  static Future<void> save(BirthInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDate, info.date.millisecondsSinceEpoch);
    await prefs.setBool(_keyIsLunar, info.isLunar);
    if (info.hour != null) {
      await prefs.setInt(_keyHour, info.hour!);
    } else {
      await prefs.remove(_keyHour);
    }
    if (info.minute != null) {
      await prefs.setInt(_keyMinute, info.minute!);
    } else {
      await prefs.remove(_keyMinute);
    }
    if (info.name != null) {
      await prefs.setString(_keyName, info.name!);
    } else {
      await prefs.remove(_keyName);
    }
    if (info.birthPlace != null) {
      await prefs.setString(_keyBirthPlace, info.birthPlace!);
    } else {
      await prefs.remove(_keyBirthPlace);
    }
    if (info.gender != null) {
      await prefs.setString(_keyGender, info.gender!.name);
    } else {
      await prefs.remove(_keyGender);
    }
    if (info.bloodType != null) {
      await prefs.setString(_keyBloodType, info.bloodType!.name);
    } else {
      await prefs.remove(_keyBloodType);
    }
  }

  /// 저장된 정보가 없으면 null.
  static Future<BirthInfo?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dateMillis = prefs.getInt(_keyDate);
    if (dateMillis == null) return null;

    final genderName = prefs.getString(_keyGender);
    final bloodTypeName = prefs.getString(_keyBloodType);

    return BirthInfo(
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      hour: prefs.getInt(_keyHour),
      minute: prefs.getInt(_keyMinute),
      isLunar: prefs.getBool(_keyIsLunar) ?? false,
      name: prefs.getString(_keyName),
      birthPlace: prefs.getString(_keyBirthPlace),
      gender: genderName == null
          ? null
          : Gender.values.asNameMap()[genderName],
      bloodType: bloodTypeName == null
          ? null
          : BloodType.values.asNameMap()[bloodTypeName],
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDate);
    await prefs.remove(_keyHour);
    await prefs.remove(_keyMinute);
    await prefs.remove(_keyIsLunar);
    await prefs.remove(_keyName);
    await prefs.remove(_keyBirthPlace);
    await prefs.remove(_keyGender);
    await prefs.remove(_keyBloodType);
  }
}
