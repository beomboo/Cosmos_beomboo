import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/core/saju/four_pillars.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/result/meta_line.dart';
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
        callout: ('木', '🌿', '새로운 걸 벌이는 힘이 넘쳐요'),
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
      expect(text, contains('목(木) 기운이 강한 타입이에요 🌿'));
      expect(text, contains('새로운 걸 벌이는 힘이 넘쳐요'));
      expect(text, contains('#사주랑 #사주팔자 #오행'));
    });

    test('태어난 시간(과 분)이 결과/리포트 화면과 동일한 형식으로 포함된다', () {
      // buildShareText는 지금까지 날짜·양음력·성별·출생지만 자체적으로 조립하고
      // meta_line.dart의 buildMetaLine과는 별개로 구현돼 있어서, 실제로는 태어난
      // 시간(hour)이 공유 텍스트에 전혀 안 들어가고 있었다 — 화면(result/report/
      // 심층 분석)은 전부 buildMetaLine을 재사용해 시간을 보여주는데, 유일하게 공유
      // 텍스트만 시간이 빠진 채 나가고 있던 것. 특히 이미지 캡처가 실패해 텍스트만
      // 단독으로 공유되는 폴백 상황에서는 사용자가 입력한 시간 정보가 아예 누락된
      // 채 나가는 실제 결함이었다. buildMetaLine을 그대로 재사용하도록 고쳐 시간(및
      // 분)이 화면과 똑같이 포함되는지 확인한다.
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, minute: 30, isLunar: false);
      final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
      final ohaengCount = pillars.ohaengCount;
      final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);

      final text = buildShareText(
        birthInfo: birthInfo,
        pillars: pillars,
        dominant: '목',
        callout: ('木', '🌿', '설명'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '회원님',
      );

      expect(text, contains('오후 2시 30분生'));
      expect(text, contains(buildMetaLine(birthInfo)));
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
        callout: ('木', '🌿', '설명'),
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
        callout: ('木', '🌿', '설명'),
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
        callout: ('木', '🌿', '설명'),
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
        callout: ('木', '🌿', '설명'),
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
        callout: ('木', '🌿', '설명'),
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
        callout: ('木', '🌿', '설명'),
        ohaengCount: ohaengCount,
        total: total,
        displayName: '회원님',
      );

      expect(text, contains('오행 밸런스: 목 25% · 화 0% · 토 25% · 금 38% · 수 13%'));
    });
  });
}
