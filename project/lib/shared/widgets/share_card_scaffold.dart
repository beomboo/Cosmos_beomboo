import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 공유용 9:16 카드 공통 스캐폴드 — `ShareCard`(사주 결과)/`DeepDiveShareCard`(심층
/// 분석)가 완전히 동일하게 복제하던 고정 크기(360x640)·텍스트 배율 고정(1.0)·
/// 이름+메타라인 헤더·해시태그 푸터를 여기서 한 번만 구현하고, 화면마다 달라지는
/// 본문(4기둥+콜아웃+오행 밸런스 바 vs MBTI+관심사 카드)만 [body] 슬롯으로 받는다.
///
/// 화면에는 보이지 않고(오프스크린 배치는 호출부 책임) `RepaintBoundary.toImage()`로만
/// 캡처되는 용도라, 공유하는 사람의 기기 글자 크기 설정을 그대로 물려받으면 안 된다 —
/// 실제로 시스템 글자 크기를 키운 상태에서 캡처하면 고정 높이(640)를 넘겨(RenderFlex
/// overflow) 잘린 이미지가 공유되는 것을 확인했다. 받는 사람은 어차피 보내는 사람의
/// 접근성 설정과 무관하게 이미지를 보므로, 이 카드 안에서는 항상 배율을 1.0으로
/// 고정해 디자인대로 렌더링한다.
class ShareCardScaffold extends StatelessWidget {
  const ShareCardScaffold({
    super.key,
    required this.title,
    required this.metaLine,
    required this.hashtags,
    required this.body,
  });

  /// 카드 상단 큰 제목(예: "$displayName의 사주팔자 ✨"). 이름은 최대 20자(birth_input의
  /// 입력 제한)까지 가능해서 줄바꿈 없이 두면 고정 높이(640)를 넘길 수 있어, 스캐폴드가
  /// 항상 두 줄까지만 허용하고 그래도 넘치면 말줄임표로 자른다.
  final String title;

  /// 제목 아래 메타 정보 한 줄(예: "1998.08.15 · 오후 2시生 · 양력"). 출생지가 최대
  /// 30자까지 들어갈 수 있어 한 줄로 제한하지 않으면 제목과 마찬가지로 카드 높이를
  /// 넘길 수 있다.
  final String metaLine;

  /// 카드 하단 해시태그 문구(예: "#사주랑  #사주팔자  #오행").
  final String hashtags;

  /// 화면마다 달라지는 본문. 남는 세로 공간은 본문과 해시태그 사이의 `Spacer`가 채운다.
  final Widget body;

  static const width = 360.0;
  static const height = 640.0;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.0,
      child: Container(
        width: width,
        height: height,
        color: AppColors.bg,
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              metaLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            body,
            const Spacer(),
            Center(
              child: Text(
                hashtags,
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
