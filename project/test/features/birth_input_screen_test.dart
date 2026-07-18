import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart' show CupertinoDatePicker;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/core/storage/deep_dive_info_store.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_info.dart';

import '../support/test_viewport.dart';

void main() {
  // 제출 시 BirthInfoStore.save()가 SharedPreferences를 사용하므로 목(mock) 초기값을 설정해둔다.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // 입력 폼(ListView)이 기본 테스트 화면(800x600)보다 길어 제출 버튼이 화면 밖에서
  // 지연 빌드된다 — 뷰포트를 세로로 넉넉하게 키워 전체 폼이 스크롤 없이 다 보이게 한다
  // (높이 2000은 test_viewport.dart의 기본값과 같다).

  Widget buildApp({Object? Function(RouteSettings)? onCalculatingRoute}) {
    return MaterialApp(
      // main.dart와 동일한 로케일 설정 — showDatePicker/showTimePicker의 "확인" 버튼 등을
      // 한국어로 띄우기 위함(테스트에서 실제로 그 버튼을 탭해야 하는 경우가 있다).
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.calculating) {
          onCalculatingRoute?.call(settings);
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('CALCULATING_STUB')),
            settings: settings,
          );
        }
        return MaterialPageRoute(builder: (_) => const BirthInputScreen());
      },
      initialRoute: '/',
    );
  }

  // **2026-07-17 버그 수정**: _birthDate/_birthTime이 더 이상 처음부터 유효한
  // 기본값(1998-08-15/14:30)으로 채워져 있지 않고 null(미선택)로 시작한다 —
  // 제출 버튼도 날짜(그리고 시간-모름이 아니면 시간)를 실제로 고르기 전까지는
  // onPressed가 null이라 비활성화된다. 아래 세 헬퍼는 "확인"으로 명시적으로
  // 확정하는 절차를 재사용하기 위한 것이다. 두 피커 모두 값이 없을 때
  // initialDate/initialTime을 각각 DateTime(2000,1,1)/TimeOfDay(14,30)로 잡아두므로
  // ("확인"만 눌러도 그 값이 그대로 반영됨), 결과는 "2000.01.01 · 오후 2시 30분"이 된다.
  Future<void> pickDate(WidgetTester tester) async {
    await tester.tap(find.text('날짜를 선택해주세요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
  }

  Future<void> pickTime(WidgetTester tester) async {
    await tester.tap(find.text('시간을 선택해주세요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
  }

  Future<void> pickDateAndTime(WidgetTester tester) async {
    await pickDate(tester);
    await pickTime(tester);
  }

  // 2026-07-19: 이름·성별·혈액형이 새로 필수값이 되면서(입력 화면 필수값 확장) 날짜/
  // 시간만 채우던 위 헬퍼로는 더 이상 제출 버튼이 활성화되지 않는다 — 나머지 세
  // 필수 항목을 각각/한 번에 채우는 헬퍼를 추가한다.
  Future<void> fillName(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pump();
  }

  Future<void> pickGender(WidgetTester tester, {bool male = false}) async {
    await tester.tap(find.text(male ? '남성' : '여성'));
    await tester.pump();
  }

  Future<void> pickBloodType(WidgetTester tester, {String label = 'A형'}) async {
    await tester.tap(find.text(label));
    await tester.pump();
  }

  /// 이름·날짜·시간·성별·혈액형 다섯 필수 항목을 한 번에 채운다 — 대부분의 제출
  /// 관련 테스트가 "필수값은 다 채웠다"는 전제를 재사용할 수 있게 한다.
  Future<void> fillAllRequired(
    WidgetTester tester, {
    String name = '민지',
    bool male = false,
    String bloodType = 'A형',
  }) async {
    await fillName(tester, name);
    await pickDateAndTime(tester);
    await pickGender(tester, male: male);
    await pickBloodType(tester, label: bloodType);
  }

  group('_canSubmit — 날짜/시간/이름/성별/혈액형 미선택 시 제출 버튼 비활성화 (2026-07-17/19 버그 수정)', () {
    // "아무런 데이터를 입력하지 않은 상태에서는 사주팔자 결과보기로 넘어가면 안 됨"
    // 리포트의 핵심 — 날짜와 시간(또는 "몰라요" 체크) 중 하나라도 비어 있으면
    // ElevatedButton.onPressed가 null이어야 한다. 버튼 스타일이나 tester.tap()의
    // 무동작만으로는 "정말 비활성 상태인지"를 확정할 수 없어 onPressed 자체를 직접 값으로 본다.

    ElevatedButton submitButton(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '사주 보러가기 🔮'));

    testWidgets('날짜/시간을 아무것도 고르지 않으면 제출 버튼이 비활성화된다(onPressed == null)',
        (tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      expect(submitButton(tester).onPressed, isNull);
    });

    testWidgets('날짜만 고르고 시간(또는 "몰라요")을 고르지 않으면 여전히 비활성화된다', (tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await pickDate(tester);

      expect(submitButton(tester).onPressed, isNull);
    });

    testWidgets('날짜와 시간을 모두 고르고 이름/성별/혈액형까지 채우면 제출 버튼이 활성화된다(onPressed != null)',
        (tester) async {
      // 2026-07-19: 날짜/시간만으로는 더 이상 충분하지 않다 — 이름·성별·혈액형까지
      // 채워야 활성화된다.
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await fillAllRequired(tester);

      expect(submitButton(tester).onPressed, isNotNull);
    });

    testWidgets(
        '날짜만 고르고 "태어난 시간을 몰라요"를 체크해도 이름/성별/혈액형까지 채우면 시간 없이 활성화된다',
        (tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await fillName(tester, '민지');
      await pickDate(tester);
      await tester.tap(find.text('태어난 시간을 몰라요'));
      await tester.pump();
      await pickGender(tester);
      await pickBloodType(tester);

      expect(submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('이름만 비어있으면(날짜·시간·성별·혈액형을 모두 채워도) 제출 버튼이 비활성화된다', (tester) async {
      // 2026-07-19 신규 필수값(이름) 자체를 직접 겨냥한다 — 나머지 네 항목을 모두
      // 채워도 이름이 비어있으면 여전히 비활성이어야 한다.
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await pickDateAndTime(tester);
      await pickGender(tester);
      await pickBloodType(tester);
      // 이름은 일부러 채우지 않는다.

      expect(submitButton(tester).onPressed, isNull);
    });

    testWidgets('성별을 고르지 않으면(나머지를 모두 채워도) 제출 버튼이 비활성화된다', (tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await fillName(tester, '민지');
      await pickDateAndTime(tester);
      await pickBloodType(tester);
      // 성별은 일부러 고르지 않는다.

      expect(submitButton(tester).onPressed, isNull);
    });

    testWidgets('혈액형을 고르지 않으면(나머지를 모두 채워도) 제출 버튼이 비활성화된다', (tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await fillName(tester, '민지');
      await pickDateAndTime(tester);
      await pickGender(tester);
      // 혈액형은 일부러 고르지 않는다.

      expect(submitButton(tester).onPressed, isNull);
    });

    testWidgets('이름·날짜·시간·성별·혈액형을 모두 채우면 제출 버튼이 활성화된다', (tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await fillAllRequired(tester);

      expect(submitButton(tester).onPressed, isNotNull);
    });

    testWidgets(
        '이름 필드에 타이핑만 해도(포커스를 잃지 않아도) 제출 버튼 활성화 상태가 실시간으로 갱신된다 '
        '(리스너 누락 버그 회귀 방지)', (tester) async {
      // 2026-07-19 버그 수정: _nameController에 리스너가 없으면 이름을 타이핑해도
      // setState가 호출되지 않아, 우연히 다른 필드를 건드려 화면이 다시 그려지기
      // 전까지는 버튼이 계속 비활성 상태로 보인다 — 날짜/시간/성별/혈액형을 먼저 다
      // 채운 뒤 이름만 enterText()로 입력하고 pump() 한 번만으로 버튼이 곧바로
      // 활성화되는지 확인한다(다른 위젯은 추가로 건드리지 않음).
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await pickDateAndTime(tester);
      await pickGender(tester);
      await pickBloodType(tester);
      expect(submitButton(tester).onPressed, isNull, reason: '이름을 아직 입력하지 않았다');

      await tester.enterText(find.byType(TextField).first, '민지');
      await tester.pump();

      expect(submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('시간만 고르고 날짜를 고르지 않으면 여전히 비활성화된다(날짜는 항상 필수)', (tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await pickTime(tester);

      expect(submitButton(tester).onPressed, isNull);
    });

    testWidgets('"태어난 시간을 몰라요"만 체크하고 날짜를 고르지 않으면 여전히 비활성화된다', (tester) async {
      await useTallViewport(tester);
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('태어난 시간을 몰라요'));
      await tester.pump();

      expect(submitButton(tester).onPressed, isNull);
    });
  });

  testWidgets('기본 입력 필드와 CTA 버튼을 보여준다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('생년월일시를 알려주세요'), findsOneWidget);
    // 2026-07-19: 이름이 필수값이 되면서 "(선택)" 표기 대신 accent색 "*" 접미사가
    // 붙는다(_FieldLabel(required: true) → Text.rich("이름 *")).
    expect(find.text('이름 *'), findsOneWidget);
    expect(find.text('양력'), findsOneWidget);
    expect(find.text('음력'), findsOneWidget);
    expect(find.text('여성'), findsOneWidget);
    expect(find.text('남성'), findsOneWidget);
    // 2026-07-19 신규: 혈액형 필수 토글(A/B/AB/O형).
    expect(find.text('A형'), findsOneWidget);
    expect(find.text('B형'), findsOneWidget);
    expect(find.text('AB형'), findsOneWidget);
    expect(find.text('O형'), findsOneWidget);
    expect(find.text('태어난 시간을 몰라요'), findsOneWidget);
    expect(find.text('MBTI를 알고 있어요'), findsOneWidget);
    expect(find.text('사주 보러가기 🔮'), findsOneWidget);
  });

  testWidgets(
      '_FieldLabel 글자 스타일이 목업 값(fontSize 11/fontWeight w800/letterSpacing 0.22)과 일치한다',
      (tester) async {
    // 2026-07-16 오버나이트 대조 수정: 목업(`.field label`)은
    // font-size:11px/font-weight:800/letter-spacing:.02em(≈0.22px)인데 지금까지는
    // 13px/700/자간 없음이었다 — 이 값 자체를 확인하는 테스트가 지금까지 없었다.
    // _FieldLabel은 6개 필드(이름·태어난 날짜·태어난 시간·성별·혈액형·태어난 곳)에
    // 재사용되는 공용 위젯이라, 대표로 두 곳만 확인해도 공용 스타일 정의 자체의
    // 회귀는 충분히 잡을 수 있다 — 2026-07-19: required 아닌 라벨(태어난 곳)은 여전히
    // 단순 Text이지만, required 라벨(이름)은 Text.rich(TextSpan)로 바뀌어 스타일이
    // Text.style이 아니라 textSpan.style에 실린다.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    final placeText = tester.widget<Text>(find.text('태어난 곳 (선택)'));
    expect(placeText.style!.fontSize, 11, reason: '태어난 곳 fontSize');
    expect(placeText.style!.fontWeight, FontWeight.w800, reason: '태어난 곳 fontWeight');
    expect(placeText.style!.letterSpacing, 0.22, reason: '태어난 곳 letterSpacing');

    final nameText = tester.widget<Text>(find.text('이름 *'));
    final nameSpan = nameText.textSpan! as TextSpan;
    expect(nameSpan.style!.fontSize, 11, reason: '이름 fontSize');
    expect(nameSpan.style!.fontWeight, FontWeight.w800, reason: '이름 fontWeight');
    expect(nameSpan.style!.letterSpacing, 0.22, reason: '이름 letterSpacing');
  });

  testWidgets('필드 라벨 아래 여백이 목업 값(7px)과 일치한다 (6개 필드 전부)', (tester) async {
    // 2026-07-16 오버나이트 대조 수정: 목업(`.field label`)은 margin-bottom:7px인데
    // 지금까지는 8px이었다 — 이 값 자체를 확인하는 테스트가 지금까지 없었다.
    // height:7인 SizedBox는 이 화면에서 필드 라벨(이름·태어난 날짜·태어난 시간·성별·
    // 혈액형·태어난 곳) 6곳 뒤에만 쓰이므로, 개수(6개)를 세는 것만으로 6곳 전부에
    // 일관되게 적용됐는지 확인할 수 있다(대표 1~2곳만 값으로 확인하는 위 스타일
    // 테스트와 달리, 간격은 위젯을 공유하지 않는 리터럴이라 개수 확인이 필요하다).
    // 2026-07-19: 혈액형 필드가 추가되며 5개 → 6개로 늘었다.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    final sevenHeightBoxes = tester.widgetList<SizedBox>(
      find.byWidgetPredicate((widget) => widget is SizedBox && widget.height == 7),
    );
    expect(sevenHeightBoxes.length, 6);
  });

  testWidgets('"사주 보러가기 🔮" 버튼의 스크린 리더 라벨은 이모지 없이 "사주 보러가기"만 읽힌다', (tester) async {
    // 2026-07-15 접근성 정리: 🔮 이모지는 시각적 장식일 뿐인데 semanticsLabel 없이
    // Text 그대로 두면 스크린 리더가 이모지를 유니코드 이름("수정 구슬")으로 읽어
    // 혼란을 준다 — semanticsLabel: '사주 보러가기'로 라벨을 깨끗하게 교체했는지 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(tester.getSemantics(find.text('사주 보러가기 🔮')).label, '사주 보러가기');

    semantics.dispose();
  });

  testWidgets(
      '"건너뛰어도 괜찮아요 →" 안내 문구의 스크린 리더 라벨은 화살표 없이 읽힌다',
      (tester) async {
    // 2026-07-16 오버나이트 접근성 정리: 장식용 화살표(→)는 스크린 리더가 "오른쪽
    // 화살표"처럼 유니코드 이름으로 그대로 읽어 혼란을 준다 — 위 "사주 보러가기 🔮"
    // 버튼과 같은 패턴으로 semanticsLabel을 화살표 없는 값으로 교체했는지 확인한다.
    // 2026-07-19: 이름이 필수값으로 바뀌면서 "이름 없이도 괜찮아요 →" 안내 문구
    // 자체가 삭제됐다 — 이제 남아있는 출생지("건너뛰어도 괜찮아요 →")만 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('이름 없이도 괜찮아요 →'), findsNothing);
    expect(tester.getSemantics(find.text('건너뛰어도 괜찮아요 →')).label, '건너뛰어도 괜찮아요');

    semantics.dispose();
  });

  testWidgets('"태어난 시간을 몰라요" 체크 시 시간 버튼이 "시간 모름"으로 바뀐다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('시간 모름'), findsNothing);
    // 이제 이 화면엔 체크박스가 둘("태어난 시간을 몰라요"·"MBTI를 알고 있어요") 있어
    // 첫 번째("태어난 시간을 몰라요")를 명시적으로 골라야 한다(2026-07-07, MBTI
    // 체크박스 추가로 생긴 모호성).
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('시간 모름'), findsOneWidget);
  });

  testWidgets('체크박스뿐 아니라 "태어난 시간을 몰라요" 글자를 눌러도 토글된다 (CheckboxListTile 터치 영역)',
      (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('시간 모름'), findsNothing);
    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();
    expect(find.text('시간 모름'), findsOneWidget);
  });

  testWidgets('날짜/시간을 고르고 제출하면 그 값 그대로 BirthInfo가 계산 화면으로 전달된다', (tester) async {
    // **2026-07-17/19 버그 수정 이후**: _birthDate/_birthTime이 더 이상 기본값으로
    // 채워져 있지 않고, 이름·성별·혈액형도 필수값이 됐다 — 제출하려면 다섯 항목을
    // 모두 실제로 채워야 한다(안 그러면 버튼이 비활성화돼 탭이 무시된다 — 위
    // "_canSubmit" 그룹 참고).
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillAllRequired(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(find.text('CALCULATING_STUB'), findsOneWidget);
    expect(captured, isNotNull);
    expect(captured!.date, DateTime(2000, 1, 1));
    expect(captured!.hour, 14);
    // timePicker 기본 초기 위치(오후 2시 30분)의 "분"이 지금까지는 BirthInfo에 필드
    // 자체가 없어서 제출 시 통째로 버려지고 있었다 — 목업 STEP 4 결과 화면이 "오후 2시
    // 30분生"처럼 분까지 보여주는 것과 어긋나던 부분이라 minute 필드를 추가해 맞췄다.
    expect(captured!.minute, 30);
    expect(captured!.isLunar, isFalse);
    // 2026-07-19: 이름이 필수값이 되면서 더 이상 null일 수 없다.
    expect(captured!.name, '민지');
    expect(captured!.gender, Gender.female);
    expect(captured!.bloodType, BloodType.a);
  });

  testWidgets('"사주 보러가기"를 빠르게 두 번 연속 눌러도 calculating 화면으로 한 번만 이동한다',
      (tester) async {
    // _submit()은 BirthInfoStore.save()를 await하는 비동기 함수라, 그 구간이 끝나기
    // 전에 버튼을 한 번 더 누르면(실제 기기의 빠른 연속 탭과 동일한 상황) _submit()이
    // 두 번 실행돼 calculating 라우트가 중복으로 push되는 실제 버그였다 — 재진입을
    // 막는 `_isSubmitting` 플래그를 추가해 고쳤다. tester.tap()은 내부적으로 프레임을
    // 진행시키는 타이밍이 화면의 await 횟수에 따라 달라 재현이 불안정할 수 있어(다른
    // 화면에서 실제로 이 차이 때문에 재현이 안 되는 경우를 확인함), onPressed 콜백을
    // 직접 두 번 동기적으로 호출해 "완전히 같은 시점에 두 번 눌림"을 결정적으로 재현한다.
    await useTallViewport(tester);
    var calculatingPushCount = 0;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (_) => calculatingPushCount++,
    ));

    // 필수 항목을 먼저 모두 채워야 onPressed가 null이 아니게 된다(2026-07-17/19
    // 버그 수정 이후 — 안 그러면 아래 button.onPressed!()가 널 체크에서 바로 예외를 던진다).
    await fillAllRequired(tester);

    final button =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '사주 보러가기 🔮'));
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();

    expect(calculatingPushCount, 1);
  });

  testWidgets('제출하면 이 화면이 스택에서 교체돼(pushReplacementNamed) 뒤로 가기로 돌아올 수 없다',
      (tester) async {
    // **2026-07-13 변경**: 이전에는 `Navigator.pushNamed()`를 써서 화면을 교체하는 게
    // 아니라 그 위에 쌓기만 했다(BirthInputScreen이 스택에 그대로 남음) — 그 결과
    // calculating 화면에서 기기 뒤로가기를 누르면 제출 직후 이 화면(같은 인스턴스,
    // 입력값 그대로)으로 돌아갈 수 있는 실제 버그였다(2026-07-08에 발견해 그때는
    // `_isSubmitting` 재설정으로만 대응했으나, 근본 원인인 "뒤로가기 자체가 가능하다"는
    // 점은 남아있었음). `pushReplacementNamed()`로 바꿔 이 화면 자체를 스택에서
    // 제거하면, calculating 화면에 도달했을 때 더 이상 뒤로 갈 곳이 없어야 한다.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await fillAllRequired(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();
    expect(find.text('CALCULATING_STUB'), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isFalse);
  });

  testWidgets('날짜를 고르고 "태어난 시간을 몰라요"를 체크해 제출하면 hour·minute 모두 null로 전달된다',
      (tester) async {
    // _canSubmit은 시간-모름이면 시간 자체는 없어도 되지만, 날짜·이름·성별·혈액형은
    // 여전히 필수다 — 이들을 먼저 채우지 않으면 버튼이 비활성화된 채라 이 흐름 자체가
    // 성립하지 않는다(2026-07-17/19 버그 수정 이후).
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillName(tester, '민지');
    await pickDate(tester);
    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();
    await pickGender(tester);
    await pickBloodType(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.hour, isNull);
    expect(captured!.minute, isNull);
  });

  testWidgets('"태어난 시간을 몰라요"를 체크했다가 다시 해제하면 골라뒀던 시간이 그대로 유지된다',
      (tester) async {
    // _timeUnknown(체크 여부)과 _birthTime(실제 시간값)은 서로 다른 state라, 체크
    // 해제만으로 _birthTime이 초기화될 이유는 없지만 — deep_dive_input_screen의
    // MBTI 체크박스와 같은 관례(껐다 켜도 값 유지)를 여기서도 지금까지 직접 값으로
    // 확인한 적은 없었다. 먼저 시간을 실제로 골라 확정한 뒤(2026-07-17 버그 수정
    // 이후 더 이상 기본값이 미리 채워져 있지 않으므로), "몰라요"를 체크했다 다시
    // 해제하고 제출해도, 시간이 0시나 null 같은 엉뚱한 값이 아니라 원래 고른 값
    // (오후 2시 30분)이 그대로 전달되는지 확인한다.
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillAllRequired(tester);

    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();
    expect(find.text('시간 모름'), findsOneWidget);

    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();
    expect(find.text('시간 모름'), findsNothing);
    expect(find.text('오후 2시 30분'), findsOneWidget);

    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.hour, 14);
    expect(captured!.minute, 30);
  });

  testWidgets('음력으로 바꾸고 제출하면 isLunar가 true로 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillAllRequired(tester);
    await tester.tap(find.text('음력'));
    await tester.pump();
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.isLunar, isTrue);
  });

  testWidgets('이름을 입력하고 제출하면 BirthInfo.name으로 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await tester.enterText(find.byType(TextField).first, '민지');
    await pickDateAndTime(tester);
    await pickGender(tester);
    await pickBloodType(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.name, '민지');
  });

  testWidgets('태어난 곳을 입력하고 제출하면 BirthInfo.birthPlace로 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillName(tester, '민지');
    await tester.enterText(find.byType(TextField).last, '서울특별시');
    await pickDateAndTime(tester);
    await pickGender(tester);
    await pickBloodType(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.birthPlace, '서울특별시');
  });

  testWidgets('태어난 곳을 비워두면(기본값) birthPlace는 null로 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillAllRequired(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.birthPlace, isNull);
  });

  testWidgets('"여성"을 선택하고 제출하면 BirthInfo.gender에 female이 전달된다', (tester) async {
    // 2026-07-19: 성별이 nullable(초기값 null)로 바뀌면서 "기본값(여성)"이라는
    // 표현이 더 이상 맞지 않는다 — "여성"도 명시적으로 골라야 한다.
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillName(tester, '민지');
    await pickDateAndTime(tester);
    await tester.tap(find.text('여성'));
    await tester.pump();
    await pickBloodType(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.gender, Gender.female);
  });

  testWidgets('"남성"을 선택하고 제출하면 BirthInfo.gender에 male이 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillName(tester, '민지');
    await tester.tap(find.text('남성'));
    await tester.pump();
    await pickDateAndTime(tester);
    await pickBloodType(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.gender, Gender.male);
  });

  testWidgets('이름 필드에 공백만 입력하면(trim 후 빈 문자열) 제출 버튼이 비활성화된 채로 남는다',
      (tester) async {
    // 2026-07-19: 이름이 필수값이 되면서 "공백만 입력 → name null로 제출됨"이라는
    // 예전 동작 자체가 더 이상 성립하지 않는다 — trim 후 빈 문자열이면 _canSubmit이
    // false가 돼 애초에 제출(navigator push) 자체가 일어나지 않는다.
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await tester.enterText(find.byType(TextField).first, '   ');
    await pickDateAndTime(tester);
    await pickGender(tester);
    await pickBloodType(tester);

    final button =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '사주 보러가기 🔮'));
    expect(button.onPressed, isNull);

    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();
    expect(captured, isNull);
  });

  testWidgets('태어난 곳 필드에 공백만 입력하면 birthPlace는 null로 전달된다', (tester) async {
    // 이름 필드는 이미 "공백만 입력 → null" 트리밍이 테스트돼 있는데, 출생지도
    // _submit()에서 정확히 같은 로직(`trimmedBirthPlace.isEmpty ? null : trimmedBirthPlace`)을
    // 쓰면서도 지금까지 이 경계값을 직접 값으로 확인한 적이 없었다.
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillAllRequired(tester);
    await tester.enterText(find.byType(TextField).at(1), '   ');
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.birthPlace, isNull);
  });

  testWidgets('이름 필드는 20자를 넘겨 입력해도 20자까지만 반영된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    // 공유 카드(share_card.dart)가 폭 고정 레이아웃이라 이름이 너무 길면 잘리거나
    // 겹칠 수 있어 maxLength로 제한해뒀다 — 실제로 그 이상은 입력되지 않는지 검증.
    await tester.enterText(find.byType(TextField).first, '가' * 25);
    await pickDateAndTime(tester);
    await pickGender(tester);
    await pickBloodType(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.name, '가' * 20);
  });

  testWidgets('태어난 곳 필드는 30자를 넘겨 입력해도 30자까지만 반영된다', (tester) async {
    // 이름 필드의 20자 제한(maxLength)은 이미 이 경계값까지 테스트돼 있는데,
    // 출생지의 30자 제한은 지금까지 실제로 그 이상이 입력되지 않는지 값으로
    // 확인한 적이 없었다.
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await fillAllRequired(tester);
    await tester.enterText(find.byType(TextField).at(1), '가' * 35);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.birthPlace, '가' * 30);
  });

  testWidgets('태어난 날짜 pill을 탭해 datePicker를 열고 "확인"을 누르면 정상 진행된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    // 아직 아무 값도 고르지 않은 초기 상태라 pill에는 플레이스홀더 문구가 보인다
    // (2026-07-17 버그 수정 이후 — 예전엔 여기가 처음부터 "1998.08.15"였다).
    expect(find.text('날짜를 선택해주세요'), findsOneWidget);
    await tester.tap(find.text('날짜를 선택해주세요'));
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    // "확인"을 누르면 initialDate(2000.01.01)가 그대로 _birthDate에 반영돼 pill에 보인다.
    expect(find.text('2000.01.01'), findsOneWidget);
  });

  testWidgets('태어난 시간 pill을 탭해 timePicker를 열고 "확인"을 누르면 정상 진행된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('시간을 선택해주세요'), findsOneWidget);
    await tester.tap(find.text('시간을 선택해주세요'));
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('오후 2시 30분'), findsOneWidget);
  });

  testWidgets('datePicker에서 "취소"를 누르면 아무 값도 채워지지 않고 플레이스홀더가 그대로 유지된다',
      (tester) async {
    // 지금까지는 "확인"으로 확정하는 경로만 테스트했지, 실제 사용자가 자주 하는
    // "취소"(picked == null) 경로는 한 번도 검증한 적이 없었다 — showDatePicker가
    // null을 반환할 때 _pickDate()의 `if (picked != null)` 가드가 실제로 잘 동작하는지 확인.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('날짜를 선택해주세요'));
    await tester.pumpAndSettle();

    expect(find.text('취소'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    // 취소했으니 _birthDate는 여전히 null이라 플레이스홀더가 그대로 남아있어야 한다.
    expect(find.text('날짜를 선택해주세요'), findsOneWidget);
  });

  testWidgets('timePicker에서 "취소"를 누르면 아무 값도 채워지지 않고 플레이스홀더가 그대로 유지된다',
      (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('시간을 선택해주세요'));
    await tester.pumpAndSettle();

    expect(find.text('취소'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text('시간을 선택해주세요'), findsOneWidget);
  });

  testWidgets('성별 토글은 초기 상태에서 둘 다 선택돼있지 않다가, "남성"을 누르면 그것만 선택된다',
      (tester) async {
    // 2026-07-19: _gender가 더 이상 기본값(여성)으로 채워지지 않고 null에서
    // 시작한다 — "아직 아무것도 안 고른" 상태를 실제로 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(
      tester.getSemantics(find.text('여성')).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    expect(
      tester.getSemantics(find.text('남성')).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    await tester.tap(find.text('남성'));
    await tester.pump();

    expect(
      tester.getSemantics(find.text('남성')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(find.text('여성')).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    semantics.dispose();
  });

  testWidgets('MBTI 축 토글에서 옵션을 누르면 스크린 리더용 selected 시맨틱스가 바뀐다', (tester) async {
    // 성별 토글과 같은 이유로, MBTI 축(2026-07-07 이 화면으로 이전됨)도 PastelToggleRow
    // 위젯 자체의 테스트(pastel_toggle_row_test.dart)와는 별개로 이 화면에 실제로
    // 연결된 onChanged·semanticLabel 배선이 tester.tap()이 아니라 스크린 리더가
    // 보내는 것과 같은 selected 플래그 갱신까지 정확히 이어지는지 확인한 적이 없었다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    expect(
      tester.getSemantics(find.text('E · 외향')).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.text('I · 내향'));
    await tester.pump();

    expect(
      tester.getSemantics(find.text('I · 내향')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(find.text('E · 외향')).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    semantics.dispose();
  });

  testWidgets('이름/출생지 입력란은 hintText뿐 아니라 필드 용도도 스크린 리더에 전달된다', (tester) async {
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    // hintText만 있으면 필드가 비어 있을 때 그 예시 문구("예: 민지")가 그대로 시맨틱
    // label이 돼버려서, 스크린 리더 사용자는 이 필드가 "이름" 입력란인지 알 수 없다 —
    // Semantics(label:)로 감싸 실제 용도가 hint 앞에 붙어 함께 읽히는지 확인한다.
    final nameLabel = tester.getSemantics(find.byType(TextField).first).label;
    expect(nameLabel, contains('이름'));
    expect(nameLabel, contains('예: 민지'));

    final placeLabel = tester.getSemantics(find.byType(TextField).last).label;
    expect(placeLabel, contains('태어난 곳'));
    expect(placeLabel, contains('예: 서울특별시'));

    semantics.dispose();
  });

  testWidgets('태어난 날짜/시간 pill은 버튼 역할을 유지한 채 필드 맥락이 붙은 라벨 하나만 읽힌다 (중복 없음)',
      (tester) async {
    // 2026-07-15 접근성 발견: PastelPillButton 자체 라벨은 값만 담고 있어, 바로 위
    // _FieldLabel을 건너뛰고 스크린 리더가 이 버튼에 도달하면 무슨 필드인지 맥락이
    // 없었다. 바깥 Semantics로 "태어난 날짜/시간" 맥락을 라벨에 더하되, 단순히
    // Semantics를 한 겹 더 씌우기만 하면 값이 "태어난 날짜 2000.01.01\n2000.01.01"처럼
    // 중복으로 이어붙는다는 걸 실측으로 확인했다 — excludeSemantics + button/onTap
    // 재선언으로 라벨을 완전히 교체하면서도 버튼 역할·탭 액션은 그대로 유지되는지
    // 검증한다. 날짜/시간을 실제로 골라 값을 채운 뒤 그 값이 라벨에 조합되는지 본다
    // (2026-07-17 버그 수정 이후 — 초기 플레이스홀더로도 같은 조합 규칙이 적용되지만,
    // 실제 선택된 값으로 검증하는 편이 이 테스트의 원래 의도에 더 가깝다).
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await pickDateAndTime(tester);

    final dateNode = tester.getSemantics(find.text('2000.01.01'));
    expect(dateNode.label, '태어난 날짜 2000.01.01');
    expect(dateNode.flagsCollection.isButton, isTrue);

    final timeNode = tester.getSemantics(find.text('오후 2시 30분'));
    expect(timeNode.label, '태어난 시간 오후 2시 30분');
    expect(timeNode.flagsCollection.isButton, isTrue);

    // "태어난 시간을 몰라요"를 체크하면 시간 pill이 탭 불가 상태(enabled: false)로
    // 바뀌고, 라벨도 "모름"으로 교체돼야 한다.
    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();

    final unknownTimeNode = tester.getSemantics(find.text('시간 모름'));
    expect(unknownTimeNode.label, '태어난 시간 모름');
    expect(unknownTimeNode.flagsCollection.isEnabled, Tristate.isFalse);

    semantics.dispose();
  });

  testWidgets('스크린 리더의 탭 액션(SemanticsAction.tap)을 직접 실행해도 날짜/시간 피커가 실제로 열린다',
      (tester) async {
    // 위 라벨 확인 테스트는 outer Semantics의 label/button 플래그만 봤을 뿐, 실제로
    // 스크린 리더가 보내는 SemanticsAction.tap이 _pickDate/_pickTime까지 이어져 피커를
    // 여는지는 검증하지 않았다 — tester.tap()은 실제 히트테스트로 안쪽 PastelPillButton의
    // InkWell을 직접 두드리기 때문에, 바깥 Semantics의 onTap 재선언을 실수로 빠뜨려도
    // (excludeSemantics만 있고 onTap이 없으면 병합 노드에 탭 액션 자체가 사라져도)
    // tester.tap() 기반 테스트는 이 회귀를 못 잡는다 — performAction으로 실제 액션 실행까지
    // 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    final dateNode = tester.getSemantics(find.text('날짜를 선택해주세요'));
    expect(dateNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(dateNode.id, SemanticsAction.tap);
    await tester.pumpAndSettle();

    // showDatePicker가 실제로 열렸다면 "확인" 버튼이 보여야 한다.
    expect(find.text('확인'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    final timeNode = tester.getSemantics(find.text('시간을 선택해주세요'));
    expect(timeNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    // ignore: deprecated_member_use
    tester.binding.pipelineOwner.semanticsOwner!.performAction(timeNode.id, SemanticsAction.tap);
    await tester.pumpAndSettle();

    // showTimePicker가 실제로 열렸다면 "확인" 버튼이 보여야 한다.
    expect(find.text('확인'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    // "태어난 시간을 몰라요" 체크 후에는 시간 pill의 탭 액션 자체가 사라져야 한다
    // (enabled:false일 때 스크린 리더 액션으로도 피커가 열리면 안 된다).
    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();

    final unknownTimeNode = tester.getSemantics(find.text('시간 모름'));
    expect(unknownTimeNode.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    semantics.dispose();
  });

  testWidgets('시스템 글자 크기를 크게(2배) 키워도 RenderFlex overflow가 나지 않는다', (tester) async {
    // result_screen.dart(카테고리 그리드)·share_card.dart에서 실제로 겪었던 고정
    // 높이+큰 글자 조합 RenderFlex overflow가 이 화면에도 있는지 지금까지 확인한
    // 적이 없었다 — 이 화면은 세로로 쌓이는 ListView + PastelPillButton/
    // PastelToggleRow(고정 높이 없이 내용에 맞춰 늘어남)라 실제로는 재현되지
    // 않음을 확인(코드 변경 없이 회귀 방지용으로 고정).
    await useTallViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: buildApp(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  // 2026-07-07: 원래 심층 분석 입력 화면에서 물었던 MBTI를 이 화면으로 옮겨왔다(사용자
  // 요청) — deep_dive_input_screen_test.dart에 있던 대응 테스트들을 이 화면 기준으로 다시 작성.

  testWidgets('"MBTI를 알고 있어요"를 체크하기 전에는 축 토글이 보이지 않는다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('E · 외향'), findsNothing);
  });

  testWidgets('"MBTI를 알고 있어요"를 체크하면 네 축 토글이 나타난다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    expect(find.text('E · 외향'), findsOneWidget);
    expect(find.text('S · 감각'), findsOneWidget);
    expect(find.text('T · 사고'), findsOneWidget);
    expect(find.text('J · 판단'), findsOneWidget);
  });

  testWidgets('MBTI를 체크하지 않고 제출하면 DeepDiveInfoStore에 mbti가 저장되지 않는다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await fillAllRequired(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    final saved = await DeepDiveInfoStore.load();
    expect(saved, isNotNull);
    expect(saved!.mbti, isNull);
    // 관심사는 deep_dive_input_screen.dart의 기존 기본값(전체 선택)으로 미리
    // 채워둬야, 나중에 그 화면을 열었을 때 처음부터 하나도 안 고른 것처럼 보이지 않는다.
    expect(saved.interests, Interest.values.toSet());
  });

  testWidgets('"MBTI를 알고 있어요"를 껐다가 다시 켜도 그 사이에 고른 축 선택은 그대로 유지된다',
      (tester) async {
    // deep_dive_input_screen.dart에 있던 이 테스트가 MBTI 질문이 이 화면으로
    // 옮겨오면서(2026-07-07) 새 화면 기준으로 다시 작성되지 않았던 걸 발견 —
    // "태어난 시간을 몰라요" 체크박스도 껐다 켜도 이미 고른 시간을 잃지 않는 것과
    // 같은 관례로, 체크박스는 축 토글을 보여줄지만 결정할 뿐 축 값(_ei/_sn/_tf/_jp)
    // 자체는 별개 상태라 체크 해제만으로 초기화되지 않아야 한다.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    await tester.tap(find.text('I · 내향'));
    await tester.pump();
    await tester.tap(find.text('N · 직관'));
    await tester.pump();

    // 체크 해제 → 축 토글이 안 보임
    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();
    expect(find.text('I · 내향'), findsNothing);

    // 다시 체크 → 방금 고른 I·N이 그대로 남아있어야 한다(기본값 E·S로 되돌아가지 않음).
    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    await fillAllRequired(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    // 기본값(E·S·T·J)에서 I·N만 바꿨으니 "INTJ"가 나와야 한다 — 체크 해제로
    // 기본값(E·S)으로 되돌아갔다면 "ESTJ"가 나왔을 것이다.
    final saved = await DeepDiveInfoStore.load();
    expect(saved!.mbti?.code, 'INTJ');
  });

  testWidgets('MBTI를 체크하고 축을 바꿔 제출하면 그 조합 그대로 DeepDiveInfoStore에 저장된다',
      (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();
    await tester.tap(find.text('I · 내향'));
    await tester.pump();
    await tester.tap(find.text('N · 직관'));
    await tester.pump();

    await fillAllRequired(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    final saved = await DeepDiveInfoStore.load();
    expect(saved, isNotNull);
    expect(saved!.mbti?.code, 'INTJ');
  });

  testWidgets('MBTI 네 축을 전부 바꿔 제출하면 그 조합 그대로 DeepDiveInfoStore에 저장된다', (tester) async {
    // 위 테스트는 E/I·S/N 축만 바꿨을 뿐이라, 나머지 두 축(T/F·J/P)의 onChanged
    // 콜백 자체는 지금까지 한 번도 실제로 발동된 적이 없었다 — MBTI 질문이
    // deep_dive_input_screen.dart에서 이 화면으로 옮겨오면서(2026-07-07) 예전에
    // 있던 "네 축 전부 바꿔보는" 테스트가 새 화면 기준으로 다시 작성되지 않아
    // 생긴 커버리지 공백(`flutter test --coverage`로 확인). 네 축을 전부 반대로
    // 뒤집어 "INFP"가 되는지 확인한다.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('MBTI를 알고 있어요'));
    await tester.pump();

    await tester.tap(find.text('I · 내향'));
    await tester.pump();
    await tester.tap(find.text('N · 직관'));
    await tester.pump();
    await tester.tap(find.text('F · 감정'));
    await tester.pump();
    await tester.tap(find.text('P · 인식'));
    await tester.pump();

    await fillAllRequired(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    final saved = await DeepDiveInfoStore.load();
    expect(saved, isNotNull);
    expect(saved!.mbti?.code, 'INFP');
  });

  // 2026-07-15: 리서치(docs/research/운세/입력_온보딩_설계.md)가 짚은 23시~01시(자시)
  // 경계 안내 문구 — 계산 로직(관법)은 그대로 두고 정보성 안내만 노출한다.
  //
  // 2026-07-19 재작성: 시간 피커가 Material `showTimePicker`(키보드 입력 전환 아이콘
  // 지원)에서 `CupertinoDatePicker`(순수 스크롤 휠, 텍스트 입력 모드 자체가 없음)로
  // 바뀌면서(wheel_date_picker_sheet.dart) 기존 "키보드 아이콘 탭 → 시/분 TextField
  // 입력" 경로가 더 이상 성립하지 않는다. 자시 경계값(23:00·00:30·22:59·01:00)처럼
  // "정확히 이 시:분이 선택된다"를 보장해야 하는 테스트 의도를 지키기 위해, 실제
  // 스크롤 제스처로 휠을 특정 인덱스까지 드래그하는 대신(itemExtent·offset 계산이
  // 필요해 취약하고 간접적) 시트가 화면에 뜬 상태에서 그 안의 `CupertinoDatePicker`
  // 위젯을 직접 찾아 `onDateTimeChanged` 콜백을 원하는 DateTime으로 호출한다 —
  // 이 콜백은 wheel_date_picker_sheet.dart의 `_showWheelPickerSheet`가 "확인" 버튼이
  // 반환할 `current` 값을 갱신하는 유일한 통로이므로, 이렇게 호출한 뒤 "확인"을 실제로
  // 탭하면 그 값이 그대로 _birthTime에 반영되는 전체 배선(콜백 연결 → 확인 버튼 →
  // setState)을 그대로 검증한다 — 다만 실제 손가락 스크롤 제스처 자체(휠이 정확히
  // 그 위치까지 물리적으로 도달하는지)는 이 경로로는 검증되지 않는다(스크롤 자체는
  // wheel_date_picker_sheet_test.dart에서 별도로 확인).
  Future<void> setTimeViaWheel(WidgetTester tester, {required int hour24, required int minute}) async {
    // 2026-07-17 버그 수정 이후 _birthTime이 처음엔 null이라 pill에 플레이스홀더
    // 문구("시간을 선택해주세요")가 보인다 — 예전엔 이 자리가 "오후 2시 30분"이었다.
    await tester.tap(find.text('시간을 선택해주세요'));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
    picker.onDateTimeChanged(DateTime(2020, 1, 1, hour24, minute));
    await tester.pump();

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
  }

  testWidgets('밤 11시대(23시)를 고르면 자시 경계 안내 문구가 보인다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsNothing);

    await setTimeViaWheel(tester, hour24: 23, minute: 0);

    expect(find.text('오후 11시 00분'), findsOneWidget);
    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsOneWidget);
  });

  testWidgets('새벽 0시대(자정 이후)를 고르면 자시 경계 안내 문구가 보인다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await setTimeViaWheel(tester, hour24: 0, minute: 30);

    expect(find.text('오전 12시 30분'), findsOneWidget);
    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsOneWidget);
  });

  testWidgets('시간을 아직 고르지 않은 초기 상태에서는 자시 경계 안내 문구가 보이지 않는다', (tester) async {
    // 2026-07-17 버그 수정 이후 _birthTime이 null인 초기 상태에서는 _isJasiRange가
    // 항상 false로 취급되므로(자시 여부를 판단할 시간 자체가 없음) 안내 문구도 없다.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsNothing);
  });

  testWidgets('자시 시간대를 고른 뒤 "태어난 시간을 몰라요"를 체크하면 안내 문구가 사라진다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await setTimeViaWheel(tester, hour24: 23, minute: 0);
    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsOneWidget);

    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();

    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsNothing);
  });

  testWidgets('밤 11시 직전(22시 59분)에는 자시 경계 안내 문구가 보이지 않는다 (경계값)', (tester) async {
    // _isJasiRange는 hour == 23 || hour == 0으로 구현돼 있다 — 23시 바로 앞
    // 시각(22시 59분)까지도 안내가 뜬다면 hour >= 22처럼 경계가 잘못 넓어진
    // 회귀를 잡지 못한다. 자시 직전 경계값을 직접 확인한다.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await setTimeViaWheel(tester, hour24: 22, minute: 59);

    expect(find.text('오후 10시 59분'), findsOneWidget);
    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsNothing);
  });

  testWidgets('정확히 새벽 1시(01시)에는 자시 경계 안내 문구가 보이지 않는다 (경계값)', (tester) async {
    // four_pillars.dart의 시주 계산(`((birthHour + 1) ~/ 2) % 12`)을 직접 대조하면
    // hour=1(01시)은 자(子) branch가 아니라 축(丑) branch로 계산된다 — 즉 실제 관법
    // 경계는 "23시·0시"까지만 자시이고 1시는 이미 축시다. 리서치 문서의 "23시~01시"라는
    // 표현(23:00~00:59, 두 시간)과 구현(`hour == 23 || hour == 0`)이 정확히 일치하는지,
    // 그리고 hour == 0을 hour <= 1처럼 잘못 넓히는 회귀가 없는지 이 경계값으로 고정한다.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await setTimeViaWheel(tester, hour24: 1, minute: 0);

    expect(find.text('오전 1시 00분'), findsOneWidget);
    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsNothing);
  });

  testWidgets('자시 경계 안내 문구는 태어난 시간 pill과 별개의 시맨틱 노드로 읽힌다 (접근성)', (tester) async {
    // 안내 Text는 일반 Text 위젯이라 자체 시맨틱 노드를 만든다 — 태어난 시간 pill은
    // Semantics(excludeSemantics: true)로 라벨을 통째로 교체해두고 있어(위 "중복 없음"
    // 테스트 참고), 그 옆에 새로 추가된 안내 Text가 그 pill의 병합 라벨 안으로 잘못
    // 흡수되거나(라벨에 안내 문구가 섞여 중복 낭독) 반대로 안내 문구 자체가 스크린
    // 리더에서 완전히 누락되지는 않는지 확인한다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await setTimeViaWheel(tester, hour24: 23, minute: 0);

    // 시간 pill의 라벨은 여전히 "태어난 시간 오후 11시 00분"뿐이어야 한다 — 안내
    // 문구가 섞여 들어가 중복 낭독되면 안 된다.
    final timeNode = tester.getSemantics(find.text('오후 11시 00분'));
    expect(timeNode.label, '태어난 시간 오후 11시 00분');

    // 안내 문구는 그 자체로 별도 노드에서 온전한 텍스트가 읽혀야 한다.
    final noticeNode = tester.getSemantics(find.textContaining('앱마다 계산 방식이 조금씩 달라요'));
    expect(
      noticeNode.label,
      '밤 11시~새벽 1시 사이는 앱마다 계산 방식이 조금씩 달라요. '
      '병원 기록상 시간이 있다면 다시 확인해보세요.',
    );
    // 안내 문구는 버튼이 아니라 순수 정보성 텍스트여야 한다.
    expect(noticeNode.flagsCollection.isButton, isFalse);

    semantics.dispose();
  });

  testWidgets('자시 경계 안내 문구는 SemanticsFlag.isLiveRegion 플래그를 갖는다 (접근성)', (tester) async {
    // 위 "별개의 시맨틱 노드로 읽힌다" 테스트는 라벨 텍스트·isButton만 확인했을 뿐,
    // 정작 이 문구가 동적으로 나타났을 때 스크린 리더가 포커스 이동 없이도 자동으로
    // 읽어주게 하는 liveRegion 플래그 자체는 검증한 적이 없었다 — Semantics(liveRegion:
    // true)로 감쌌더라도 실수로 값을 빠뜨리거나 다른 위치에 흡수되면 이 플래그가
    // 사라질 수 있어, getSemanticsData().flagsCollection.isLiveRegion으로 직접 확인한다
    // (hasFlag(SemanticsFlag.isLiveRegion)은 flagsCollection으로 대체되며 deprecated됨).
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await setTimeViaWheel(tester, hour24: 23, minute: 0);

    final noticeNode = tester.getSemantics(find.textContaining('앱마다 계산 방식이 조금씩 달라요'));
    expect(noticeNode.getSemanticsData().flagsCollection.isLiveRegion, isTrue);

    semantics.dispose();
  });

  testWidgets('시맨틱스가 활성화된 상태에서 체크박스로 안내 문구를 없애도 시맨틱 트리 처리 중 예외가 없다 (접근성)',
      (tester) async {
    // liveRegion 노드가 트리에서 제거되는 과정(체크박스 토글로 문구 자체가 사라짐)에서
    // 시맨틱스 파이프라인이 예외 없이 노드를 정리하는지 확인한다 — ensureSemantics()로
    // 시맨틱 트리를 실제로 구성해둔 상태에서 진행해야 이 정리 경로가 실행된다.
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await setTimeViaWheel(tester, hour24: 23, minute: 0);
    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsOneWidget);

    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();

    expect(find.textContaining('앱마다 계산 방식이 조금씩 달라요'), findsNothing);
    expect(tester.takeException(), isNull);

    semantics.dispose();
  });

  testWidgets('이미 심층 분석에서 좁혀둔 관심사가 있으면 제출해도 전체 선택으로 되돌아가지 않는다',
      (tester) async {
    // 2026-07-08 버그 수정: 사주 결과 화면은 이 화면이 스택 아래에 그대로 남아 있어
    // (계산 중 화면만 pushReplacement로 교체되고 이 화면은 안 지워짐) Flutter가
    // AppBar에 자동으로 뒤로 가기 버튼을 붙여준다 — "다시 입력하기"(명시적으로 두
    // 스토어를 함께 지움)를 거치지 않고 이 자동 뒤로 가기로 이 화면에 돌아와 재제출하면,
    // 심층 분석에서 이미 관심사를 좁혀뒀어도(예: 연애운만 남기고 나머지 해제) 조용히
    // 전체 선택으로 되돌아가는 실제 데이터 유실 버그가 있었다. 여기서는 뒤로 가기
    // 내비게이션 자체를 재현하지 않고(그건 result_screen_test.dart 영역), 이 화면
    // 단독으로 "제출 시점에 이미 좁혀진 관심사가 저장돼 있으면 그대로 유지되는지"만
    // 확인한다 — 좁혀진 값을 미리 저장해두고 제출한 뒤 값이 그대로인지 본다.
    // 2026-07-19: 이름/성별/혈액형이 필수값이 되면서, 이 필드들을 채우지 않으면
    // _canSubmit이 false라 탭이 그냥 무시된다 — 그러면 이 테스트는 애초에 제출이
    // 일어나지 않아도(사전에 저장해둔 값이 그대로 남아있을 뿐이라) 우연히 통과해버려
    // 실제로 아무것도 검증하지 못하는 상태였다. fillAllRequired로 제출이 실제로
    // 일어나게 해야 이 테스트가 의미가 있다.
    await DeepDiveInfoStore.save(const DeepDiveInfo(interests: {Interest.love}));

    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await fillAllRequired(tester);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    final saved = await DeepDiveInfoStore.load();
    expect(saved, isNotNull);
    expect(saved!.interests, {Interest.love});
  });
}
