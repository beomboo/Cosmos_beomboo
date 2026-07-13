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

  group('dominantComboCallout', () {
    test('subCount가 0이면 dominant 단독 콜아웃 문구로 폴백한다', () {
      for (final dominant in const ['목', '화', '토', '금', '수']) {
        // sub 값 자체는 subCount:0일 때 전혀 쓰이지 않아야 하므로, 아무 다른 오행이나
        // 넘겨도 결과가 바뀌면 안 된다 — 폴백 분기가 sub를 참조하지 않는지 확인.
        final withDummySub = const ['목', '화', '토', '금', '수'].firstWhere((o) => o != dominant);
        expect(
          dominantComboCallout(dominant, withDummySub, subCount: 0),
          dominantComboCallout(dominant, dominant == '목' ? '화' : '목', subCount: 0),
        );
      }
    });

    test('목 우세 + 화 2순위(목생화) 콜아웃은 실제 문구와 정확히 일치한다', () {
      final callout = dominantComboCallout('목', '화', subCount: 2);
      expect(callout.$1, '木');
      expect(callout.$2, '🌿');
      expect(
        callout.$3,
        '화 기운이 화르르 옮겨붙어서 아이디어가 곧장 행동으로 이어져요. 시작한 일에 속도가 붙는 타입이에요',
      );
    });

    test('금 우세 + 목 2순위(금극목) 콜아웃은 실제 문구와 정확히 일치한다', () {
      final callout = dominantComboCallout('금', '목', subCount: 3);
      expect(callout.$1, '金');
      expect(
        callout.$3,
        '금 기운이 목 기운을 정리해줘서 벌여둔 일을 야무지게 마무리 짓는 힘이 있어요',
      );
    });

    test('5(dominant) × 4(sub) = 20가지 조합 전부 서로 다른 문구를 반환한다', () {
      final seen = <String>{};
      for (final dominant in const ['목', '화', '토', '금', '수']) {
        for (final sub in const ['목', '화', '토', '금', '수']) {
          if (sub == dominant) continue;
          seen.add(dominantComboCallout(dominant, sub, subCount: 1).$3);
        }
      }
      expect(seen.length, 20);
    });
  });

  group('categoryReadingsForCombo', () {
    test('subCount가 0이면 categoryReadingsFor(dominant)와 완전히 동일하다', () {
      for (final dominant in const ['목', '화', '토', '금', '수']) {
        expect(
          categoryReadingsForCombo(dominant, '토', subCount: 0),
          categoryReadingsFor(dominant),
        );
      }
    });

    test('subCount가 0보다 크면 4개 카드 모두 기존 설명 뒤에 접미사가 붙는다', () {
      final base = categoryReadingsFor('목');
      final combo = categoryReadingsForCombo('목', '화', subCount: 2);

      expect(combo.length, 4);
      for (var i = 0; i < 4; i++) {
        expect(combo[i].$1, base[i].$1, reason: '아이콘은 그대로 유지');
        expect(combo[i].$2, base[i].$2, reason: '제목은 그대로 유지');
        expect(combo[i].$3, startsWith(base[i].$3), reason: '기존 설명이 그대로 앞에 남아있어야 함');
        expect(combo[i].$3.length, greaterThan(base[i].$3.length));
      }
    });

    test('목 우세 + 화 2순위(목생화) 접미사는 실제 문구와 정확히 일치한다', () {
      final combo = categoryReadingsForCombo('목', '화', subCount: 2);
      expect(
        combo[0].$3,
        '적극적으로 다가가면 좋은 인연이 생기는 시기예요. 화 기운까지 힘을 보태서 이 흐름이 한층 살아나요',
      );
    });

    test('관계 4종(생/피생/극/피극)에 대응하는 접미사 4가지는 서로 다르다', () {
      // 목(dominant) 기준 화·수·토·금(sub)은 각각 dominantGeneratesSub·subGeneratesDominant·
      // dominantOvercomesSub·subOvercomesDominant 네 관계에 정확히 하나씩 대응한다.
      final suffixes = {
        for (final sub in const ['화', '수', '토', '금'])
          sub: categoryReadingsForCombo('목', sub, subCount: 1)[0].$3,
      };
      expect(suffixes.values.toSet().length, 4);
    });
  });
}
