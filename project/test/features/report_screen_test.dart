import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cosmos_saju/app/router.dart';
import 'package:cosmos_saju/app/theme/app_colors.dart';
import 'package:cosmos_saju/core/saju/four_pillars.dart';
import 'package:cosmos_saju/core/saju/ganzhi.dart';
import 'package:cosmos_saju/features/birth_input/birth_info.dart';
import 'package:cosmos_saju/features/deep_dive/deep_dive_input_screen.dart';
import 'package:cosmos_saju/features/report/report_readings.dart';
import 'package:cosmos_saju/features/report/report_screen.dart';
import 'package:cosmos_saju/features/result/ohaeng_readings.dart';
import 'package:cosmos_saju/features/result/result_screen.dart';

import '../support/test_viewport.dart';

void main() {
  // 리포트/결과 화면 모두 리스트가 길어 기본 테스트 화면(800x600)보다 콘텐츠가 크다 —
  // 뷰포트를 세로로 넉넉하게 키워 하단 콘텐츠까지 스크롤 없이 다 보이게 한다.
  Future<void> useReportViewport(WidgetTester tester) => useTallViewport(tester, height: 3000);

  testWidgets('상세 리포트 화면이 오행 5종 설명과 명식 breakdown을 모두 보여준다', (tester) async {
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(find.text('상세 리포트'), findsOneWidget);
    expect(find.text('명식 한 글자씩 뜯어보기'), findsOneWidget);
    expect(find.text('오행 五行 완전 정복'), findsOneWidget);
    expect(find.textContaining('계산 정확도 안내'), findsOneWidget);
    // 2026-07-06 리서치로 자시 관법(splitJasi 등과 다른 midnight 관법 채택)과 진태양시
    // 미보정(출생지 경도·균시차 보정 없음)이라는 두 가지 추가 정확도 한계를 새로 문서화했는데,
    // 지금까지 절기 근사만 안내하고 이 두 가지는 사용자에게 전혀 알리지 않고 있었다 —
    // 실제 안내 문구에 반영됐는지 확인한다.
    expect(find.textContaining('진태양시'), findsOneWidget);
    expect(find.textContaining('자시'), findsOneWidget);
    // 2026-07-06 추가 발견: 음력 입력을 양력으로 변환하지 않고 그대로 계산에 쓴다는
    // 한계도 상세 리포트 안내 문구에 함께 반영됐는지 확인한다.
    expect(find.textContaining('음력'), findsOneWidget);
    // 2026-07-07에 "사주 계산 로직" 행에 다섯 번째 정확도 이슈(한국의 역사적 서머타임
    // 미반영)를 리서치로 새로 문서화했는데, 계산 로직 자체의 산술 버그(날짜 차이 계산의
    // DST 오프셋 문제)만 고쳤을 뿐 이 한계 자체는 다른 네 가지(절기·자시·진태양시·음력)와
    // 달리 사용자 안내 문구에 반영된 적이 없었던 공백을 2026-07-08에 발견 — 안내 문구에
    // 반영됐는지 확인한다.
    expect(find.textContaining('서머타임'), findsOneWidget);
    // 오행 5종 의미 카드가 모두 렌더링되는지 (결과 화면과 달리 우세 오행 하나가 아니라 5개 전부)
    expect(find.textContaining('목 · 성장'), findsOneWidget);
    expect(find.textContaining('화 · 열정'), findsOneWidget);
    expect(find.textContaining('토 · 안정'), findsOneWidget);
    expect(find.textContaining('금 · 원칙'), findsOneWidget);
    expect(find.textContaining('수 · 지혜'), findsOneWidget);
  });

  testWidgets('명식 breakdown 표가 실제 계산값(천간·지지 각 글자와 오행)과 정확히 일치한다', (tester) async {
    // result_screen_test.dart에서 결과 화면의 4기둥 한자·퍼센트를 값으로 검증했는데,
    // report_screen.dart는 그보다 더 자세히(천간/지지를 따로, 각각의 오행 라벨까지)
    // 보여주면서도 지금까지 "년주"/"월주" 같은 라벨만 확인했을 뿐 실제 글자·오행 값
    // 자체는 검증한 적이 없었다. 1998-08-15 14시의 4주(년주 무인·월주 경신·일주 갑자·
    // 시주 신미)를 그대로 재사용한다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    // 천간: 무(토), 경(금), 갑(목), 신(금, 시주) — 지지: 인(목), 신(금, 월주), 자(수), 미(토)
    // '신'은 시주 천간(辛)과 월주 지지(申)가 우연히 같은 한글로 표기돼 2번 나타난다.
    expect(find.text('무'), findsOneWidget);
    expect(find.text('경'), findsOneWidget);
    expect(find.text('갑'), findsOneWidget);
    expect(find.text('신'), findsNWidgets(2));
    expect(find.text('인'), findsOneWidget);
    expect(find.text('자'), findsOneWidget);
    expect(find.text('미'), findsOneWidget);

    // 천간/지지 · 오행 라벨 — "천간 · 금"은 월주 지지가 아니라 월주 천간(경)과
    // 시주 천간(신) 둘 다 금이라 2번 나타난다.
    expect(find.text('천간 · 토'), findsOneWidget); // 년주 무
    expect(find.text('지지 · 목'), findsOneWidget); // 년주 인
    expect(find.text('천간 · 금'), findsNWidgets(2)); // 월주 경, 시주 신
    expect(find.text('지지 · 금'), findsOneWidget); // 월주 신
    expect(find.text('천간 · 목'), findsOneWidget); // 일주 갑
    expect(find.text('지지 · 수'), findsOneWidget); // 일주 자
    expect(find.text('지지 · 토'), findsOneWidget); // 시주 미

    // _charCell은 글자색(ohaengTextColors)뿐 아니라 칸 배경색(ohaengSoftColors)도
    // 오행별로 물들이는데, 지금까지 한자·라벨 문자열만 확인했을 뿐 이 두 색 값 자체는
    // 검증한 적이 없었다 — result_screen/share_card의 기둥 칩과 같은 성격의 공백.
    Color textColorOf(String hanja) => tester.widget<Text>(find.text(hanja).first).style!.color!;
    Color bgColorOf(String hanja) => (tester
            .widget<Container>(find.ancestor(of: find.text(hanja).first, matching: find.byType(Container)).first)
            .decoration! as BoxDecoration)
        .color!;

    expect(textColorOf('무'), AppColors.ohaengTextColors['토']);
    expect(bgColorOf('무'), AppColors.ohaengSoftColors['토']);
    expect(textColorOf('경'), AppColors.ohaengTextColors['금']);
    expect(bgColorOf('경'), AppColors.ohaengSoftColors['금']);
    expect(textColorOf('갑'), AppColors.ohaengTextColors['목']);
    expect(bgColorOf('갑'), AppColors.ohaengSoftColors['목']);
    expect(textColorOf('인'), AppColors.ohaengTextColors['목']);
    expect(bgColorOf('인'), AppColors.ohaengSoftColors['목']);
    expect(textColorOf('자'), AppColors.ohaengTextColors['수']);
    expect(bgColorOf('자'), AppColors.ohaengSoftColors['수']);
    expect(textColorOf('미'), AppColors.ohaengTextColors['토']);
    expect(bgColorOf('미'), AppColors.ohaengSoftColors['토']);
    // '신'은 시주 천간(辛)·월주 지지(申) 둘 다 금이라 두 인스턴스 모두 같은 색이어야 한다.
    for (final w in tester.widgetList<Text>(find.text('신'))) {
      expect(w.style!.color, AppColors.ohaengTextColors['금']);
    }
  });

  testWidgets('명식 breakdown 행이 스크린 리더에 "기둥 · 천간/지지 · 오행"이 하나로 병합된 문장으로 들린다',
      (tester) async {
    // _pillarRow가 년주 라벨 + 천간 칸(글자+오행) + 지지 칸(글자+오행)을 시각적으로는
    // 나란히 보여주지만, Semantics로 묶지 않으면 스크린 리더가 4개 텍스트 노드를
    // 따로따로 읽어 어느 기둥의 어느 글자인지 맥락이 끊긴다 — 지금까지 이 표의 실제
    // 계산값(한자·오행 라벨)은 검증했지만 스크린 리더 접근성은 검증한 적이 없었다.
    final semantics = tester.ensureSemantics();
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    // 년주 무인(戊寅) — 천간 무(토), 지지 인(목)
    expect(
      tester.getSemantics(find.text('무')),
      matchesSemantics(label: '년주. 천간 무, 오행 토. 지지 인, 오행 목.'),
    );

    // 2026-07-15 발견한 콘텐츠 스왑 취약점 보강: 년주 한 행만 값으로 고정돼 있어
    // _pillarRow 4번 호출(년/월/일/시) 중 월주↔일주 두 줄의 pillars 인자가 실수로
    // 뒤바뀌어도(예: 월주 줄에 pillars.day, 일주 줄에 pillars.month) 년주·시주만
    // 맞으면 이 테스트가 그대로 통과해버렸다 — 월주 경신(庚申), 일주 갑자(甲子)도
    // 값으로 고정해 스왑 시 반드시 실패하도록 한다.
    expect(
      tester.getSemantics(find.text('경')),
      matchesSemantics(label: '월주. 천간 경, 오행 금. 지지 신, 오행 금.'),
    );
    expect(
      tester.getSemantics(find.text('갑')),
      matchesSemantics(label: '일주. 천간 갑, 오행 목. 지지 자, 오행 수.'),
    );

    semantics.dispose();
  });

  group('납음오행·공망(_PillarExtras)', () {
    // 1998-08-15 14시 픽스처(년주 무인·월주 경신·일주 갑자·시주 신미)는 일주 기준
    // 공망 지지가 [술,해]라 년/월/시주 중 공망에 해당하는 기둥이 하나도 없다 — 이
    // 그룹에서는 순수하게 납음오행 배지·카피만 검증하는 용도로 쓴다. GanzhiPillar.
    // ganzhiIndex60 + nayinFor()로 테스트 안에서 직접 계산해 대조한다(하드코딩 문자열을
    // core/saju/ganzhi.dart·features/report/report_readings.dart와 별개로 다시 베껴 쓰면
    // 그 자체가 동어반복이 되므로, 계산 함수를 그대로 호출해 "실제 계산값"과 비교한다).
    final pillars1998 = calculateFourPillars(birthDate: DateTime(1998, 8, 15), birthHour: 14);
    final nayin1998 = {
      '년주': nayinFor(pillars1998.year.ganzhiIndex60),
      '월주': nayinFor(pillars1998.month.ganzhiIndex60),
      '일주': nayinFor(pillars1998.day.ganzhiIndex60),
      '시주': nayinFor(pillars1998.hour!.ganzhiIndex60),
    };

    testWidgets('각 기둥 행에 실제 계산된 납음오행 이름(한글+한자)이 배지로 표시된다', (tester) async {
      await useReportViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      );

      for (final entry in nayin1998.entries) {
        final badgeText = '${entry.key} · ${entry.value.name}(${entry.value.hanja})';
        expect(find.text(badgeText), findsOneWidget, reason: '${entry.key} 납음오행 배지');
      }
    });

    testWidgets('납음오행·공망 정보가 스크린 리더에 "라벨 납음오행 ..." 하나의 병합 문장으로 들린다 (공망 없는 픽스처)',
        (tester) async {
      // 1998 픽스처는 공망 기둥이 하나도 없으므로, 병합 라벨에 "공망(空亡)에 해당해요"
      // 문장이 붙지 않고 "$label 납음오행 이름(한자). 카피"로만 구성돼야 한다.
      final semantics = tester.ensureSemantics();
      await useReportViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      );

      for (final entry in nayin1998.entries) {
        final badgeText = '${entry.key} · ${entry.value.name}(${entry.value.hanja})';
        final expectedLabel =
            '${entry.key} 납음오행 ${entry.value.name}(${entry.value.hanja}). ${nayinReadingFor(entry.value.name)}';
        expect(
          tester.getSemantics(find.text(badgeText)),
          matchesSemantics(label: expectedLabel),
          reason: '${entry.key} 병합 시맨틱스',
        );
      }

      semantics.dispose();
    });

    testWidgets(
        '일주 자신에는 절대 공망 배지가 붙지 않고, 공망 지지를 가진 기둥에만 공망 배지·카피가 붙는다 (공망이 실제로 있는 픽스처)',
        (tester) async {
      // 1998 픽스처는 우연히 공망 기둥이 없어(voidBranchIndices가 [술,해]인데 년/월/
      // 시주 지지가 인/신/미), 공망 배지 자체가 뜨는 경로를 전혀 검증하지 못한다.
      // voidBranchIndices()로 역산해 실제로 공망이 존재하는 1990-01-01 00시 픽스처
      // (년주 기사·월주 정축·일주 병신·시주 무자, 일주 기준 공망 지지=[진,사])를 쓴다 —
      // 년주 지지 '사'가 공망에 해당하고, 월/일/시주는 해당하지 않는다.
      final semantics = tester.ensureSemantics();
      final pillars1990 = calculateFourPillars(birthDate: DateTime(1990, 1, 1), birthHour: 0);
      final voidBranches = voidBranchIndices(
        dayStemIndex: pillars1990.day.stemIndex,
        dayBranchIndex: pillars1990.day.branchIndex,
      );
      // 픽스처 자체가 실제로 "년주만 공망"인 조건을 만족하는지 먼저 확인한다 — 픽스처가
      // 바뀌거나 계산 로직이 바뀌어도 이 테스트가 조용히 무의미해지지 않도록 하는 안전장치.
      expect(voidBranches.contains(pillars1990.year.branchIndex % 12), isTrue);
      expect(voidBranches.contains(pillars1990.month.branchIndex % 12), isFalse);
      expect(voidBranches.contains(pillars1990.day.branchIndex % 12), isFalse);
      expect(voidBranches.contains(pillars1990.hour!.branchIndex % 12), isFalse);

      final nayin1990 = {
        '년주': nayinFor(pillars1990.year.ganzhiIndex60),
        '월주': nayinFor(pillars1990.month.ganzhiIndex60),
        '일주': nayinFor(pillars1990.day.ganzhiIndex60),
        '시주': nayinFor(pillars1990.hour!.ganzhiIndex60),
      };

      await useReportViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1990, 1, 1), hour: 0, isLunar: false),
          ),
        ),
      );

      // 화면 전체에 "공망" 배지 Text가 정확히 1개(년주 몫)만 있어야 한다.
      expect(find.text('공망'), findsOneWidget);

      // 년주 행 — 납음오행 배지 뒤에 공망(空亡) 문장 + 공망 재해석 카피가 이어붙는다.
      final yearBadgeText = '년주 · ${nayin1990['년주']!.name}(${nayin1990['년주']!.hanja})';
      final expectedYearLabel = '년주 납음오행 ${nayin1990['년주']!.name}(${nayin1990['년주']!.hanja}). '
          '공망(空亡)에 해당해요. ${nayinReadingFor(nayin1990['년주']!.name)} $gongmangReadingCaption';
      expect(
        tester.getSemantics(find.text(yearBadgeText)),
        matchesSemantics(label: expectedYearLabel),
      );

      // 월/일/시주 행 — 공망에 해당하지 않으므로 "공망" 문장이 전혀 붙지 않아야 한다.
      // 특히 일주는 공망 판별 기준 자체(일간·일지)라 절대 자기 자신에게 배지를 붙이면
      // 안 된다 — 다른 두 기둥과 같은 방식으로 검증해 예외 취급하지 않는다.
      for (final label in const ['월주', '일주', '시주']) {
        final nayin = nayin1990[label]!;
        final badgeText = '$label · ${nayin.name}(${nayin.hanja})';
        final expectedLabel = '$label 납음오행 ${nayin.name}(${nayin.hanja}). ${nayinReadingFor(nayin.name)}';
        expect(
          tester.getSemantics(find.text(badgeText)),
          matchesSemantics(label: expectedLabel),
          reason: '$label 병합 시맨틱스 (공망 아님)',
        );
      }

      semantics.dispose();
    });
  });

  testWidgets('명식 breakdown 행 라벨(년주/월주/일주/시주)이 FittedBox로 감싸져 폰트 확대 시 잘리지 않는다',
      (tester) async {
    // 2026-07-15 접근성 감사 발견: SizedBox(width: 44) 고정폭 라벨은 시스템 폰트
    // 확대 배율이 커지면 Container/SizedBox 특성상 예외 없이 조용히 잘린다 —
    // 기존 `takeException()` 방식 테스트로는 이 조용한 잘림을 못 잡는다. FittedBox로
    // 감싸 배율이 커져도 44px 폭 안에서 스스로 축소되게 고쳤는데, 이 구조 자체가
    // 남아있는지(누군가 실수로 FittedBox를 걷어내도) 확인한다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    for (final label in const ['년주', '월주', '일주', '시주']) {
      final fittedBoxAncestor = find.ancestor(
        of: find.text(label),
        matching: find.byType(FittedBox),
      );
      expect(fittedBoxAncestor, findsOneWidget, reason: '"$label" 라벨이 FittedBox로 감싸져 있어야 함');
    }
  });

  testWidgets('시스템 글자 크기를 크게(3배) 키워도 명식 breakdown 표에서 예외가 나지 않는다', (tester) async {
    // FittedBox로 감싼 라벨(위 테스트 참고)이 실제로 큰 배율에서도 예외 없이
    // 렌더링되는지 함께 확인한다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
        child: MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      '시스템 폰트 확대 배율 2.0~3.0에서도 명식 breakdown 라벨이 실제로 잘리지 않고 '
      '온전한 크기로 그려진다(FittedBox 구조 존재만이 아니라 실제 렌더링 검증)',
      (tester) async {
    // 위 "예외가 나지 않는다" 테스트는 이름 그대로 예외 유무만 본다 — FittedBox를
    // 걷어내도(RenderParagraph가 폭은 스스로 44px에 맞춰 잘라내고 예외를 던지지
    // 않으므로) 절대 실패하지 않는 눈속임 테스트였다(재검증 발견). 진짜 구별
    // 기준은 "글자가 실제로 잘렸는가"다 — FittedBox는 자식에게 무제한 제약을 준 뒤
    // 그 결과(제약 없는 자연 크기)를 축소 변환으로 보여주므로, 텍스트 위젯 자신의
    // 로컬 렌더 크기(tester.getSize, 변환 적용 전)는 항상 TextPainter로 직접 계산한
    // "제약 없는 자연 크기"와 같아야 한다. FittedBox가 없으면 44px 폭 제약 때문에
    // 자연 크기보다 작게(=잘려서) 렌더링된다.
    for (final scale in const [2.0, 3.0]) {
      await useReportViewport(tester);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            home: ReportScreen(
              birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
            ),
          ),
        ),
      );
      await tester.pump();

      for (final label in const ['년주', '월주', '일주', '시주']) {
        final finder = find.text(label);
        final textWidget = tester.widget<Text>(finder);
        final naturalPainter = TextPainter(
          text: TextSpan(text: textWidget.data, style: textWidget.style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(scale),
        )..layout();
        final naturalSize = naturalPainter.size;
        final renderedSize = tester.getSize(finder);
        expect(
          renderedSize.width,
          greaterThanOrEqualTo(naturalSize.width - 0.5),
          reason: '배율 $scale, "$label" 라벨이 가로로 잘림 — '
              '실제 렌더 폭=${renderedSize.width}, 제약 없는 자연 폭=${naturalSize.width}',
        );
        expect(
          renderedSize.height,
          greaterThanOrEqualTo(naturalSize.height - 0.5),
          reason: '배율 $scale, "$label" 라벨이 세로로 잘림 — '
              '실제 렌더 높이=${renderedSize.height}, 제약 없는 자연 높이=${naturalSize.height}',
        );
      }
    }
  });

  testWidgets('시간을 모르면 시주 breakdown 행도 하나의 안내 문장으로 병합된다', (tester) async {
    final semantics = tester.ensureSemantics();
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('시주')),
      matchesSemantics(
        label: '시주. 태어난 시간을 몰라 계산하지 않았어요. 태어난 시간을 알면 더 정확한 결과를 볼 수 있어요.',
      ),
    );

    semantics.dispose();
  });

  testWidgets('오행 5종 의미 카드도 스크린 리더에 "오행 · 제목. 설명"으로 병합된 시맨틱스를 제공한다',
      (tester) async {
    // _OhaengMeaningCard가 배지 한자·"오행 · 의미" 제목·설명을 시각적으로는 한 카드
    // 안에 나란히 보여주지만, _pillarRow와 달리 지금까지 Semantics로 묶여 있지 않아
    // 스크린 리더가 세 노드로 따로 읽었다(2026-07-07 발견) — 카드 5개가 나란히 있어도
    // 서로 안 섞이고 "목 · 성장 · 시작 · 추진력. 새싹이 자라나는 이미지"처럼 하나로
    // 들리는지 확인한다.
    final semantics = tester.ensureSemantics();
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.textContaining('목 · 성장')),
      matchesSemantics(label: '목 · 성장 · 시작 · 추진력. 새싹이 자라나는 이미지'),
    );

    semantics.dispose();
  });

  testWidgets('오행 5종 의미 카드의 원형 배지 배경·글자색이 각 오행 색과 정확히 일치한다', (tester) async {
    // _OhaengMeaningCard의 40x40 원형 배지(木/火/土/金/水 한자)는 태어난 정보와 무관하게
    // 늘 5개 전부 렌더링되는데도, 지금까지 색상 값(ohaengSoftColors 배경·ohaengTextColors
    // 글자색) 자체는 한 번도 검증한 적이 없었다 — _pillarRow/_charCell(위 테스트) 색상
    // 검증과 같은 성격의 공백.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    const hanjaToOhaeng = {'木': '목', '火': '화', '土': '토', '金': '금', '水': '수'};
    for (final entry in hanjaToOhaeng.entries) {
      final badgeContainer = tester.widget<Container>(
        find.ancestor(of: find.text(entry.key), matching: find.byType(Container)).first,
      );
      final decoration = badgeContainer.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.ohaengSoftColors[entry.value], reason: '${entry.key} 배지 배경');
      expect(
        tester.widget<Text>(find.text(entry.key)).style!.color,
        AppColors.ohaengTextColors[entry.value],
        reason: '${entry.key} 배지 글자색',
      );
    }
  });

  testWidgets('오행 5종 의미 카드의 원형 배지 한자가 FittedBox로 감싸져 폰트 확대 시 잘리지 않는다',
      (tester) async {
    // 2026-07-15 접근성 감사(선택 보강) — 40x40 원형 배지 안 한자 1글자도 시스템
    // 폰트 확대 시 조용히 잘릴 수 있어 FittedBox로 감쌌다. 위 배경/글자색 테스트와
    // 달리 이 구조(FittedBox 존재) 자체를 확인한다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    for (final hanja in const ['木', '火', '土', '金', '水']) {
      final fittedBoxAncestor = find.ancestor(
        of: find.text(hanja).first,
        matching: find.byType(FittedBox),
      );
      expect(fittedBoxAncestor, findsOneWidget, reason: '"$hanja" 배지가 FittedBox로 감싸져 있어야 함');
    }
  });

  testWidgets(
      '시스템 폰트 확대 배율 2.0~3.0에서도 오행 5종 의미 카드 배지 한자가 '
      '실제로 잘리지 않고 온전한 크기로 그려진다(FittedBox 구조 존재만이 아니라 실제 렌더링 검증)',
      (tester) async {
    // 위 FittedBox 구조 존재 확인 테스트의 한계: 배지는 Container(width:40,height:40,
    // alignment:center)라 가로·세로 모두 최대 40으로 막혀 있어, FittedBox 없이도
    // RenderParagraph가 가로·세로를 각각 독립적으로 40 이하로 잘라 보고한다 — 즉
    // "렌더 크기가 40x40 박스 안에 담기는지"만 재면 clipping도 항상 <=40으로 보여
    // FittedBox 유무와 무관하게 항상 통과해버린다(재검증 중 발견한 진짜 함정).
    // 진짜 구별 기준은 "글자가 실제로 잘렸는가"다 — FittedBox는 자식에게 무제한
    // 제약을 준 뒤 그 결과(자연 크기)를 축소 변환으로 보여주므로, 텍스트 위젯 자신의
    // 로컬 렌더 크기(tester.getSize, 변환 적용 전)는 항상 "제약 없이 계산한 자연
    // 크기"와 같아야 한다. FittedBox가 없으면 자연 크기가 40을 넘는 배율에서
    // 로컬 렌더 크기가 자연 크기보다 작게(=잘려서) 나온다.
    await useTallViewport(tester, height: 9000);

    for (final scale in const [2.0, 3.0]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            home: ReportScreen(
              birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
            ),
          ),
        ),
      );
      await tester.pump();

      for (final hanja in const ['木', '火', '土', '金', '水']) {
        final finder = find.text(hanja).first;
        final textWidget = tester.widget<Text>(finder);
        final naturalPainter = TextPainter(
          text: TextSpan(text: textWidget.data, style: textWidget.style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(scale),
        )..layout();
        final naturalSize = naturalPainter.size;
        final renderedSize = tester.getSize(finder);
        expect(
          renderedSize.width,
          greaterThanOrEqualTo(naturalSize.width - 0.5),
          reason: '배율 $scale, "$hanja" 배지 글자가 가로로 잘림 — '
              '실제 렌더 폭=${renderedSize.width}, 제약 없는 자연 폭=${naturalSize.width}',
        );
        expect(
          renderedSize.height,
          greaterThanOrEqualTo(naturalSize.height - 0.5),
          reason: '배율 $scale, "$hanja" 배지 글자가 세로로 잘림 — '
              '실제 렌더 높이=${renderedSize.height}, 제약 없는 자연 높이=${naturalSize.height}',
        );
      }
    }
  });

  testWidgets('오행 5종 의미 카드의 제목·설명 문구가 5개 전부 실제 값과 정확히 일치한다', (tester) async {
    // 기존 테스트는 '목'만 "목 · 성장 · 시작 · 추진력. 새싹이 자라나는 이미지"처럼
    // 제목+설명 전체를 시맨틱 라벨로 확인했고, 나머지 4개(화·토·금·수)는
    // "화 · 열정"처럼 제목의 접두어만 textContaining으로 확인했을 뿐 설명 문구
    // ("따뜻한 온기의 이미지" 등)는 단 한 번도 값으로 확인한 적이 없었다 —
    // ohaeng_readings.dart/deep_dive_readings.dart의 문구에서 반복 발견된 것과
    // 같은 종류의 공백(2026-07-08/2026-07-11). find.text()로 문구가 "어딘가에"
    // 존재하는지만 보면 두 오행의 설명이 통째로 맞바뀌어도 둘 다 화면 어딘가에는
    // 여전히 존재해 못 잡는다(실제로 이렇게 짰다가 화-토 설명을 맞바꿔도 통과하는
    // 것을 발견해 재작성함) — `_OhaengMeaningCard`가 이미 "$ohaeng · 제목. 설명"을
    // 하나의 병합 시맨틱 라벨로 제공하므로, 그 병합 라벨 전체가 정확히 일치하는지
    // 확인해야 특정 오행의 설명이 맞는 카드에 붙어 있는지 확실히 검증된다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    const expected = {
      '목 · 성장 · 시작 · 추진력': '목 · 성장 · 시작 · 추진력. 새싹이 자라나는 이미지',
      '화 · 열정 · 표현력 · 인기운': '화 · 열정 · 표현력 · 인기운. 따뜻한 온기의 이미지',
      '토 · 안정 · 신뢰 · 중재': '토 · 안정 · 신뢰 · 중재. 땅에 발붙인 이미지',
      '금 · 원칙 · 결단력 · 완성도': '금 · 원칙 · 결단력 · 완성도. 정제된 금속의 이미지',
      '수 · 지혜 · 유연함 · 통찰': '수 · 지혜 · 유연함 · 통찰. 흐르는 물의 이미지',
    };
    for (final entry in expected.entries) {
      expect(
        tester.getSemantics(find.textContaining(entry.key)),
        matchesSemantics(label: entry.value),
        reason: entry.key,
      );
    }
  });

  testWidgets('오행별 오늘의 풀이 모음 섹션이 5개 오행 전부의 실제 풀이 내용·제목 색을 그대로 보여준다',
      (tester) async {
    // "오행별 오늘의 풀이 모음"(_AllReadingsSection, ohaeng_readings.dart의
    // categoryReadingsByOhaeng 5개 전부를 for 루프로 순회) 섹션은 지금까지 어떤
    // 테스트에서도 존재 자체가 언급된 적이 없었다 — 5개 오행 × 4개 영역(연애·재물·
    // 건강·성격) = 20줄의 실제 풀이 문구, 제목 5개의 글자색 전부 미검증 상태였다.
    // categoryReadingsFor()는 알 수 없는 키가 들어오면 조용히 '토' 풀이로 폴백하므로,
    // 루프 변수가 잘못 전달돼도 화면이 깨지지 않고 그냥 틀린(엉뚱한 오행) 내용을
    // 보여줄 수 있어 실제 문구까지 값으로 대조해야 이런 회귀를 잡을 수 있다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(find.text('오행별 오늘의 풀이 모음'), findsOneWidget);

    // 제목 문구·색상 — 5개 오행 전부.
    const ohaengHanja = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    for (final ohaeng in ohaengHanja.keys) {
      final hanja = ohaengHanja[ohaeng]!;
      final titleFinder = find.text('$ohaeng($hanja) 기운이 강할 때');
      expect(titleFinder, findsOneWidget, reason: '$ohaeng 제목 문구');
      expect(
        tester.widget<Text>(titleFinder).style!.color,
        AppColors.ohaengTextColors[ohaeng],
        reason: '$ohaeng 제목 글자색',
      );
    }

    // 실제 풀이 내용 — ohaeng_readings.dart의 categoryReadingsByOhaeng와 값이 정확히
    // 일치하는지, 5개 오행이 서로 뒤섞이거나 '토'로 폴백되지 않았는지 확인한다.
    expect(find.text('💘 연애운: 적극적으로 다가가면 좋은 인연이 생기는 시기예요'), findsOneWidget); // 목
    expect(find.text('🎭 성격: 밝고 열정적인 분위기 메이커 타입이에요'), findsOneWidget); // 화
    expect(find.text('💰 재물운: 무리한 투자보다 꾸준한 저축이 유리해요'), findsOneWidget); // 토
    expect(find.text('🌱 건강운: 호흡기·피부 컨디션을 신경 쓰면 좋아요'), findsOneWidget); // 금
    expect(find.text('💘 연애운: 은근한 매력으로 다가오는 인연이 있어요'), findsOneWidget); // 수
  });

  testWidgets('오행별 오늘의 풀이 모음 섹션 뒤에 건강운 면책 문구가 정확히 1번만 노출된다', (tester) async {
    // 2026-07-17 오버나이트 리서치 반영: 오행 5개 반복문(_AllReadingsSection)이 5번
    // 도는데, 건강운 면책 문구는 그 반복문 "안"이 아니라 반복문이 끝난 지점에 딱 1번만
    // 노출돼야 한다 — 실수로 반복문 안(각 _AllReadingsSection)에 넣으면 5번 중복
    // 노출되는 회귀가 생기는데, findsOneWidget으로 그 회귀를 고정해 잡아낸다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(find.text(healthReadingDisclaimer), findsOneWidget);
  });

  testWidgets('오행별 오늘의 풀이 모음 항목의 스크린 리더 라벨에는 장식용 이모지가 빠져 있다', (tester) async {
    // reading.$1(💘/💰/🌱/🎭)은 시각적 장식용 이모지일 뿐인데, 이 섹션만 같은 파일의
    // _pillarRow/_OhaengMeaningCard(위 테스트들 참고)와 달리 Semantics 병합 처리가
    // 안 돼 있어 스크린 리더가 이모지를 유니코드 이름으로 그대로 읽어 혼란을 줬다
    // (2026-07-14 발견). 시각적 텍스트(이모지 포함)는 위 테스트에서 이미 확인했으므로,
    // 여기서는 라벨에서 이모지가 빠졌는지만 확인한다.
    final semantics = tester.ensureSemantics();
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('💘 연애운: 적극적으로 다가가면 좋은 인연이 생기는 시기예요')),
      matchesSemantics(label: '연애운: 적극적으로 다가가면 좋은 인연이 생기는 시기예요'),
    );
    expect(
      tester.getSemantics(find.text('💰 재물운: 무리한 투자보다 꾸준한 저축이 유리해요')),
      matchesSemantics(label: '재물운: 무리한 투자보다 꾸준한 저축이 유리해요'),
    );

    semantics.dispose();
  });

  testWidgets('이름과 메타 라인이 결과 화면과 같은 형식으로 헤더에 표시된다', (tester) async {
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(
            date: DateTime(1998, 8, 15),
            hour: 14,
            isLunar: false,
            name: '민지',
            gender: Gender.female,
            birthPlace: '서울특별시',
          ),
        ),
      ),
    );

    expect(find.text('민지의 상세 리포트'), findsOneWidget);
    expect(find.text('1998.08.15 · 오후 2시生 · 양력 · 여성 · 서울특별시'), findsOneWidget);
  });

  testWidgets('음력으로 입력했으면 메타 라인에 "음력"으로 표시된다', (tester) async {
    // 2026-07-08 발견한 커버리지 공백: `buildMetaLine`의 isLunar 분기 자체는
    // meta_line_test.dart에서 이미 검증돼 있고 result_screen_test.dart/
    // share_text_test.dart도 isLunar: true로 실제 렌더링/조립을 확인해왔는데,
    // 이 화면(report_screen.dart도 같은 `buildMetaLine(info)`를 그대로 호출)만
    // isLunar: true로 렌더링해본 적이 한 번도 없었던 비대칭을 발견 — share_card.dart의
    // hour: null 공백(바로 위 "사주 결과 화면" 행 참고)과 같은 종류의 발견.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: true),
        ),
      ),
    );

    expect(find.text('1998.08.15 · 오후 2시生 · 음력'), findsOneWidget);
  });

  testWidgets('이름이 없거나 공백뿐이면 헤더에 "회원님"으로 표시된다', (tester) async {
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );
    expect(find.text('회원님의 상세 리포트'), findsOneWidget);

    // 이름이 아예 없는(null) 경우는 위에서 확인했는데, 공백뿐인 이름(trim하면 빈
    // 문자열)도 같은 폴백을 타는지는 지금까지 값으로 확인한 적이 없었다 —
    // result_screen.dart/deep_dive_result_screen.dart의 같은 로직 검증과 대칭을 맞춘다.
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false, name: '   '),
        ),
      ),
    );
    expect(find.text('회원님의 상세 리포트'), findsOneWidget);
    expect(find.text('   의 상세 리포트'), findsNothing);
  });

  testWidgets('시간을 모르면 시주 자리에 안내 문구가 표시된다', (tester) async {
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false),
        ),
      ),
    );

    expect(find.textContaining('태어난 시간을 몰라'), findsOneWidget);
  });

  testWidgets('시간을 몰라 시주가 없을 때만 재입력 유도 넛지 문구가 보이고, 시간을 알면 보이지 않는다', (tester) async {
    // docs/research/운세/입력_온보딩_설계.md 권장안 반영: "모름" 선택 시 3주만 보여주고
    // 재입력을 유도하는 넛지 문구를 붙인다 — hour가 있을 때는 이 문구가 전혀 없어야 한다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: null, isLunar: false),
        ),
      ),
    );
    expect(find.textContaining('더 정확한 결과를 볼 수 있어요'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );
    expect(find.textContaining('더 정확한 결과를 볼 수 있어요'), findsNothing);
  });

  testWidgets('결과 화면의 "상세 리포트 보기" 버튼을 누르면 상세 리포트 화면으로 이동한다', (tester) async {
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.report) {
            return MaterialPageRoute(
              builder: (_) => ReportScreen(birthInfo: settings.arguments as BirthInfo?),
            );
          }
          return MaterialPageRoute(
            builder: (_) => const ResultScreen(),
            settings: RouteSettings(
              arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
            ),
          );
        },
        initialRoute: '/',
      ),
    );

    await tester.tap(find.text('상세 리포트 보기 (무료)'));
    await tester.pumpAndSettle();

    expect(find.text('상세 리포트'), findsOneWidget);
  });

  testWidgets('"MBTI·관심사로 심층 분석 받기 →" 버튼의 스크린 리더 라벨은 화살표 없이 읽힌다', (tester) async {
    // 2026-07-15 접근성 정리: 화살표(→)는 시각적 장식일 뿐인데 semanticsLabel 없이
    // Text 그대로 두면 스크린 리더가 "MBTI·관심사로 심층 분석 받기 화살표"처럼 장식
    // 기호까지 그대로 읽어준다 — semanticsLabel로 라벨을 깨끗하게 교체했는지 확인한다.
    final semantics = tester.ensureSemantics();
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('MBTI·관심사로 심층 분석 받기 →')).label,
      'MBTI·관심사로 심층 분석 받기',
    );

    semantics.dispose();
  });

  testWidgets('"MBTI·관심사로 심층 분석 받기"를 누르면 심층 분석 입력 화면으로 이동한다', (tester) async {
    // 2026-07-07: 결과 화면에 있던 이 진입점을 상세 리포트 화면으로 옮겼다(사용자 요청).
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.deepDiveInput) {
            return MaterialPageRoute(
              builder: (_) => DeepDiveInputScreen(
                birthInfo: settings.arguments as BirthInfo?,
              ),
            );
          }
          return MaterialPageRoute(
            builder: (_) => ReportScreen(
              birthInfo: settings.arguments as BirthInfo?,
            ),
            settings: RouteSettings(
              arguments: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
            ),
          );
        },
        initialRoute: '/',
      ),
    );

    await tester.tap(find.text('MBTI·관심사로 심층 분석 받기 →'));
    await tester.pumpAndSettle();

    expect(find.byType(DeepDiveInputScreen), findsOneWidget);
  });

  testWidgets('시스템 글자 크기를 크게(2배) 키워도 RenderFlex overflow가 나지 않는다', (tester) async {
    // result_screen.dart(카테고리 그리드)·share_card.dart에서 실제로 겪었던 고정
    // 높이+큰 글자 조합 RenderFlex overflow가 이 화면에도 있는지 지금까지 확인한
    // 적이 없었다 — _OhaengMeaningCard의 40x40 고정 크기 원형 배지처럼 눈여겨볼
    // 만한 고정 크기 요소가 있어 검증해봤으나, Container는 Row/Column과 달리
    // 내용이 넘쳐도 조용히 잘릴 뿐 RenderFlex 예외를 던지지 않아 실제로는
    // 재현되지 않음을 확인(코드 변경 없이 회귀 방지용으로 고정).
    await useReportViewport(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('생성자 birthInfo도 라우트 arguments도 없으면 하드코딩된 기본값(1998-08-15 14시)으로 표시된다',
      (tester) async {
    // build()의 `birthInfo ?? (라우트 arguments) ?? BirthInfo(1998-08-15, 14시)` 3단
    // 폴백 중 마지막 분기(result_screen.dart와 완전히 같은 패턴)는 지금까지 이 화면
    // 테스트에서도 한 번도 타본 적이 없었다 — result_screen_test.dart에 같은 회귀
    // 테스트를 추가하며 발견한 비대칭. 실제 앱 흐름에서는 도달하지 않아야 정상이지만
    // (결과 화면의 "상세 리포트 보기"가 항상 birthInfo를 넘김), 라우트 배선이 실수로
    // 깨지면 크래시 대신 조용히 엉뚱한 기본값을 보여줄 수 있어 값으로 고정해둔다.
    await useReportViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: ReportScreen()));

    expect(find.text('회원님의 상세 리포트'), findsOneWidget);
    expect(find.text('무'), findsOneWidget);
    expect(find.text('경'), findsOneWidget);
    expect(find.text('갑'), findsOneWidget);
  });

  testWidgets('리스트 컨테이너 여백이 목업 공통 토큰(20/14/20/18)과 정확히 일치한다', (tester) async {
    // 2026-07-14 대조 발견: 다른 화면들(result_screen.dart, deep_dive_input_screen.dart 등)은
    // 이미 목업 `.screen-body`(padding:14px 20px 18px) 값으로 맞춰졌는데 이 화면만
    // 옛 값(24/8/24/32)이 남아 있었다 — 수치 자체를 잠그는 테스트가 없어 다음에 실수로
    // 옛 값으로 되돌아가도 못 잡는 공백이 있었다.
    await useReportViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ReportScreen(
          birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.padding, const EdgeInsets.fromLTRB(20, 14, 20, 18));
  });

  group('섹션 제목의 header 시맨틱스(TalkBack/VoiceOver 헤딩 단위 탐색)', () {
    // 2026-07-16 접근성 감사로 페이지 제목·소제목 4곳에 Semantics(header: true)가
    // 추가됐는데, 그 header 플래그 자체를 검증하는 테스트가 없었다 — Semantics 래핑이
    // 걷히거나 header: true가 실수로 지워져도 잡아낼 방법이 없는 공백이었다. 이
    // 화면(report_screen.dart)은 result/deep_dive와 달리 오프스크린 공유 카드가 없어
    // 문구 중복이 없으므로 find.text()를 그대로 써도 안전하다.

    testWidgets('페이지 제목 "회원님의 상세 리포트"가 헤딩(isHeader)으로 노출된다', (tester) async {
      final semantics = tester.ensureSemantics();
      await useReportViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('회원님의 상세 리포트')),
        matchesSemantics(label: '회원님의 상세 리포트', isHeader: true),
      );

      semantics.dispose();
    });

    testWidgets('소제목 "명식 한 글자씩 뜯어보기"가 헤딩(isHeader)으로 노출된다', (tester) async {
      final semantics = tester.ensureSemantics();
      await useReportViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('명식 한 글자씩 뜯어보기')),
        matchesSemantics(label: '명식 한 글자씩 뜯어보기', isHeader: true),
      );

      semantics.dispose();
    });

    testWidgets('소제목 "오행 五行 완전 정복"이 헤딩(isHeader)으로 노출된다', (tester) async {
      final semantics = tester.ensureSemantics();
      await useReportViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('오행 五行 완전 정복')),
        matchesSemantics(label: '오행 五行 완전 정복', isHeader: true),
      );

      semantics.dispose();
    });

    testWidgets('소제목 "오행별 오늘의 풀이 모음"이 헤딩(isHeader)으로 노출된다', (tester) async {
      final semantics = tester.ensureSemantics();
      await useReportViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportScreen(
            birthInfo: BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('오행별 오늘의 풀이 모음')),
        matchesSemantics(label: '오행별 오늘의 풀이 모음', isHeader: true),
      );

      semantics.dispose();
    });
  });
}
