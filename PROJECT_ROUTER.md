# PROJECT_ROUTER — 기능별 경로 안내

이 문서는 `COSMOS_BEOMBOO` 앱의 모든 기능이 어느 경로에 있는지 알려주는 네비게이션 문서입니다.
**작업을 시작하기 전, 관련 기능이 이미 이 표에 있는지 먼저 확인하고 해당 경로로 이동해 작업하세요.**
새 기능/화면/모듈을 추가했다면 반드시 아래 표에 항목을 추가하세요.

관련 규칙: [CLAUDE.md](CLAUDE.md) · 진행 로그: [PROGRESS.md](PROGRESS.md)

## 채택된 디자인 컨셉

**파스텔 큐트** — [docs/mockups/01-pastel-cute.html](docs/mockups/01-pastel-cute.html) (흰 배경 + 파스텔 오행 컬러 + 귀여운 마스코트)

## 기능 라우팅 표

| 기능 | 상태 | 경로 | 설명 |
|---|---|---|---|
| 앱 진입점 | 🟢 완료 | `project/lib/main.dart` | `CosmosSajuApp` — 시작 시 저장된 `BirthInfo`가 있으면 바로 결과 화면, 없으면 온보딩. OS 홈 화면 앱 이름도 "사주랑"으로 통일(`android/.../AndroidManifest.xml`, `ios/Runner/Info.plist`, `macos/.../AppInfo.xcconfig`). `flutter_localizations`로 로케일을 `ko_KR` 고정해 `showDatePicker`/`showTimePicker`가 한국어로 표시됨. `test/widget_test.dart`에 실제 `AppRoutes.routes` 배선을 그대로 타는 온보딩→입력→계산 중→결과→상세 리포트 전체 여정(end-to-end) 테스트, 그리고 저장된 값→"다시 입력하기"→새 값 재제출까지 실제 라우트로 잇는 테스트도 포함(개별 화면 스텁 테스트만으로는 못 잡는 라우트/인자 전달/데이터 교체 회귀를 잡기 위함) |
| 공통 테마/디자인 토큰 | 🟡 진행 중 | `project/lib/app/theme/` | `app_colors.dart`(파스텔 큐트 팔레트+오행 5색), `app_theme.dart`(ThemeData). `inkSoft` 조정 완료. 오행색을 텍스트로 쓸 때는 `ohaengColors`(배경/아이콘 전용) 대신 `ohaengTextColors`(WCAG AA 4.5:1 통과하도록 진하게 조정, `test/app/theme/app_colors_contrast_test.dart`로 검증)를 쓴다. 마찬가지로 `accent`를 텍스트로 쓸 때는 `accentText`(같은 방식으로 조정, 온보딩 워드마크에서 사용)를 쓴다. **`accent`(#FF6B8A) 배경 위 흰 CTA 텍스트만 여전히 WCAG AA 미달(2.72:1) — 브랜드 버튼 색 자체를 바꿔야 해 사람 결정 대기 중(PROGRESS.md 참고)** |
| 라우팅 | 🟢 완료 | `project/lib/app/router.dart` | `AppRoutes` — birthInput/calculating/result 등록. 온보딩은 `routes`에 없고 `main.dart`의 `home:`에서만 결정(이유는 파일 상단 doc-comment 참고). 신규 화면 추가 시 이 표에 등록 |
| 생년월일시 저장소 | 🟢 완료 | `project/lib/core/storage/` | `BirthInfoStore` — `SharedPreferences`로 마지막 입력값(성별 포함) 저장/조회/삭제. 앱 재실행 시 온보딩 스킵에 사용 |
| 온보딩 화면 | 🟢 완료 | `project/lib/features/onboarding/` | 워드마크("사주랑") + 헤드라인("내 안의 오행, 3분이면 알 수 있어요") + 설명 + "시작하기"(→ birthInput 실제 이동) + "어떻게 계산되나요?"(60갑자 변환·절기 근사 한계를 설명하는 다이얼로그, `report_screen.dart` 안내 문구와 같은 취지) — 목업 STEP 1 카피와 실제로 맞춤. 저장된 정보가 없을 때만 보임. 장식용 마스코트 아이콘은 `ExcludeSemantics`로 스크린 리더에서 제외. 위젯 테스트 3개(`test/features/onboarding_screen_test.dart`) + 앱 레벨 테스트는 `test/widget_test.dart` |
| 생년월일시 정보 입력 화면 | 🟢 완료 | `project/lib/features/birth_input/` | 이름(선택, 20자 제한), 생년월일(datePicker), 양력/음력, 태어난 시간(timePicker+`CheckboxListTile`로 전체 행 탭 가능한 모름 체크), 성별(`Gender` enum, `BirthInfo.gender`로 실제 전달됨), 출생지(선택, 30자 제한, `BirthInfo.birthPlace`로 실제 전달됨) 구현 완료 — 글자 수 제한은 `share_card.dart`의 폭 고정 레이아웃이 아주 긴 입력에 깨지는 걸 막기 위함. 이름/출생지 `TextField`는 `Semantics(label:)`로 감싸 스크린 리더가 hintText뿐 아니라 필드 용도도 함께 읽도록 처리. datePicker/timePicker는 "확인" 확정뿐 아니라 "취소"해도 원래 값이 유지되는지도 검증됨. "사주 보러가기" → `BirthInfoStore.save()` 후 `BirthInfo`를 담아 calculating으로 실제 이동. 위젯 테스트 16개(`test/features/birth_input_screen_test.dart`) |
| 명식 계산 중 화면 | 🟢 완료 | `project/lib/features/calculating/` | 궤도 애니메이션(달+🌿⭐💫) + 진행 바 + 로딩 문구 3종 1.8초 순환(목업 STEP 3) 구현 완료 — 궤도 회전과 문구 순환 둘 다 `MediaQuery.disableAnimations`(동작 줄이기)일 때는 멈춘다(궤도 쪽은 `didChangeDependencies()`에서 판단 — `initState()`에서 `MediaQuery.of(context)`를 쓰면 예외가 나서 옮김, CLAUDE.md 참고). 3초 뒤 `BirthInfo`를 그대로 들고 result로 실제 이동. 위젯 테스트 4개(`test/features/calculating_screen_test.dart`) |
| 사주 결과 화면 | 🟢 완료 | `project/lib/features/result/` | 이름 있으면 헤더/공유에 실제 이름 반영(없으면 "회원님"), 성별·출생지 있으면 메타 라인·공유 텍스트에 순서대로 표시(날짜 · 시간 · 양/음력 · 성별 · 출생지 — 메타 라인 조립은 `meta_line.dart`의 `buildMetaLine`, report 화면과 공유), 4기둥 카드(한자·오행 밸런스 % 모두 실제 계산값과 정확히 일치하는지 값으로 검증됨), 카테고리 2x2(연애·재물·건강·성격 — `ohaeng_readings.dart` 규칙 기반, 아직 실제 AI 해석은 아님. 어떤 오행이 "우세"한지 뽑는 선택 로직 자체를 실제 값·동률 상황까지 포함해 검증한 테스트 있음). 공유 버튼은 `share_card.dart`(9:16 카드 위젯, 이름 최대 2줄·메타 라인 1줄로 말줄임 처리해 20자/30자 입력 제한 최대치에서도 고정 높이를 넘치지 않게 함)를 `RepaintBoundary.toImage()`로 캡처하고 `share_text.dart`(`buildShareText`, 테스트 가능한 순수 함수 — 오행 밸런스 퍼센트 줄이 `ohaengCount` 실제 분포·반올림까지 정확히 일치하는지 값으로 검증됨)로 만든 텍스트와 함께 `share_plus`로 공유, 캡처 실패 시 텍스트 전용으로 자동 폴백. `SharePlus.instance.share()` 자체가 실패해도 try/catch로 잡아 스낵바로 사용자에게 알림(무반응처럼 보이지 않게). AppBar의 "다시 입력하기"(확인 다이얼로그 거침)로 저장값 초기화 후 재입력 가능. "상세 리포트 보기" → report 화면으로 실제 이동 |
| 상세 리포트 화면 | 🟢 완료 | `project/lib/features/report/` | 상단에 결과 화면과 같은 "{이름}의 상세 리포트" 헤더 + 메타 라인(`buildMetaLine` 재사용)을 표시해 문맥 유지, 명식 8자(천간/지지) breakdown 표(실제 계산값·오행 라벨과 정확히 일치하는지 값으로 검증됨) + 오행 5종 전체 의미 + 오행별 영역 풀이 전체(결과 화면은 우세 오행만) + 계산 정확도 안내 문단. **아직 결제/구독 로직 없이 전부 무료로 노출하는 MVP** (PROGRESS.md 참고) |
| 사주 계산 로직 | 🟡 진행 중 | `project/lib/core/saju/` | `ganzhi.dart`+`four_pillars.dart`로 4주(년/월/일/시) 60갑자 + 오행 집계 구현 완료, 결과 화면에 실제 연결됨. 시주 계산의 전통 시진 경계(23/0시=자시, 1/2시=축시 등), 입춘(2/3 vs 2/4) 경계값, 월주(오호둔년기월법) 실제 계산값, `ohaengCount`(오행 집계)의 8글자 분포 자체를 각각 직접 검증하는 테스트 있음(`test/core/saju/four_pillars_test.dart`) — 4주(년/월/일/시) + 오행 집계 전부 값 자체가 테스트로 잠겨 있음. **단, 절기 근사 계산이라 정확도 한계 있음(PROGRESS.md 참고, 출시 전 만세력 대조 검증 필요)** → 정밀 검증 전까지 🟡 |
| 공용 위젯 | 🟢 완료 | `project/lib/shared/widgets/` | `PastelPillButton`, `PastelToggleRow<T>`, `PastelCard` — birth_input/result 화면의 중복 스타일을 공용화. 둘 다 `Semantics(button:, selected/enabled:, onTap:, excludeSemantics: true)`로 선택/비활성 상태와 탭 액션을 스크린 리더에 정확히 전달 |
| 빌드 검증 스크립트 | 🟢 완료 | `project/tool/check_build.sh` | 표준 빌드 체크 절차(pub get → analyze → test → build apk --debug → 산출물 존재/크기 확인)를 한 번에 실행하는 스크립트. `CLAUDE.md`의 "빌드/린트 체크" 섹션 및 오버나이트 루프 프롬프트와 절차가 동일. 실패 시 즉시 중단(`set -e`)하고 산출물이 없거나 1MB 미만이면 별도로 실패 처리 |
| 앱 아이콘 | 🟢 완료 | `project/test/tool/generate_app_icon.dart`, `project/assets/icon/icon.png` | 파스텔 큐트 톤(초승달+오행 5색 알갱이) 아이콘. SVG→PNG 변환 도구 없이 `RenderRepaintBoundary.toImage()`로 직접 캡처해 소스 PNG를 생성(주의: `Icon`/텍스트 글리프는 `flutter test`가 빈 박스로 치환하므로 `CustomPainter`로 순수 도형만 그림). `flutter_launcher_icons`(dev_dependency, pubspec.yaml에 설정)로 Android/iOS/macOS 아이콘 일괄 생성. 아이콘을 바꾸려면 스크립트 수정 후 `flutter test test/tool/generate_app_icon.dart` → `dart run flutter_launcher_icons` 순서로 재실행 |

상태 범례: 🟢 완료 · 🟡 진행 중/부분 완료 · ⚪ 미착수

## 참고 자료 (원자료, 수정 지양)

| 자료 | 경로 |
|---|---|
| 사주팔자 기초개념 | `docs/research/01_사주팔자_기초개념/` |
| 경쟁앱 분석 | `docs/research/02_경쟁앱_분석/` |
| UI/UX 트렌드 | `docs/research/03_UI_UX_레퍼런스/` |
| 입력정보 요구사항 | `docs/research/04_입력정보_요구사항/` |
| 결과화면 사례 | `docs/research/05_결과화면_사례/` |
| 소셜미디어 레퍼런스 | `docs/research/06_소셜미디어_레퍼런스/` |
| 오픈소스 계산로직 | `docs/research/07_오픈소스_계산로직/` |
| UI/UX 목업 4종 | `docs/mockups/` |
