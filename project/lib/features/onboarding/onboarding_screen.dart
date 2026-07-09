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
          // 목업(`.screen-body`)의 좌우 padding은 20px인데 지금까지는 32px이었다
          // (2026-07-07 대조 발견).
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: Stack(
                    // 반짝이(spark) 두 개가 블롭 경계 밖으로 살짝 나가는 위치라
                    // (top:-6, left:-10) 잘리지 않게 clip을 끈다.
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        // 목업(`.mascot`)은 104x104인데 지금까지는 120x120이었다(2026-07-07
                        // 대조 발견) — 모서리 반경(`.mascot .blob`의 44%~58% 퍼센트값)도
                        // 120 기준으로 계산돼 있었던 걸 104 기준으로 다시 계산해 맞춤.
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.elliptical(46, 50),
                            topRight: Radius.elliptical(58, 46),
                            bottomRight: Radius.elliptical(60, 58),
                            bottomLeft: Radius.elliptical(44, 54),
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.accentSoft, AppColors.woodSoft],
                          ),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            2,
                            // 목업(`.mascot .face i`)은 6x8인데 지금까지는 8x10이었다
                            // (2026-07-07 대조 발견). 가로 여백(7)은 `.face{gap:14px}`와
                            // 이미 일치(점 두 개 사이에 각 7씩 더하면 총 14).
                            (_) => Container(
                              width: 6,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 7),
                              decoration: const BoxDecoration(
                                color: AppColors.ink,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 목업(`.mascot .spark`)의 반짝이 두 개 — 지금까지는 아예 없었다
                      // (2026-07-07 대조 발견). CSS의 `float`/`twinkle` 애니메이션은
                      // 순수 장식용 낮은 우선순위 항목이라 이번에도 스코프 밖으로 남겨두고
                      // (test/tool 등에서 무한 반복 애니메이션 처리 패턴이 필요해질 수 있음),
                      // 정적 위치·크기만 추가한다.
                      const Positioned(
                        top: -6,
                        right: 6,
                        child: Text('✨', style: TextStyle(fontSize: 14)),
                      ),
                      const Positioned(
                        bottom: 2,
                        left: -10,
                        child: Text('⋆', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ),
              // 목업(`.onboarding .screen-body`)은 자식 사이에 균일한 gap:18px를 쓰고,
              // 마스코트만 자기 margin-bottom:4px가 더해져 18+4=22px다 — 지금까지는 20px
              // 이었다(2026-07-07 대조 발견).
              const SizedBox(height: 22),
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
              // 목업의 gap:18px인데 지금까지는 12px이었다(2026-07-07 대조 발견).
              const SizedBox(height: 18),
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
              // 목업의 gap:18px인데 지금까지는 12px이었다(2026-07-07 대조 발견).
              const SizedBox(height: 18),
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
        '입력한 날짜를 그대로 계산에 사용하니, 음력 생일이라면 결과가 실제와 다를 수 있어요. '
        '한국이 서머타임을 시행했던 1948~1960년·1987~1988년생이라면 그 보정도 아직 반영하지 '
        '않아 실제 시각과 최대 1시간까지 차이가 날 수 있어요.',
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
