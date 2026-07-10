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

    test('오행 5종 × 영역 4개(20가지) 전부 실제 문구 값과 정확히 일치한다', () {
      // 위 "복사-붙여넣기 오류 방지" 테스트는 오행 5개가 서로 다른 문구를 반환하는지
      // (구조적 유일성)만 확인할 뿐, 그 문구들이 서로 뒤바뀌어도(예: 목의 연애운과
      // 화의 연애운이 통째로 스왑돼도) 마찬가지로 "5개 모두 서로 다름"은 여전히
      // 참이라 이 테스트로는 못 잡는다 — 화면 테스트(result_screen_test.dart)도
      // '금' 하나만, report_screen_test.dart도 각 오행에서 1개 영역씩만 실제 문구를
      // 값으로 고정해뒀을 뿐, 20가지 조합 전부를 값으로 박아둔 적은 없었다. 여기서
      // 20가지 전부를 한 번에 값으로 고정해, 오행 간 문구가 뒤바뀌는 회귀를
      // 어디서든 확실히 잡는다.
      const expected = {
        '목': [
          '적극적으로 다가가면 좋은 인연이 생기는 시기예요',
          '새로운 시도가 돈이 되는 타이밍이에요',
          '활동량이 많아지는 만큼 충분히 쉬어주세요',
          '추진력 갑, 시작은 빠르고 화끈해요',
        ],
        '화': [
          '매력이 넘쳐서 자연스럽게 인기가 많아져요',
          '표현력을 살린 부업이나 홍보가 잘 통해요',
          '텐션이 높은 만큼 방전되지 않게 페이스 조절이 필요해요',
          '밝고 열정적인 분위기 메이커 타입이에요',
        ],
        '토': [
          '천천히 신뢰를 쌓는 관계가 잘 맞아요',
          '무리한 투자보다 꾸준한 저축이 유리해요',
          '소화기 계통 컨디션을 특히 잘 챙기면 좋아요',
          '믿음직하고 중심을 잘 잡아주는 타입이에요',
        ],
        '금': [
          '눈이 높은 편이라 확실한 상대를 알아보는 시기예요',
          '계획적으로 관리하면 돈이 잘 모이는 편이에요',
          '호흡기·피부 컨디션을 신경 쓰면 좋아요',
          '원칙적이고 맺고 끊음이 확실한 타입이에요',
        ],
        '수': [
          '은근한 매력으로 다가오는 인연이 있어요',
          '정보력을 활용하면 좋은 기회를 잡을 수 있어요',
          '컨디션 기복이 있는 편이니 수분 섭취를 챙기세요',
          '유연하고 눈치가 빠른 지략가 타입이에요',
        ],
      };

      for (final entry in expected.entries) {
        final actual = categoryReadingsFor(entry.key).map((r) => r.$3).toList();
        expect(actual, entry.value, reason: '${entry.key} 오행의 4개 영역 문구');
      }
    });
  });
}
