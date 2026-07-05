import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/saju/four_pillars.dart';
import '../../core/saju/ganzhi.dart';
import '../../core/storage/birth_info_store.dart';
import '../../shared/widgets/pastel_card.dart';
import '../birth_input/birth_info.dart';
import '../birth_input/birth_input_screen.dart';
import 'meta_line.dart';
import 'ohaeng_readings.dart';
import 'share_card.dart';
import 'share_text.dart';

/// 오행 한자 + 설명 (docs/mockups/01-pastel-cute.html "오행 컬러 시스템" 참고)
const _ohaengCallout = {
  '목': ('木', '새로운 걸 벌이는 힘이 넘치는 타입이에요 🌿'),
  '화': ('火', '표현력과 인기운이 좋은 타입이에요 🔥'),
  '토': ('土', '안정감 있고 신뢰를 주는 타입이에요 🪵'),
  '금': ('金', '원칙적이고 결단력 있는 타입이에요 ✨'),
  '수': ('水', '유연하고 통찰력이 뛰어난 타입이에요 💧'),
};

/// 사주 결과 화면 — 4기둥 명식 + 오행 밸런스 바 차트 + 영역별 풀이 + 공유.
/// 참고: docs/mockups/01-pastel-cute.html STEP 4
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, this.birthInfo});

  /// 앱 시작 시 저장된 값으로 바로 이 화면을 여는 경우(홈 화면으로 사용) 직접 전달.
  /// 생략하면 라우트 arguments(calculating → result 네비게이션)를 사용한다.
  final BirthInfo? birthInfo;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  /// 화면에는 보이지 않는 공유용 카드(ShareCard)를 캡처하기 위한 키.
  final _shareCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final birthInfo = widget.birthInfo ??
        (ModalRoute.of(context)?.settings.arguments as BirthInfo?) ??
        BirthInfo(date: DateTime(1998, 8, 15), hour: 14, isLunar: false);

    final pillars = calculateFourPillars(
      birthDate: birthInfo.date,
      birthHour: birthInfo.hour,
    );
    final ohaengCount = pillars.ohaengCount;
    final total = ohaengCount.values.fold<int>(0, (a, b) => a + b);
    final dominant = pillars.dominantOhaeng;
    final callout = _ohaengCallout[dominant]!;
    final displayName =
        birthInfo.name?.trim().isNotEmpty == true ? birthInfo.name!.trim() : '회원님';
    final metaLine = buildMetaLine(birthInfo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사주팔자 결과'),
        actions: [
          IconButton(
            tooltip: '다시 입력하기',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _resetAndReenter(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              key: const Key('resultScrollView'),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Text(
                  '$displayName의 사주팔자 ✨',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metaLine,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  '※ 절기 계산 없이 근사치로 계산한 간이 결과예요',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 11),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${callout.$1}($dominant) 기운이 강한 타입이에요\n${callout.$2}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _PillarCard(label: '년주', pillar: pillars.year),
                    const SizedBox(width: 8),
                    _PillarCard(label: '월주', pillar: pillars.month),
                    const SizedBox(width: 8),
                    _PillarCard(label: '일주', pillar: pillars.day),
                    const SizedBox(width: 8),
                    _PillarCard(label: '시주', pillar: pillars.hour),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  '오행 밸런스',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15),
                ),
                const SizedBox(height: 12),
                for (final ohaeng in const ['목', '화', '토', '금', '수'])
                  _OhaengBarRow(
                    ohaeng: ohaeng,
                    percent: total == 0 ? 0 : (ohaengCount[ohaeng]! / total * 100),
                  ),
                const SizedBox(height: 28),
                const Text(
                  '오늘 궁금한 것부터',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    for (final category in categoryReadingsFor(dominant))
                      _CategoryCard(category: category),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleShare(
                      birthInfo: birthInfo,
                      pillars: pillars,
                      dominant: dominant,
                      callout: callout,
                      ohaengCount: ohaengCount,
                      total: total,
                      displayName: displayName,
                      metaLine: metaLine,
                    ),
                    child: const Text('📸 공유하기'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.report,
                      arguments: birthInfo,
                    ),
                    child: const Text(
                      '상세 리포트 보기 (무료)',
                      style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.deepDiveInput,
                      arguments: birthInfo,
                    ),
                    child: const Text(
                      'MBTI·관심사로 심층 분석 받기 →',
                      style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            // 화면 밖(왼쪽 멀리)에 배치해 사용자 눈에는 보이지 않지만,
            // RepaintBoundary는 여전히 레이아웃·페인트되므로 캡처는 가능하다.
            Positioned(
              left: -4000,
              top: 0,
              child: RepaintBoundary(
                key: _shareCardKey,
                child: ShareCard(
                  displayName: displayName,
                  metaLine: metaLine,
                  pillars: pillars,
                  dominant: dominant,
                  calloutHanja: callout.$1,
                  calloutText: callout.$2,
                  ohaengCount: ohaengCount,
                  total: total,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 저장된 생년월일시를 지우고 입력 화면으로 돌아간다 (뒤로 가기로 결과 화면에 못 돌아오게
  /// 스택을 모두 비운다). 실수로 눌러 저장된 정보를 잃지 않도록 먼저 확인을 받는다.
  Future<void> _resetAndReenter(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('다시 입력할까요?'),
        content: const Text('저장된 생년월일시 정보가 삭제되고, 처음부터 다시 입력하게 돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('다시 입력하기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 삭제가 실패해도(플랫폼 채널 오류 등) 사용자가 입력 화면으로 못 돌아가면 안 되므로
    // 화면 전환은 항상 진행한다.
    try {
      await BirthInfoStore.clear();
    } catch (_) {
      // 무시
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BirthInputScreen()),
      (route) => false,
    );
  }

  /// 공유용 카드를 이미지로 캡처해 텍스트와 함께 공유한다.
  /// 캡처가 실패하면(레이아웃 전이거나 플랫폼 문제 등) 텍스트만이라도 공유한다.
  Future<void> _handleShare({
    required BirthInfo birthInfo,
    required FourPillars pillars,
    required String dominant,
    required (String, String) callout,
    required Map<String, int> ohaengCount,
    required int total,
    required String displayName,
    required String metaLine,
  }) async {
    final text = buildShareText(
      birthInfo: birthInfo,
      pillars: pillars,
      dominant: dominant,
      callout: callout,
      ohaengCount: ohaengCount,
      total: total,
      displayName: displayName,
    );

    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin =
        box != null ? (box.localToGlobal(Offset.zero) & box.size) : null;

    Uint8List? imageBytes;
    try {
      final boundary =
          _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null && !boundary.debugNeedsPaint) {
        final image = await boundary.toImage(pixelRatio: 3);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        imageBytes = byteData?.buffer.asUint8List();
      }
    } catch (_) {
      // 캡처 실패 시 아래에서 텍스트만 공유한다.
      imageBytes = null;
    }

    // 공유 시트 자체가 실패하는 경우(플랫폼 채널 오류 등)에도 버튼이 아무 반응 없이
    // 조용히 실패하는 것처럼 보이지 않도록, 실패를 사용자에게 스낵바로 알려준다.
    try {
      if (imageBytes != null) {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: '나의 사주팔자',
            files: [XFile.fromData(imageBytes, mimeType: 'image/png', name: 'saju_result.png')],
            sharePositionOrigin: sharePositionOrigin,
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: '나의 사주팔자',
            sharePositionOrigin: sharePositionOrigin,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유하는 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({required this.label, required this.pillar});

  final String label;

  /// null이면 "시간 모름"으로 표시 (시주).
  final GanzhiPillar? pillar;

  @override
  Widget build(BuildContext context) {
    final color = pillar == null
        ? AppColors.inkSoft
        : (AppColors.ohaengTextColors[stemOhaeng(pillar!.stemIndex)] ?? AppColors.ink);

    return Expanded(
      // 시각적으로는 값(예: "갑자")이 위, 기둥 이름("년주")이 아래 순서로 보이지만,
      // 스크린 리더가 그 순서 그대로 두 노드를 따로 읽으면 "갑자, 년주"처럼 값을
      // 먼저 들려줘 맥락 없이 혼란스럽다 — "년주 갑자"로 순서를 바로잡아 병합한다.
      child: Semantics(
        label: '$label ${pillar?.label ?? "모름"}',
        excludeSemantics: true,
        // 4기둥 카드가 한 Row 안에 나란히 있어, container 없이는 이웃 카드의
        // 시맨틱스와 하나로 합쳐져 "년주 무인\n월주 경신\n..."처럼 뭉개진다 —
        // 카드마다 독립된 시맨틱스 노드가 되도록 경계를 명시한다.
        container: true,
        child: PastelCard(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                pillar?.label ?? '모름',
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OhaengBarRow extends StatelessWidget {
  const _OhaengBarRow({required this.ohaeng, required this.percent});

  final String ohaeng;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ohaengTextColors[ohaeng] ?? AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(ohaeng, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${percent.round()}%',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final (String, String, String) category;

  @override
  Widget build(BuildContext context) {
    final (icon, title, desc) = category;
    return PastelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
