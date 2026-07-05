import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';

/// 온보딩 화면 — 앱 소개 + 시작 CTA.
/// 참고: docs/mockups/01-pastel-cute.html (파스텔 큐트 컨셉)
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // 바로 아래 "사주랑" 텍스트와 의미가 겹치는 장식용 아이콘이라, 스크린 리더가
              // 중복으로 읽지 않도록 시맨틱 트리에서 제외한다.
              ExcludeSemantics(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 56,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 목업(STEP 1)의 워드마크 — 아래 헤드라인보다 작게, 브랜드 이름만 짧게 보여준다.
              // 목업 CSS는 이 텍스트에 accent(#FF6B8A)를 그대로 쓰지만 WCAG AA 미달(2.64:1)이라,
              // 오행 텍스트와 같은 방식으로 만든 accentText(텍스트 전용 진한 버전)를 대신 쓴다.
              const Text(
                '사주랑',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentText,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '내 안의 오행,\n3분이면 알 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '생년월일시만 입력하면 끝!\n어려운 명리학 용어 없이 쉽게 풀어드려요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.inkSoft,
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.birthInput);
                  },
                  child: const Text('시작하기'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showHowItWorksDialog(context),
                child: const Text(
                  '어떻게 계산되나요?',
                  style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// "어떻게 계산되나요?" 링크(참고: docs/mockups/01-pastel-cute.html STEP 1)를 눌렀을 때
/// 뜨는 설명 다이얼로그. `report_screen.dart`의 계산 정확도 안내 문단과 같은 내용을
/// 온보딩 시점에도 미리 짧게 알려줘, 시작하기 전부터 정직하게 기대치를 맞춘다.
void _showHowItWorksDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('어떻게 계산되나요?'),
      content: const Text(
        '생년월일시를 60갑자(간지)로 변환해 네 기둥(년주·월주·일주·시주)과 오행 밸런스를 계산해요.\n\n'
        '다만 정확한 절기 대신 근사치(입춘을 2월 4일로 고정, 달력상의 월 기준)를 써서 계산해요. '
        '그래서 절기 경계에 가까운 생일은 정통 만세력과 며칠 차이가 날 수 있어요.',
        style: TextStyle(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
