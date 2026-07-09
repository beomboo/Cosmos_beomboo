import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/result/meta_line.dart';

void main() {
  group('buildMetaLine', () {
    test('시간·성별·출생지가 모두 있으면 순서대로 이어붙인다', () {
      final info = BirthInfo(
        date: DateTime(1998, 8, 15),
        hour: 14,
        isLunar: false,
        gender: Gender.female,
        birthPlace: '서울특별시',
      );

      expect(buildMetaLine(info), '1998.08.15 · 오후 2시生 · 양력 · 여성 · 서울특별시');
    });

    test('시간을 모르면 "시간 모름"이 들어간다', () {
      final info = BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: true);

      expect(buildMetaLine(info), '1998.08.15 · 시간 모름 · 음력');
    });

    test('성별·출생지가 없으면 접미사 없이 날짜/시간/양음력만 남는다', () {
      final info = BirthInfo(date: DateTime(2000, 1, 1), hour: 0, isLunar: false);

      expect(buildMetaLine(info), '2000.01.01 · 오전 12시生 · 양력');
    });

    test('정오(12시)는 "오후 12시"로 표시된다', () {
      // 자정(hour: 0 → "오전 12시")은 위 테스트로 이미 검증돼 있었지만, 12시간제
      // 변환 공식(`hour % 12 == 0 ? 12 : hour % 12` + `hour < 12`로 오전/오후 판단)의
      // 또 다른 경계인 정오(hour: 12)는 지금까지 한 번도 검증한 적이 없었다 —
      // 이 공식은 12 % 12 == 0이라 자정과 똑같이 "12시"가 나오지만, 오전/오후를
      // 가르는 `hour < 12` 비교에서는 12가 false가 되어 "오후"로 갈라져야 한다.
      final info = BirthInfo(date: DateTime(2000, 1, 1), hour: 12, isLunar: false);

      expect(buildMetaLine(info), '2000.01.01 · 오후 12시生 · 양력');
    });

    test('minute이 있으면 목업(STEP 4 "오후 2시 30분生")과 동일하게 분까지 표시된다', () {
      // birth_input의 timePicker는 분까지 고를 수 있고 입력 화면 pill에도
      // "오후 2시 30분"처럼 분이 보이는데, 지금까지 BirthInfo에는 hour만 있고
      // minute은 아예 없어서 제출 후에는 분 정보가 통째로 사라지고 있었다 — 목업
      // STEP 4 결과 화면도 "오후 2시 30분生"처럼 분을 표시하도록 돼 있어 실제
      // 목업과 다른 부분이었다. minute 필드 추가 후 정확히 반영되는지 확인한다.
      final info = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, minute: 30, isLunar: false);

      expect(buildMetaLine(info), '1998.08.15 · 오후 2시 30분生 · 양력');
    });

    test('minute이 한 자리 수(예: 5분)여도 두 자리로 0을 채워 표시한다', () {
      final info = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, minute: 5, isLunar: false);

      expect(buildMetaLine(info), '1998.08.15 · 오후 2시 05분生 · 양력');
    });

    test('hour는 있지만 minute이 없으면(예: 예전 저장값) 기존처럼 분 없이 표시된다', () {
      // BirthInfo에 minute을 추가하면서 기존 호출부(테스트 fixture, 예전에 저장된
      // 값 등)가 minute을 안 넘기는 경우와 호환이 깨지지 않는지 확인 — 위 "시간·성별·
      // 출생지가 모두 있으면..." 테스트가 이미 암묵적으로 검증하고 있지만, 의도를
      // 명시적으로 남겨둔다.
      final info = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

      expect(info.minute, isNull);
      expect(buildMetaLine(info), '1998.08.15 · 오후 2시生 · 양력');
    });

    test('출생지가 공백뿐이면(null이 아니어도) 접미사가 붙지 않는다', () {
      // birth_input_screen.dart는 입력값을 trim() 후 비어있으면 null로 바꿔서
      // BirthInfo를 만들지만, buildMetaLine() 자체는 어떤 BirthInfo가 와도 안전해야
      // 하는 공용 함수다 — `birthPlace?.trim().isNotEmpty == true` 가드가 "null"과
      // "공백뿐인 문자열" 두 경우 모두 접미사를 붙이지 않도록 방어하는데, 지금까지는
      // null 케이스(성별·출생지 둘 다 없는 테스트)만 검증됐을 뿐 "공백뿐인 값이 실제로
      // null과 동일하게 처리되는지"는 값으로 확인한 적이 없었다.
      final info = BirthInfo(date: DateTime(2000, 1, 1), hour: 0, isLunar: false, birthPlace: '   ');

      expect(buildMetaLine(info), '2000.01.01 · 오전 12시生 · 양력');
    });
  });
}
