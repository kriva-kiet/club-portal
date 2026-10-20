import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/service_providers.dart';
import '../../../widgets/radial_progress.dart';
import '../web_responsive.dart';

class WebRoadmapView extends ConsumerWidget {
  const WebRoadmapView({super.key});

  static const _domainIcons = {
    'dsa': Icons.data_array_rounded,
    'web_dev': Icons.web_rounded,
    'ml': Icons.psychology_rounded,
    'app_dev': Icons.phone_android_rounded,
  };

  static const _domainColors = {
    'dsa': AppColors.primary,
    'web_dev': AppColors.secondary,
    'ml': AppColors.success,
    'app_dev': AppColors.accent,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainsAsync = ref.watch(domainsProvider);
    final user = ref.watch(currentUserProvider);

    return SingleChildScrollView(
      padding: WebResponsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: WebResponsive.contentMaxWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Technical Roadmaps',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Step-by-step curated engineering paths with interactive tasks & quizzes',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Roadmaps Grid
              domainsAsync.when(
                data: (domains) {
                  if (domains.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No roadmap domains configured yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 1000
                          ? 3
                          : constraints.maxWidth >= 600
                              ? 2
                              : 1;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: cols == 3 ? 1.3 : cols == 2 ? 1.4 : 1.8,
                        ),
                        itemCount: domains.length,
                        itemBuilder: (context, index) {
                          final domain = domains[index];
                          final isFollowing =
                              user?.domainsFollowing.contains(domain.id) ?? false;
                          final color =
                              _domainColors[domain.id] ?? AppColors.primary;
                          final icon =
                              _domainIcons[domain.id] ?? Icons.book_rounded;

                          return Consumer(
                            builder: (context, ref, child) {
                              final progressAsync = ref.watch(
                                userProgressProvider(domain.id),
                              );

                              final percent = progressAsync.maybeWhen(
                                data: (p) => p?.percentComplete ?? 0.0,
                                orElse: () => 0.0,
                              );
                              final completedCount = progressAsync.maybeWhen(
                                data: (p) => p?.topicsCompleted.length ?? 0,
                                orElse: () => 0,
                              );

                              return Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isFollowing
                                        ? color.withValues(alpha: 0.4)
                                        : AppColors.border,
                                    width: isFollowing ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.06),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Icon(icon, color: color, size: 26),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isFollowing
                                                ? AppColors.success
                                                    .withValues(alpha: 0.15)
                                                : AppColors.surfaceLight,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isFollowing
                                                  ? AppColors.success
                                                      .withValues(alpha: 0.4)
                                                  : AppColors.border,
                                            ),
                                          ),
                                          child: Text(
                                            isFollowing ? 'Enrolled' : 'Available',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isFollowing
                                                  ? AppColors.success
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      domain.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      domain.description.isNotEmpty
                                          ? domain.description
                                          : 'Comprehensive curriculum and projects curated for students.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        RadialProgress(
                                          percentage: percent,
                                          size: 40,
                                          strokeWidth: 4,
                                          activeColor: color,
                                          child: Text(
                                            '${(percent * 100).toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '$completedCount tasks completed',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const Spacer(),
                                        ElevatedButton(
                                          onPressed: () => context
                                              .push('/roadmap/${domain.id}'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'View Path',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading roadmaps: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
