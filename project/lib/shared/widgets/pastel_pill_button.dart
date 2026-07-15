import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 알약(pill) 모양 버튼. 날짜/시간 선택 등 단일 값을 보여주고 탭하면 동작하는 용도.
/// `onTap`이 null이면 비활성 상태로 표시된다.
class PastelPillButton extends StatelessWidget {
  const PastelPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fieldLabel,
    this.semanticValue,
  });

  final String label;
  final VoidCallback? onTap;

  /// 필드 맥락(예: '태어난 날짜')을 시맨틱 라벨 앞에 덧붙이고 싶을 때 지정한다.
  /// 버튼 자체 라벨은 값만("1998.08.15") 담고 있어, 필드 이름을 안내하는 라벨(예:
  /// _FieldLabel)을 스크린 리더가 건너뛰고 이 버튼에 바로 도달하면 무슨 필드인지
  /// 맥락이 없다 — birth_input_screen.dart의 날짜/시간 pill이 겪었던 문제
  /// (2026-07-15 접근성 발견, 이후 이 위젯 안으로 이동해 중복 제거·2026-07-15).
  /// 지정하면 시맨틱 라벨이 '$fieldLabel ${semanticValue ?? label}'이 되고, 미지정
  /// 시(null, 기본값) 기존 동작(라벨은 $label 그대로)과 100% 동일하게 유지된다 —
  /// 이 위젯을 쓰는 다른 화면(예: PastelToggleRow가 아닌 다른 pill 사용처)에는
  /// 영향이 없다.
  final String? fieldLabel;

  /// `fieldLabel`과 조합될 값이 화면에 보이는 [label]과 다를 때 지정한다(예: 시간
  /// 모름 상태에서 버튼에는 "시간 모름"이 보이지만 "태어난 시간 시간 모름"처럼
  /// "시간"이 중복되지 않도록 시맨틱 조합에는 "모름"만 써야 하는 경우). 지정하지
  /// 않으면 [label]을 그대로 쓴다. `fieldLabel`이 null이면 아예 쓰이지 않는다.
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = fieldLabel == null ? label : '$fieldLabel ${semanticValue ?? label}';
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      // excludeSemantics로 자식(InkWell)의 자동 시맨틱스를 대체하므로, 탭 액션도
      // 여기서 직접 다시 선언해야 스크린 리더의 "두 번 탭해서 활성화"가 동작한다.
      onTap: onTap,
      // 자식 Text가 만드는 자동 라벨과 병합되면 "라벨\n라벨"처럼 중복되므로 대체한다.
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        // 목업(docs/mockups/01-pastel-cute.html)의 `.pill`은 완전히 둥근 알약 모양이
        // 아니라 12px 모서리 반경만 쓴다 — 이름과 달리 "알약"이 아니었음(2026-07-06 대조).
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // 목업(`.pill`)은 padding:9px 14px인데 지금까지는 20/14였다
          // (2026-07-07 대조 발견).
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: onTap == null ? AppColors.border.withValues(alpha: 0.4) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            // 목업(`.pill`)은 1.5px 테두리를 쓰는데 지금까지는 기본값인 1px이었다
            // (2026-07-07 대조 발견).
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
