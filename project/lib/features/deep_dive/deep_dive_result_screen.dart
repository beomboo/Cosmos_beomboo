import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/saju/four_pillars.dart';
import '../../shared/widgets/pastel_card.dart';
import '../birth_input/birth_info.dart';
import '../result/meta_line.dart';
import 'deep_dive_info.dart';
import 'deep_dive_readings.dart';

/// MBTI·관심사를 반영한 심층 분석 결과 화면 (1단계: 조합형 규칙 기반).
/// 오행 × MBTI(16) × 관심사를 전부 곱해 손으로 문구를 쓰는 대신, 우세 오행 기준
/// 카테고리 풀이(관심사로 고른 것만)에 MBTI 성향 코멘트 한 줄을 더하는 방식으로 구성한다.
class DeepDiveResultScreen extends StatelessWidget {
  const DeepDiveResultScreen({super.key, required this.birthInfo, required this.deepDiveInfo});

  final BirthInfo birthInfo;
  final DeepDiveInfo deepDiveInfo;

  @override
  Widget build(BuildContext context) {
    final pillars = calculateFourPillars(birthDate: birthInfo.date, birthHour: birthInfo.hour);
    final dominant = pillars.dominantOhaeng;
    final sub = pillars.subDominantOhaeng;
    final subCount = pillars.ohaengCount[sub] ?? 0;
    final displayName =
        birthInfo.name?.trim().isNotEmpty == true ? birthInfo.name!.trim() : '회원님';
    final mbtiComment = mbtiCommentFor(deepDiveInfo.mbti?.code);

    return Scaffold(
      appBar: AppBar(title: const Text('심층 분석')),
      body: SafeArea(
        child: ListView(
          key: const Key('deepDiveResultScrollView'),
          // 하단에 별도 CTA가 없어 리스트 끝 여백을 다른 화면(18)보다 조금 더 둔다.
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            Text(
              '$displayName의 심층 분석 ✨',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              buildMetaLine(birthInfo),
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            if (mbtiComment != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${deepDiveInfo.mbti!.code} — $mbtiComment',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.4),
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
                      label: '${interest.categoryTitle}. ${readingFor(interest, dominant, sub, subCount: subCount)}',
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
          ],
        ),
      ),
    );
  }
}
