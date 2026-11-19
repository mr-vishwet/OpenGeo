import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'select_mode_screen.dart';

/// Navy splash from the reference: brand mark, wordmark, tagline, Get Started.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SelectModeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navyTop, AppColors.navyMid, AppColors.navyBottom],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -90,
              left: -70,
              child: _Glow(size: 320, color: Color(0x552E9BFF)),
            ),
            const Positioned(
              bottom: -160,
              right: -120,
              child: _Glow(size: 420, color: Color(0x332E9BFF)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: S.xl),
                        child: Column(
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.14),
                            Container(
                              padding: const EdgeInsets.all(S.lg),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brandGlow.withValues(alpha: 0.45),
                                    blurRadius: 60,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: const BrandMark(size: 108),
                            ),
                            const SizedBox(height: S.xl),
                            const Text(
                              'OpenGeo',
                              style: TextStyle(
                                fontSize: 40,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: S.md),
                            const Text(
                              'Explore. Navigate. Build Smarter.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE6EEF9),
                              ),
                            ),
                            const SizedBox(height: S.lg),
                            const Text(
                              'A next-generation open source\ngeospatial platform',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF9FB6D1),
                              ),
                            ),
                            const SizedBox(height: S.xxl),
                            SizedBox(
                              width: 230,
                              child: FilledButton(
                                onPressed: () => _start(context),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(R.pill),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Get Started'),
                                    SizedBox(width: S.sm),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
