import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Decorative gradient background used behind every top-level screen.
class PinkBackground extends StatelessWidget {
  const PinkBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundGradientStart, AppColors.surfaceSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Stack(
        children: [
          Positioned(
            top: -40,
            left: -20,
            child: _DecorBlob(size: 140, color: AppColors.blobLight),
          ),
          Positioned(
            top: 180,
            right: -60,
            child: _DecorBlob(size: 200, color: AppColors.blobSoft),
          ),
          Positioned(
            bottom: -40,
            left: 30,
            child: _DecorBlob(size: 160, color: AppColors.blobDeep),
          ),
        ],
      ),
    );
  }
}

class _DecorBlob extends StatelessWidget {
  const _DecorBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.6),
      ),
    );
  }
}

/// Scaffold with the brand background and a safe-area body.
class BackgroundScaffold extends StatelessWidget {
  const BackgroundScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
  });

  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const PinkBackground(),
          SafeArea(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
