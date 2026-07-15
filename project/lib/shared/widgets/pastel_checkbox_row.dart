import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 목업(`.check-row`)의 체크박스 행 — CheckboxListTile을 써서 체크박스뿐 아니라
/// 라벨 글자를 눌러도 반응하게 한다(터치 영역이 넓어져 접근성/사용성 모두 개선됨).
/// birth_input_screen.dart의 "태어난 시간을 몰라요"/"MBTI를 알고 있어요" 두 체크박스가
/// 완전히 동일한 스타일(`activeColor`/`controlAffinity`/`contentPadding`/`dense`)을
/// 반복하고 있어 공용 위젯으로 통합했다(2026-07-15 리팩터).
class PastelCheckboxRow extends StatelessWidget {
  const PastelCheckboxRow({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      // 목업(`.check-row`)은 12px인데 지금까지 기본 크기였다(2026-07-06 대조 발견).
      title: Text(
        label,
        style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
