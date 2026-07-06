import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/theme/app_colors.dart';

/// WCAG 2.x 상대 휘도/명암비 계산. 참고: https://www.w3.org/TR/WCAG21/#contrast-minimum
double _channel(double c) {
  if (c <= 0.03928) return c / 12.92;
  return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  return 0.2126 * _channel(color.r) + 0.7152 * _channel(color.g) + 0.0722 * _channel(color.b);
}

double _contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppColors 텍스트 대비(WCAG AA)', () {
    test('inkSoft는 bg/bgCard 위에서 4.5:1 이상을 유지한다 (작은 캡션 텍스트에 많이 쓰임)', () {
      expect(_contrastRatio(AppColors.inkSoft, AppColors.bg), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(AppColors.inkSoft, AppColors.bgCard), greaterThanOrEqualTo(4.5));
    });

    test('ink는 bg/bgCard 위에서 넉넉히 통과한다 (회귀 방지용 기준선)', () {
      expect(_contrastRatio(AppColors.ink, AppColors.bg), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(AppColors.ink, AppColors.bgCard), greaterThanOrEqualTo(4.5));
    });

    test(
      'ohaengTextColors는 bg/bgCard뿐 아니라 자신의 ohaengSoftColors 배경 위에서도 4.5:1 이상이다 '
      '(순수 오행색 ohaengColors는 배경/아이콘용이라 대비가 낮음 — 텍스트에는 이 값을 대신 써야 함)',
      () {
        for (final ohaeng in AppColors.ohaengTextColors.keys) {
          final textColor = AppColors.ohaengTextColors[ohaeng]!;
          final softBg = AppColors.ohaengSoftColors[ohaeng]!;
          expect(
            _contrastRatio(textColor, AppColors.bg),
            greaterThanOrEqualTo(4.5),
            reason: '$ohaeng on bg',
          );
          expect(
            _contrastRatio(textColor, AppColors.bgCard),
            greaterThanOrEqualTo(4.5),
            reason: '$ohaeng on bgCard',
          );
          expect(
            _contrastRatio(textColor, softBg),
            greaterThanOrEqualTo(4.5),
            reason: '$ohaeng on its own ohaengSoftColors',
          );
        }
      },
    );

    test(
      'accentText는 bg/bgCard/accentSoft 위에서 모두 4.5:1 이상이다 '
      '(순수 accent는 브랜드 버튼 배경용이라 대비가 낮음 — 텍스트에는 이 값을 대신 써야 함)',
      () {
        expect(_contrastRatio(AppColors.accentText, AppColors.bg), greaterThanOrEqualTo(4.5));
        expect(_contrastRatio(AppColors.accentText, AppColors.bgCard), greaterThanOrEqualTo(4.5));
        expect(
          _contrastRatio(AppColors.accentText, AppColors.accentSoft),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    test(
      'accent 배경 + accentInk(흰) 텍스트는 여전히 WCAG AA 미달이다 — 알려진 이슈, 사람 결정 대기 '
      '(PROJECT_ROUTER.md/CLAUDE.md 참고). `ElevatedButtonThemeData`의 브랜드 CTA 버튼("시작하기 →" '
      '등)이 이 조합을 그대로 쓴다 — 목업(.btn-primary)도 동일하게 accent 배경+흰 글자를 쓰므로 '
      '목업 그대로 구현한 의도적 결과다. **2026-07-06 수정**: `PastelToggleRow`의 선택된 토글(성별·'
      '양력/음력)과 심층 분석의 선택된 관심사 칩은 원래 이 조합을 그대로 잘못 재사용하고 있었는데, '
      '목업(`.pill.is-active`)을 다시 대조해보니 실제로는 accentSoft 배경+accentText 글자(아래 '
      '"accentText는..." 테스트로 이미 통과가 확인된 조합)를 쓴다는 걸 발견해 그쪽만 바로잡았다 — '
      '이제 이 accent+accentInk 미달 조합은 브랜드 CTA 버튼에만 남아있다. 이 값이 바뀌면(예: 팔레트 '
      '조정으로 우연히 통과) 이 테스트가 실패하면서 문서를 갱신할 시점을 알려준다.',
      () {
        final ratio = _contrastRatio(AppColors.accent, AppColors.accentInk);
        expect(ratio, closeTo(2.72, 0.05));
        expect(ratio, lessThan(4.5));
      },
    );
  });

  group('AppColors 비텍스트 대비(WCAG 1.4.11 Non-text Contrast) — 2026-07-06 신규 발견', () {
    test(
      'border(카드/버튼 테두리)는 bg/bgCard 위에서 3:1 미달이다 — 알려진 이슈, 사람 결정 대기. '
      '위 그룹은 "텍스트" 대비(WCAG 1.4.3, 4.5:1 기준)만 다뤘는데, `border`는 텍스트가 아니라 '
      '`PastelCard`/`PastelPillButton`/`PastelToggleRow`(비선택)/`ShareCard`의 카드·버튼·칩 '
      '테두리로 쓰여 WCAG 1.4.11(비텍스트 대비, 3:1 기준) 대상이다. 실측 대비가 약 1.2:1로 '
      '거의 안 보이는 수준이라(같은 톤의 매우 옅은 오프화이트끼리라 그런 것으로 보임), 저시력 '
      '사용자에게는 카드/버튼의 경계 자체가 안 보일 수 있다. `accent`/`accentInk` 텍스트 대비 '
      '미달과 마찬가지로 팔레트(브랜드 컬러) 조정이 필요해 코드 수정이 아니라 사람 결정 대기 '
      '항목으로 남겨두고, 값이 바뀌면 이 테스트가 먼저 실패해 문서 갱신 시점을 알려준다.',
      () {
        final onBg = _contrastRatio(AppColors.border, AppColors.bg);
        final onBgCard = _contrastRatio(AppColors.border, AppColors.bgCard);
        expect(onBg, closeTo(1.21, 0.05));
        expect(onBgCard, closeTo(1.24, 0.05));
        expect(onBg, lessThan(3.0));
        expect(onBgCard, lessThan(3.0));
      },
    );

    test(
      'PastelToggleRow 선택된 토글의 accent 테두리도 bgCard 위에서 3:1 미달이다 — 위 accent/accentInk '
      '텍스트 대비 이슈와 원인이 같은 브랜드 컬러(accent) 문제라 별도 항목이 아니라 같은 사람 결정에 '
      '포함해 참고용으로 남겨둔다. **2026-07-06 참고**: 선택된 토글의 배경·글자색은 accentSoft/'
      'accentText로 바로잡아 텍스트 대비는 해결됐지만, 테두리 색 자체(목업 `.pill.is-active`의 '
      '`border-color: var(--app-accent)`)는 그대로 accent를 쓰므로 이 비텍스트 대비 이슈는 '
      '여전히 남아있다.',
      () {
        final ratio = _contrastRatio(AppColors.accent, AppColors.bgCard);
        expect(ratio, closeTo(2.72, 0.05));
        expect(ratio, lessThan(3.0));
      },
    );
  });
}
