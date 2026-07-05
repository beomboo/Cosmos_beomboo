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
  });
}
