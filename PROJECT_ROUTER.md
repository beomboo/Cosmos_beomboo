# PROJECT_ROUTER — 기능별 경로 안내

이 문서는 `COSMOS_BEOMBOO` 앱(Flutter, `project/`)에 구현된 비즈니스 로직의 조직도입니다.
작업 요구사항을 분석한 후, 이 표에서 관련 기능의 경로를 먼저 확인하고 해당 코드로 이동해
작업하세요. 새 기능/화면/모듈을 추가했다면 반드시 아래 표에 항목을 추가하세요.

**이 문서는 경로를 빠르게 찾기 위한 네비게이션 용도입니다 — 사이클별 발견/수정 이력을
누적해서 기록하는 곳이 아닙니다.** 각 행은 "현재 상태"만 한 줄로 유지하세요. 과거 이력이
궁금하면 `git log -p PROJECT_ROUTER.md`로 확인할 수 있습니다.

관련 규칙: [CLAUDE.md](CLAUDE.md)

## 기능별 경로

| 기능 | 경로 | 상태 | 설명 |
|---|---|---|---|
| 앱 진입점 | `project/lib/main.dart` | 🟢 | 앱 시작점, 강제 라이트 테마 초기화 |
| 공통 테마/디자인 토큰 | `project/lib/app/theme/` | 🟡 | 파스텔 큐트 컬러/타이포 토큰. accent 버튼 대비(WCAG)는 사람 결정 대기 |
| 라우팅 | `project/lib/app/router.dart` | 🟢 | 화면 간 라우트 정의 |
| 생년월일시 저장소 | `project/lib/core/storage/` | 🟢 | `BirthInfoStore`/`DeepDiveInfoStore` (SharedPreferences) |
| 온보딩 화면 | `project/lib/features/onboarding/` | 🟢 | 최초 진입 화면. 랜드스케이프처럼 세로 폭이 좁은 뷰포트에서 오버플로우 나지 않도록 `LayoutBuilder`+`SingleChildScrollView`로 감싸 필요할 때만 스크롤 |
| 생년월일시 정보 입력 화면 | `project/lib/features/birth_input/` | 🟢 | 생년월일시·성별·MBTI 입력. 제출 시 `pushReplacementNamed`로 계산 중 화면으로 넘어가 스택에서 제거됨(뒤로가기로 재진입 불가) |
| 명식 계산 중 화면 | `project/lib/features/calculating/` | 🟢 | 계산 중 애니메이션. 궤도(달+이모지)는 온보딩 마스코트와 같은 장식용이라 `ExcludeSemantics` 처리, 로딩 문구는 `Semantics(liveRegion: true)`로 갱신 안내 |
| 사주 결과 화면 | `project/lib/features/result/` | 🟢 | 4기둥·오행 밸런스(우세+2순위 오행 상생상극 콤보 콜아웃·카테고리 접미사, `ohaeng_readings.dart`의 공용 함수 `ohaengComboSuffix`—심층 분석 직장운과 공유·서술 문단)·공유 카드. 시주(`pillars.hour`)를 모르면 절기 디스클레이머 아래에 3주 계산 사실+재입력 유도 넛지 문구(AppBar "다시 입력하기"와 중복 안 되게 안내 텍스트만) 표시. 메타 라인/헤더 이름 폴백은 `meta_line.dart`의 공용 함수 `buildMetaLine`·`displayNameFor`를 결과·리포트·심층 분석 세 화면이 공유 |
| 상세 리포트 화면 | `project/lib/features/report/` | 🟢 | 오행별 상세 해석. 시주를 모르면 `_pillarRow` 안내 문구 뒤에 재입력 유도 넛지 문구 덧붙임 |
| 심층 분석(MBTI·관심사) | `project/lib/features/deep_dive/` | 🟢 | 관심사 선택 + 심층 분석 결과. 직장운 콤보 접미사는 결과 화면과 같은 공용 함수(`ohaengComboSuffix`) 재사용. 관심사 입력 화면의 안내 문구+칩 Wrap도 `PastelToggleRow`와 같은 그룹 시맨틱스(`Semantics(container: true, label: '관심 있는 영역 선택')`) 적용. 결과 화면은 사주 결과 화면과 같은 패턴의 공유하기(`DeepDiveShareCard`+`buildDeepDiveShareText`, MBTI 코멘트/관심사 중 하나라도 있어야 버튼 노출, MBTI 박스는 오행색 대신 항상 `accentSoft` 고정) 지원 |
| 십신(十神) 콘텐츠 확장 | 아직 없음 — 만든다면 `project/lib/features/deep_dive/` 또는 `project/lib/features/ten_gods/` | ⚪ | 사람 결정 대기, 자동화 루프 임의 착수 금지 |
| 사주 계산 로직 | `project/lib/core/saju/` | 🟡 | `ganzhi.dart`(오행 한자 공용 상수 `ohaengHanja`, 오행 상생상극 관계 판별 `ohaengRelationOf`/`OhaengRelation` 포함)+`four_pillars.dart`(`dominantOhaeng`/`subDominantOhaeng`). 절기 근사·자시 관법·진태양시·음력 변환 등 정확도 이슈는 사람 결정 대기 |
| 공용 위젯 | `project/lib/shared/widgets/` | 🟢 | `PastelPillButton`/`PastelToggleRow`/`PastelCard` |
| 빌드 검증 스크립트 | `project/tool/check_build.sh` | 🟢 | 표준 빌드/린트 체크(pub get→analyze→test→build apk) 일괄 실행 |
| 앱 아이콘 | `project/assets/icon/icon.png` | 🟢 | 생성 도구: `project/test/tool/generate_app_icon.dart` |

상태 범례: 🟢 완료 · 🟡 진행 중/부분 완료(사람 결정 대기 항목 포함) · ⚪ 미착수

## 참고 자료 (원자료, 수정 지양)

| 자료 | 경로 |
|---|---|
| 사주팔자 계산·이론(십신/용신/대운세운/십이운성/신살/공망/택일/정확도 이슈/오픈소스) | `docs/research/사주팔자/` |
| 궁합 | `docs/research/궁합/` |
| MBTI | `docs/research/MBTI/` |
| 운세(시장·트렌드·UI/UX·SNS 전략) | `docs/research/운세/` |
| UI/UX 목업 4종 | `docs/mockups/` |
| 오버나이트 루프 재사용 프롬프트 | `COSMOS_LOOP_JOB.md` |
