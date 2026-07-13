import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/features/deep_dive/deep_dive_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_readings.dart';
import 'package:cosmos_saju/features/result/ohaeng_readings.dart';

void main() {
  group('readingFor', () {
    // 아래 그룹은 대부분 subCount: 0(2순위 오행이 사실상 없는 경우)으로 호출해, 기존
    // 단일-오행 시그니처(readingFor(interest, ohaeng))와 동작이 완전히 같은지 확인한다 —
    // '목'을 아무 sub로나 넘겨도(subCount: 0이면 아예 쓰이지 않으므로) 결과가 바뀌면 안 된다.
    test('연애·재물·건강 관심사는 ohaeng_readings.dart의 카테고리 풀이를 그대로 재사용한다 (subCount 0)', () {
      for (final ohaeng in const ['목', '화', '토', '금', '수']) {
        final categories = categoryReadingsByOhaeng[ohaeng]!;
        expect(
          readingFor(Interest.love, ohaeng, '토', subCount: 0),
          categories.firstWhere((c) => c.$2 == '연애운').$3,
        );
        expect(
          readingFor(Interest.wealth, ohaeng, '토', subCount: 0),
          categories.firstWhere((c) => c.$2 == '재물운').$3,
        );
        expect(
          readingFor(Interest.health, ohaeng, '토', subCount: 0),
          categories.firstWhere((c) => c.$2 == '건강운').$3,
        );
      }
    });

    test('직장운(career)은 오행별로 5가지 모두 채워진 별도 콘텐츠를 반환한다 (subCount 0)', () {
      // 기존 카테고리 풀이(연애·재물·건강·성격)에는 없던 항목이라, 5개 오행 전부
      // 빈 문자열 없이 실제 문구가 채워져 있는지 직접 확인한다.
      final seen = <String>{};
      for (final ohaeng in const ['목', '화', '토', '금', '수']) {
        final reading = readingFor(Interest.career, ohaeng, '토', subCount: 0);
        expect(reading, isNotEmpty);
        seen.add(reading);
      }
      // 오행마다 서로 다른 문구여야 한다(복붙 실수로 같은 문구가 여러 번 들어가는 걸 방지).
      expect(seen.length, 5);
    });

    test('직장운(career) 5가지 문구가 실제 값과 정확히 일치한다 (subCount 0)', () {
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
        expect(
          readingFor(Interest.career, entry.key, '토', subCount: 0),
          entry.value,
          reason: '${entry.key} 직장운',
        );
      }
    });

    test('알 수 없는 오행이 들어오면 토(土) 문구로 폴백한다 (subCount 0)', () {
      expect(
        readingFor(Interest.career, '알수없음', '토', subCount: 0),
        readingFor(Interest.career, '토', '토', subCount: 0),
      );
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

    group('콤보(2순위 오행 반영, subCount > 0)', () {
      // 결과 화면(ohaeng_readings_test.dart)의 categoryReadingsForCombo와 정확히 같은
      // 접미사 문구를 연애·재물·건강에 그대로 이어붙이는지, 그리고 직장운도 자체
      // 접미사 로직이 똑같이 적용되는지 확인한다.
      test('연애·재물·건강은 categoryReadingsForCombo와 동일한 접미사가 붙는다', () {
        final expectedCategories = categoryReadingsForCombo('목', '화', subCount: 2);
        expect(
          readingFor(Interest.love, '목', '화', subCount: 2),
          expectedCategories.firstWhere((c) => c.$2 == '연애운').$3,
        );
        expect(
          readingFor(Interest.wealth, '목', '화', subCount: 2),
          expectedCategories.firstWhere((c) => c.$2 == '재물운').$3,
        );
        expect(
          readingFor(Interest.health, '목', '화', subCount: 2),
          expectedCategories.firstWhere((c) => c.$2 == '건강운').$3,
        );
      });

      test('직장운도 subCount > 0이면 접미사 문장이 덧붙는다', () {
        final base = readingFor(Interest.career, '목', '화', subCount: 0);
        final combo = readingFor(Interest.career, '목', '화', subCount: 2);

        expect(combo, startsWith(base));
        expect(combo.length, greaterThan(base.length));
        expect(combo, contains('화 기운'));
      });

      test('직장운 접미사는 관계(OhaengRelation) 4종에 따라 서로 다른 문구를 붙인다', () {
        // 목(dominant) 기준 화·토·금·수(sub) 각각 관계가 다르므로(생/극/피생/피극),
        // 4가지 접미사 문구가 전부 달라야 한다.
        final combos = {
          for (final sub in const ['화', '토', '금', '수'])
            sub: readingFor(Interest.career, '목', sub, subCount: 1),
        };
        expect(combos.values.toSet().length, 4);
      });
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

    test('16개 유형 코멘트가 실제 값과 정확히 일치한다', () {
      // 위 두 테스트는 "16개가 서로 다르다"(구조적 유일성)와 "INTJ는 mbtiComments
      // 맵 조회 결과와 같다"(같은 소스를 양쪽에서 다시 읽는 것이라 실제 문구가
      // 틀렸는지는 못 잡음)만 확인한다 — ohaeng_readings.dart/deep_dive_readings.dart의
      // 오행별 문구에서 반복 발견된 것과 같은 종류의 공백: 두 유형끼리 코멘트가
      // 통째로 뒤바뀌어도 "서로 다른 16개"는 여전히 참이라 안 잡힌다. 16개 전체를
      // 하드코딩된 문자열과 직접 대조해 고정한다.
      const expected = {
        'INTJ': '치밀하게 그림을 그리고 움직이는 전략가 타입이에요',
        'INTP': '호기심을 따라가다 보면 남들이 못 본 답을 찾아내는 타입이에요',
        'ENTJ': '목표가 정해지면 거침없이 밀어붙이는 타입이에요',
        'ENTP': '즉흥적인 아이디어로 판을 뒤집는 걸 즐기는 타입이에요',
        'INFJ': '깊이 있는 통찰로 사람 마음을 잘 헤아리는 타입이에요',
        'INFP': '자기만의 가치관이 뚜렷해서 쉽게 흔들리지 않는 타입이에요',
        'ENFJ': '주변을 잘 챙기고 이끄는 데 자연스러운 재능이 있는 타입이에요',
        'ENFP': '에너지가 넘치고 새로운 인연·경험에 적극적인 타입이에요',
        'ISTJ': '한번 정한 원칙은 끝까지 지키는 믿음직한 타입이에요',
        'ISFJ': '조용히 곁을 지키며 챙겨주는 세심한 타입이에요',
        'ESTJ': '체계적으로 일을 정리하고 이끄는 데 능한 타입이에요',
        'ESFJ': '분위기를 살피고 사람들을 잘 챙기는 타입이에요',
        'ISTP': '실전에서 손으로 문제를 해결하는 데 강한 타입이에요',
        'ISFP': '자기만의 속도로 조용히 취향을 다져가는 타입이에요',
        'ESTP': '일단 부딪혀보며 그때그때 상황을 즐기는 타입이에요',
        'ESFP': '분위기 메이커답게 순간을 마음껏 즐길 줄 아는 타입이에요',
      };

      for (final entry in expected.entries) {
        expect(mbtiCommentFor(entry.key), entry.value, reason: '${entry.key} 코멘트');
      }
    });
  });
}
