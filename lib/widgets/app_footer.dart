import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppFooter extends StatelessWidget {
  final bool compact;
  const AppFooter({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code_rounded, size: 13, color: AppColors.primary),
            const SizedBox(width: 5),
            const Text(
              'Developed by ',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF3B82F6)],
              ).createShader(bounds),
              child: const Text(
                'Abhisht Singh',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Developer Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.12),
                  const Color(0xFFEC4899).withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 15,
                  color: Color(0xFF818CF8),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lead Developer & Architect: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFFF472B6), Color(0xFF60A5FA)],
                  ).createShader(bounds),
                  child: const Text(
                    'Abhisht Singh',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.favorite_rounded,
                  size: 13,
                  color: Color(0xFFF43F5E),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'KRIVA Community Platform · Crafted for Excellence',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '© 2026 KRIVA · Designed & Built by Abhisht Singh',
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
