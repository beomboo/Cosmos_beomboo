import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/core/saju/ganzhi.dart';

void main() {
  group('stemOhaeng / branchOhaeng', () {
    test('천간 인덱스 0~9는 갑을=목, 병정=화, 무기=토, 경신=금, 임계=수 순서로 매핑된다', () {
      expect(stemOhaeng(0), '목'); // 갑
      expect(stemOhaeng(1), '목'); // 을
      expect(stemOhaeng(2), '화'); // 병
      expect(stemOhaeng(4), '토'); // 무
      expect(stemOhaeng(6), '금'); // 경
      expect(stemOhaeng(8), '수'); // 임
    });

    test('지지 인덱스 0~11은 자=수, 인=목, 진=토, 오=화, 신=금 순서로 매핑된다', () {
      expect(branchOhaeng(0), '수'); // 자
      expect(branchOhaeng(2), '목'); // 인
      expect(branchOhaeng(4), '토'); // 진
      expect(branchOhaeng(6), '화'); // 오
      expect(branchOhaeng(8), '금'); // 신
    });

    test('인덱스가 범위를 넘어가면 60갑자 주기처럼 순환한다(% 10, % 12)', () {
      expect(stemOhaeng(10), stemOhaeng(0));
      expect(stemOhaeng(23), stemOhaeng(3));
      expect(branchOhaeng(12), branchOhaeng(0));
      expect(branchOhaeng(25), branchOhaeng(1));
    });
  });

  group('ohaengHanja', () {
    test('오행 5종(목화토금수)을 한자(木火土金水)로 매핑한다', () {
      expect(ohaengHanja['목'], '木');
      expect(ohaengHanja['화'], '火');
      expect(ohaengHanja['토'], '土');
      expect(ohaengHanja['금'], '金');
      expect(ohaengHanja['수'], '水');
    });
  });

  group('GanzhiPillar', () {
    test('stemIndex/branchIndex로 천간·지지 한 글자씩을 조합해 label을 만든다', () {
      const pillar = GanzhiPillar(stemIndex: 0, branchIndex: 0);
      expect(pillar.stem, '갑');
      expect(pillar.branch, '자');
      expect(pillar.label, '갑자');
    });

    test('ohaeng은 [천간 오행, 지지 오행] 순서의 2개짜리 리스트다', () {
      // 무인(戊寅) — 무(토) + 인(목)
      const pillar = GanzhiPillar(stemIndex: 4, branchIndex: 2);
      expect(pillar.ohaeng, ['토', '목']);
    });

    test('toString()은 label과 같다', () {
      const pillar = GanzhiPillar(stemIndex: 6, branchIndex: 8);
      expect(pillar.toString(), pillar.label);
      expect('$pillar', pillar.label);
    });

    test('인덱스가 60을 넘어가도(예: 60갑자 여러 바퀴) 정상적으로 순환한다', () {
      const pillar = GanzhiPillar(stemIndex: 60, branchIndex: 72);
      expect(pillar.label, '갑자'); // 60%10=0, 72%12=0
    });
  });

  group('ohaengRelationOf', () {
    // 결과 화면 콤보 콜아웃·카테고리 접미사(features/result/ohaeng_readings.dart)가
    // 이 함수로 dominant/sub 관계를 판별한다 — 표 기반으로 5(dominant) × 4(sub, 나머지
    // 전부) = 20가지 조합 전부가 정확히 하나의 관계로 분류되는지 확인한다.
    const expected = {
      // dominant가 순환상 바로 다음 오행을 생(生)한다: 목→화, 화→토, 토→금, 금→수, 수→목.
      ('목', '화'): OhaengRelation.dominantGeneratesSub,
      ('화', '토'): OhaengRelation.dominantGeneratesSub,
      ('토', '금'): OhaengRelation.dominantGeneratesSub,
      ('금', '수'): OhaengRelation.dominantGeneratesSub,
      ('수', '목'): OhaengRelation.dominantGeneratesSub,

      // dominant가 두 칸 뒤 오행을 극(克)한다: 목→토, 화→금, 토→수, 금→목, 수→화.
      ('목', '토'): OhaengRelation.dominantOvercomesSub,
      ('화', '금'): OhaengRelation.dominantOvercomesSub,
      ('토', '수'): OhaengRelation.dominantOvercomesSub,
      ('금', '목'): OhaengRelation.dominantOvercomesSub,
      ('수', '화'): OhaengRelation.dominantOvercomesSub,

      // sub가 dominant를 극(克)한다(위 극 관계의 반대 방향): 목→금, 화→수, 토→목, 금→화, 수→토.
      ('목', '금'): OhaengRelation.subOvercomesDominant,
      ('화', '수'): OhaengRelation.subOvercomesDominant,
      ('토', '목'): OhaengRelation.subOvercomesDominant,
      ('금', '화'): OhaengRelation.subOvercomesDominant,
      ('수', '토'): OhaengRelation.subOvercomesDominant,

      // sub가 dominant를 생(生)한다(위 생 관계의 반대 방향): 목→수, 화→목, 토→화, 금→토, 수→금.
      ('목', '수'): OhaengRelation.subGeneratesDominant,
      ('화', '목'): OhaengRelation.subGeneratesDominant,
      ('토', '화'): OhaengRelation.subGeneratesDominant,
      ('금', '토'): OhaengRelation.subGeneratesDominant,
      ('수', '금'): OhaengRelation.subGeneratesDominant,
    };

    test('20가지 (dominant, sub) 조합 전부가 표와 정확히 일치하는 관계로 분류된다', () {
      expect(expected.length, 20, reason: '5×4=20가지 조합이 표에 전부 있어야 한다');
      for (final entry in expected.entries) {
        final (dominant, sub) = entry.key;
        expect(
          ohaengRelationOf(dominant, sub),
          entry.value,
          reason: '($dominant, $sub)',
        );
      }
    });

    test('네 관계가 상호 배타적이다 — 각 dominant마다 sub 4개가 서로 다른 관계로 정확히 한 번씩 나뉜다', () {
      for (final dominant in const ['목', '화', '토', '금', '수']) {
        final subs = const ['목', '화', '토', '금', '수'].where((o) => o != dominant);
        final relations = subs.map((sub) => ohaengRelationOf(dominant, sub)).toSet();
        expect(relations.length, 4, reason: '$dominant 기준 4개 sub가 서로 다른 4가지 관계여야 한다');
      }
    });

    test('dominant와 sub가 같은 오행이면 예외를 던진다', () {
      expect(() => ohaengRelationOf('목', '목'), throwsArgumentError);
    });

    test('알 수 없는 오행이 들어오면 예외를 던진다', () {
      expect(() => ohaengRelationOf('알수없음', '목'), throwsArgumentError);
      expect(() => ohaengRelationOf('목', '알수없음'), throwsArgumentError);
    });
  });
}
