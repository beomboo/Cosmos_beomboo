# Dr.Saju 오픈소스 심층 분석

GitHub API로 실제 소스(`globals.css`, 컴포넌트 디렉토리)를 직접 확인한 결과입니다.

## 실제 컬러 테마 — "다크 + 보라(violet) 프리미엄" 컨셉
포스텔러류의 파스텔/큐트 방향과 달리, Dr.Saju는 **어둡고 신비로운 프리미엄 톤**을 선택했습니다.

| 역할 | 값 | 비고 |
|---|---|---|
| Primary | `#8b5cf6` (violet) | 버튼/강조/링/차트 기본색 — "toss-blue"란 변수명이지만 실제 톤은 보라 |
| Primary Dark | `#7c3aed` | hover 등 |
| 포인트(골드) | `#C5A44E` ("legal-gold") | 프리미엄/유료 배지 등에 사용 추정 |
| Background | `#0a0a0f` | 거의 검정에 가까운 다크 배경 |
| Card | `#13131a` | |
| Border | `#2a2a3a` | |
| Text | `#e2e8f0` | 밝은 회색 텍스트 |
| Success/Warning/Error | `#10b981` / `#f59e0b` / `#ef4444` | 표준 시맨틱 컬러 |

- 폰트: DM Sans (`--font-dm-sans`), 모노스페이스는 Geist Mono
- shadcn/ui + daisyUI 병행 사용, radius는 `0.75rem` 기본(카드/버튼 모두 둥근 편)
- 마이크로 인터랙션: `glowPulse`(보라색 글로우 펄스), `shimmer`, `marquee`(무한 슬라이드), `fadeIn/slideUp/scaleIn` 스태거 애니메이션 다수 — 정적인 리포트가 아니라 등장 연출에 공을 들인 구조

## 실제 사용자 플로우 (컴포넌트 디렉토리 기준)
`src/components/saju/` 하위 실제 폴더명 — 곧 이 앱의 화면/기능 단위:

```
landing → input → preview → result → report
                                 ↓
                    share / referral / upsell → payment → coin-shop
chat/[characterId] → (캐릭터별 AI 채팅 결과 해석)
```

- **landing → input → preview → result**: 정통 온보딩→입력→미리보기(일부 무료 공개)→전체 결과 흐름
- **result → report**: 요약형 결과에서 상세 리포트(유료)로 확장되는 지점이 명확히 분리되어 있음
- **share / referral**: 결과 공유와 추천인 초대가 결과 화면 바로 다음 단계로 설계됨 (바이럴 루프를 플로우에 내장)
- **upsell → payment → coin-shop**: 코인(재화) 구매 방식의 과금 모델 — 리포트 1건당 코인 차감 구조로 추정
- **chat/[characterId]**: 캐릭터별로 별도 라우트 — 8종 캐릭터 각각 성격이 다른 대화형 해석 제공

## 우리 프로젝트에 주는 시사점
1. **디자인 방향성 선택 필요**: "파스텔 큐트"(포스텔러/헬로우봇 계열) vs "다크 프리미엄 미스틱"(Dr.Saju 계열) — 둘 다 유효한 전략이므로 타겟(더 어린 Z세대 vs 2030 프리미엄 지향)에 따라 결정 필요. 아래 03 문서에 비교표 추가함.
2. **결과 화면을 result/report 두 단계로 분리**하는 구조는 무료/유료 경계 설계에 그대로 참고 가능
3. **캐릭터별 별도 라우트**(`chat/[characterId]`) 구조는 "캐릭터화" UX 트렌드를 기술적으로 어떻게 구현했는지 보여주는 실전 사례
4. 애니메이션이 상당히 많음 — 로딩/결과 등장 연출에 투자할 가치가 있다는 방증

## 출처
- [globals.css 원본](https://raw.githubusercontent.com/imgompanda/drsaju-opensource/main/src/app/globals.css)
- [저장소](https://github.com/imgompanda/drsaju-opensource)
