import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 알약(pill) 모양 버튼. 날짜/시간 선택 등 단일 값을 보여주고 탭하면 동작하는 용도.
/// `onTap`이 null이면 비활성 상태로 표시된다.
class PastelPillButton extends StatelessWidget {
  const PastelPillButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      // excludeSemantics로 자식(InkWell)의 자동 시맨틱스를 대체하므로, 탭 액션도
      // 여기서 직접 다시 선언해야 스크린 리더의 "두 번 탭해서 활성화"가 동작한다.
      onTap: onTap,
      // 자식 Text가 만드는 자동 라벨과 병합되면 "라벨\n라벨"처럼 중복되므로 대체한다.
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: onTap == null ? AppColors.border.withValues(alpha: 0.4) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
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
