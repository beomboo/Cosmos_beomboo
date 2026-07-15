import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/saju/four_pillars.dart';
import '../../core/saju/ganzhi.dart';
import '../../shared/widgets/pastel_card.dart';
import '../birth_input/birth_info.dart';
import '../result/meta_line.dart';
import '../result/ohaeng_readings.dart';

/// 오행별 의미. 참고: docs/mockups/01-pastel-cute.html "오행 컬러 시스템" 섹션.
/// 한자 값은 core/saju/ganzhi.dart의 공용 상수 `ohaengHanja`를 재사용한다(화면마다
/// 따로 하드코딩하면 한 곳만 고쳤을 때 값이 어긋나는 회귀가 생길 수 있음).
final _ohaengMeaning = {
  '목': (ohaengHanja['목']!, '성장 · 시작 · 추진력', '새싹이 자라나는 이미지'),
  '화': (ohaengHanja['화']!, '열정 · 표현력 · 인기운', '따뜻한 온기의 이미지'),
  '토': (ohaengHanja['토']!, '안정 · 신뢰 · 중재', '땅에 발붙인 이미지'),
  '금': (ohaengHanja['금']!, '원칙 · 결단력 · 완성도', '정제된 금속의 이미지'),
  '수': (ohaengHanja['수']!, '지혜 · 유연함 · 통찰', '흐르는 물의 이미지'),
};

/// 상세 리포트 화면 — 결과 화면보다 한 단계 더 깊은 정보:
/// 8자(또는 시주를 모르면 6자) 개별 오행 breakdown + 오행 5종 전체 의미 + 영역별 풀이 전체.
/// 참고: docs/mockups/01-pastel-cute.html의 "상세 리포트 보기 (무료)" 링크.
///
/// **범위 한계**: docs/research의 "무료/유료 경계선" 설계를 실제 결제/구독 로직으로
/// 구현한 것은 아니다. 지금은 전체를 무료로 보여주는 MVP 버전이며, 화면 하단에 그 사실을
/// 명시한다.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, this.birthInfo});

  final BirthInfo? birthInfo;

  @override
  Widget build(BuildContext context) {
    final info = birthInfo ??
        (ModalRoute.of(context)?.settings.arguments as BirthInfo?) ??
        BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

    final pillars = calculateFourPillars(birthDate: info.date, birthHour: info.hour);
    final displayName = displayNameFor(info);

    return Scaffold(
      appBar: AppBar(title: const Text('상세 리포트')),
      body: SafeArea(
        child: ListView(
          // 목업(`.screen-body{padding:14px 20px 18px}`)과 다른 화면들(result_screen.dart
          // 등)은 이미 맞췄는데 이 화면만 옛 값(24/8/24/32)이 남아 있었다(2026-07-14 대조 발견).
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          children: [
            // 결과 화면에서 넘어왔을 때, 지금 보고 있는 리포트가 누구 걸 얼마나 자세히
            // 보는 건지 문맥이 끊기지 않도록 결과 화면과 같은 헤더를 재사용한다.
            // TalkBack/VoiceOver의 헤딩 단위 탐색(제목만 골라 건너뛰기)을 지원하려면
            // 섹션 제목에 header 플래그가 필요하다 — 지금까지는 앱 전체에 이 플래그가
            // 한 곳도 없었다(2026-07-16 접근성 감사 발견). 자식 Text가 만드는 자동
            // 라벨을 그대로 병합해 쓰므로 별도 label은 지정하지 않는다.
            Semantics(
              header: true,
              child: Text(
                '$displayName의 상세 리포트',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              buildMetaLine(info),
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 20),
            // 헤딩 단위 탐색 지원(2026-07-16 접근성 감사 발견, 위 페이지 제목과 같은 이유).
            Semantics(
              header: true,
              child: const Text(
                '명식 한 글자씩 뜯어보기',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '사주는 총 4개의 기둥, 각 기둥은 천간(위)과 지지(아래) 두 글자로 이루어져요.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _PillarBreakdownTable(pillars: pillars),
            const SizedBox(height: 10),
            const Text(
              '※ 계산 정확도 안내: 년주는 입춘을 2월 4일로 고정해 근사하고, 월주는 정확한 절기 대신 '
              '달력상의 월을 기준으로 계산해요. 일주는 날짜 차이만으로 계산돼 절기와 무관하게 정확하지만, '
              '절기 경계에 걸친 생일은 정통 만세력과 며칠 차이가 날 수 있어요. 또한 진태양시(출생지 경도·균시차 '
              '보정)는 반영하지 않고 입력한 시각을 그대로 사용하며, 자시(밤 11시~새벽 1시) 출생은 일주를 '
              '정하는 방식이 유파마다 달라 저희 결과와 차이가 날 수 있어요. 음력으로 입력한 경우에도 '
              '지금은 양력으로 변환하지 않고 입력한 날짜를 그대로 계산에 사용해요. 그리고 한국이 '
              '서머타임(일광절약시간제)을 시행했던 1948~1960년·1987~1988년에 태어났다면, 그 보정은 '
              '아직 반영하지 않아 실제 시각과 최대 1시간까지 차이가 날 수 있어요.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 11, height: 1.5),
            ),
            const SizedBox(height: 32),
            // 헤딩 단위 탐색 지원(2026-07-16 접근성 감사 발견, 위 페이지 제목과 같은 이유).
            Semantics(
              header: true,
              child: const Text(
                '오행 五行 완전 정복',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            for (final ohaeng in const ['목', '화', '토', '금', '수'])
              _OhaengMeaningCard(ohaeng: ohaeng),
            const SizedBox(height: 32),
            // 헤딩 단위 탐색 지원(2026-07-16 접근성 감사 발견, 위 페이지 제목과 같은 이유).
            Semantics(
              header: true,
              child: const Text(
                '오행별 오늘의 풀이 모음',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '결과 화면에서는 가장 우세한 오행 풀이만 보여드렸어요. 여기서는 5가지 오행의 풀이를 모두 볼 수 있어요.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final ohaeng in const ['목', '화', '토', '금', '수'])
              _AllReadingsSection(ohaeng: ohaeng),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '지금은 모든 내용을 무료로 볼 수 있어요. 더 깊은 개인 맞춤 해석은 추후 추가될 예정이에요.',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            // 결과 화면에 있던 "MBTI·관심사로 심층 분석 받기" 진입점을 여기로 옮겨왔다
            // (2026-07-07, 사용자 요청) — 상세 리포트까지 다 본 다음 더 보고 싶은
            // 사람만 자연스럽게 이어가도록 함.
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.deepDiveInput,
                  arguments: info,
                ),
                child: const Text(
                  'MBTI·관심사로 심층 분석 받기 →',
                  semanticsLabel: 'MBTI·관심사로 심층 분석 받기',
                  style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarBreakdownTable extends StatelessWidget {
  const _PillarBreakdownTable({required this.pillars});

  final FourPillars pillars;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('년주', pillars.year),
      ('월주', pillars.month),
      ('일주', pillars.day),
      ('시주', pillars.hour),
    ];

    return PastelCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 24, color: AppColors.border),
            _pillarRow(rows[i].$1, rows[i].$2),
          ],
        ],
      ),
    );
  }

  Widget _pillarRow(String label, GanzhiPillar? pillar) {
    if (pillar == null) {
      // 입력 온보딩 설계(docs/research/운세/입력_온보딩_설계.md)의 권장안 — 시주를
      // 계산하지 않았다는 안내 뒤에 재입력을 유도하는 넛지 문구를 덧붙인다. 이 화면엔
      // 재입력 경로가 따로 없어(결과 화면의 "다시 입력하기"만 존재) 문구만 추가한다.
      return Semantics(
        label: '$label. 태어난 시간을 몰라 계산하지 않았어요. '
            '태어난 시간을 알면 더 정확한 결과를 볼 수 있어요.',
        excludeSemantics: true,
        // 이 표는 년/월/일/시 4개 행이 한 Column 안에 나란히 있어, container 없이는
        // 이웃 행의 시맨틱스와 하나로 합쳐진다 — 행마다 독립된 노드가 되도록 한다.
        container: true,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              // 고정폭 44px 라벨("년주"/"월주"/"일주"/"시주")도 시스템 폰트 확대 시
              // 조용히 잘릴 수 있어 FittedBox로 감싼다(2026-07-15 접근성 감사 발견) —
              // 기본 배율에서는 원래 크기 그대로다.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
              ),
            ),
            const Expanded(
              child: Text(
                '태어난 시간을 몰라 시주는 계산하지 않았어요. 태어난 시간을 알면 더 정확한 결과를 볼 수 있어요',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // 시각적으로는 "년주" 옆에 천간/지지 두 칸(글자+오행 라벨)이 나란히 있지만,
    // 스크린 리더가 그대로 4개 노드를 따로 읽으면 어느 기둥의 어느 글자인지
    // 맥락 없이 흩어져 들린다 — 한 문장으로 병합해 순서·소속을 분명히 한다.
    final semanticLabel = '$label. 천간 ${pillar.stem}, 오행 ${stemOhaeng(pillar.stemIndex)}. '
        '지지 ${pillar.branch}, 오행 ${branchOhaeng(pillar.branchIndex)}.';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      container: true,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            // 위 null-분기(시주 없음 안내)와 같은 이유 — FittedBox로 감싸 폰트 확대 시
            // 조용히 잘리지 않게 한다.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
          ),
          Expanded(child: _charCell('천간', pillar.stem, stemOhaeng(pillar.stemIndex))),
          const SizedBox(width: 8),
          Expanded(child: _charCell('지지', pillar.branch, branchOhaeng(pillar.branchIndex))),
        ],
      ),
    );
  }

  Widget _charCell(String kind, String hanja, String ohaeng) {
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ohaengSoftColors[ohaeng],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(hanja, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
          const SizedBox(height: 2),
          Text('$kind · $ohaeng', style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _OhaengMeaningCard extends StatelessWidget {
  const _OhaengMeaningCard({required this.ohaeng});

  final String ohaeng;

  @override
  Widget build(BuildContext context) {
    final meaning = _ohaengMeaning[ohaeng]!;
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // 같은 파일의 _PillarBreakdownTable._pillarRow(위 참고)와 같은 이유(2026-07-07
      // 발견) — 배지 한자·"오행 · 의미" 제목·설명이 각각 별도 Text/Container라
      // 지금까지 스크린 리더가 세 번 나눠 읽었다. 카드 5개가 한 Column 안에 나란히
      // 있어 container:true로 이웃 카드와 안 섞이게 한다.
      child: Semantics(
        label: '$ohaeng · ${meaning.$2}. ${meaning.$3}',
        excludeSemantics: true,
        container: true,
        child: PastelCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ohaengSoftColors[ohaeng],
                  shape: BoxShape.circle,
                ),
                // 40x40 원형 배지 안 한자 1글자도 시스템 폰트 확대 시 원 밖으로 잘릴 수
                // 있어 FittedBox로 감싼다(2026-07-15 접근성 감사, 선택 보강).
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(meaning.$1, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$ohaeng · ${meaning.$2}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(meaning.$3, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllReadingsSection extends StatelessWidget {
  const _AllReadingsSection({required this.ohaeng});

  final String ohaeng;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    final readings = categoryReadingsFor(ohaeng);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$ohaeng(${_ohaengMeaning[ohaeng]!.$1}) 기운이 강할 때',
            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 13),
          ),
          const SizedBox(height: 6),
          for (final reading in readings)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              // reading.$1은 순수 장식용 이모지(💘/💰/🌱/🎭)라 스크린 리더가 그대로
              // 읽으면 유니코드 이름으로 낭독돼 혼란을 준다 — 같은 파일의
              // _OhaengMeaningCard(위 참고)와 같은 방식으로 라벨에서는 이모지를 빼고
              // 시각적 표시는 이모지를 그대로 둔다. 항목 여러 개가 한 Column 안에
              // 나란히 있어 container:true로 이웃 항목과 안 섞이게 한다.
              child: Semantics(
                label: '${reading.$2}: ${reading.$3}',
                excludeSemantics: true,
                container: true,
                child: Text(
                  '${reading.$1} ${reading.$2}: ${reading.$3}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
