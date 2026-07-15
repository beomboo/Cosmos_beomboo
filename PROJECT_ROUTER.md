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
| 온보딩 화면 | `project/lib/features/onboarding/` | 🟢 | 최초 진입 화면. 랜드스케이프처럼 세로 폭이 좁은 뷰포트에서 오버플로우 나지 않도록 `LayoutBuilder`+`SingleChildScrollView`로 감싸 필요할 때만 스크롤. 시작 버튼 `Text('시작하기 →')`는 장식용 화살표가 스크린 리더에 읽히지 않도록 `semanticsLabel: '시작하기'` 지정 |
| 생년월일시 정보 입력 화면 | `project/lib/features/birth_input/` | 🟢 | 생년월일시·성별·MBTI 입력. 제출 시 `pushReplacementNamed`로 계산 중 화면으로 넘어가 스택에서 제거됨(뒤로가기로 재진입 불가). 날짜/시간 `PastelPillButton`은 `fieldLabel`('태어난 날짜'/'태어난 시간') 옵션 파라미터로 필드 맥락을 더한 시맨틱 라벨을 위젯 내부에서 조합(값이 라벨과 다를 때는 `semanticValue`로 override, 예: 시간 모름 상태의 "모름")—이전엔 화면마다 바깥 Semantics 래핑 보일러플레이트가 중복돼 있었음(2026-07-15 리팩터로 위젯 안으로 이동). 자시(23시~01시) 경계 안내: 계산 로직(`four_pillars.dart`의 `midnight` 관법)은 그대로 두고, `_isJasiRange`(hour==23 또는 0)이면서 시간 모름 체크가 꺼져 있을 때만 시간 pill 아래에 순화된 안내 문구를 노출(리서치: `docs/research/운세/입력_온보딩_설계.md`). "태어난 시간을 몰라요"/"MBTI를 알고 있어요" 체크박스는 공용 `PastelCheckboxRow` 재사용. 제출 버튼 `Text('사주 보러가기 🔮')`는 이모지가 스크린 리더에 읽히지 않도록 `semanticsLabel: '사주 보러가기'` 지정 |
| 명식 계산 중 화면 | `project/lib/features/calculating/` | 🟢 | 계산 중 애니메이션. 궤도(달+이모지)는 온보딩 마스코트와 같은 장식용이라 `ExcludeSemantics` 처리, 로딩 문구는 `Semantics(liveRegion: true)`로 갱신 안내 |
| 사주 결과 화면 | `project/lib/features/result/` | 🟢 | 4기둥·오행 밸런스(우세+2순위 오행 상생상극 콤보 콜아웃·카테고리 접미사, `ohaeng_readings.dart`의 공용 함수 `ohaengComboSuffix`—심층 분석 직장운과 공유·서술 문단)·공유 카드. 시주(`pillars.hour`)를 모르면 절기 디스클레이머 아래에 3주 계산 사실+재입력 유도 넛지 문구(AppBar "다시 입력하기"와 중복 안 되게 안내 텍스트만) 표시. 메타 라인/헤더 이름 폴백은 `meta_line.dart`의 공용 함수 `buildMetaLine`·`displayNameFor`를 결과·리포트·심층 분석 세 화면이 공유. 메인 콜아웃(결과 화면+공유 카드)과 `_CategoryCard`는 목업 `.callout`/`.cat-card`와 여백·글자 크기까지 일치(콜아웃 padding 15/13·font-size 12.5·line-height 1.55, 카테고리 카드 아이콘 15px·제목 11px). 공유 캡처(`_handleShare`→`shareCapturedCard`, 오프스크린 래퍼→`OffscreenShareCapture`, 둘 다 `shared/`)와 공유 카드 9:16 스캐폴드(`share_card.dart`→`shared/widgets/share_card_scaffold.dart`)는 심층 분석 화면과 공용 로직으로 통합됨(2026-07-15). 오행 밸런스 바(`_OhaengBarRow`)는 한자 대신 한글 오행명으로 `Semantics(label: '$오행 비중 $퍼센트%')` 병합, 한자 태그 14px/바 높이 8px/행 간격 5px·섹션 소제목("오행 밸런스"/"오늘 궁금한 것부터") 11px·inkSoft 톤은 목업(`.bar-row`/`.bars h3`/`.cards h3`)과 일치(2026-07-15). 그라데이션 공유 버튼(`Text('📸 공유하기')`, `semanticsLabel: '공유하기'`)은 심층 분석 화면과 완전히 같은 구조라 공용 `GradientShareButton`으로 통합됨(2026-07-15). 오행 밸런스 바(`_OhaengBarRow`)의 한자 태그(`SizedBox(width:14)`)·퍼센트 텍스트(`SizedBox(width:40)`)는 시스템 폰트 확대 시 조용히 잘리던 걸 각각 `FittedBox(fit: scaleDown)`로 감싸 방지(기본 배율에선 시각 변화 없음, 2026-07-15 접근성 감사) |
| 상세 리포트 화면 | `project/lib/features/report/` | 🟢 | 오행별 상세 해석. 시주를 모르면 `_pillarRow` 안내 문구 뒤에 재입력 유도 넛지 문구 덧붙임. 심층 분석 진입 링크 `Text('MBTI·관심사로 심층 분석 받기 →')`는 장식용 화살표가 스크린 리더에 읽히지 않도록 `semanticsLabel: 'MBTI·관심사로 심층 분석 받기'` 지정. `_PillarBreakdownTable._pillarRow`의 년주/월주/일주/시주 라벨(`SizedBox(width:44)`)·`_OhaengMeaningCard`의 40x40 원형 배지 한자도 시스템 폰트 확대 시 조용히 잘리던 걸 `FittedBox(fit: scaleDown)`로 감싸 방지(기본 배율에선 시각 변화 없음, 2026-07-15 접근성 감사) |
| 심층 분석(MBTI·관심사) | `project/lib/features/deep_dive/` | 🟢 | 관심사 선택 + 심층 분석 결과. 직장운 콤보 접미사는 결과 화면과 같은 공용 함수(`ohaengComboSuffix`) 재사용. 관심사 입력 화면의 안내 문구+칩 Wrap도 `PastelToggleRow`와 같은 그룹 시맨틱스(`Semantics(container: true, label: '관심 있는 영역 선택')`) 적용. 결과 화면과 같은 패턴의 공유하기(`DeepDiveShareCard`+`buildDeepDiveShareText`, MBTI 코멘트/관심사 중 하나라도 있어야 버튼 노출, MBTI 박스는 오행색 대신 항상 `accentSoft` 고정) 지원 — 캡처/공유 로직·오프스크린 래퍼·9:16 스캐폴드는 결과 화면과 공용(`shared/share/share_capture.dart`, `shared/widgets/offscreen_share_capture.dart`, `shared/widgets/share_card_scaffold.dart`)으로 통합됨(2026-07-15). `deep_dive_input_screen.dart`의 `initState()`가 `_loadSaved()`를 fire-and-forget으로 던지던 걸 `late final Future<void> _loadFuture`로 바꿔 보관하고, 제출 콜백(`_saveAndContinue`)이 저장 직전 그 Future를 먼저 기다리게 해서 로드 완료 전 즉시 제출 시 birth_input에서 저장해둔 MBTI가 `null`로 덮어써지던 데이터 유실 버그 수정. 그라데이션 공유 버튼도 결과 화면과 완전히 같은 구조라 공용 `GradientShareButton`으로 통합됨(2026-07-15) |
| 십신(十神) 콘텐츠 확장 | 아직 없음 — 만든다면 `project/lib/features/deep_dive/` 또는 `project/lib/features/ten_gods/` | ⚪ | 사람 결정 대기, 자동화 루프 임의 착수 금지 |
| 사주 계산 로직 | `project/lib/core/saju/` | 🟡 | `ganzhi.dart`(오행 한자 공용 상수 `ohaengHanja`, 오행 상생상극 관계 판별 `ohaengRelationOf`/`OhaengRelation` 포함)+`four_pillars.dart`(`dominantOhaeng`/`subDominantOhaeng`). 절기 근사·자시 관법·진태양시·음력 변환 등 정확도 이슈는 사람 결정 대기 |
| 공용 위젯 | `project/lib/shared/widgets/` | 🟢 | `PastelPillButton`(`fieldLabel`/`semanticValue`로 필드 맥락 시맨틱 라벨 조합 지원)/`PastelToggleRow`/`PastelCard`/`PastelCheckboxRow`(체크박스+터치 가능 라벨 행)/`GradientShareButton`(accent→metal 그라데이션 공유 버튼, 결과·심층 분석 화면 공용)/`OffscreenShareCapture`(오프스크린 공유 캡처 래퍼)/`ShareCardScaffold`(공유 카드 9:16 공통 스캐폴드) |
| 공유 캡처 로직 | `project/lib/shared/share/share_capture.dart` | 🟢 | `shareCapturedCard` — RepaintBoundary 캡처→SharePlus 공유→실패 스낵바를 결과·심층 분석 화면이 공용으로 사용 |
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
