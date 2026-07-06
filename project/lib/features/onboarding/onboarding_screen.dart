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
              // 바로 아래 "사주랑" 텍스트와 의미가 겹치는 장식용 마스코트라, 스크린 리더가
              // 중복으로 읽지 않도록 시맨틱 트리에서 제외한다.
              // 2026-07-06 목업 대조 발견: 지금까지는 그냥 원 안에 반짝임 아이콘을 넣은
              // 형태였는데, 목업(`.mascot .blob`)은 완전한 원이 아니라 CSS
              // `border-radius: 44% 56% 58% 42% / 48% 44% 56% 52%`로 만든 비대칭
              // "블롭"(구름 같은 유기적 도형) 모양에 accentSoft→woodSoft 그라데이션과
              // 옅은 accent 테두리, 그리고 반짝이는 아이콘 대신 작은 점 두 개짜리
              // "눈"(`.face i`)이 있는 캐릭터였음 — Flutter의 `Radius.elliptical`이
              // CSS의 가로/세로 분리 반경(`/`로 구분된 두 값)과 정확히 대응돼 그대로 포팅.
              ExcludeSemantics(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.elliptical(53, 58),
                      topRight: Radius.elliptical(67, 53),
                      bottomRight: Radius.elliptical(70, 67),
                      bottomLeft: Radius.elliptical(50, 62),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accentSoft, AppColors.woodSoft],
                    ),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                      (_) => Container(
                        width: 8,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
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
                  child: const Text('시작하기 →'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showHowItWorksDialog(context),
                child: const Text(
                  '어떻게 계산되나요?',
                  // 목업(`.link-quiet`)은 밑줄 있는 링크(12px, font-weight 700)인데
                  // 지금까지는 밑줄 없이 기본 크기/w600이었다 — result_screen.dart의
                  // "상세 리포트 보기" 링크(.report-link)에서 겪은 것과 같은 종류의
                  // 누락이라 같은 방식으로 수정(2026-07-06 대조 발견).
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.inkSoft,
                  ),
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
        '그래서 절기 경계에 가까운 생일은 정통 만세력과 며칠 차이가 날 수 있어요. '
        '자시(밤 11시~새벽 1시) 출생이나 태어난 지역의 시차 보정도 아직 반영하지 않아서, '
        '그 경우엔 결과가 조금 다를 수 있어요. 음력으로 입력해도 지금은 양력으로 변환하지 않고 '
        '입력한 날짜를 그대로 계산에 사용하니, 음력 생일이라면 결과가 실제와 다를 수 있어요.',
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
