import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/core/storage/deep_dive_info_store.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_info.dart';

void main() {
  // 제출 시 BirthInfoStore.save()가 SharedPreferences를 사용하므로 목(mock) 초기값을 설정해둔다.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // 입력 폼(ListView)이 기본 테스트 화면(800x600)보다 길어 제출 버튼이 화면 밖에서
  // 지연 빌드된다 — 뷰포트를 세로로 넉넉하게 키워 전체 폼이 스크롤 없이 다 보이게 한다.
  Future<void> useTallViewport(WidgetTester tester) async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });
  }

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

  testWidgets('기본 입력 필드와 CTA 버튼을 보여준다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('생년월일시를 알려주세요'), findsOneWidget);
    expect(find.text('이름 (선택)'), findsOneWidget);
    expect(find.text('양력'), findsOneWidget);
    expect(find.text('음력'), findsOneWidget);
    expect(find.text('여성'), findsOneWidget);
    expect(find.text('남성'), findsOneWidget);
    expect(find.text('태어난 시간을 몰라요'), findsOneWidget);
    expect(find.text('MBTI를 알고 있어요'), findsOneWidget);
    expect(find.text('사주 보러가기 🔮'), findsOneWidget);
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

  testWidgets('기본값으로 제출하면 BirthInfo가 계산 화면으로 그대로 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(find.text('CALCULATING_STUB'), findsOneWidget);
    expect(captured, isNotNull);
    expect(captured!.date, DateTime(1998, 8, 15));
    expect(captured!.hour, 14);
    // timePicker 기본값(오후 2시 30분)의 "분"이 지금까지는 BirthInfo에 필드 자체가
    // 없어서 제출 시 통째로 버려지고 있었다 — 목업 STEP 4 결과 화면이 "오후 2시
    // 30분生"처럼 분까지 보여주는 것과 어긋나던 부분이라 minute 필드를 추가해 맞췄다.
    expect(captured!.minute, 30);
    expect(captured!.isLunar, isFalse);
    expect(captured!.name, isNull);
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

    final button =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '사주 보러가기 🔮'));
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();

    expect(calculatingPushCount, 1);
  });

  testWidgets('한 번 제출한 뒤 뒤로가기로 돌아와도 "사주 보러가기"를 다시 누를 수 있다', (tester) async {
    // 위 더블탭 가드(_isSubmitting)를 추가하면서 새로 생긴 실제 버그: 제출 시
    // Navigator.pushNamed()는 화면을 교체(replace)하는 게 아니라 그 위에 쌓기만
    // 해서(BirthInputScreen이 스택에 그대로 남음), 사용자가 calculating 화면에서
    // 뒤로가기로 이 화면에 돌아오면 그 인스턴스의 _isSubmitting이 true로 남아있는
    // 채였다. 원래 코드는 이 플래그를 다시 false로 되돌리는 지점이 전혀 없어서,
    // 한 번 제출한 뒤 뒤로 돌아오면 "사주 보러가기"를 아무리 눌러도 아무 반응 없이
    // 영원히 먹통이 되는 실제 버그였다 — pushNamed()가 반환하는 Future가 완료되는
    // 시점(뒤로가기로 돌아왔을 때)에 맞춰 플래그를 되돌리도록 고쳤다.
    await useTallViewport(tester);
    var calculatingPushCount = 0;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (_) => calculatingPushCount++,
    ));

    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();
    expect(calculatingPushCount, 1);

    // calculating 스텁 화면에서 뒤로가기로 BirthInputScreen에 돌아온다.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('사주 보러가기 🔮'), findsOneWidget);

    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(calculatingPushCount, 2);
  });

  testWidgets('"태어난 시간을 몰라요"를 체크하고 제출하면 hour·minute 모두 null로 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await tester.tap(find.text('태어난 시간을 몰라요'));
    await tester.pump();
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
    // 확인한 적은 없었다. "몰라요"를 체크했다 다시 해제하고 제출해도, 시간이 0시나
    // null 같은 엉뚱한 값이 아니라 원래 고른 기본값(오후 2시 30분)이 그대로
    // 전달되는지 확인한다.
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

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

    await tester.enterText(find.byType(TextField).last, '서울특별시');
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

    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.birthPlace, isNull);
  });

  testWidgets('기본값(여성)으로 제출하면 BirthInfo.gender에 female이 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

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

    await tester.tap(find.text('남성'));
    await tester.pump();
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.gender, Gender.male);
  });

  testWidgets('이름 필드에 공백만 입력하면 name은 null로 전달된다', (tester) async {
    await useTallViewport(tester);
    BirthInfo? captured;
    await tester.pumpWidget(buildApp(
      onCalculatingRoute: (settings) => captured = settings.arguments as BirthInfo?,
    ));

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.name, isNull);
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

    await tester.enterText(find.byType(TextField).at(1), '가' * 35);
    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    expect(captured!.birthPlace, '가' * 30);
  });

  testWidgets('태어난 날짜 pill을 탭해 datePicker를 열고 "확인"을 누르면 정상 진행된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('1998.08.15'));
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    // 같은 날짜를 그대로 확정해도 화면은 오류 없이 유지되고 pill에 날짜가 계속 보인다.
    expect(find.text('1998.08.15'), findsOneWidget);
  });

  testWidgets('태어난 시간 pill을 탭해 timePicker를 열고 "확인"을 누르면 정상 진행된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('오후 2시 30분'));
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('오후 2시 30분'), findsOneWidget);
  });

  testWidgets('datePicker에서 "취소"를 누르면 원래 날짜가 그대로 유지된다', (tester) async {
    // 지금까지는 "확인"으로 확정하는 경로만 테스트했지, 실제 사용자가 자주 하는
    // "취소"(picked == null) 경로는 한 번도 검증한 적이 없었다 — showDatePicker가
    // null을 반환할 때 _pickDate()의 `if (picked != null)` 가드가 실제로 잘 동작하는지 확인.
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('1998.08.15'));
    await tester.pumpAndSettle();

    expect(find.text('취소'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text('1998.08.15'), findsOneWidget);
  });

  testWidgets('timePicker에서 "취소"를 누르면 원래 시간이 그대로 유지된다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('오후 2시 30분'));
    await tester.pumpAndSettle();

    expect(find.text('취소'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(find.text('오후 2시 30분'), findsOneWidget);
  });

  testWidgets('성별 토글에서 "남성"을 누르면 선택 상태가 바뀐다', (tester) async {
    final semantics = tester.ensureSemantics();
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(
      tester.getSemantics(find.text('여성')).flagsCollection.isSelected,
      Tristate.isTrue,
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

    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    final saved = await DeepDiveInfoStore.load();
    expect(saved, isNotNull);
    expect(saved!.mbti?.code, 'INFP');
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
    await DeepDiveInfoStore.save(const DeepDiveInfo(interests: {Interest.love}));

    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('사주 보러가기 🔮'));
    await tester.pumpAndSettle();

    final saved = await DeepDiveInfoStore.load();
    expect(saved, isNotNull);
    expect(saved!.interests, {Interest.love});
  });
}
