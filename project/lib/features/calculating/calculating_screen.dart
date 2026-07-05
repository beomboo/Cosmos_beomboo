import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../birth_input/birth_info.dart';

/// 명식 계산 중 화면 — 오행/명식 계산 로딩 애니메이션.
/// 참고: docs/mockups/01-pastel-cute.html STEP 3
class CalculatingScreen extends StatefulWidget {
  const CalculatingScreen({super.key});

  @override
  State<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;
  Timer? _messageTimer;
  int _messageIndex = 0;
  bool _orbitAnimationDecided = false;

  static const _orbitEmojis = ['🌿', '⭐', '💫'];

  // 목업(STEP 3)의 로딩 문구 3종 순환. 1.8초마다 다음 문구로 바뀐다.
  static const _loadingMessages = [
    '사주팔자를 계산하고 있어요...',
    '오행 기운을 분석하는 중...',
    '당신만의 이야기를 준비하고 있어요...',
  ];

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _messageTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      // 목업과 동일하게 "동작 줄이기(reduce motion)"를 켠 사용자에게는 문구를 고정한다.
      if (MediaQuery.of(context).disableAnimations) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _loadingMessages.length);
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final birthInfo = ModalRoute.of(context)?.settings.arguments as BirthInfo?;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.result,
        arguments: birthInfo,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // initState()에서는 MediaQuery.of(context)를 쓸 수 없어(아직 빌드 중이라 예외 발생)
    // 여기서 딱 한 번만 판단한다. 로딩 문구 순환과 마찬가지로 "동작 줄이기(reduce motion)"를
    // 켠 사용자에게는 궤도 회전도 멈춰둔다 — 오히려 이 회전이 문구보다 훨씬 크고 지속적인
    // 움직임이라 놓치면 더 아쉬운 부분이었다.
    if (_orbitAnimationDecided) return;
    _orbitAnimationDecided = true;
    if (!MediaQuery.of(context).disableAnimations) {
      _orbitController.repeat();
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.accentSoft,
                            shape: BoxShape.circle,
                          ),
                        ),
                        for (var i = 0; i < _orbitEmojis.length; i++)
                          _orbitingEmoji(
                            emoji: _orbitEmojis[i],
                            angle: _orbitController.value * 2 * math.pi +
                                (i * 2 * math.pi / _orbitEmojis.length),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _loadingMessages[_messageIndex],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '평균 3초 소요돼요',
                style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orbitingEmoji({required String emoji, required double angle}) {
    const radius = 90.0;
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}
