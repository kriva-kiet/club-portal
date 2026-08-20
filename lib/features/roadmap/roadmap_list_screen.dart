import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_providers.dart';
import '../../core/localization/app_localizations.dart';

class RoadmapListScreen extends ConsumerWidget {
  const RoadmapListScreen({super.key});

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

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.translate('roadmaps_title') ??
                          'Learning Roadmaps',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your progress across technical domains',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            domainsAsync.when(
              data: (domains) {
                if (domains.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No domains configured yet.\nAsk your Admin to add roadmap paths.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final domain = domains[index];
                    final isFollowing =
                        user?.domainsFollowing.contains(domain.id) ?? false;
                    final color = _domainColors[domain.id] ?? AppColors.primary;
                    final icon = _domainIcons[domain.id] ?? Icons.book_rounded;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push('/roadmap/${domain.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Domain icon badge
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(icon, color: color, size: 26),
                                ),
                                const SizedBox(width: 16),
                                // Domain info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        domain.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        domain.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Follow/Unfollow chip
                                Consumer(
                                  builder: (context, ref, _) {
                                    return GestureDetector(
                                      onTap: () async {
                                        if (user == null) return;
                                        final updated = List<String>.from(
                                          user.domainsFollowing,
                                        );
                                        if (isFollowing) {
                                          updated.remove(domain.id);
                                        } else {
                                          if (domain.password.isNotEmpty) {
                                            final isCorrect = await showDialog<bool>(
                                              context: context,
                                              builder: (context) {
                                                final ctrl = TextEditingController();
                                                return AlertDialog(
                                                  backgroundColor: AppColors.surface,
                                                  title: const Text('Password Required'),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('This domain roadmap requires an access password to follow.'),
                                                      const SizedBox(height: 12),
                                                      TextField(
                                                        controller: ctrl,
                                                        obscureText: true,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Enter Password',
                                                          border: OutlineInputBorder(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        if (ctrl.text.trim() == domain.password) {
                                                          Navigator.pop(context, true);
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Incorrect Password'),
                                                              backgroundColor: AppColors.error,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: const Text('Unlock'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            if (isCorrect != true) return;
                                          }
                                          updated.add(domain.id);
                                        }
                                        await ref
                                            .read(databaseRepositoryProvider)
                                            .updateFollowedDomains(
                                              user.uid,
                                              updated,
                                            );
                                        // Also update in AuthRepo cache
                                        final authRepo = ref.read(
                                          authRepositoryProvider,
                                        );
                                        await authRepo.completeProfile(
                                          name: user.name,
                                          bio: user.bio,
                                          batch: user.batch,
                                          domains: updated,
                                          photoUrl: user.photoUrl,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isFollowing
                                              ? color.withValues(alpha: 0.15)
                                              : AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isFollowing
                                                ? color.withValues(alpha: 0.4)
                                                : AppColors.border,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          isFollowing ? 'Following' : 'Follow',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isFollowing
                                                ? color
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: domains.length),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverFillRemaining(
                child: Center(child: Text('Error loading domains: $e')),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
