import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/shared/widgets/wheel_date_picker_sheet.dart';

/// wheel_date_picker_sheet.dart(showWheelDatePicker/showWheelTimePicker) 자체를
/// 겨냥한 위젯 테스트 — 지금까지 이 신규 공용 위젯을 직접 검증한 테스트가 없었고,
/// birth_input_screen_test.dart는 화면에 실제로 연결된 배선(_pickDate/_pickTime)만
/// 확인할 뿐 "확인"/"취소"/firstDate·lastDate 전달 같은 이 시트 자체의 계약은
/// 별도로 커버하지 않았다.
///
/// CupertinoDatePicker는 텍스트 입력 전환이나 특정 값을 직접 탭하는 방식이 없는
/// 순수 스크롤 휠이라, "휠로 값을 바꾼 뒤 확인" 시나리오는 실제 드래그 제스처
/// 대신 시트가 뜬 상태에서 CupertinoDatePicker 위젯을 찾아 onDateTimeChanged
/// 콜백을 직접 호출해 흉내낸다 — 이 콜백은 _showWheelPickerSheet가 "확인" 버튼이
/// 반환할 현재 값을 갱신하는 유일한 통로이므로, 콜백 호출 → 확인 탭 → 반환값까지
/// 이어지는 배선은 그대로 검증되지만 실제 손가락 스크롤 제스처 자체(휠이 물리적으로
/// 그 위치까지 도달하는지)는 이 방식으로는 검증하지 못한다.
void main() {
  group('showWheelDatePicker', () {
    Widget buildHost({
      required void Function(DateTime?) onResult,
      DateTime? initialDate,
      DateTime? firstDate,
      DateTime? lastDate,
    }) {
      return MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final picked = await showWheelDatePicker(
                  context: context,
                  initialDate: initialDate ?? DateTime(2000, 1, 1),
                  firstDate: firstDate ?? DateTime(1900),
                  lastDate: lastDate ?? DateTime(2030),
                );
                onResult(picked);
              },
              child: const Text('날짜 피커 열기'),
            ),
          ),
        ),
      );
    }

    testWidgets('휠을 건드리지 않고 "확인"만 눌러도 initialDate가 그대로 반환된다', (tester) async {
      DateTime? result;
      await tester.pumpWidget(buildHost(onResult: (v) => result = v, initialDate: DateTime(2005, 3, 4)));

      await tester.tap(find.text('날짜 피커 열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result, DateTime(2005, 3, 4));
    });

    testWidgets('휠로 값을 바꾼 뒤 "확인"을 누르면 바뀐 값이 반환된다 (onDateTimeChanged → 확인 배선)',
        (tester) async {
      DateTime? result;
      await tester.pumpWidget(buildHost(onResult: (v) => result = v, initialDate: DateTime(2000, 1, 1)));

      await tester.tap(find.text('날짜 피커 열기'));
      await tester.pumpAndSettle();

      final picker = tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
      picker.onDateTimeChanged(DateTime(2010, 6, 15));
      await tester.pump();

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result, DateTime(2010, 6, 15));
    });

    testWidgets('휠로 값을 바꿔도 "취소"를 누르면 null이 반환된다 (바뀐 값이 새어나가지 않음)',
        (tester) async {
      DateTime? result = DateTime(1999, 1, 1); // 널이 아닌 값에서 시작해 실제로 null로 덮이는지 본다.
      await tester.pumpWidget(buildHost(onResult: (v) => result = v, initialDate: DateTime(2000, 1, 1)));

      await tester.tap(find.text('날짜 피커 열기'));
      await tester.pumpAndSettle();

      final picker = tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
      picker.onDateTimeChanged(DateTime(2010, 6, 15));
      await tester.pump();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('시트 바깥(모달 배리어)을 탭해 닫아도 "취소"와 동일하게 null이 반환된다', (tester) async {
      DateTime? result = DateTime(1999, 1, 1);
      await tester.pumpWidget(buildHost(onResult: (v) => result = v));

      await tester.tap(find.text('날짜 피커 열기'));
      await tester.pumpAndSettle();

      // 시트는 화면 하단에서 올라오므로, 화면 위쪽(배리어 영역)을 탭하면 시트 바깥을
      // 탭한 것과 같다.
      await tester.tapAt(const Offset(400, 50));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('firstDate/lastDate가 CupertinoDatePicker의 minimumDate/maximumDate로 그대로 전달된다',
        (tester) async {
      await tester.pumpWidget(buildHost(
        onResult: (_) {},
        firstDate: DateTime(1990, 5, 1),
        lastDate: DateTime(2020, 12, 31),
      ));

      await tester.tap(find.text('날짜 피커 열기'));
      await tester.pumpAndSettle();

      final picker = tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
      expect(picker.minimumDate, DateTime(1990, 5, 1));
      expect(picker.maximumDate, DateTime(2020, 12, 31));
    });
  });

  group('showWheelTimePicker', () {
    Widget buildHost({required void Function(TimeOfDay?) onResult, TimeOfDay? initialTime}) {
      return MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                final picked = await showWheelTimePicker(
                  context: context,
                  initialTime: initialTime ?? const TimeOfDay(hour: 14, minute: 30),
                );
                onResult(picked);
              },
              child: const Text('시간 피커 열기'),
            ),
          ),
        ),
      );
    }

    testWidgets('휠을 건드리지 않고 "확인"만 눌러도 initialTime이 그대로 반환된다', (tester) async {
      TimeOfDay? result;
      await tester.pumpWidget(
        buildHost(onResult: (v) => result = v, initialTime: const TimeOfDay(hour: 9, minute: 5)),
      );

      await tester.tap(find.text('시간 피커 열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result, const TimeOfDay(hour: 9, minute: 5));
    });

    testWidgets('휠로 값을 바꾼 뒤 "확인"을 누르면 바뀐 시:분이 반환된다 (날짜 부분은 버려짐)',
        (tester) async {
      TimeOfDay? result;
      await tester.pumpWidget(buildHost(onResult: (v) => result = v));

      await tester.tap(find.text('시간 피커 열기'));
      await tester.pumpAndSettle();

      final picker = tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
      // 날짜 부분(연/월/일)은 TimeOfDay로 변환되며 버려지므로, 기준일과 다른 날짜를
      // 넣어도 결과에는 시:분만 반영돼야 한다.
      picker.onDateTimeChanged(DateTime(2099, 12, 31, 23, 45));
      await tester.pump();

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result, const TimeOfDay(hour: 23, minute: 45));
    });

    testWidgets('"취소"를 누르면 null이 반환된다', (tester) async {
      TimeOfDay? result = const TimeOfDay(hour: 1, minute: 1); // 널이 아닌 값에서 시작.
      await tester.pumpWidget(buildHost(onResult: (v) => result = v));

      await tester.tap(find.text('시간 피커 열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('시트 바깥(모달 배리어)을 탭해 닫아도 "취소"와 동일하게 null이 반환된다', (tester) async {
      TimeOfDay? result = const TimeOfDay(hour: 1, minute: 1);
      await tester.pumpWidget(buildHost(onResult: (v) => result = v));

      await tester.tap(find.text('시간 피커 열기'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(400, 50));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
