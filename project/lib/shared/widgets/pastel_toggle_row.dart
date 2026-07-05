import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 알약 모양 토글 버튼 여러 개를 가로로 나열해 하나만 고르게 하는 위젯.
/// 양력/음력, 성별 선택 등에 사용.
class PastelToggleRow<T> extends StatelessWidget {
  const PastelToggleRow({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.entries.map((entry) {
        final isActive = entry.key == value;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Semantics(
            button: true,
            selected: isActive,
            label: entry.value,
            // excludeSemantics로 자식(InkWell)의 자동 시맨틱스를 대체하므로, 탭 액션도
            // 여기서 직접 다시 선언해야 스크린 리더의 "두 번 탭해서 활성화"가 동작한다.
            onTap: () => onChanged(entry.key),
            // 자식 Text가 만드는 자동 라벨과 병합되면 "라벨\n라벨"처럼 중복되므로 대체한다.
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.accentInk : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
