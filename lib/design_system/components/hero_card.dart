import 'package:flutter/material.dart';

class HeroCard extends StatelessWidget {
  final List<Color> gradientColors;
  final String kicker;
  final String title;
  final String description;
  final String ctaText;
  final VoidCallback? onCtaTap;
  final String artEmoji;

  const HeroCard({
    super.key,
    required this.gradientColors,
    required this.kicker,
    required this.title,
    required this.description,
    required this.ctaText,
    this.onCtaTap,
    required this.artEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 184),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 29,
                    height: 1.03,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.48,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(height: 15),
                if (ctaText.isNotEmpty)
                  GestureDetector(
                    onTap: onCtaTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        ctaText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4D2CA8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            bottom: 13,
            child: Text(artEmoji, style: const TextStyle(fontSize: 77)),
          ),
        ],
      ),
    );
  }
}
