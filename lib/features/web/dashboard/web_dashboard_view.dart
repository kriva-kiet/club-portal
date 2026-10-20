import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/broadcast_model.dart';
import '../../../models/domain_model.dart';
import '../../../models/session_model.dart';
import '../../../models/standalone_quiz_model.dart';
import '../../../models/user_model.dart';
import '../../../services/service_providers.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/radial_progress.dart';
import '../../../widgets/user_list_sheet.dart';
import '../../leaderboard/leaderboard_screen.dart';
import '../../quiz/quiz_runtime_screen.dart';
import '../web_responsive.dart';
import '../../complaints/complaint_box_dialog.dart';
import '../../authorities/authorities_screen.dart';

class WebDashboardView extends ConsumerWidget {
  final VoidCallback onNavigateToRoadmaps;
  final VoidCallback onNavigateToCollab;
  final VoidCallback onNavigateToCommunity;
  final VoidCallback? onNavigateToAdmin;
  final VoidCallback? onNavigateToLead;

  const WebDashboardView({
    super.key,
    required this.onNavigateToRoadmaps,
    required this.onNavigateToCollab,
    required this.onNavigateToCommunity,
    this.onNavigateToAdmin,
    this.onNavigateToLead,
  });

  void _showStreakBoard(BuildContext context, WidgetRef ref, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
    );
  }

  void _showBroadcastModal(
    BuildContext context,
    WidgetRef ref,
    BroadcastModel bc,
    String uid,
  ) {
    ref.read(databaseRepositoryProvider).markBroadcastAsRead(uid, bc.id);
    final currentUser = ref.read(currentUserProvider);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bc.audienceType.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('MMM dd, hh:mm a').format(bc.sentAt),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bc.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sent by: ${bc.sentBy}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(height: 24, color: AppColors.border),
            Text(
              bc.body,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          if (currentUser?.role == UserRole.admin ||
              currentUser?.role == UserRole.developer)
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Delete Broadcast?'),
                    content: const Text(
                      'Are you sure you want to delete this broadcast? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && dialogCtx.mounted) {
                  await ref
                      .read(databaseRepositoryProvider)
                      .deleteBroadcast(bc.id);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final broadcastsAsync = ref.watch(broadcastsProvider);
    final domainsAsync = ref.watch(domainsProvider);
    final postsAsync = ref.watch(postsProvider('all'));
    final quizzesAsync = ref.watch(standaloneQuizzesProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final membersAsync = ref.watch(membersProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDesktop = WebResponsive.isDesktop(context);
    final isTablet = WebResponsive.isTablet(context);

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
              // 1. Hero Greeting Banner
              _buildHeroGreeting(context, user),
              const SizedBox(height: 24),

              // 2. 4-Metric Bento Stat Cards
              _buildStatsGrid(context, ref, user, postsAsync),
              const SizedBox(height: 28),

              // 3. Responsive Content Layout (2-Column on Desktop, 1-Column on Tablet/Mobile)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Left Column (65%)
                    Expanded(
                      flex: 65,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecentBroadcasts(
                            context,
                            ref,
                            user,
                            broadcastsAsync,
                          ),
                          const SizedBox(height: 28),
                          _buildEnrolledDomains(context, ref, user, domainsAsync),
                          const SizedBox(height: 28),
                          _buildAvailableAssessments(
                            context,
                            ref,
                            user,
                            quizzesAsync,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Secondary Right Column (35%)
                    Expanded(
                      flex: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLeaderboardSpotlight(context, user, membersAsync),
                          const SizedBox(height: 24),
                          _buildUpcomingSessionsPreview(
                            context,
                            user,
                            sessionsAsync,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecentBroadcasts(
                      context,
                      ref,
                      user,
                      broadcastsAsync,
                    ),
                    const SizedBox(height: 24),
                    _buildEnrolledDomains(context, ref, user, domainsAsync),
                    const SizedBox(height: 24),
                    _buildAvailableAssessments(
                      context,
                      ref,
                      user,
                      quizzesAsync,
                    ),
                    const SizedBox(height: 24),
                    _buildLeaderboardSpotlight(context, user, membersAsync),
                    const SizedBox(height: 24),
                    _buildUpcomingSessionsPreview(
                      context,
                      user,
                      sessionsAsync,
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Greeting Banner ───────────────────────────────────────────────────
  Widget _buildHeroGreeting(BuildContext context, UserModel user) {
    Color roleColor = AppColors.primary;
    if (user.role == UserRole.lead) roleColor = AppColors.success;
    if (user.role == UserRole.admin || user.role == UserRole.developer) {
      roleColor = AppColors.error;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleColor.withValues(alpha: 0.2),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppAvatar(
                photoUrl: user.photoUrl,
                name: user.name,
                radius: 28,
                borderWidth: 2,
                borderColor: roleColor,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Welcome back, ${user.name.split(' ').first} 👋',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            user.role.name.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.batch} • KML Machine Learning Society',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildQuickActionButton(
                label: 'Explore Roadmaps',
                icon: Icons.map_rounded,
                color: AppColors.primary,
                onTap: onNavigateToRoadmaps,
              ),
              _buildQuickActionButton(
                label: 'Collab Sessions',
                icon: Icons.hub_rounded,
                color: AppColors.secondary,
                onTap: onNavigateToCollab,
              ),
              _buildQuickActionButton(
                label: 'Community Feed',
                icon: Icons.people_alt_rounded,
                color: AppColors.info,
                onTap: onNavigateToCommunity,
              ),
              _buildQuickActionButton(
                label: 'Authorities & Cells',
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF818CF8),
                onTap: () => context.push('/authorities'),
              ),
              _buildQuickActionButton(
                label: 'Anonymous Grievance Box',
                icon: Icons.shield_outlined,
                color: const Color(0xFFEF4444),
                onTap: () => ComplaintBoxDialog.show(context),
              ),
              if (user.role == UserRole.admin || user.role == UserRole.developer)
                _buildQuickActionButton(
                  label: 'Admin Control Center',
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppColors.error,
                  onTap: onNavigateToAdmin ?? () {},
                )
              else if (user.role == UserRole.lead)
                _buildQuickActionButton(
                  label: 'Lead Hub',
                  icon: Icons.star_rounded,
                  color: AppColors.success,
                  onTap: onNavigateToLead ?? () {},
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4-Metric Bento Stat Cards ──────────────────────────────────────────────
  Widget _buildStatsGrid(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    AsyncValue<dynamic> postsAsync,
  ) {
    final postCount = postsAsync.maybeWhen(
      data: (posts) => posts.where((p) => p.authorUid == user.uid).length,
      orElse: () => 0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: crossAxisCount == 4 ? 2.1 : 1.9,
          children: [
            _buildStatCard(
              title: 'Posts Shared',
              value: '$postCount',
              icon: Icons.article_outlined,
              accent: AppColors.primary,
              onTap: onNavigateToCommunity,
            ),
            _buildStatCard(
              title: 'Followers',
              value: '${user.followerIds.length}',
              icon: Icons.people_outline_rounded,
              accent: AppColors.secondary,
              onTap: () {
                if (user.followerIds.isNotEmpty) {
                  UserListSheet.show(
                    context,
                    title: 'Followers',
                    userIds: user.followerIds,
                  );
                }
              },
            ),
            _buildStatCard(
              title: 'Following',
              value: '${user.followingIds.length}',
              icon: Icons.person_add_alt_1_rounded,
              accent: AppColors.info,
              onTap: () {
                if (user.followingIds.isNotEmpty) {
                  UserListSheet.show(
                    context,
                    title: 'Following',
                    userIds: user.followingIds,
                  );
                }
              },
            ),
            _buildStatCard(
              title: 'Active Streak',
              value: '${user.streak.count} Days',
              icon: Icons.local_fire_department_rounded,
              accent: AppColors.accent,
              onTap: () => _showStreakBoard(context, ref, user),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Broadcasts ──────────────────────────────────────────────────────
  Widget _buildRecentBroadcasts(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    AsyncValue<List<BroadcastModel>> broadcastsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.campaign_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Recent Broadcasts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        broadcastsAsync.when(
          data: (broadcasts) {
            if (broadcasts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No recent broadcasts for your feed.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }

            final topBroadcasts = broadcasts.take(4).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topBroadcasts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final bc = topBroadcasts[idx];
                final isUnread = !bc.readBy.contains(user.uid);

                return InkWell(
                  onTap: () => _showBroadcastModal(context, ref, bc, user.uid),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnread
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : AppColors.border,
                        width: isUnread ? 1.5 : 1,
                      ),
                      boxShadow: isUnread
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      bc.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isUnread) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    DateFormat('MMM dd').format(bc.sentAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bc.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'By ${bc.sentBy}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Click to read full announcement →',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading broadcasts: $e'),
        ),
      ],
    );
  }

  // ── Enrolled Domains & Progress ───────────────────────────────────────────
  Widget _buildEnrolledDomains(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    AsyncValue<List<DomainModel>> domainsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.school_rounded,
              color: AppColors.secondary,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Your Technical Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onNavigateToRoadmaps,
              child: const Text('View All Paths →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        domainsAsync.when(
          data: (domains) {
            final followed = domains
                .where((d) => user.domainsFollowing.contains(d.id))
                .toList();

            if (followed.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.explore_outlined,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You are not enrolled in any roadmap paths yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: onNavigateToRoadmaps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Explore Learning Roadmaps'),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 700 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: cols == 2 ? 2.6 : 3.0,
                  ),
                  itemCount: followed.length,
                  itemBuilder: (context, index) {
                    final domain = followed[index];
                    return Consumer(
                      builder: (context, ref, child) {
                        final progressAsync = ref.watch(
                          userProgressProvider(domain.id),
                        );

                        return progressAsync.when(
                          data: (progress) {
                            final percent = progress?.percentComplete ?? 0.0;
                            final completedCount =
                                progress?.topicsCompleted.length ?? 0;

                            return InkWell(
                              onTap: () => context.push('/roadmap/${domain.id}'),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    RadialProgress(
                                      percentage: percent,
                                      size: 56,
                                      strokeWidth: 5,
                                      activeColor: AppColors.secondary,
                                      child: Text(
                                        '${(percent * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            domain.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$completedCount tasks completed',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loading: () => Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading domains: $e'),
        ),
      ],
    );
  }

  // ── Available Assessments ──────────────────────────────────────────────────
  Widget _buildAvailableAssessments(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    AsyncValue<List<StandaloneQuizModel>> quizzesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.quiz_rounded,
              color: AppColors.accent,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Available Assessments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        quizzesAsync.when(
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No assessments scheduled currently.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 700 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: cols == 2 ? 2.5 : 2.8,
                  ),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    final canDelete =
                        user.role == UserRole.admin || user.role == UserRole.developer;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.assignment_outlined,
                                color: AppColors.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  quiz.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (canDelete)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 16,
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.surface,
                                        title: const Text('Delete Assessment?'),
                                        content: Text(
                                          'Delete "${quiz.title}" permanently?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref
                                          .read(databaseRepositoryProvider)
                                          .deleteStandaloneQuiz(quiz.id);
                                    }
                                  },
                                ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${quiz.questions.length} Questions',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    quiz.type == 'timed' &&
                                            quiz.timeLimitMinutes != null
                                        ? '⏱ ${quiz.timeLimitMinutes} min limit'
                                        : 'Untimed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: quiz.type == 'timed'
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          QuizRuntimeScreen(quiz: quiz),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Start Quiz'),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading quizzes: $e'),
        ),
      ],
    );
  }

  // ── Leaderboard Spotlight ──────────────────────────────────────────────────
  Widget _buildLeaderboardSpotlight(
    BuildContext context,
    UserModel user,
    AsyncValue<List<UserModel>> membersAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Streak Leaders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaderboardScreen(),
                    ),
                  );
                },
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          membersAsync.when(
            data: (members) {
              final sorted = [...members]
                ..sort((a, b) => b.streak.count.compareTo(a.streak.count));
              final topMembers = sorted.take(5).toList();

              if (topMembers.isEmpty) {
                return const Text(
                  'No streak leaders yet.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topMembers.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 16, color: AppColors.border),
                itemBuilder: (context, idx) {
                  final member = topMembers[idx];
                  final isCurrent = member.uid == user.uid;
                  String medal = '${idx + 1}';
                  if (idx == 0) medal = '🥇';
                  if (idx == 1) medal = '🥈';
                  if (idx == 2) medal = '🥉';

                  return Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          medal,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppAvatar(
                        photoUrl: member.photoUrl,
                        name: member.name,
                        radius: 14,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isCurrent
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              member.batch,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 12,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${member.streak.count}d',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  // ── Upcoming Sessions Preview ──────────────────────────────────────────────
  Widget _buildUpcomingSessionsPreview(
    BuildContext context,
    UserModel user,
    AsyncValue<List<SessionModel>> sessionsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Upcoming Sessions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onNavigateToCollab,
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          sessionsAsync.when(
            data: (sessions) {
              final upcoming = sessions
                  .where((s) => s.dateTime.isAfter(DateTime.now()))
                  .toList();

              if (upcoming.isEmpty) {
                return const Text(
                  'No sessions scheduled at this moment.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                );
              }

              final nextSessions = upcoming.take(2).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nextSessions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 16, color: AppColors.border),
                itemBuilder: (context, idx) {
                  final session = nextSessions[idx];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, hh:mm a')
                                .format(session.dateTime),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
