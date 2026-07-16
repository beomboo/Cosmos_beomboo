import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/saju/four_pillars.dart';
import '../../shared/share/share_capture.dart';
import '../../shared/widgets/gradient_share_button.dart';
import '../../shared/widgets/offscreen_share_capture.dart';
import '../../shared/widgets/pastel_card.dart';
import '../birth_input/birth_info.dart';
import '../result/meta_line.dart';
import 'deep_dive_info.dart';
import 'deep_dive_readings.dart';
import 'deep_dive_share_card.dart';
import 'deep_dive_share_text.dart';

/// MBTI·관심사를 반영한 심층 분석 결과 화면 (1단계: 조합형 규칙 기반).
/// 오행 × MBTI(16) × 관심사를 전부 곱해 손으로 문구를 쓰는 대신, 우세 오행 기준
/// 카테고리 풀이(관심사로 고른 것만)에 MBTI 성향 코멘트 한 줄을 더하는 방식으로 구성한다.
class DeepDiveResultScreen extends StatefulWidget {
  const DeepDiveResultScreen({super.key, required this.birthInfo, required this.deepDiveInfo});

  final BirthInfo birthInfo;
  final DeepDiveInfo deepDiveInfo;

  @override
  State<DeepDiveResultScreen> createState() => _DeepDiveResultScreenState();
}

class _DeepDiveResultScreenState extends State<DeepDiveResultScreen> {
  /// 화면에는 보이지 않는 공유용 카드(DeepDiveShareCard)를 캡처하기 위한 키.
  /// result_screen.dart의 ResultScreen과 같은 패턴.
  final _shareCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final birthInfo = widget.birthInfo;
    final deepDiveInfo = widget.deepDiveInfo;
    final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
    final dominant = pillars.dominantOhaeng;
    final sub = pillars.subDominantOhaeng;
    final subCount = pillars.ohaengCount[sub] ?? 0;
    final displayName = displayNameFor(birthInfo);
    final metaLine = buildMetaLine(birthInfo);
    final mbtiComment = mbtiCommentFor(deepDiveInfo.mbti?.code);
    // Interest.values 선언 순서(연애·재물·직장·건강)를 고정해 화면 카드 순서와
    // 공유 카드/텍스트 순서가 항상 일치하도록 한다 — deepDiveInfo.interests는
    // Set이라 삽입 순서를 보장하지 않는다.
    final selectedItems = [
      for (final interest in Interest.values)
        if (deepDiveInfo.interests.contains(interest))
          (interest.icon, interest.categoryTitle, readingFor(interest, dominant, sub, subCount: subCount)),
    ];
    // MBTI 코멘트 또는 관심사 풀이 중 하나라도 있어야 공유할 내용이 있다고 본다 —
    // 둘 다 없으면(관심사 미선택 + MBTI 미입력) 공유 버튼 자체를 숨긴다.
    final canShare = mbtiComment != null || selectedItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('심층 분석')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              key: const Key('deepDiveResultScrollView'),
              // 하단에 별도 CTA가 없어 리스트 끝 여백을 다른 화면(18)보다 조금 더 둔다.
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                // TalkBack/VoiceOver의 헤딩 단위 탐색(제목만 골라 건너뛰기)을 지원하려면
                // 섹션 제목에 header 플래그가 필요하다 — 지금까지는 앱 전체에 이 플래그가
                // 한 곳도 없었다(2026-07-16 접근성 감사 발견). 자식 Text가 만드는 자동
                // 라벨을 그대로 병합해 쓰므로 별도 label은 지정하지 않는다.
                Semantics(
                  header: true,
                  child: Text(
                    '$displayName의 심층 분석 ✨',
                    semanticsLabel: '$displayName의 심층 분석',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metaLine,
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                if (mbtiComment != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: PastelCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      color: AppColors.accentSoft,
                      showBorder: false,
                      child: Text(
                        '${deepDiveInfo.mbti!.code} — $mbtiComment',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.4),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (deepDiveInfo.interests.isEmpty)
                  const Text(
                    '관심사를 고르지 않아 보여드릴 심층 풀이가 없어요. 뒤로 가서 관심 있는 영역을 골라보세요.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  )
                else
                  for (final interest in Interest.values)
                    if (deepDiveInfo.interests.contains(interest))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        // result_screen.dart의 _CategoryCard와 같은 이유(2026-07-07 발견) —
                        // 지금까지는 아이콘·제목·설명이 각각 별도 Text라 스크린 리더가 세 번
                        // 나눠 읽었다. "제목. 설명"으로 병합해 하나의 노드로 읽히게 한다.
                        child: Semantics(
                          label:
                              '${interest.categoryTitle}. ${readingFor(interest, dominant, sub, subCount: subCount)}',
                          excludeSemantics: true,
                          container: true,
                          child: PastelCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(interest.icon, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        interest.categoryTitle,
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        readingFor(interest, dominant, sub, subCount: subCount),
                                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                if (canShare) ...[
                  const SizedBox(height: 4),
                  // result_screen.dart의 공유 버튼과 완전히 동일한 구조라 공용 위젯
                  // (GradientShareButton)으로 통합했다(2026-07-15 리팩터).
                  GradientShareButton(
                    onPressed: () => _handleShare(
                      birthInfo: birthInfo,
                      displayName: displayName,
                      mbtiCode: deepDiveInfo.mbti?.code,
                      mbtiComment: mbtiComment,
                      items: selectedItems,
                    ),
                  ),
                ],
              ],
            ),
            if (canShare)
              // 오프스크린 캡처 래퍼(Positioned+ExcludeSemantics+RepaintBoundary)는
              // `shared/widgets/offscreen_share_capture.dart`의 공용 위젯으로
              // 옮겨졌다(result_screen.dart와 동일 패턴).
              OffscreenShareCapture(
                repaintBoundaryKey: _shareCardKey,
                child: DeepDiveShareCard(
                  displayName: displayName,
                  metaLine: metaLine,
                  mbtiCode: deepDiveInfo.mbti?.code,
                  mbtiComment: mbtiComment,
                  items: selectedItems,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 공유용 카드를 이미지로 캡처해 텍스트와 함께 공유한다. 캡처/공유/실패 안내 로직
  /// 자체는 `shared/share/share_capture.dart`의 공용 함수(`shareCapturedCard`, result_screen.dart와
  /// 공유)로 옮겨졌고, 이 화면은 텍스트 빌드(`buildDeepDiveShareText`)와 공유 메타만 맡는다.
  Future<void> _handleShare({
    required BirthInfo birthInfo,
    required String displayName,
    required String? mbtiCode,
    required String? mbtiComment,
    required List<(String, String, String)> items,
  }) async {
    final text = buildDeepDiveShareText(
      birthInfo: birthInfo,
      displayName: displayName,
      mbti: mbtiCode != null && mbtiComment != null ? (mbtiCode, mbtiComment) : null,
      items: items,
    );

    await shareCapturedCard(
      context: context,
      repaintBoundaryKey: _shareCardKey,
      text: text,
      subject: '나의 심층 분석',
      fileName: 'deep_dive_result.png',
    );
  }
}
