import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/core/saju/four_pillars.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/result/share_text.dart';

void main() {
  group('buildShareText', () {
    test('이름·날짜·4기둥·오행 밸런스·해시태그를 모두 포함한다', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '민지');
      final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
      final ohaengCount = pillars.ohaengCount;
      final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

      final text = buildShareText(
        birthInfo: birthInfo,
        pillars: pillars,
        dominant: '목',
        callout: ('木', '새로운 걸 벌이는 힘이 넘치는 타입이에요 🌿'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '민지',
      );

      expect(text, contains('민지의 사주팔자'));
      expect(text, contains('1998.08.15'));
      expect(text, contains('양력'));
      expect(text, contains('年柱 ${pillars.year.label}'));
      expect(text, contains('月柱 ${pillars.month.label}'));
      expect(text, contains('日柱 ${pillars.day.label}'));
      expect(text, contains('時柱 ${pillars.hour!.label}'));
      expect(text, contains('木(목) 기운이 강한 타입이에요'));
      expect(text, contains('#사주랑 #사주팔자 #오행'));
    });

    test('태어난 곳을 입력했으면 텍스트에 포함된다', () {
      final birthInfo = BirthInfo(
        date: DateTime(1998, 8, 15),
        hour: 14,
        isLunar: false,
        birthPlace: '서울특별시',
      );
      final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
      final ohaengCount = pillars.ohaengCount;
      final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

      final text = buildShareText(
        birthInfo: birthInfo,
        pillars: pillars,
        dominant: '목',
        callout: ('木', '설명'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '회원님',
      );

      expect(text, contains('양력 · 서울특별시'));
    });

    test('성별을 입력했으면 텍스트에 출생지보다 먼저 포함된다', () {
      final birthInfo = BirthInfo(
        date: DateTime(1998, 8, 15),
        hour: 14,
        isLunar: false,
        gender: Gender.male,
        birthPlace: '부산광역시',
      );
      final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
      final ohaengCount = pillars.ohaengCount;
      final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

      final text = buildShareText(
        birthInfo: birthInfo,
        pillars: pillars,
        dominant: '목',
        callout: ('木', '설명'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '회원님',
      );

      expect(text, contains('양력 · 남성 · 부산광역시'));
    });

    test('시주를 모르면(hour: null) 時柱 부분이 텍스트에 포함되지 않는다', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false);
      final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
      final ohaengCount = pillars.ohaengCount;
      final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

      final text = buildShareText(
        birthInfo: birthInfo,
        pillars: pillars,
        dominant: '목',
        callout: ('木', '설명'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '회원님',
      );

      expect(text, isNot(contains('時柱')));
      expect(pillars.hour, isNull);
    });

    test('음력을 선택하면 텍스트에 "음력"이 표시된다', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: true);
      final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
      final ohaengCount = pillars.ohaengCount;
      final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

      final text = buildShareText(
        birthInfo: birthInfo,
        pillars: pillars,
        dominant: '목',
        callout: ('木', '설명'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '회원님',
      );

      expect(text, contains('음력'));
      expect(text, isNot(contains('양력')));
    });

    test('오행 밸런스 퍼센트 합은 100에 가깝다(반올림 오차 허용)', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);
      final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
      final ohaengCount = pillars.ohaengCount;
      final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

      final text = buildShareText(
        birthInfo: birthInfo,
        pillars: pillars,
        dominant: '목',
        callout: ('木', '설명'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '회원님',
      );

      final match = RegExp(r'오행 밸런스: (.+)').firstMatch(text);
      expect(match, isNotNull);
      final percents = RegExp(r'(\d+)%')
          .allMatches(match!.group(1)!)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      expect(percents.length, 5);
      expect(percents.reduce((a, b) => a + b), inInclusiveRange(95, 105));
    });

    test('오행 밸런스 줄이 실제 ohaengCount 분포와 정확히 일치하는 퍼센트를 보여준다', () {
      // 위 테스트는 "합이 100 근처"만 확인했을 뿐, 각 오행 퍼센트 숫자 자체가
      // four_pillars_test.dart에서 이미 확인해둔 실제 분포(목2·화0·토2·금3·수1,
      // 총 8개)와 정확히 일치하는지는 검증한 적이 없었다. 반올림까지 포함해서
      // 정확한 문자열을 비교한다(3/8=37.5%→38%, 1/8=12.5%→13%로 반올림되는 것까지 확인).
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);
      final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
      final ohaengCount = pillars.ohaengCount;
      final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

      expect(ohaengCount, {'목': 2, '화': 0, '토': 2, '금': 3, '수': 1});

      final text = buildShareText(
        birthInfo: birthInfo,
        pillars: pillars,
        dominant: '목',
        callout: ('木', '설명'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '회원님',
      );

      expect(text, contains('오행 밸런스: 목 25% · 화 0% · 토 25% · 금 38% · 수 13%'));
    });
  });
}
