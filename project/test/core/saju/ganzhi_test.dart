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
}
