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
    this.semanticLabel,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  /// 이 토글 묶음이 무엇을 고르는 그룹인지 스크린 리더에 알려주는 라벨
  /// (목업의 `role="group" aria-label="..."`와 동일한 목적). 화면에 이 그룹의
  /// 의미를 알려주는 `_FieldLabel`이 바로 앞에 있어도, 스크린 리더 사용자가
  /// 순서대로 읽지 않고(예: 화면 훑기) 버튼으로 곧장 이동하면 그 라벨을 놓칠 수
  /// 있으므로, 버튼 각각의 라벨과는 별도로 그룹 자체에도 라벨을 붙여둔다.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final row = Row(
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                // 목업(`.pill`)은 padding:9px 14px인데 지금까지는 20/12였다
                // (2026-07-07 대조 발견).
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  // 목업(docs/mockups/01-pastel-cute.html)의 `.pill.is-active`는 배경을
                  // 진한 accent가 아니라 옅은 accentSoft로, 글자도 흰색이 아니라 진한
                  // accentText로 쓴다 — 2026-07-06까지는 브랜드 CTA 버튼(.btn-primary)과
                  // 같은 조합(accent+흰 글자)을 잘못 써서 WCAG AA 텍스트 대비(4.5:1) 미달
                  // 문제가 있었는데, 목업 그대로 맞추면서 자연히 해결됨(accentText는 이미
                  // accentSoft 위에서 4.5:1 이상 통과하도록 설계돼 있음, app_colors.dart 참고).
                  color: isActive ? AppColors.accentSoft : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  // 목업(`.pill`)은 1.5px 테두리를 쓰는데 지금까지는 기본값인 1px이었다
                  // (2026-07-07 대조 발견).
                  border: Border.all(
                    color: isActive ? AppColors.accent : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.accentText : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );

    if (semanticLabel == null) return row;

    // container: true로 그룹 자체가 독립된 시맨틱스 노드가 되게 하되(이웃 필드와
    // 안 섞이도록), excludeSemantics는 안 줘서 버튼 각각의 selected/button 상태는
    // 그대로 유지한다 — 그룹 라벨과 개별 버튼 상태를 둘 다 들려주기 위함.
    return Semantics(
      container: true,
      label: semanticLabel,
      child: row,
    );
  }
}
