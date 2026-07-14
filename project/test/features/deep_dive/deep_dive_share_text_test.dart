import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_share_text.dart';
import 'package:cosmos_saju/features/result/meta_line.dart';

/// `share_text_test.dart`(사주 결과 화면의 buildShareText)와 같은 관점으로
/// `buildDeepDiveShareText`를 검증한다.
void main() {
  group('buildDeepDiveShareText', () {
    test('이름·메타라인·MBTI·관심사·해시태그를 모두 포함한다', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '민지');

      final text = buildDeepDiveShareText(
        birthInfo: birthInfo,
        displayName: '민지',
        mbti: ('INTJ', '치밀하게 그림을 그리고 움직이는 전략가 타입이에요'),
        items: const [
          ('💘', '연애운', '연애운 설명'),
          ('💼', '직장운', '직장운 설명'),
        ],
      );

      expect(text, contains('✨ 민지의 심층 분석 ✨'));
      expect(text, contains(buildMetaLine(birthInfo)));
      expect(text, contains('INTJ — 치밀하게 그림을 그리고 움직이는 전략가 타입이에요'));
      expect(text, contains('💘 연애운: 연애운 설명'));
      expect(text, contains('💼 직장운: 직장운 설명'));
      expect(text, contains('#사주랑 #심층분석 #MBTI'));
    });

    test('MBTI를 입력하지 않았으면(null) MBTI 줄이 텍스트에 없다', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

      final text = buildDeepDiveShareText(
        birthInfo: birthInfo,
        displayName: '회원님',
        items: const [('💘', '연애운', '연애운 설명')],
      );

      // MBTI 줄의 유일한 " — " 구분자이므로, 이게 없으면 MBTI 줄 자체가 생략된 것.
      expect(text, isNot(contains(' — ')));
    });

    test('관심사를 하나도 고르지 않았으면 관심사 줄이 없다', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

      final text = buildDeepDiveShareText(
        birthInfo: birthInfo,
        displayName: '회원님',
        mbti: ('INTJ', '코멘트'),
        items: const [],
      );

      // "아이콘 제목: 풀이" 형식의 콜론이 관심사 줄에만 등장하므로, 관심사가 없으면
      // 콜론도 없어야 한다(MBTI 줄엔 콜론이 없음).
      expect(text, isNot(contains(':')));
    });

    test('관심사가 여러 개면 전달한 순서 그대로 텍스트에 나열된다', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

      final text = buildDeepDiveShareText(
        birthInfo: birthInfo,
        displayName: '회원님',
        items: const [
          ('💰', '재물운', '재물운 설명'),
          ('🌱', '건강운', '건강운 설명'),
          ('💘', '연애운', '연애운 설명'),
        ],
      );

      final wealthIndex = text.indexOf('재물운');
      final healthIndex = text.indexOf('건강운');
      final loveIndex = text.indexOf('연애운');
      expect(wealthIndex, lessThan(healthIndex));
      expect(healthIndex, lessThan(loveIndex));
    });

    test('각 관심사 줄은 자신의 아이콘·제목·풀이만 짝지어 나오고 다른 관심사와 뒤섞이지 않는다', () {
      // 콘텐츠 스왑 취약점 점검: 두 관심사의 풀이가 서로 자리를 바꿔도(둘 다 텍스트
      // 어딘가에는 여전히 존재하므로) contains() 단독 검증으로는 못 잡는다 —
      // "아이콘 제목: 풀이" 한 줄 형식 전체를 정확히 대조한다.
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

      final text = buildDeepDiveShareText(
        birthInfo: birthInfo,
        displayName: '회원님',
        items: const [
          ('💘', '연애운', 'AAA'),
          ('💰', '재물운', 'BBB'),
        ],
      );

      expect(text, contains('💘 연애운: AAA'));
      expect(text, contains('💰 재물운: BBB'));
      expect(text, isNot(contains('💘 연애운: BBB')));
      expect(text, isNot(contains('💰 재물운: AAA')));
    });

    test('MBTI 줄은 항상 "코드 — 코멘트" 순서다(코멘트가 먼저 오지 않는다)', () {
      final birthInfo = BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

      final text = buildDeepDiveShareText(
        birthInfo: birthInfo,
        displayName: '회원님',
        mbti: ('INTJ', '치밀하게 그림을 그리고 움직이는 전략가 타입이에요'),
        items: const [],
      );

      expect(text, contains('INTJ — 치밀하게 그림을 그리고 움직이는 전략가 타입이에요'));
      expect(text, isNot(contains('치밀하게 그림을 그리고 움직이는 전략가 타입이에요 — INTJ')));
    });
  });
}
