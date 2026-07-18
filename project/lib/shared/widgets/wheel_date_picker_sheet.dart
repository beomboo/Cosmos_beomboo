import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 태어난 날짜를 고르는 3열(연/월/일) 스크롤 휠 피커 바텀시트를 띄운다.
/// docs/mockups/01-pastel-cute.html "생년월일 선택 UI — 스크롤 휠 피커로 교체" 시안대로,
/// 기존 "숫자 pill 3개 → 팝업 달력"(`showDatePicker`) 방식을 대신한다. 휠을 아무리
/// 돌려도 하단 "확인"을 눌러야만 그 값이 실제로 반영되고, "취소"를 누르거나 시트
/// 바깥을 탭해 닫으면 null을 반환해 기존 값을 그대로 유지한다(기존 `showDatePicker`와
/// 동일한 동작 — birth_input_screen.dart의 `_pickDate`가 반환값이 null이 아닐 때만
/// setState하는 이유).
Future<DateTime?> showWheelDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return _showWheelPickerSheet<DateTime>(
    context: context,
    initialValue: initialDate,
    pickerHeight: 216,
    pickerBuilder: (value, onChanged) => CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: value,
      minimumDate: firstDate,
      maximumDate: lastDate,
      onDateTimeChanged: onChanged,
    ),
  );
}

/// 태어난 시간을 고르는 2열(시/분) 스크롤 휠 피커 바텀시트를 띄운다. 위
/// [showWheelDatePicker]와 동일하게 "확인"을 눌러야만 값이 반영된다.
Future<TimeOfDay?> showWheelTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  // CupertinoDatePicker(time 모드)는 DateTime을 다루므로, 시/분만 의미 있는
  // TimeOfDay를 감싸기 위해 임의의 기준 날짜(오늘)를 붙였다가 반환값에서 다시
  // 시/분만 뽑아낸다 — 날짜 부분은 어차피 쓰이지 않는다.
  final now = DateTime.now();
  final initialDateTime = DateTime(now.year, now.month, now.day, initialTime.hour, initialTime.minute);
  final picked = await _showWheelPickerSheet<DateTime>(
    context: context,
    initialValue: initialDateTime,
    pickerHeight: 216,
    pickerBuilder: (value, onChanged) => CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      initialDateTime: value,
      onDateTimeChanged: onChanged,
    ),
  );
  if (picked == null) return null;
  return TimeOfDay(hour: picked.hour, minute: picked.minute);
}

/// [showWheelDatePicker]/[showWheelTimePicker]가 함께 쓰는 바텀시트 뼈대.
/// `CupertinoDatePicker`는 기기의 시스템 라이트/다크 모드를 따라가는데, 이 앱은
/// `main.dart`(`themeMode: ThemeMode.light`)에서 항상 밝은 파스텔 톤만 쓰기로
/// 고정했다 — 감싸지 않으면 기기가 다크 모드일 때 이 시트만 어두운 iOS 기본 톤으로
/// 나와 나머지 화면과 어긋난다. `CupertinoTheme`으로 명시적으로 라이트 톤을 강제한다.
Future<T?> _showWheelPickerSheet<T>({
  required BuildContext context,
  required T initialValue,
  required double pickerHeight,
  required Widget Function(T value, ValueChanged<T> onChanged) pickerBuilder,
}) {
  var current = initialValue;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  // 취소 — 아무 값도 반영하지 않고 시트만 닫는다(시트 바깥을 탭해
                  // 닫는 것과 동일한 동작).
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text(
                    '취소',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                  ),
                ),
                TextButton(
                  // 확인 — 여기까지 휠로 맞춰온 현재 값을 실제로 반영한다.
                  onPressed: () => Navigator.of(sheetContext).pop(current),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentText),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: pickerHeight,
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.light,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(fontSize: 18, color: AppColors.ink),
                  ),
                ),
                child: pickerBuilder(current, (value) => current = value),
              ),
            ),
          ],
        ),
      );
    },
  );
}
