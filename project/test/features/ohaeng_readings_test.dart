import 'package:flutter_test/flutter_test.dart';
import 'package:cosmos_saju/features/result/ohaeng_readings.dart';

void main() {
  group('categoryReadingsFor', () {
    test('오행 5종 모두 4개(연애·재물·건강·성격) 항목을 반환한다', () {
      for (final ohaeng in const ['목', '화', '토', '금', '수']) {
        final readings = categoryReadingsFor(ohaeng);
        expect(readings.length, 4);
        expect(readings.map((r) => r.$2), ['연애운', '재물운', '건강운', '성격']);
      }
    });

    test('오행마다 서로 다른 문구를 반환한다 (복사-붙여넣기 오류 방지)', () {
      final descsByOhaeng = {
        for (final ohaeng in const ['목', '화', '토', '금', '수'])
          ohaeng: categoryReadingsFor(ohaeng).map((r) => r.$3).join('|'),
      };
      expect(descsByOhaeng.values.toSet().length, 5);
    });

    test('알 수 없는 값은 토(기본값)로 대체된다', () {
      expect(categoryReadingsFor('알수없음'), categoryReadingsFor('토'));
    });
  });
}
