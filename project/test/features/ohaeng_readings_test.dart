import 'package:flutter_test/flutter_test.dart';
import 'package:cosmos_saju/core/saju/ganzhi.dart';
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
      // 2026-07-19 W5 문구 확장(02b9441)으로 한두 문장씩 더 상세해졌다 — 기대값도
      // ohaeng_readings.dart의 실제 문구 그대로 갱신한다.
      final callout = dominantComboCallout('목', '화', subCount: 2);
      expect(callout.$1, '木');
      expect(callout.$2, '🌿');
      expect(
        callout.$3,
        '화 기운이 화르르 옮겨붙어서 머릿속 아이디어가 곧장 행동으로 이어지는 편이에요. 마치 마른 장작에 불이 옮겨붙듯 '
            '한번 시작한 일에는 속도가 확 붙어서, 남들이 고민만 하고 있을 때 이미 저만치 앞서가고 있는 타입이에요',
      );
    });

    test('금 우세 + 목 2순위(금극목) 콜아웃은 실제 문구와 정확히 일치한다', () {
      final callout = dominantComboCallout('금', '목', subCount: 3);
      expect(callout.$1, '金');
      expect(
        callout.$3,
        '가지치기로 정원을 정리하듯, 금 기운이 목 기운을 다듬어줘서 여기저기 벌여둔 일을 끝까지 야무지게 마무리 짓는 '
            '힘이 있는 편이에요. 시작하는 추진력에 마무리하는 뒷심까지 더해지니, 일 잘한다는 소리를 자주 듣는 타입이에요',
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

    test('20가지 (dominant, sub) 조합 전부 실제 문구 값과 정확히 일치한다 (콤보 스왑 방지)', () {
      // 바로 위 "20가지 서로 다른 문구" 테스트는 구조적 유일성만 확인할 뿐, 예를 들어
      // (목,화)와 (화,목)처럼 서로 다른 (dominant,sub) 조합끼리 문구가 통째로
      // 뒤바뀌어도 "20개 모두 서로 다름"은 여전히 참이라 이 테스트로는 못 잡는다 —
      // 지금까지 이 파일에서 값으로 정확히 고정해둔 조합은 (목,화)·(금,목) 단 2개뿐이었다.
      // ohaeng_readings.dart의 _comboCallout 원본과 그대로 대조해 20가지 전부를 값으로
      // 고정한다.
      // 2026-07-19 W5 문구 확장(02b9441)으로 20가지 전부가 한두 문장씩 더 상세해졌다 —
      // ohaeng_readings.dart의 _comboCallout 원본과 그대로 대조해 기대값을 갱신한다.
      const expected = {
        ('목', '화'): '화 기운이 화르르 옮겨붙어서 머릿속 아이디어가 곧장 행동으로 이어지는 편이에요. 마치 마른 장작에 '
            '불이 옮겨붙듯 한번 시작한 일에는 속도가 확 붙어서, 남들이 고민만 하고 있을 때 이미 저만치 앞서가고 있는 '
            '타입이에요',
        ('목', '토'): '나무가 뿌리로 땅을 파고들듯, 목 기운이 토 기운을 다잡아서 하고 싶은 대로 밀어붙이는 힘이 꽤 센 '
            '편이에요. 다만 그 힘이 셀수록 주변이 미처 못 따라올 수 있으니, 가끔은 속도를 늦추고 페이스를 맞춰주면 '
            '관계도 성과도 더 오래갈 수 있어요',
        ('목', '금'): '가지치기하는 손길처럼, 금 기운이 앞서가려는 마음에 살짝 브레이크를 걸어줘요. 덕분에 다듬어지지 '
            '않은 채 무모하게 밀어붙이는 결정은 줄어들고, 뻗어나가는 힘은 그대로 유지하면서도 방향은 훨씬 정교해지는 '
            '편이에요',
        ('목', '수'): '마른 나무에 물을 대주듯, 수 기운이 뒤에서 꾸준히 받쳐줘서 아이디어가 마르지 않고 계속 샘솟는 '
            '편이에요. 겉으로 보이는 추진력뿐 아니라 뿌리 깊숙이 지혜까지 함께 자라는 셈이라, 한때 반짝하고 끝나는 게 '
            '아니라 오래도록 힘을 발휘하는 타입이에요',
        ('화', '토'): '햇볕이 땅을 따뜻하게 데워 씨앗을 틔우듯, 화 기운이 토 기운을 데워줘서 넘치는 열정이 그때그때 '
            '사라지지 않고 안정적인 결과로 차곡차곡 쌓여가는 편이에요. 뜨겁게 타오르면서도 발은 땅에 딱 붙이고 있는, '
            '실속 있는 열정파예요',
        ('화', '수'): '뜨거운 불에 시원한 물을 끼얹듯, 수 기운이 화 기운을 차분히 식혀줘서 욱하는 마음이 곧바로 터지지 '
            '않고 한 박자 늦게 나오는 편이에요. 감정 기복이 큰 폭으로 흔들리기보단 스스로 조절이 되는 편이라, 열정은 '
            '열정대로 유지하면서도 침착함을 잃지 않아요',
        ('화', '금'): '쇠도 녹이는 불처럼, 화 기운이 금 기운을 녹여내는 힘이 있어서 아무리 원칙적이고 완고한 상대라도 '
            '결국엔 내 페이스로 끌어들이는 편이에요. 열정과 매력으로 밀어붙이면 딱딱하던 분위기도 어느새 부드럽게 '
            '풀리곤 해요',
        ('화', '목'): '장작을 계속 넣어주듯, 목 기운이 끊임없이 불씨를 지펴줘서 열정이 반짝하고 꺼지지 않고 오래도록 '
            '타오르는 편이에요. 새로운 자극과 아이디어가 계속 공급되니, 지치지 않고 끝까지 밀어붙이는 뒷심까지 갖춘 '
            '타입이에요',
        ('토', '금'): '땅속에서 오랜 시간 다져진 광물처럼, 토 기운이 금 기운을 단단히 다져줘서 겉으로는 묵묵하고 '
            '안정적이지만 결정적인 순간에는 결단력이 은근히 빛나는 편이에요. 평소엔 서두르지 않다가도 필요할 땐 '
            '정확하게 끊고 맺을 줄 아는 타입이에요',
        ('토', '목'): '단단한 땅을 뚫고 새순이 돋아나듯, 목 기운이 안정만 좇던 토 기운을 흔들어서 마음에 새로운 자극과 '
            '호기심이 생기는 편이에요. 변화가 낯설게 느껴질 수 있지만, 막상 겪어보면 그 변화가 오히려 더 단단한 '
            '안정으로 이어지는 계기가 되곤 해요',
        ('토', '수'): '둑이 물길을 다잡아 흐름을 잡아주듯, 토 기운이 수 기운을 다잡아서 이런저런 생각으로 흔들리던 '
            '마음도 결국엔 안정적으로 정리해내는 편이에요. 유연한 사고와 묵직한 중심을 동시에 갖춘 셈이라, 웬만한 '
            '일에는 크게 흔들리지 않아요',
        ('토', '화'): '따뜻한 온기가 스며들듯, 화 기운이 은은하게 힘을 보태서 묵묵하기만 하던 안정감에 생기와 활력이 '
            '더해지는 편이에요. 무게감은 그대로 유지하면서도 표정과 태도에서 훈훈한 매력이 느껴지는 타입이에요',
        ('금', '수'): '샘의 근원이 바위틈에서 솟아나듯, 금 기운이 수 기운에 힘을 실어줘서 원칙을 지키는 태도 위에 '
            '유연한 지혜까지 더해지는 편이에요. 맺고 끊는 건 확실하면서도 상황에 따라 부드럽게 방법을 바꿀 줄 아는, '
            '똑똑하게 원칙적인 타입이에요',
        ('금', '화'): '불에 달궈진 쇠가 조금씩 휘어지듯, 화 기운이 금 기운을 살짝 녹여줘서 원래 딱딱하던 태도에 뜻밖의 '
            '부드러움과 표현력이 더해지는 편이에요. 원칙은 원칙대로 지키면서도 사람을 대할 때는 훨씬 인간적인 매력이 '
            '묻어나요',
        ('금', '목'): '가지치기로 정원을 정리하듯, 금 기운이 목 기운을 다듬어줘서 여기저기 벌여둔 일을 끝까지 야무지게 '
            '마무리 짓는 힘이 있는 편이에요. 시작하는 추진력에 마무리하는 뒷심까지 더해지니, 일 잘한다는 소리를 자주 '
            '듣는 타입이에요',
        ('금', '토'): '단단한 지반 위에 세워진 기둥처럼, 토 기운이 든든하게 받쳐줘서 한번 세운 원칙이 쉽게 흔들리지 '
            '않고 오래도록 유지되는 편이에요. 겉으론 냉정해 보여도 그 밑바탕에는 믿음직한 안정감이 깔려 있는 '
            '타입이에요',
        ('수', '목'): '빗물이 스며들어 나무를 무성하게 키우듯, 수 기운이 목 기운을 키워줘서 깊은 통찰력이 머릿속에만 '
            '머물지 않고 새로운 시도와 행동으로 술술 이어지는 편이에요. 생각만 많은 게 아니라 그 생각을 실제로 '
            '실행에 옮기는 지략가 타입이에요',
        ('수', '화'): '출렁이던 물결이 서서히 잠잠해지듯, 수 기운이 화 기운을 가라앉혀줘서 순간적으로 욱하는 감정보다 '
            '차분한 판단이 먼저 앞서는 편이에요. 겉으로는 조용해 보여도 상황을 냉철하게 읽어내는 눈이 있는 타입이에요',
        ('수', '토'): '물길에 둑을 쌓아 흐름을 잡아주듯, 토 기운이 수 기운을 붙잡아줘서 이리저리 흔들리던 마음에 '
            '든든한 중심이 생기는 편이에요. 유연한 사고는 그대로 살아있으면서도, 쉽게 휩쓸리지 않는 무게감까지 '
            '갖추게 돼요',
        ('수', '금'): '바위틈에서 맑은 샘물이 솟아나듯, 금 기운이 원천이 되어줘서 유연하게 흘러가는 성격 속에 단단한 '
            '원칙까지 함께 갖추게 되는 편이에요. 눈치 빠르게 상황에 맞춰가면서도 지킬 건 확실히 지키는, 균형 잡힌 '
            '지략가 타입이에요',
      };

      expect(expected.length, 20, reason: '5×4=20가지 조합이 표에 전부 있어야 한다');
      for (final entry in expected.entries) {
        final (dominant, sub) = entry.key;
        expect(
          dominantComboCallout(dominant, sub, subCount: 1).$3,
          entry.value,
          reason: '($dominant, $sub) 콜아웃 문구',
        );
      }
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

    test('20가지 (dominant, sub) 조합 전부에서 접미사가 관계(OhaengRelation)와 정확히 일치한다 (스왑 방지)', () {
      // 위 두 테스트(pin 1개 + '목' 기준 4개 유일성)만으로는 예를 들어
      // dominantOvercomesSub와 subOvercomesDominant의 접미사 문구가 통째로 서로
      // 바뀌어도 "4가지가 서로 다르다"는 여전히 참이라 못 잡는다 — ohaengRelationOf로
      // 실제 관계를 구해 관계별 기대 접미사와 20가지 (dominant, sub) 조합 전부를
      // 대조한다(ohaeng_readings.dart의 공용 함수 ohaengComboSuffix 원본과 그대로
      // 일치해야 함 — deep_dive_readings.dart의 직장운도 같은 함수를 재사용한다).
      String expectedSuffix(OhaengRelation relation, String sub) {
        switch (relation) {
          case OhaengRelation.dominantGeneratesSub:
            return '$sub 기운까지 힘을 보태서 이 흐름이 한층 살아나요';
          case OhaengRelation.subGeneratesDominant:
            return '$sub 기운이 뒤에서 든든하게 받쳐줘서 이 흐름이 오래 유지돼요';
          case OhaengRelation.dominantOvercomesSub:
            return '$sub 기운을 잘 다스리는 편이라 중심을 잃지 않아요';
          case OhaengRelation.subOvercomesDominant:
            return '$sub 기운이 브레이크가 되어줘서 과하지 않게 조절이 돼요';
        }
      }

      for (final dominant in const ['목', '화', '토', '금', '수']) {
        for (final sub in const ['목', '화', '토', '금', '수']) {
          if (sub == dominant) continue;
          final relation = ohaengRelationOf(dominant, sub);
          final combo = categoryReadingsForCombo(dominant, sub, subCount: 1);
          for (final (_, title, desc) in combo) {
            expect(
              desc,
              endsWith(expectedSuffix(relation, sub)),
              reason: '($dominant, $sub, $title) 접미사',
            );
          }
        }
      }
    });
  });
}
