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
  });
}
