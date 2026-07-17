import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 화면 최상단 페이지 제목(예: "회원님의 상세 리포트", "회원님의 심층 분석 ✨")에 쓰는 공용
/// 헤딩 위젯. TalkBack/VoiceOver의 헤딩 단위 탐색(제목만 골라 건너뛰기)을 지원하려면
/// `Semantics(header: true)`가 필요한데(2026-07-16 접근성 감사 발견), 이 스타일 조합
/// (`fontWeight: FontWeight.w800`/`color: AppColors.ink`/`fontSize: 20`)을
/// report_screen.dart와 deep_dive_result_screen.dart가 각각 하드코딩하고 있었다
/// (2026-07-17 오버나이트 코드 정리로 통합).
///
/// [semanticsLabel]은 제목에 장식용 이모지(예: "✨")가 섞여 스크린 리더가 그대로 읽으면
/// 어색한 경우에만 넘긴다(생략하면 [title] 문자열이 그대로 자동 라벨이 된다).
class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, this.semanticsLabel});

  final String title;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        semanticsLabel: semanticsLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          fontSize: 20,
        ),
      ),
    );
  }
}
