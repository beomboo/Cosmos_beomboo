import 'package:flutter_test/flutter_test.dart';
import 'package:cosmos_saju/core/saju/four_pillars.dart';

void main() {
  group('calculateFourPillars', () {
    test('기준일(1900-01-01)의 일주는 갑진이다', () {
      final result = calculateFourPillars(birthDate: DateTime(1900, 1, 1));
      expect(result.day.label, '갑진');
    });

    test('60일 뒤에는 일주가 같은 갑자로 돌아온다', () {
      final base = calculateFourPillars(birthDate: DateTime(2000, 1, 1));
      final after60Days = calculateFourPillars(
        birthDate: DateTime(2000, 1, 1).add(const Duration(days: 60)),
      );
      expect(after60Days.day.label, base.day.label);
    });

    test('2024년은 갑진년이다 (입춘 이후 기준)', () {
      final result = calculateFourPillars(birthDate: DateTime(2024, 3, 1));
      expect(result.year.label, '갑진');
    });

    test('입춘(2/4) 이전 생일은 전년도 년주를 사용한다', () {
      final result = calculateFourPillars(birthDate: DateTime(2024, 1, 15));
      // 2024 이전 갑자년은 1964년 → (1964-1984)%60 = -20 -> +60 = 40 -> 계묘(2023)의 다음 해가 아니라
      // 2023년 기준(입춘 전이므로 2023년 갑자 사용) = 계묘년이어야 함
      final expected = calculateFourPillars(birthDate: DateTime(2023, 6, 1));
      expect(result.year.label, expected.year.label);
    });

    test('시간을 모르면 시주가 없고 오행 개수는 6개(3기둥)만 센다', () {
      final result = calculateFourPillars(birthDate: DateTime(1998, 8, 15));
      expect(result.hour, isNull);
      final total = result.ohaengCount.values.fold<int>(0, (a, b) => a + b);
      expect(total, 6);
    });

    test('시간을 알면 시주가 생기고 오행 개수는 8개(4기둥)를 센다', () {
      final result = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
      expect(result.hour, isNotNull);
      final total = result.ohaengCount.values.fold<int>(0, (a, b) => a + b);
      expect(total, 8);
    });

    test('ohaengCount는 8글자 각각의 오행을 정확히 집계한다 (총 개수뿐 아니라 분포까지)', () {
      // 지금까지는 ohaengCount의 총합(6개/8개)만 확인했을 뿐, 실제 분포가 8글자
      // 각각의 오행과 정확히 일치하는지는 검증한 적이 없었다 — 이 결과 화면의
      // 오행 밸런스 바 차트/공유 텍스트가 직접 쓰는 값이라 총합만 맞고 분포가
      // 틀리면(예: 한 글자를 두 번 세고 다른 글자를 빠뜨림) 사용자에게 그대로 보인다.
      final result = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);

      // 년주 무인(戊寅=토+목), 월주 경신(庚申=금+금), 일주 갑자(甲子=목+수), 시주 신미(辛未=금+토)
      expect(result.year.label, '무인');
      expect(result.month.label, '경신');
      expect(result.day.label, '갑자');
      expect(result.hour!.label, '신미');

      expect(
        result.ohaengCount,
        {'목': 2, '화': 0, '토': 2, '금': 3, '수': 1},
      );
    });

    group('시주(時柱) 경계값 — 전통 시진 경계가 정확히 반영되는지', () {
      // 시진 경계: 자시 23~01시, 축시 01~03시, 인시 03~05시 ... 해시 21~23시.
      // 시주 지지 계산(((hour+1)~/2)%12)이 실제 이 경계와 맞는지 지금까지 직접
      // 테스트한 적이 없었다 — 자정(0시)과 23시가 같은 자시로 묶이는 것,
      // 1시/2시가 같은 축시로 묶이는 것 등 경계 자체를 명시적으로 검증한다.
      String hourBranch(int hour) =>
          calculateFourPillars(birthDate: DateTime(2000, 1, 1), birthHour: hour).hour!.branch;

      test('23시와 0시는 같은 자시(子時)다', () {
        expect(hourBranch(23), '자');
        expect(hourBranch(0), '자');
      });

      test('1시와 2시는 같은 축시(丑時)다', () {
        expect(hourBranch(1), '축');
        expect(hourBranch(2), '축');
      });

      test('3시는 인시(寅時)로 넘어간다', () {
        expect(hourBranch(3), '인');
      });

      test('21시와 22시는 같은 해시(亥時)다', () {
        expect(hourBranch(21), '해');
        expect(hourBranch(22), '해');
      });

      test('11시와 12시(정오)는 같은 오시(午時)다', () {
        // 자시/축시/인시/해시 경계는 이미 검증돼 있었지만, 지지 순환에서 자시의
        // 정반대(6칸 떨어진) 위치인 오시 — 특히 정오(12시)가 낀 경계는 아직
        // 검증한 적이 없었다. meta_line.dart의 12시간제 표기에서 정오가 별도
        // 분기("오후 12시")를 타는 것과는 별개 공식이라, 여기서는 오행/지지
        // 계산 자체가 정오를 오시(화 오행)로 올바르게 묶는지 확인한다.
        expect(hourBranch(11), '오');
        expect(hourBranch(12), '오');
      });
    });

    group('입춘(立春) 경계 — 2/4를 기준으로 년주가 정확히 갈리는지', () {
      // 기존 "입춘 이전 생일" 테스트는 1/15로 명백히 이전인 날짜만 썼을 뿐,
      // 실제 경계인 2/3(이전)과 2/4(당일, 이미 입춘 이후로 취급) 자체를
      // 직접 비교한 적이 없었다.
      test('2월 3일은 전년도 년주를, 2월 4일은 해당 연도 년주를 쓴다', () {
        final feb3 = calculateFourPillars(birthDate: DateTime(2024, 2, 3));
        final feb4 = calculateFourPillars(birthDate: DateTime(2024, 2, 4));
        final prevYear = calculateFourPillars(birthDate: DateTime(2023, 6, 1));
        final thisYear = calculateFourPillars(birthDate: DateTime(2024, 3, 1));

        expect(feb3.year.label, prevYear.year.label);
        expect(feb4.year.label, thisYear.year.label);
      });
    });

    group('월주(月柱) — 오호둔년기월법(五虎遁年起月法)이 정확히 반영되는지', () {
      // 년주/일주/시주는 각각 테스트가 있었지만, 월주(月柱)의 실제 값을 직접
      // 검증한 테스트는 지금까지 하나도 없었다 — 고전 공식(오호둔년기월법: 갑기년
      // 병인월, 을경년 무인월 ... 인월부터 순서대로 천간이 하나씩 밀리는 규칙)을
      // 기준으로 실제 계산값이 맞는지 확인한다.
      test('갑자년(1984) 인월(2월, 입춘 이후)은 병인(丙寅)이다 — 갑기지년병작수', () {
        final result = calculateFourPillars(birthDate: DateTime(1984, 2, 5));
        expect(result.year.label, '갑자');
        expect(result.month.label, '병인');
      });

      test('을축년(1985) 인월(2월, 입춘 이후)은 무인(戊寅)이다 — 을경지세무위두', () {
        final result = calculateFourPillars(birthDate: DateTime(1985, 2, 5));
        expect(result.year.label, '을축');
        expect(result.month.label, '무인');
      });

      test('갑자년(1984) 신월(8월)은 임신(壬申)이다 — 인월에서 6개월 뒤, 천간도 6칸 밀림', () {
        final result = calculateFourPillars(birthDate: DateTime(1984, 8, 15));
        expect(result.year.label, '갑자');
        expect(result.month.label, '임신');
      });
    });
  });
}
