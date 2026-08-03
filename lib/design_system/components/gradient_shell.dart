import 'package:flutter/material.dart';

class GradientShell extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget child;
  final double paddingBottom;

  const GradientShell({
    super.key,
    required this.gradientColors,
    required this.child,
    this.paddingBottom = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -75,
            top: -70,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}
