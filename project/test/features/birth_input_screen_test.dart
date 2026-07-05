import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/birth_input/birth_input_screen.dart';

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
    expect(find.text('사주 보러가기 🔮'), findsOneWidget);
  });

  testWidgets('"태어난 시간을 몰라요" 체크 시 시간 버튼이 "시간 모름"으로 바뀐다', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(buildApp());

    expect(find.text('시간 모름'), findsNothing);
    await tester.tap(find.byType(Checkbox));
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
}
