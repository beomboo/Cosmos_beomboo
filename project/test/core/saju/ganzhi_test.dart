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

  group('GanzhiPillar.ganzhiIndex60', () {
    test('갑자(stem=0, branch=0)는 60갑자 인덱스 0이다', () {
      const pillar = GanzhiPillar(stemIndex: 0, branchIndex: 0);
      expect(pillar.ganzhiIndex60, 0);
    });

    test('임신(stem=8, branch=8)은 60갑자 인덱스 8이다', () {
      const pillar = GanzhiPillar(stemIndex: 8, branchIndex: 8);
      expect(pillar.ganzhiIndex60, 8);
    });

    test('경신(stem=6, branch=8)은 60갑자 인덱스 56이다', () {
      const pillar = GanzhiPillar(stemIndex: 6, branchIndex: 8);
      expect(pillar.ganzhiIndex60, 56);
    });

    test('임술·계해(60갑자 마지막 두 간지)는 각각 인덱스 58, 59다', () {
      const imsul = GanzhiPillar(stemIndex: 8, branchIndex: 10);
      const gyehae = GanzhiPillar(stemIndex: 9, branchIndex: 11);
      expect(imsul.ganzhiIndex60, 58);
      expect(gyehae.ganzhiIndex60, 59);
    });

    test('stem/branch가 60을 넘는 배수여도(순환) 같은 인덱스로 정규화된다', () {
      const pillar = GanzhiPillar(stemIndex: 60, branchIndex: 72); // 60%10=0, 72%12=0 → 갑자
      expect(pillar.ganzhiIndex60, 0);
    });

    test('60갑자 인덱스 0~59 전부가 서로 다른 (stem,branch) 조합에서 정확히 역산된다', () {
      // calculateFourPillars()가 실제로 만드는 방식(원본 인덱스 % 10, % 12)과 반대
      // 방향의 역산이 항상 원래 인덱스로 돌아오는지 60개 전부 확인한다.
      for (var i = 0; i < 60; i++) {
        final pillar = GanzhiPillar(stemIndex: i % 10, branchIndex: i % 12);
        expect(pillar.ganzhiIndex60, i, reason: '60갑자 인덱스 $i');
      }
    });
  });

  group('voidBranchIndices — 공망(空亡)', () {
    // docs/research/사주팔자/공망.md의 6개 순(旬) 중 세 개를 표와 대조한다
    // (saju-dart core/sinsals.dart · manseryeok void-branches.ts 교차검증 공식).
    test('갑자(일간=갑0, 일지=자0)의 공망은 술(10)·해(11)다', () {
      expect(
        voidBranchIndices(dayStemIndex: 0, dayBranchIndex: 0),
        [10, 11],
      );
    });

    test('갑술(일간=갑0, 일지=술10)의 공망은 신(8)·유(9)다', () {
      expect(
        voidBranchIndices(dayStemIndex: 0, dayBranchIndex: 10),
        [8, 9],
      );
    });

    test('갑인(일간=갑0, 일지=인2)의 공망은 자(0)·축(1)다', () {
      expect(
        voidBranchIndices(dayStemIndex: 0, dayBranchIndex: 2),
        [0, 1],
      );
    });

    test('같은 순(旬)에 속한 일주는 모두 같은 공망 2지지를 공유한다', () {
      // 갑자순 10개 간지(갑자~계유, stem 0~9·branch 0~9)는 전부 술해(10,11) 공망이어야 한다.
      for (var i = 0; i < 10; i++) {
        expect(
          voidBranchIndices(dayStemIndex: i, dayBranchIndex: i),
          [10, 11],
          reason: '갑자순 $i번째 간지',
        );
      }
    });
  });

  group('nayinFor — 납음오행(納音五行)', () {
    test('60갑자 인덱스 0(갑자)은 해중금(금)이다', () {
      final nayin = nayinFor(0);
      expect(nayin.name, '해중금');
      expect(nayin.hanja, '海中金');
      expect(nayin.ohaeng, '금');
    });

    test('60갑자 인덱스 8(임신, 검봉금)과 9(계유)는 같은 조라 같은 납음이다', () {
      final a = nayinFor(8);
      final b = nayinFor(9);
      expect(a, (name: '검봉금', hanja: '劍鋒金', ohaeng: '금'));
      expect(a, b);
    });

    test('60갑자 인덱스 56(경신)은 석류목(목)이다', () {
      final nayin = nayinFor(56);
      expect(nayin.name, '석류목');
      expect(nayin.hanja, '石榴木');
      expect(nayin.ohaeng, '목');
    });

    test('60갑자 인덱스 59(계해, 마지막)는 대해수(수)다', () {
      final nayin = nayinFor(59);
      expect(nayin.name, '대해수');
      expect(nayin.hanja, '大海水');
      expect(nayin.ohaeng, '수');
    });

    test('60갑자 인덱스 7(신미)은 노방토(토)다', () {
      final nayin = nayinFor(7);
      expect(nayin.name, '노방토');
      expect(nayin.ohaeng, '토');
    });
  });
}
