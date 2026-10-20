import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/authority_model.dart';
import '../../models/authority_group_model.dart';
import '../../models/user_model.dart';
import '../../services/service_providers.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_footer.dart';
import 'widgets/edit_authority_dialog.dart';
import 'widgets/manage_groups_dialog.dart';

class AuthoritiesScreen extends ConsumerStatefulWidget {
  const AuthoritiesScreen({super.key});

  @override
  ConsumerState<AuthoritiesScreen> createState() => _AuthoritiesScreenState();
}

class _AuthoritiesScreenState extends ConsumerState<AuthoritiesScreen> {
  String _selectedGroupId = 'all'; // 'all' or specific group id
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchExternalUrl(String url) async {
    if (url.trim().isEmpty) return;
    var target = url.trim();
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'https://$target';
    }
    final uri = Uri.tryParse(target);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $url'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    if (email.trim().isEmpty) return;
    final uri = Uri.parse('mailto:${email.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:${phone.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _confirmDeleteAuthority(AuthorityModel auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove Authority?'),
        content: Text(
          'Are you sure you want to remove "${auth.name}" (${auth.position}) from the authorities section?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(databaseRepositoryProvider).deleteAuthority(auth.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authority removed successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final authoritiesAsync = ref.watch(authoritiesProvider);
    final groupsAsync = ref.watch(authorityGroupsProvider);
    final membersAsync = ref.watch(membersProvider);
    final members = membersAsync.valueOrNull ?? [];

    final isAdminOrDev = currentUser != null &&
        (currentUser.role == UserRole.admin ||
            currentUser.role == UserRole.developer);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Authorities & Cells',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          if (isAdminOrDev) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final groups = groupsAsync.valueOrNull ?? [];
                  ManageGroupsDialog.show(context, existingGroups: groups);
                },
                icon: const Icon(Icons.hub_outlined, size: 16),
                label: const Text('Cells / Wings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.terminal_rounded, size: 12, color: Color(0xFF818CF8)),
                SizedBox(width: 4),
                Text(
                  'Dev: Abhisht Singh',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC7D2FE),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: isAdminOrDev
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                final groups = groupsAsync.valueOrNull ?? [];
                final effectiveGroups = groups.isNotEmpty
                    ? groups
                    : [
                        AuthorityGroupModel(
                          id: 'executive_council',
                          name: 'Executive Council',
                          description: 'Executive governance of the club.',
                          order: 1,
                        ),
                        AuthorityGroupModel(
                          id: 'women_cell',
                          name: 'Women Cell',
                          description: 'Dedicated committee for women empowerment in tech.',
                          order: 2,
                        ),
                      ];
                EditAuthorityDialog.show(context, groups: effectiveGroups);
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text(
                'Add Authority',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: groupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading groups: $err')),
          data: (groups) {
            return authoritiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error loading authorities: $err')),
              data: (authorities) {
                // Filter by group & search
                var filtered = authorities.where((a) {
                  if (_selectedGroupId != 'all' && a.groupId != _selectedGroupId) {
                    return false;
                  }
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final matchesName = a.name.toLowerCase().contains(query);
                    final matchesPos = a.position.toLowerCase().contains(query);
                    final matchesGroup = a.groupName.toLowerCase().contains(query);
                    final matchesBio = a.bio.toLowerCase().contains(query);
                    return matchesName || matchesPos || matchesGroup || matchesBio;
                  }
                  return true;
                }).toList();

                return CustomScrollView(
                  slivers: [
                    // ── Header Banner ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              const Color(0xFF1E1B4B).withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    'GOVERNANCE & LEADERSHIP',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (isAdminOrDev)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.error),
                                    ),
                                    child: const Text(
                                      'ADMIN CONTROLS ACTIVE',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Club Authorities & Domain Heads',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Official executive council, domain coordinators, and dedicated cells (including the Women Cell) driving KRIVA Community forward.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Search & Filter Controls ────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Box
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by authority name, position, or cell...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            ),
                            const SizedBox(height: 12),

                            // Group Filter Pills
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildGroupPill(
                                    id: 'all',
                                    name: 'All Authorities (${authorities.length})',
                                    icon: Icons.all_inclusive_rounded,
                                    accentColor: AppColors.primary,
                                  ),
                                  ...groups.map((g) {
                                    final count = authorities.where((a) => a.groupId == g.id).length;
                                    final isWomenCell = g.name.toLowerCase().contains('women');
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _buildGroupPill(
                                        id: g.id,
                                        name: '${g.name} ($count)',
                                        icon: isWomenCell
                                            ? Icons.female_rounded
                                            : Icons.group_work_outlined,
                                        accentColor: isWomenCell
                                            ? const Color(0xFFEC4899)
                                            : AppColors.primary,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // ── Authorities Grid ────────────────────────────────────
                    if (filtered.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.people_outline_rounded,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No Authorities in this Cell',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isAdminOrDev
                                      ? 'Tap "+ Add Authority" below to add official leadership details for this cell.'
                                      : 'Leadership details for this domain/cell will appear here soon.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.crossAxisExtent;
                            int crossAxisCount = 1;
                            if (width >= 1100) {
                              crossAxisCount = 3;
                            } else if (width >= 700) {
                              crossAxisCount = 2;
                            }

                            return SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 310,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final authority = filtered[index];
                                  return _buildAuthorityCard(
                                    context,
                                    authority,
                                    isAdminOrDev,
                                    groups,
                                    members,
                                  );
                                },
                                childCount: filtered.length,
                              ),
                            );
                          },
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 40),
                        child: AppFooter(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGroupPill({
    required String id,
    required String name,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedGroupId == id;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedGroupId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorityCard(
    BuildContext context,
    AuthorityModel authority,
    bool isAdminOrDev,
    List<AuthorityGroupModel> groups,
    List<UserModel> members,
  ) {
    // ── Live Account Synchronization ──────────────────────────────────────────
    // If the position holder updates their details in their KRIVA user account,
    // this live-sync immediately pulls their latest photo, name, bio, and social links.
    UserModel? liveUser;
    if (authority.userId.isNotEmpty) {
      final match = members.where((m) => m.uid == authority.userId);
      if (match.isNotEmpty) liveUser = match.first;
    }
    if (liveUser == null && authority.email.isNotEmpty) {
      final match = members.where((m) => m.email.toLowerCase() == authority.email.toLowerCase());
      if (match.isNotEmpty) liveUser = match.first;
    }

    final displayName = (liveUser != null && liveUser.name.trim().isNotEmpty)
        ? liveUser.name.trim()
        : authority.name;
    final displayPhotoUrl = (liveUser != null && liveUser.photoUrl.trim().isNotEmpty)
        ? liveUser.photoUrl.trim()
        : authority.photoUrl;
    final displayEmail = (liveUser != null && liveUser.email.trim().isNotEmpty)
        ? liveUser.email.trim()
        : authority.email;
    final displayBio = (liveUser != null && liveUser.bio.trim().isNotEmpty)
        ? liveUser.bio.trim()
        : (authority.bio.isNotEmpty ? authority.bio : 'Dedicated authority and mentor guiding club members and community initiatives.');
    final displayLinkedin = (liveUser != null && liveUser.linkedinId.trim().isNotEmpty)
        ? (liveUser.linkedinId.startsWith('http') ? liveUser.linkedinId.trim() : 'https://linkedin.com/in/${liveUser.linkedinId.trim()}')
        : authority.linkedinUrl;
    final displayGithub = (liveUser != null && liveUser.githubId.trim().isNotEmpty)
        ? (liveUser.githubId.startsWith('http') ? liveUser.githubId.trim() : 'https://github.com/${liveUser.githubId.trim()}')
        : authority.githubUrl;
    final displayInstagram = (liveUser != null && liveUser.instagramId.trim().isNotEmpty)
        ? (liveUser.instagramId.startsWith('http') ? liveUser.instagramId.trim() : 'https://instagram.com/${liveUser.instagramId.trim()}')
        : authority.instagramUrl;
    final isLiveSynced = liveUser != null;

    final isWomenCell = authority.groupName.toLowerCase().contains('women');
    final accentColor = isWomenCell ? const Color(0xFFEC4899) : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner with group & admin actions
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWomenCell ? Icons.female_rounded : Icons.group_work_outlined,
                        size: 12,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        authority.groupName.toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLiveSynced) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Live synced with $displayName\'s account',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.sync_rounded, size: 10, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (isAdminOrDev) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primary,
                    tooltip: 'Edit Authority',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      EditAuthorityDialog.show(
                        context,
                        existingAuthority: authority,
                        groups: groups,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    tooltip: 'Delete Authority',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDeleteAuthority(authority),
                  ),
                ],
              ],
            ),
          ),

          // Main Profile section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: AppAvatar(
                          photoUrl: displayPhotoUrl,
                          name: displayName,
                          radius: 30,
                          borderWidth: 2,
                          borderColor: accentColor,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name & Position
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                authority.position,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Bio / Quote
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        displayBio,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Contact Actions Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
            ),
            child: Row(
              children: [
                // Email
                if (displayEmail.isNotEmpty)
                  _buildContactIconButton(
                    icon: Icons.email_outlined,
                    tooltip: displayEmail,
                    color: AppColors.primary,
                    onTap: () => _launchEmail(displayEmail),
                  ),

                // Phone
                if (authority.phone.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildContactIconButton(
                    icon: Icons.phone_outlined,
                    tooltip: authority.phone,
                    color: const Color(0xFF10B981),
                    onTap: () => _launchPhone(authority.phone),
                  ),
                ],

                // LinkedIn
                if (displayLinkedin.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildContactIconButton(
                    icon: Icons.link_rounded,
                    tooltip: 'LinkedIn Profile',
                    color: const Color(0xFF0A66C2),
                    onTap: () => _launchExternalUrl(displayLinkedin),
                  ),
                ],

                // GitHub
                if (displayGithub.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildContactIconButton(
                    icon: Icons.code_rounded,
                    tooltip: 'GitHub Profile',
                    color: Colors.white,
                    onTap: () => _launchExternalUrl(displayGithub),
                  ),
                ],

                // Instagram
                if (displayInstagram.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _buildContactIconButton(
                    icon: Icons.alternate_email_rounded,
                    tooltip: 'Social Handle',
                    color: const Color(0xFFE1306C),
                    onTap: () => _launchExternalUrl(displayInstagram),
                  ),
                ],

                const Spacer(),
                if (displayEmail.isNotEmpty)
                  InkWell(
                    onTap: () => _launchEmail(displayEmail),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Contact',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: accentColor),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
