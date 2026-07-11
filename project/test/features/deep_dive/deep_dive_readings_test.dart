import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/features/deep_dive/deep_dive_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_readings.dart';
import 'package:cosmos_saju/features/result/ohaeng_readings.dart';

void main() {
  group('readingFor', () {
    test('연애·재물·건강 관심사는 ohaeng_readings.dart의 카테고리 풀이를 그대로 재사용한다', () {
      for (final ohaeng in const ['목', '화', '토', '금', '수']) {
        final categories = categoryReadingsByOhaeng[ohaeng]!;
        expect(
          readingFor(Interest.love, ohaeng),
          categories.firstWhere((c) => c.$2 == '연애운').$3,
        );
        expect(
          readingFor(Interest.wealth, ohaeng),
          categories.firstWhere((c) => c.$2 == '재물운').$3,
        );
        expect(
          readingFor(Interest.health, ohaeng),
          categories.firstWhere((c) => c.$2 == '건강운').$3,
        );
      }
    });

    test('직장운(career)은 오행별로 5가지 모두 채워진 별도 콘텐츠를 반환한다', () {
      // 기존 카테고리 풀이(연애·재물·건강·성격)에는 없던 항목이라, 5개 오행 전부
      // 빈 문자열 없이 실제 문구가 채워져 있는지 직접 확인한다.
      final seen = <String>{};
      for (final ohaeng in const ['목', '화', '토', '금', '수']) {
        final reading = readingFor(Interest.career, ohaeng);
        expect(reading, isNotEmpty);
        seen.add(reading);
      }
      // 오행마다 서로 다른 문구여야 한다(복붙 실수로 같은 문구가 여러 번 들어가는 걸 방지).
      expect(seen.length, 5);
    });

    test('직장운(career) 5가지 문구가 실제 값과 정확히 일치한다', () {
      // 위 테스트는 "5개 전부 비어있지 않고 서로 다르다"는 구조적 조건만 확인할 뿐,
      // 그 문구들이 오행끼리 통째로 뒤바뀌어도(예: 목과 화의 직장운 문구를 맞바꿔도)
      // 마찬가지로 "서로 다른 5개"는 참이라 이 테스트로는 못 잡는다 —
      // ohaeng_readings.dart의 categoryReadingsByOhaeng에서 실제로 겪은 것과 같은
      // 종류의 공백(2026-07-08 발견)이 이 파일의 _careerReadingByOhaeng에도 그대로
      // 있었음(지금까지 이 5가지 문구는 단 한 곳에서도 값으로 고정된 적이 없었음).
      const expected = {
        '목': '새 프로젝트나 이직처럼 확장하는 움직임이 잘 맞는 시기예요',
        '화': '적극적으로 어필하면 성과를 인정받기 좋은 타이밍이에요',
        '토': '묵묵히 맡은 역할을 다지면 신뢰를 얻는 타입이에요',
        '금': '원칙과 기준이 분명해서 책임 있는 자리가 잘 어울려요',
        '수': '상황 판단이 빨라 위기 속에서도 기회를 찾는 타입이에요',
      };
      for (final entry in expected.entries) {
        expect(readingFor(Interest.career, entry.key), entry.value, reason: '${entry.key} 직장운');
      }
    });

    test('알 수 없는 오행이 들어오면 토(土) 문구로 폴백한다', () {
      expect(readingFor(Interest.career, '알수없음'), readingFor(Interest.career, '토'));
    });

    test('연애·재물·건강의 categoryTitle은 항상 ohaeng_readings.dart 제목과 일치한다', () {
      // 2026-07-08 발견: `Interest.categoryTitle`(deep_dive_info.dart)과
      // `categoryReadingsByOhaeng`의 제목(ohaeng_readings.dart)은 서로 다른 파일의
      // 문자열 리터럴이라 컴파일 타임 연결이 없다 — 지금까지는 우연히 값이 일치해서
      // `readingFor()` 내부의 조회가 항상 성공했을 뿐, 둘 중 하나만 바뀌면
      // (예: "건강운"→"건강 운" 오타 수정) `readingFor()`가 크래시하는 실제 위험이
      // 있었다(같은 파일 다른 조회는 전부 기본값 폴백이 있는데 이것만 없었음, 지금은
      // 폴백 추가함). 이 테스트는 그 크래시를 막는 런타임 폴백 자체가 아니라, 애초에
      // 두 문자열이 어긋나면 여기서 먼저 실패하도록 만들어 CI에서 조기에 잡기 위함이다.
      final titles = categoryReadingsByOhaeng['토']!.map((c) => c.$2).toSet();
      for (final interest in [Interest.love, Interest.wealth, Interest.health]) {
        expect(
          titles.contains(interest.categoryTitle),
          isTrue,
          reason: '${interest.categoryTitle}이 categoryReadingsByOhaeng 제목 목록에 없음',
        );
      }
    });
  });

  group('mbtiCommentFor', () {
    test('16개 유형 전부 서로 다른 코멘트를 갖는다', () {
      const eiValues = MbtiEi.values;
      const snValues = MbtiSn.values;
      const tfValues = MbtiTf.values;
      const jpValues = MbtiJp.values;

      final codes = <String>{};
      for (final ei in eiValues) {
        for (final sn in snValues) {
          for (final tf in tfValues) {
            for (final jp in jpValues) {
              codes.add(Mbti(ei: ei, sn: sn, tf: tf, jp: jp).code);
            }
          }
        }
      }

      expect(codes.length, 16);
      final comments = codes.map((code) => mbtiCommentFor(code)).toSet();
      expect(comments.length, 16, reason: '16개 코드 전부 코멘트가 있어야 하고, 서로 달라야 한다');
      expect(comments.contains(null), isFalse);
    });

    test('mbtiCode가 null이면 코멘트도 null이다(MBTI를 모르는 경우)', () {
      expect(mbtiCommentFor(null), isNull);
    });

    test('INTJ는 실제로 정의된 코멘트를 반환한다', () {
      const mbti = Mbti(ei: MbtiEi.i, sn: MbtiSn.n, tf: MbtiTf.t, jp: MbtiJp.j);
      expect(mbti.code, 'INTJ');
      expect(mbtiCommentFor(mbti.code), mbtiComments['INTJ']);
      expect(mbtiCommentFor(mbti.code), isNotNull);
    });
  });
}
