# COSMOS_BEOMBOO — 작업 규칙

사주팔자(사주/명리) 서비스를 위한 Flutter 앱 프로젝트입니다. Flutter 프로젝트 본체는 저장소 루트가 아니라 **`project/` 폴더 안**에 있습니다 (`project/pubspec.yaml`, `project/lib/` 등). 저장소 루트에는 문서(`docs/`, `CLAUDE.md`, `PROJECT_ROUTER.md`, `PROGRESS.md`)와 설정(`config/`)만 둡니다.

## 필수 규칙

1. **경로 탐색은 반드시 [PROJECT_ROUTER.md](PROJECT_ROUTER.md)부터 시작한다.**
   새 기능을 추가하거나 기존 기능을 찾을 때, 먼저 `PROJECT_ROUTER.md`에서 해당 기능의 경로를 확인하고 그 경로로 이동해 작업한다. 새 기능을 추가했다면 `PROJECT_ROUTER.md`에도 반드시 항목을 추가한다.

2. **모든 마크다운 문서는 한국어로 작성한다.** (`*.md` 전부 해당. 코드 주석/커밋 메시지도 한국어 우선)

3. **작업 범위는 `COSMOS_BEOMBOO` 폴더 내부로 한정한다.** 이 디렉터리 밖의 파일을 읽거나 쓰지 않는다. (예: `~/.claude`, 다른 프로젝트 디렉터리 등 접근 금지)

4. **[PROGRESS.md](PROGRESS.md)는 2026-07-05부로 더 이상 갱신하지 않는다(사용자 요청).** 그 시점까지의 기록은 참고용으로만 남겨두고, 새 항목을 추가하거나 기존 내용을 고치지 않는다. 진행 상황 추적은 이제 [PROJECT_ROUTER.md](PROJECT_ROUTER.md)의 기능별 상태(⚪/🟡/🟢)와 설명만으로 한다 — 작업을 시작하기 전에 `PROJECT_ROUTER.md`를 먼저 읽어 현재 상태를 확인하고 중복 작업을 피하며, 작업이 끝나면 관련 항목의 상태와 설명을 갱신한다.

5. **UI/UX는 반드시 [docs/mockups/01-pastel-cute.html](docs/mockups/01-pastel-cute.html)(파스텔 큐트) 목업을 기준으로 개발한다.** 신규 화면/컴포넌트를 만들거나 기존 화면을 고칠 때, 이 목업의 컬러 토큰(`app_colors.dart`에 이미 반영됨)·레이아웃·카피 톤에서 벗어나지 않는지 먼저 대조한다. 자세한 설명은 아래 "UI/UX 기준" 섹션 참고.

6. **오버나이트 자동화 루프는 한국 시간(KST) 기준 시간대별로 모드가 나뉜다(2026-07-05, 사용자 요청).**
   - **00:00~06:59 — 리서치 보강 모드**: Agent-Reach(`agent-reach` CLI)로 `docs/research/` 내용을 보강한다. 조사 중 UI/UX 목업을 구체적으로 개선할 근거를 찾으면 `docs/mockups/*.html`도 함께 개선한다. `project/` 코드는 건드리지 않으므로 flutter 빌드 검증은 생략한다.
   - **07:00~23:59 — 개발 모드**: 그 시점까지 수집·보강된 `docs/research/`·`docs/mockups/` 자료를 참고해 `project/lib/`에서 실제 기능 구현/개선을 진행한다(표준 빌드 검증 절차 그대로 적용).
   - 두 모드 모두 `PROGRESS.md`는 절대 수정하지 않고, `PROJECT_ROUTER.md`(및 리서치 모드에서는 `docs/research/README.md`)만으로 상태를 추적한다.

7. **사용자가 "푸시"를 요청하면, 그 시점까지 쌓인 변경사항을 기능 단위로 나눠 각각 커밋한 뒤에 푸시한다(2026-07-05, 사용자 요청).** 한 번에 통짜로 커밋하지 않고, 변경된 파일들을 화면/모듈/문서 등 논리적 단위로 묶어 커밋 메시지도 그 단위에 맞게 한국어로 작성한다(이전에 `project/` 전체를 15개 커밋으로 나눴던 방식 참고). 커밋 자체는 이 규칙에 따라 자동으로 진행하되, 푸시는 "푸시해달라"는 명시적 요청이 있을 때만 한다 — 커밋과 푸시를 요청 없이 먼저 하지 않는다는 기존 원칙과 배치되지 않는다.

## 프로젝트 구조

- `project/` — Flutter 프로젝트 루트 (여기서 `flutter` 명령을 실행한다)
  - `project/lib/` — 앱 소스 (기능별 하위 구조는 `PROJECT_ROUTER.md` 참고)
  - `project/android/`, `project/ios/`, `project/macos/` — 플랫폼별 빌드 설정
- `docs/research/` — 사주 도메인 조사 자료 (원자료, 수정 지양)
- `docs/mockups/` — UI/UX 목업 4종 (HTML). 현재 채택된 컨셉: **01-pastel-cute.html (파스텔 큐트)**
- `PROJECT_ROUTER.md` — 기능별 경로 네비게이션 (필수 참조)
- `PROGRESS.md` — 작업 진행 로그

## UI/UX 기준

현재 채택 디자인 컨셉은 **파스텔 큐트**([docs/mockups/01-pastel-cute.html](docs/mockups/01-pastel-cute.html))이다. 흰 배경 + 파스텔 오행(五行) 컬러 + 귀여운 마스코트 톤을 따른다. 신규 화면/컴포넌트 작업 시 이 목업의 컬러 토큰과 레이아웃을 기준으로 삼는다.

## 빌드/린트 체크

`project/` 디렉터리에서 실행한다 (`cd project && ...`). 아래 표준 절차 전체를 한 번에 실행하려면 `./tool/check_build.sh`를 쓴다(각 단계를 그대로 순서대로 실행하고, 산출물 존재/크기 확인까지 포함하며, 실패 시 즉시 중단하고 비정상 종료 코드를 반환한다).

표준 검증 순서(매 사이클 이 순서를 그대로 따른다):

1. `flutter pub get` — 의존성 해석이 깨끗한지 먼저 확인한다(경고/오류가 있으면 원인을 살펴본다). 새 패키지를 추가하지 않은 사이클에도 매번 실행해 `pubspec.lock` 드리프트나 캐시 손상을 조기에 잡는다.
2. `flutter analyze` — 린트 통과 확인.
3. `flutter test` — 전체 테스트 통과 확인.
4. 위 세 단계가 모두 통과하면 `flutter build apk --debug` (Android)를 실행한다.
   - **새 pub 패키지(특히 네이티브 플러그인)를 `flutter pub add`로 추가한 직후에는, 이 빌드 전에 먼저 `flutter clean && flutter pub get`을 실행한다.** `share_plus`, `shared_preferences`를 추가한 직후 각각 `Type io.flutter.plugins.GeneratedPluginRegistrant is defined multiple times` (stale dex 캐시) 오류로 최초 빌드가 실패하는 것을 반복 확인했다 — `flutter clean` 이후에는 항상 정상 빌드됨.
5. 빌드 명령이 exit 0이어도 그것만으로 "성공"이라 단정하지 않는다 — `project/build/app/outputs/flutter-apk/app-debug.apk` 파일이 실제로 존재하고 크기가 1MB 이상인지 확인한다(0바이트/누락된 산출물은 겉보기엔 성공이어도 실패로 간주하고 원인을 조사한다).
   - **이 환경에는 연결된 Android 에뮬레이터/실기기가 없다** (`flutter devices` 확인 결과 iOS 시뮬레이터/macOS 데스크톱/Chrome만 조회되고 Android 기기는 없음, `adb`는 설치돼 있으나 `emulator` 바이너리는 없음). 따라서 지금 검증 범위는 "빌드 산출물이 정상적으로 생성되는지"까지이며, 설치 후 실제 실행(런타임) 검증은 할 수 없다 — 나중에 Android 에뮬레이터/기기가 연결되면 `flutter install`/실행 검증 단계 추가를 고려한다.
- iOS 빌드(시뮬레이터): **현재 이 개발 환경에서는 실행하지 않는다.** `flutter build ios --simulator --debug`가 Flutter SDK 엔진 캐시(`Flutter.xcframework`)에 이미 붙어 있는 `com.apple.provenance` 확장 속성 때문에 코드사이닝 단계에서 항상 실패하는 것을 확인했다 (`resource fork, Finder information, or similar detritus not allowed`). 프로젝트 코드 문제가 아니라 로컬 Flutter SDK 설치(저장소 밖, 공유 자원)의 환경 문제이며, 일반 사용자 권한의 `xattr -c`로는 제거되지 않는다. 자동화된 작업에서는 이 빌드 단계를 건너뛰고 `flutter analyze` + `flutter test` + Android 빌드만으로 검증한다. (해결하려면 `sudo xattr -cr <flutter sdk>/bin/cache`가 필요할 수 있으나, 이는 COSMOS_BEOMBOO 밖의 공유 SDK를 건드리는 작업이라 사용자 승인 없이는 수행하지 않는다.)
- macOS 빌드: 플랫폼 자체는 추가되어 있으나(`project/macos/`), **이 개발 환경에서는 `flutter build macos --debug`도 iOS와 동일한 `com.apple.provenance`/코드사이닝 문제로 항상 실패한다** (빌드된 `.app` 번들 자체와 Flutter SDK의 `FlutterMacOS.xcframework` 캐시 양쪽에서 확인됨, 샌드박스 비활성화(`dangerouslyDisableSandbox`)로도 해결 안 됨). 마찬가지로 자동화된 작업에서는 이 빌드 단계를 건너뛴다.
  - **추가 조사(2026-07-04, 사용자 승인 후)**: `~/BeomBoo/sdk/flutter/bin/cache/artifacts/engine` 전체에서 `com.apple.quarantine`/`com.apple.provenance`를 재귀 제거(`xattr -dr`, sudo 불필요 — SDK가 사용자 홈 아래 설치돼 있음)해도 여전히 실패함. 새로 빌드되는 `.app` 안의 파일들에 그 자리에서 다시 `com.apple.provenance`가 붙는 것을 확인 — **이 Claude Code 세션(에이전트) 안에서 실행되는 프로세스가 새로 쓰는 모든 파일에 자동으로 이 태그가 붙는 것으로 추정**된다 (SDK 캐시나 프로젝트 코드 문제가 아님). 사용자가 자신의 터미널(Claude Code 세션 밖)에서 직접 `flutter build macos`/`flutter run -d macos`를 실행하면 정상 작동할 가능성이 높음 — iOS/macOS 실행·디버깅은 사용자 터미널에서, 이 세션은 Android 빌드 검증만 담당하는 것을 권장.

## 테스트 작성 시 알아두면 좋은 점 (반복 발견된 함정)

- **긴 `ListView`가 있는 화면**: 기본 테스트 뷰포트(800x600)보다 콘텐츠가 길면 하단 위젯이 지연 빌드되어 `find`로 못 찾는다. `tester.view.physicalSize`를 세로로 크게(예: 400x2000~3000) 키우고 테스트 후 원복하는 헬퍼를 사용한다 (`birth_input_screen_test.dart`, `report_screen_test.dart` 참고).
- **무한 반복 애니메이션이 있는 화면**(`AnimationController.repeat()`): `pumpAndSettle()`을 쓰면 절대 끝나지 않으므로 `pump()`로 프레임을 직접 진행시킨다. 내부에 `Future.delayed` 타이머가 있다면(예: `calculating_screen.dart`의 3초 뒤 이동) 테스트 종료 전에 그 시간만큼 `pump(duration)`으로 흘려보내야 "A Timer is still pending" 오류가 안 난다.
- **`Semantics(excludeSemantics: true)`를 쓸 때**: 자식 위젯(예: `InkWell`)이 만드는 탭 액션까지 통째로 사라진다. `Semantics` 위젯 자체에 `onTap:`을 다시 선언해야 스크린 리더로 활성화할 수 있다. (`PastelPillButton`, `PastelToggleRow`에서 실제로 겪은 회귀)
- **`matchesSemantics()`는 완전일치 매처**다 — 지정하지 않은 플래그는 전부 "없어야 함"으로 간주한다. `hasEnabledState`와 `isEnabled`처럼 짝을 이루는 플래그는 둘 다 명시해야 한다. 최신 Flutter에서 `SemanticsData.hasFlag()`는 deprecated이며 `flagsCollection.isSelected`(`Tristate`), `flagsCollection.isButton`(`bool`) 같은 새 API를 쓴다.
- **`tester.ensureSemantics()`로 얻은 핸들**은 `addTearDown`으로 dispose하면 안 된다 (그 콜백은 테스트 바디가 return한 *이후*에 실행되는데, 열린 핸들 검사는 return 시점에 바로 이뤄짐) — 테스트 함수 끝에서 직접 `semantics.dispose()`를 호출한다.
- **SharedPreferences를 쓰는 위젯 테스트**는 `setUp(() => SharedPreferences.setMockInitialValues({}))`을 먼저 호출해야 한다.
- **`RenderRepaintBoundary.toImage()`/`Image.toByteData()`를 테스트(또는 테스트 형태의 일회성 스크립트) 안에서 쓸 때**: `testWidgets` 콜백은 기본적으로 FakeAsync 존 안에서 돌아가는데, 이 두 호출은 실제 엔진 콜백을 기다려야 해서 FakeAsync 안에서 직접 `await`하면 영원히 안 끝난다("Test timed out after 10 minutes"로 확인됨) — `tester.runAsync(() async { ... })`로 감싸야 한다 (`test/tool/generate_app_icon.dart` 참고).
- **`flutter test`(테스트 바인딩) 안에서 `Icon`/텍스트 등 폰트 글리프를 렌더링해 캡처하면 안 된다**: 결정론적 렌더링을 위해 모든 글리프(Material Icons 폰트 포함)를 빈 사각형으로 치환한다(`--use-test-fonts`). 실제 사용자에게 보이는 화면과 달리 스크린샷/PNG 생성 용도로 테스트 바인딩을 재사용할 땐 폰트 글리프 대신 `CustomPainter`로 순수 벡터 도형만 그려야 원하는 그림이 나온다 (`test/tool/generate_app_icon.dart`에서 아이콘 폰트 대신 `Canvas`로 초승달을 직접 그린 사례 참고).
- **`State.initState()` 안에서 `MediaQuery.of(context)`(또는 다른 `InheritedWidget.of(context)`)를 호출하면 안 된다**: "dependOnInheritedWidgetOfExactType<MediaQuery>() ... was called before initState() completed" 예외가 실제로 발생하는 걸 확인했다(이 Flutter 버전에서는 initState 중 inherited 의존성 등록이 막혀 있음) — 위젯을 쓰는 모든 테스트가 한꺼번에 깨진다. 최초 1회만 판단하면 되는 로직(예: `MediaQuery.disableAnimations`를 보고 애니메이션을 시작할지 결정)은 `didChangeDependencies()`로 옮기고, 여러 번 불릴 수 있으니 `bool` 플래그로 한 번만 실행되게 가드한다 (`calculating_screen.dart`의 궤도 애니메이션이 reduce-motion을 존중하도록 고치다 실제로 겪은 사례).
