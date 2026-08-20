import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/animated_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Accelerate Learning',
      description:
          'Follow curated technical roadmaps tailored for developers. Track your tasks, milestones, and master key concepts systematically.',
      icon: Icons.school_rounded,
      lottieUrl:
          'https://lottie.host/8c131557-0130-4e31-8977-70e0f80bcde1/Pj3h3w08qA.json',
      glowColor: AppColors.primary,
    ),
    OnboardingData(
      title: 'Peer Collaboration',
      description:
          'Connect with leads, educators, and fellow club members. Discuss complex topics and work on real-world projects together.',
      icon: Icons.hub_rounded,
      lottieUrl:
          'https://lottie.host/de0413de-9fb0-4389-9a74-b52b365825ee/4F5wH1uMqy.json',
      glowColor: AppColors.secondary,
    ),
    OnboardingData(
      title: 'Quizzes & Achievements',
      description:
          'Test your knowledge with real-time quizzes. Track your progress, build streak counts, and rise to the top of the leaderboard.',
      icon: Icons.emoji_events_rounded,
      lottieUrl:
          'https://lottie.host/020464f8-1996-4177-ad6d-74d41fa7ea60/2Zk7U4BskT.json',
      glowColor: AppColors.accent,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background soft glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.5,
                colors: [
                  _pages[_currentPage].glowColor.withValues(alpha: 0.12),
                  AppColors.background,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated Lottie or Icon Fallback
                            SizedBox(
                              height: 280,
                              child: Lottie.network(
                                page.lottieUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Beautiful fallback with flutter_animate
                                  return Container(
                                        height: 180,
                                        width: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: page.glowColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          border: Border.all(
                                            color: page.glowColor.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          page.icon,
                                          size: 80,
                                          color: page.glowColor,
                                        ),
                                      )
                                      .animate(
                                        onPlay: (controller) =>
                                            controller.repeat(reverse: true),
                                      )
                                      .scaleXY(
                                        begin: 0.9,
                                        end: 1.1,
                                        duration: 1500.ms,
                                        curve: Curves.easeInOut,
                                      )
                                      .elevation(
                                        end: 12,
                                        color: page.glowColor.withValues(
                                          alpha: 0.2,
                                        ),
                                      );
                                },
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Slide Title
                            Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: AppColors.textPrimary,
                                      ),
                                )
                                .animate(key: ValueKey(index))
                                .fade(duration: 400.ms)
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 16),
                            // Slide Description
                            Text(
                                  page.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                )
                                .animate(key: ValueKey(index + 10))
                                .fade(delay: 150.ms, duration: 400.ms)
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Indicators and Navigation Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicators
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _pages[_currentPage].glowColor
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Next/Get Started Button
                      AnimatedButton(
                            onPressed: () {
                              if (_currentPage < _pages.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                );
                              } else {
                                _completeOnboarding();
                              }
                            },
                            text: _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            icon: Icons.arrow_forward_rounded,
                          )
                          .animate(
                            target: _currentPage == _pages.length - 1 ? 1 : 0,
                          )
                          .shimmer(duration: 1200.ms, delay: 500.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final String lottieUrl;
  final Color glowColor;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.lottieUrl,
    required this.glowColor,
  });
}
