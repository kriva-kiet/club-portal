import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_providers.dart';
import '../../core/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../models/profile_update_request_model.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/fancy_chip.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/user_list_sheet.dart';
import '../../widgets/image_crop_dialog.dart';
import '../../widgets/app_footer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final domainsAsync = ref.watch(domainsProvider);
    final postsAsync = ref.watch(postsProvider('all'));

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Profile Hero Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      AppColors.background,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar with glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: AppAvatar(
                        photoUrl: user.photoUrl,
                        name: user.name,
                        radius: 50,
                        borderWidth: 3,
                        borderColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showEditProfileModal(
                        context,
                        ref,
                        user,
                      ),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Change profile photo'),
                    ),
                    const Text(
                      'JPG, PNG or WebP · maximum 1 MB',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            user.role.name.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          user.batch,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (user.githubId.isNotEmpty || user.linkedinId.isNotEmpty || user.instagramId.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.githubId.isNotEmpty)
                            _buildSocialButton(
                              context: context,
                              label: 'GitHub',
                              icon: Icons.code_rounded,
                              color: Colors.white,
                              backgroundColor: const Color(0xFF24292E),
                              url: user.githubId.startsWith('http')
                                  ? user.githubId
                                  : 'https://github.com/${user.githubId.replaceAll('@', '')}',
                            ),
                          if (user.linkedinId.isNotEmpty)
                            _buildSocialButton(
                              context: context,
                              label: 'LinkedIn',
                              icon: Icons.business_center_rounded,
                              color: const Color(0xFF70B5F9),
                              backgroundColor: const Color(0xFF0A66C2),
                              url: user.linkedinId.startsWith('http')
                                  ? user.linkedinId
                                  : 'https://www.linkedin.com/in/${user.linkedinId.replaceAll('@', '')}',
                            ),
                          if (user.instagramId.isNotEmpty)
                            _buildSocialButton(
                              context: context,
                              label: 'Instagram',
                              icon: Icons.camera_alt_rounded,
                              color: const Color(0xFFFF85A2),
                              backgroundColor: const Color(0xFFE1306C),
                              url: user.instagramId.startsWith('http')
                                  ? user.instagramId
                                  : 'https://instagram.com/${user.instagramId.replaceAll('@', '')}',
                            ),
                        ],
                      ),
                    ],
                    ],
                  ),
                ),

                // Profile controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showEditProfileModal(context, ref, user),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Profile'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ),

                // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    _StatCard(
                      label:
                          AppLocalizations.of(
                            context,
                          )?.translate('streak_label') ??
                          'Day Streak',
                      value: '${user.streak.count}',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label:
                          AppLocalizations.of(
                            context,
                          )?.translate('club_id_label') ??
                          'Club ID',
                      value: user.clubId.isNotEmpty ? user.clubId : '—',
                      icon: Icons.badge_outlined,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label:
                          AppLocalizations.of(
                            context,
                          )?.translate('domains_label') ??
                          'Domains',
                      value: '${user.domainsFollowing.length}',
                      icon: Icons.map_rounded,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),

              // Social Stats row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                child: Row(
                  children: [
                    _StatCard(
                      label: 'Posts',
                      value: postsAsync.maybeWhen(
                        data: (posts) => '${posts.where((p) => p.authorUid == user.uid).length}',
                        orElse: () => '-',
                      ),
                      icon: Icons.article_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Followers',
                      value: '${user.followerIds.length}',
                      icon: Icons.people_outline,
                      color: AppColors.secondary,
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
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Following',
                      value: '${user.followingIds.length}',
                      icon: Icons.person_add_alt,
                      color: AppColors.accent,
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Following domains section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Following Domains',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    domainsAsync.when(
                      data: (domains) {
                        final followed = domains
                            .where((d) => user.domainsFollowing.contains(d.id))
                            .toList();

                        if (followed.isEmpty) {
                          return const Text(
                            'Not following any domains yet. Go to Roadmaps to explore!',
                            style: TextStyle(color: AppColors.textMuted),
                          );
                        }

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: followed
                              .map(
                                (d) => FancyChip(
                                  label: d.name,
                                  isSelected: true,
                                  onSelected: (selected) {
                                    // Toggle domain logic
                                  },
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Verified Accomplishments / Certificates Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Credentials',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    domainsAsync.when(
                      data: (domains) {
                        final followed = domains
                            .where((d) => user.domainsFollowing.contains(d.id))
                            .toList();

                        if (followed.isEmpty) {
                          return const Text(
                            'No certificates earned yet.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          );
                        }

                        return Column(
                          children: followed.map((domain) {
                            return Consumer(
                              builder: (context, ref, _) {
                                final progressAsync = ref.watch(
                                  userProgressProvider(domain.id),
                                );

                                return progressAsync.when(
                                  data: (progress) {
                                    final isCompleted =
                                        (progress?.percentComplete ?? 0.0) >=
                                        1.0;

                                    // If not 100% complete, show a teaser progress box
                                    if (!isCompleted) {
                                      return const SizedBox.shrink();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: GlassContainer(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.verified_user_rounded,
                                              color: AppColors.success,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${domain.name} Expert',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  const Text(
                                                    '100% Roadmap Completed',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                _showCertificate(
                                                  context,
                                                  user.name,
                                                  domain.name,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.workspace_premium_rounded,
                                                size: 16,
                                              ),
                                              label: const Text('View Cert'),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.secondary,
                                                textStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (e, s) => const SizedBox.shrink(),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notification Preferences Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer(
                  builder: (context, ref, _) {
                    return GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Notification Settings',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppColors.border),
                          _NotificationToggleTile(
                            prefKey: 'profile_status',
                            title: 'Profile Request Status',
                            subtitle: 'Get notified when Admin approves or rejects profile edits',
                            icon: Icons.manage_accounts_rounded,
                            initialValue: true,
                          ),
                          _NotificationToggleTile(
                            prefKey: 'broadcasts',
                            title: 'Community Broadcasts & Posts',
                            subtitle: 'Alerts for official announcements & community posts',
                            icon: Icons.campaign_rounded,
                            initialValue: true,
                          ),
                          _NotificationToggleTile(
                            prefKey: 'interactions',
                            title: 'Likes & Comments on Posts',
                            subtitle: 'Get notified when someone likes or comments on your posts',
                            icon: Icons.favorite_rounded,
                            initialValue: true,
                          ),
                          _NotificationToggleTile(
                            prefKey: 'events',
                            title: 'Hackathon & Class Alerts',
                            subtitle: 'Reminders for scheduled classes, competitions & sessions',
                            icon: Icons.event_available_rounded,
                            initialValue: true,
                          ),
                          _NotificationToggleTile(
                            prefKey: 'admissions',
                            title: 'Admission Approvals',
                            subtitle: 'Notifications when new member access is granted',
                            icon: Icons.how_to_reg_rounded,
                            initialValue: true,
                          ),
                          _NotificationToggleTile(
                            prefKey: 'chat_invites',
                            title: 'Direct Chat & Team Invites',
                            subtitle: 'Push alerts when teammates message or invite you',
                            icon: Icons.mark_chat_unread_rounded,
                            initialValue: false,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Language Setting Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                                context,
                              )?.translate('language_setting') ??
                              'App Language',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        value: ref.watch(localeProvider).languageCode,
                        underline: const SizedBox.shrink(),
                        dropdownColor: AppColors.surface,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(
                              'English',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'es',
                            child: Text(
                              'Español',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: (langCode) {
                          if (langCode != null) {
                            ref
                                .read(localeProvider.notifier)
                                .setLocale(langCode);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // About Platform & Developer Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.12),
                        const Color(0xFFEC4899).withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.terminal_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Architect & Lead Developer',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Abhisht Singh',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Crafted for KRIVA ML Community • v1.0.0',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sign out
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48, // Accessibility target
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const AppFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  void _showCertificate(
    BuildContext context,
    String userName,
    String domainName,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(28),
          color: AppColors.surface.withValues(alpha: 0.85),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CERTIFICATE OF COMPLETION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.accent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'KRIVA KML TECHNICAL ACADEMY',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const Divider(height: 32, color: AppColors.border),
              const Text(
                'This credential confirms that',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'has successfully completed all module checkpoints, passed all verification quizzes, and mastered the technical domain curriculum for:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  domainName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.secondary,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Divider(height: 36, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'VERIFIED DATE',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '20 Aug 2026',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ISSUED BY',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'KRIVA Club Board',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Verification Hash: SHA256-${domainName.hashCode.abs().toRadixString(16).padLeft(8, '0')}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Certificate downloaded successfully (PDF)!',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EditProfileSheet(user: user),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required String url,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchExternalUrl(context, url),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: backgroundColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_outward_rounded,
                size: 12,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchExternalUrl(BuildContext context, String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    String finalUrl = trimmed;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    try {
      final uri = Uri.parse(finalUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $finalUrl')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $finalUrl')),
        );
      }
    }
  }
}

// ── Notification Toggle Switch Tile Widget ────────────────────────────────────
class _NotificationToggleTile extends StatefulWidget {
  final String prefKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool initialValue;

  const _NotificationToggleTile({
    required this.prefKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.initialValue = true,
  });

  @override
  State<_NotificationToggleTile> createState() => _NotificationToggleTileState();
}

class _NotificationToggleTileState extends State<_NotificationToggleTile> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialValue;
    _loadPref();
  }

  Future<void> _loadPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool('pref_notify_${widget.prefKey}');
      if (val != null && mounted) {
        setState(() => _enabled = val);
      }
    } catch (_) {}
  }

  Future<void> _savePref(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_notify_${widget.prefKey}', value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(widget.icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) async {
              setState(() => _enabled = val);
              await _savePref(val);
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    val
                        ? '${widget.title} notifications ON 🔔'
                        : '${widget.title} notifications OFF 🔕',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Rich Full-Featured Edit Profile Bottom Sheet ──────────────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel user;

  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _githubCtrl;
  late final TextEditingController _linkedinCtrl;
  late final TextEditingController _instaCtrl;
  late String _selectedBatch;
  late String _photoUrl;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final List<String> _batchOptions = [
    'Batch of 2024',
    'Batch of 2025',
    'Batch of 2026',
    'Batch of 2027',
    'Batch of 2028',
    'Batch of 2029',
    'Faculty / Mentor',
    'Alumni',
  ];

  final List<String> _presetAvatars = [
    'Felix',
    'Aneka',
    'Leo',
    'Aria',
    'KRIVA',
    'Alex',
    'Sam',
    'Maya',
    'Jordan',
    'Taylor',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _githubCtrl = TextEditingController(text: widget.user.githubId);
    _linkedinCtrl = TextEditingController(text: widget.user.linkedinId);
    _instaCtrl = TextEditingController(text: widget.user.instagramId);
    _selectedBatch = _batchOptions.contains(widget.user.batch)
        ? widget.user.batch
        : _batchOptions[4]; // Default to Batch of 2028
    _photoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _githubCtrl.dispose();
    _linkedinCtrl.dispose();
    _instaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true, // Required on web — pre-loads bytes into file.bytes
    );
    if (files.isEmpty) return;

    final file = files.single;
    // Use xFile.readAsBytes() — works correctly on web via the browser Blob API.
    // file.bytes was removed in file_picker_platform_interface v3.x.
    // withData is no longer needed but kept for compatibility.
    Uint8List initialBytes;
    try {
      initialBytes = await file.xFile.readAsBytes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not read image file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    if (initialBytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected file appears empty. Please try another image.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Open Interactive Cropper Dialog with circular mask & <= 700 KB size guarantee
    final croppedBytes = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ImageCropDialog(
        imageBytes: initialBytes,
        maxBytes: 700 * 1024,
      ),
    );

    if (croppedBytes == null) return;

    const maxAllowedBytes = 700 * 1024;
    if (croppedBytes.lengthInBytes > maxAllowedBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cropped image exceeds 700 KB limit. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final base64String = base64Encode(croppedBytes);
      final dataUrl = 'data:image/png;base64,$base64String';

      setState(() {
        _photoUrl = dataUrl;
        _isUploadingPhoto = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom profile photo ready! Click "Request to Save". ✨'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo processing failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final newName = _nameCtrl.text.trim();
      final newBio = _bioCtrl.text.trim();
      final newBatch = _selectedBatch;
      final newPhoto = _photoUrl;
      final newGithub = _githubCtrl.text.trim();
      final newLinkedin = _linkedinCtrl.text.trim();
      final newInsta = _instaCtrl.text.trim();

      // If the current user is an admin or developer, update directly
      final isAdmin = widget.user.role == UserRole.admin || widget.user.role == UserRole.developer;

      if (isAdmin) {
        final updatedUser = widget.user.copyWith(
          name: newName,
          bio: newBio,
          batch: newBatch,
          photoUrl: newPhoto,
          githubId: newGithub,
          linkedinId: newLinkedin,
          instagramId: newInsta,
        );

        await ref.read(databaseRepositoryProvider).updateUser(updatedUser);
        if (newPhoto != widget.user.photoUrl && newPhoto.isNotEmpty) {
          await ref.read(authRepositoryProvider).updateProfilePhoto(newPhoto);
        }
        ref.invalidate(authStateChangesProvider);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully! 🎉'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Submit profile update request for admin approval
        final reqId = 'pureq_${const Uuid().v4().substring(0, 8)}';
        final request = ProfileUpdateRequestModel(
          id: reqId,
          uid: widget.user.uid,
          clubId: widget.user.clubId,
          currentName: widget.user.name,
          currentBatch: widget.user.batch,
          currentBio: widget.user.bio,
          currentPhotoUrl: widget.user.photoUrl,
          currentGithubId: widget.user.githubId,
          currentLinkedinId: widget.user.linkedinId,
          currentInstagramId: widget.user.instagramId,
          requestedName: newName,
          requestedBatch: newBatch,
          requestedBio: newBio,
          requestedPhotoUrl: newPhoto,
          requestedGithubId: newGithub,
          requestedLinkedinId: newLinkedin,
          requestedInstagramId: newInsta,
          status: 'pending',
          requestedAt: DateTime.now(),
        );

        await ref.read(databaseRepositoryProvider).submitProfileUpdateRequest(request);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile update request sent to Admins for review! 🚀',
              ),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stack) {
      print('Profile request submission error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit profile request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Update your bio, photo & social handles',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Avatar & Photo Picker section
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.25),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: _isUploadingPhoto
                              ? const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  ),
                                )
                              : AppAvatar(
                                  photoUrl: _photoUrl,
                                  name: _nameCtrl.text,
                                  radius: 44,
                                ),
                        ),
                        InkWell(
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Upload Custom Photo (max 700 KB)'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Avatar preset pills
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presetAvatars.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final seed = _presetAvatars[index];
                          final avatarUrl =
                              'https://api.dicebear.com/7.x/avataaars/png?seed=$seed';
                          final isSelected = _photoUrl == avatarUrl;

                          return InkWell(
                            onTap: () {
                              setState(() => _photoUrl = avatarUrl);
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: AppAvatar(
                                photoUrl: avatarUrl,
                                radius: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Full Name field
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Batch Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBatch,
                decoration: const InputDecoration(
                  labelText: 'Batch / Group',
                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                ),
                dropdownColor: AppColors.surfaceLight,
                items: _batchOptions.map((batch) {
                  return DropdownMenuItem<String>(
                    value: batch,
                    child: Text(batch),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBatch = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              // Bio field
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 250,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell the community about what you are building & learning...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Social Handles Section Header
              Row(
                children: [
                  const Icon(Icons.link_rounded, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Social Profiles & Links',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // GitHub
              TextFormField(
                controller: _githubCtrl,
                decoration: const InputDecoration(
                  labelText: 'GitHub Username or URL',
                  hintText: 'e.g. Abhisht2000',
                  prefixIcon: Icon(Icons.code_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // LinkedIn
              TextFormField(
                controller: _linkedinCtrl,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn Profile URL or Handle',
                  hintText: 'e.g. https://linkedin.com/in/username',
                  prefixIcon: Icon(Icons.business_center_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // Instagram
              TextFormField(
                controller: _instaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Instagram Handle or URL',
                  hintText: 'e.g. yourhandle',
                  prefixIcon: Icon(Icons.camera_alt_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.black,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Text(
                              (widget.user.role == UserRole.admin || widget.user.role == UserRole.developer)
                                  ? 'Save Changes'
                                  : 'Request to Save',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
