import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/linkable_text.dart';
import '../../services/service_providers.dart';
import '../../models/broadcast_model.dart';
import '../../models/domain_model.dart';
import '../../models/standalone_quiz_model.dart';
import '../../models/user_model.dart';
import '../../models/access_request_model.dart';
import '../../models/team_request_model.dart';
import '../../models/profile_update_request_model.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/app_avatar.dart';
import '../roadmap/roadmap_detail_screen.dart';
import 'widgets/bulk_module_upload_dialog.dart';
import 'widgets/complaints_admin_tab.dart';

Future<void> _confirmAdminPassword(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String message,
  required Future<void> Function() onConfirmed,
}) async {
  final passwordCtrl = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 16),
          TextField(
            controller: passwordCtrl,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Confirm your admin password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            try {
              await ref
                  .read(authRepositoryProvider)
                  .verifyCurrentPassword(passwordCtrl.text.trim());
              Navigator.pop(dialogContext);
              await onConfirmed();
            } catch (_) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Incorrect admin password.')),
                );
              }
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  passwordCtrl.dispose();
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(currentUserProvider);
    final isAdminOrDev =
        user?.role == UserRole.admin || user?.role == UserRole.developer;
    final tabsCount = isAdminOrDev ? 9 : 4;
    if (_tabController.length != tabsCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabsCount, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final bool isAdminOrDev =
        user?.role == UserRole.admin || user?.role == UserRole.developer;
    final complaintsAsync = ref.watch(complaintsProvider);
    final pendingComplaints = complaintsAsync.valueOrNull
            ?.where((c) => c.status == 'pending')
            .length ??
        0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Admin Panel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://www.linkedin.com/in/abhisht-singh-71063b327/');
                      // ignore: deprecated_member_use
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            const Color(0xFF0A66C2).withValues(alpha: 0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            size: 13,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Developer: Abhisht Singh',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF0A66C2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              isScrollable: true,
              tabs: [
                const Tab(text: 'Members'),
                if (isAdminOrDev) const Tab(text: 'Admissions'),
                if (isAdminOrDev) const Tab(text: 'Profile Requests'),
                if (isAdminOrDev)
                  Tab(
                    text: pendingComplaints > 0
                        ? 'Complaints ($pendingComplaints)'
                        : 'Complaints',
                  ),
                if (isAdminOrDev) const Tab(text: 'Teams'),
                if (isAdminOrDev) const Tab(text: 'Hackathons'),
                const Tab(text: 'Broadcast'),
                const Tab(text: 'Roadmaps'),
                const Tab(text: 'Analytics'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const _MembersTab(),
                  if (isAdminOrDev) const _RequestsTab(),
                  if (isAdminOrDev) const _ProfileRequestsTab(),
                  if (isAdminOrDev) const ComplaintsAdminTab(),
                  if (isAdminOrDev) const _TeamRequestsTab(),
                  if (isAdminOrDev) const _HackathonsAdminTab(),
                  const _BroadcastTab(),
                  const _RoadmapEditorTab(),
                  const _AnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Members Tab ──────────────────────────────────────────────────────────────
class _MembersTab extends ConsumerStatefulWidget {
  const _MembersTab();

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  final _searchController = TextEditingController();
  bool _showPastMembers = false;
  String _sortBy = 'Name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(
      _showPastMembers ? _pastMembersStreamProvider : _membersStreamProvider,
    );
    final currentUser = ref.watch(currentUserProvider);
    final domains = ref.watch(domainsProvider).valueOrNull ?? [];
    final ledDomain = domains.firstWhere(
      (d) => d.leadUserIds.contains(currentUser?.uid),
      orElse: () => DomainModel(
        id: '',
        name: '',
        description: '',
        leadUserIds: [],
        password: '',
        modules: [],
      ),
    );

    return membersAsync.when(
      data: (members) {
        final query = _searchController.text.trim().toLowerCase();
        final displayed = members.where((member) {
          return query.isEmpty ||
              member.name.toLowerCase().contains(query) ||
              member.clubId.toLowerCase().contains(query) ||
              member.email.toLowerCase().contains(query);
        }).toList();
        displayed.sort((a, b) {
          return switch (_sortBy) {
            'Role' => a.role.name.compareTo(b.role.name),
            'Newest' => b.createdAt.compareTo(a.createdAt),
            _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          };
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayed.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(
                            () => _showPastMembers = !_showPastMembers,
                          ),
                          icon: Icon(
                            _showPastMembers
                                ? Icons.people_rounded
                                : Icons.history_rounded,
                          ),
                          label: Text(
                            _showPastMembers
                                ? 'Active Members'
                                : 'Past Members',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        initialValue: _sortBy,
                        onSelected: (value) => setState(() => _sortBy = value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'Name',
                            child: Text('Sort by name'),
                          ),
                          PopupMenuItem(
                            value: 'Role',
                            child: Text('Sort by role'),
                          ),
                          PopupMenuItem(
                            value: 'Newest',
                            child: Text('Sort by newest'),
                          ),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.sort_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search by name, Club ID, or email',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (displayed.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: Text(
                        _showPastMembers
                            ? 'No past members found.'
                            : 'No members found.',
                      ),
                    ),
                ],
              );
            }
            final m = displayed[index - 1];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (currentUser?.role == UserRole.lead) {
                    _showStudentProgressSheet(context, ref, m, ledDomain);
                  } else if (!_showPastMembers) {
                    _showRoleSheet(context, ref, m);
                  } else {
                    _showMemberDetails(context, m, isPastMember: true);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        photoUrl: m.photoUrl,
                        name: m.name,
                        radius: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${m.clubId} · ${m.batch}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor(m.role).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.role.name.toUpperCase(),
                          style: TextStyle(
                            color: _roleColor(m.role),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _showRoleSheet(BuildContext context, WidgetRef ref, UserModel member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Member Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditFullProfileDialog(context, ref, member),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _memberDetails(member),
                const Divider(height: 24),
                const Text(
                  'Manage role',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...UserRole.values.map((role) {
                  final isCurrent = member.role == role;
                  return ListTile(
                    title: Text(
                      role.name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      await ref
                          .read(databaseRepositoryProvider)
                          .updateUserRole(member.uid, role);

                      ref.invalidate(_membersStreamProvider);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Updated role to ${role.name.toUpperCase()}',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  );
                }),
                if (ref.read(currentUserProvider)?.role == UserRole.admin ||
                    ref.read(currentUserProvider)?.role ==
                        UserRole.developer) ...[
                  const Divider(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close current sheet
                      _showResetPasswordDialog(context, ref, member);
                    },
                    icon: const Icon(Icons.password_rounded, size: 16),
                    label: const Text('Reset Account Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _confirmArchive(context, ref, member),
                    icon: const Icon(Icons.person_remove_rounded),
                    label: const Text('Remove / Move to Past Members'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditFullProfileDialog(BuildContext context, WidgetRef ref, UserModel member) {
    final nameCtrl = TextEditingController(text: member.name);
    final bioCtrl = TextEditingController(text: member.bio);
    final batchCtrl = TextEditingController(text: member.batch);
    final clubIdCtrl = TextEditingController(text: member.clubId);
    final githubCtrl = TextEditingController(text: member.githubId);
    final instaCtrl = TextEditingController(text: member.instagramId);
    final linkedinCtrl = TextEditingController(text: member.linkedinId);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Edit Full Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: clubIdCtrl,
                  decoration: const InputDecoration(labelText: 'Club ID'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: batchCtrl,
                  decoration: const InputDecoration(labelText: 'Batch'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: githubCtrl,
                  decoration: const InputDecoration(labelText: 'GitHub URL'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: instaCtrl,
                  decoration: const InputDecoration(labelText: 'Instagram URL'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: linkedinCtrl,
                  decoration: const InputDecoration(labelText: 'LinkedIn URL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final updated = member.copyWith(
                  name: nameCtrl.text.trim(),
                  clubId: clubIdCtrl.text.trim(),
                  batch: batchCtrl.text.trim(),
                  bio: bioCtrl.text.trim(),
                  githubId: githubCtrl.text.trim(),
                  instagramId: instaCtrl.text.trim(),
                  linkedinId: linkedinCtrl.text.trim(),
                );
                await ref.read(databaseRepositoryProvider).updateUser(updated);
                ref.invalidate(_membersStreamProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated.')),
                  );
                  Navigator.pop(context); // Close the role sheet too
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _memberDetails(UserModel member) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        member.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const SizedBox(height: 6),
      Text('Club ID: ${member.clubId}'),
      Text('Email: ${member.email}'),
      Text('Role: ${member.role.name.toUpperCase()} · ${member.batch}'),
      if (member.bio.isNotEmpty) Text('Bio: ${member.bio}'),
      if (member.domainsFollowing.isNotEmpty)
        Text('Domains: ${member.domainsFollowing.join(', ').toUpperCase()}'),
      Text('Joined: ${member.createdAt.toLocal().toString().split(' ').first}'),
    ],
  );

  void _showMemberDetails(
    BuildContext context,
    UserModel member, {
    bool isPastMember = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isPastMember ? 'Past Member Details' : 'Member Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            _memberDetails(member),
          ],
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, WidgetRef ref, UserModel member) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          '${member.name} will be moved to Past Members and will no longer be able to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _confirmAdminPassword(
                context,
                ref,
                title: 'Confirm member removal',
                message:
                    'Enter your admin password to remove ${member.name} and block their login.',
                onConfirmed: () async {
                  Navigator.pop(context);
                  await ref.read(databaseRepositoryProvider).archiveMember(
                    member,
                    ref.read(currentUserProvider)?.uid ?? '',
                  );
                },
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel member,
  ) {
    // Enforce role check: Only admins or developers can change user passwords
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.role != UserRole.admin &&
        currentUser?.role != UserRole.developer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied: Only Admins can change user passwords.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final passwordCtrl = TextEditingController();
    bool obscurePassword = true;
    bool isSubmitting = false;
    String? validationError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.accent, size: 22),
              SizedBox(width: 8),
              Text(
                'Reset User Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter new password for ${member.name} (${member.clubId}):',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordCtrl,
                obscureText: obscurePassword,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: '••••••••',
                  prefixIcon: const Icon(
                    Icons.key_rounded,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setDialogState(
                      () => obscurePassword = !obscurePassword,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (validationError != null) {
                    setDialogState(() => validationError = null);
                  }
                },
              ),
              if (validationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  validationError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final newPass = passwordCtrl.text.trim();
                      if (newPass.length < 6) {
                        setDialogState(() {
                          validationError =
                              'Password must be at least 6 characters long.';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        validationError = null;
                      });

                      try {
                        await ref
                            .read(databaseRepositoryProvider)
                            .changeUserPassword(member.uid, newPass);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Password updated successfully for ${member.name}!',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        final errorMsg =
                            e.toString().replaceAll('Exception: ', '');
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to change password: $errorMsg',
                              ),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentProgressSheet(
    BuildContext context,
    WidgetRef ref,
    UserModel student,
    DomainModel domain,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final progressAsync = ref.watch(
              studentProgressProvider((uid: student.uid, domainId: domain.id)),
            );
            final modulesAsync = ref.watch(modulesProvider(domain.id));

            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        photoUrl: student.photoUrl,
                        name: student.name,
                        radius: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${student.clubId} · ${student.batch}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Domain Progress: ${domain.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  progressAsync.when(
                    data: (progress) {
                      final percent = progress?.percentComplete ?? 0.0;
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 12,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(percent * 100).toInt()}% Complete',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${progress?.topicsCompleted.length ?? 0} Checkpoints Mastered',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error loading progress: $e'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Checkpoint & Module Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: modulesAsync.when(
                      data: (modules) {
                        if (modules.isEmpty) {
                          return const Center(
                            child: Text(
                              'No modules configured.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: modules.length,
                          itemBuilder: (context, mIdx) {
                            final m = modules[mIdx];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    m.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                ...m.topics.map((t) {
                                  final isCompleted =
                                      progressAsync.valueOrNull?.topicsCompleted
                                          .containsKey(t.id) ??
                                      false;
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons
                                                .radio_button_unchecked_rounded,
                                      color: isCompleted
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                      size: 18,
                                    ),
                                    title: Text(
                                      t.title,
                                      style: TextStyle(
                                        color: isCompleted
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }),
                                const Divider(),
                              ],
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.admin => AppColors.error,
      UserRole.developer => Theme.of(context).colorScheme.primary,
      UserRole.lead => AppColors.accent,
      UserRole.member => AppColors.secondary,
    };
  }
}

final _membersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final db = ref.watch(databaseRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  if (user.role == UserRole.lead) {
    final domainsAsync = ref.watch(domainsProvider);
    return domainsAsync.when(
      data: (domains) {
        final ledDomainIds = domains
            .where((d) => d.leadUserIds.contains(user.uid))
            .map((d) => d.id)
            .toList();

        return db.getMembers().map((membersList) {
          return membersList.where((m) {
            return m.role == UserRole.member &&
                m.domainsFollowing.any((dId) => ledDomainIds.contains(dId));
          }).toList();
        });
      },
      loading: () => const Stream.empty(),
      error: (e, s) => const Stream.empty(),
    );
  }

  return db.getMembers();
});

final _pastMembersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getPastMembers();
});

// ── Broadcast Tab ──────────────────────────────────────────────────────────────
class _BroadcastTab extends ConsumerStatefulWidget {
  const _BroadcastTab();

  @override
  ConsumerState<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends ConsumerState<_BroadcastTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audienceType = 'all';
  String _audienceValue = '';
  bool _isSending = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final user = ref.read(currentUserProvider);
    final bc = BroadcastModel(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      audienceType: _audienceType,
      audienceValue: _audienceValue,
      sentBy: user?.name ?? 'Admin',
      sentAt: DateTime.now(),
      readBy: [],
    );

    try {
      await ref.read(databaseRepositoryProvider).createBroadcast(bc);
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Compose Broadcast',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title_rounded, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.message_outlined, size: 20),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Target Audience',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('All'),
                  icon: Icon(Icons.groups),
                ),
                ButtonSegment(
                  value: 'domain',
                  label: Text('Domain'),
                  icon: Icon(Icons.map_outlined),
                ),
                ButtonSegment(
                  value: 'batch',
                  label: Text('Batch'),
                  icon: Icon(Icons.school_outlined),
                ),
              ],
              selected: {_audienceType},
              onSelectionChanged: (sel) =>
                  setState(() => _audienceType = sel.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
                  }
                  return AppColors.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.primary;
                  }
                  return AppColors.textMuted;
                }),
              ),
            ),
            if (_audienceType != 'all') ...[
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: _audienceType == 'domain'
                      ? 'Domain ID (e.g. dsa)'
                      : 'Batch (e.g. Batch of 2026)',
                  prefixIcon: const Icon(Icons.filter_list_rounded, size: 20),
                ),
                onChanged: (v) => _audienceValue = v.trim(),
              ),
            ],
            const SizedBox(height: 28),
            _isSending
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sendBroadcast,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text('Send Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Broadcast History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, _) {
                final user = ref.watch(currentUserProvider);
                if (user == null) return const SizedBox.shrink();

                final broadcastsAsync = ref.watch(broadcastsProvider);
                return broadcastsAsync.when(
                  data: (broadcasts) {
                    if (broadcasts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No broadcast history found.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: broadcasts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final bc = broadcasts[idx];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bc.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bc.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Target: ${bc.audienceType.toUpperCase()} | By ${bc.sentBy}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                tooltip: 'Delete Broadcast',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: const Text('Delete Broadcast?'),
                                      content: Text(
                                        'Are you sure you want to delete "${bc.title}"?',
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

                                  if (confirm == true && context.mounted) {
                                    await ref
                                        .read(databaseRepositoryProvider)
                                        .deleteBroadcast(bc.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Broadcast deleted'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading history: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Roadmap Editor Tab ──────────────────────────────────────────────────────
class _RoadmapEditorTab extends ConsumerStatefulWidget {
  const _RoadmapEditorTab();

  @override
  ConsumerState<_RoadmapEditorTab> createState() => _RoadmapEditorTabState();
}

class _RoadmapEditorTabState extends ConsumerState<_RoadmapEditorTab> {
  final _domainIdCtrl = TextEditingController();
  final _domainNameCtrl = TextEditingController();
  final _domainDescCtrl = TextEditingController();
  final _domainPasswordCtrl = TextEditingController();
  List<String> _selectedLeadIds = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _domainIdCtrl.dispose();
    _domainNameCtrl.dispose();
    _domainDescCtrl.dispose();
    _domainPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createDomain() async {
    if (_domainIdCtrl.text.isEmpty || _domainNameCtrl.text.isEmpty) return;
    setState(() => _isCreating = true);

    final user = ref.read(currentUserProvider);
    final domain = DomainModel(
      id: _domainIdCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
      name: _domainNameCtrl.text.trim(),
      description: _domainDescCtrl.text.trim(),
      leadUserIds: _selectedLeadIds.isNotEmpty ? _selectedLeadIds : (user != null ? [user.uid] : []),
      password: _domainPasswordCtrl.text.trim(),
      modules: [],
    );

    try {
      await ref.read(databaseRepositoryProvider).createDomain(domain);
      _domainIdCtrl.clear();
      _domainNameCtrl.clear();
      _domainDescCtrl.clear();
      _domainPasswordCtrl.clear();
      setState(() => _selectedLeadIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Domain created!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _bulkGenerateDomains() async {
    setState(() => _isCreating = true);
    final db = ref.read(databaseRepositoryProvider);

    final techDomains = [
      DomainModel(
        id: 'cyber_security',
        name: 'Cyber Security Track',
        description:
            'Learn ethical hacking, network security, penetration testing, and cryptography.',
        leadUserIds: [],
        password: '',
        modules: [],
      ),
      DomainModel(
        id: 'cloud_computing',
        name: 'Cloud Infrastructure',
        description:
            'Master AWS, Google Cloud, Docker, Kubernetes, and modern DevOps practices.',
        leadUserIds: ['user_adm001'],
        password: '',
        modules: [],
      ),
      DomainModel(
        id: 'blockchain',
        name: 'Web3 & Blockchain',
        description:
            'Explore Ethereum, solidity smart contracts, decentralized apps, and cryptography.',
        leadUserIds: ['user_adm001'],
        password: '',
        modules: [],
      ),
    ];

    try {
      for (final domain in techDomains) {
        await db.createDomain(domain);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bulk Domains (Cyber, Cloud, Blockchain) generated successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk generation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showDomainDetailSheet(
    BuildContext context,
    WidgetRef ref,
    DomainModel domain,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DomainDetailEditorSheet(domain: domain),
    );
  }

  void _confirmDeleteDomain(BuildContext context, DomainModel domain) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete domain?'),
        content: Text(
          'Delete ${domain.name}, all its modules, topics, and resource links? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _confirmAdminPassword(
                context,
                ref,
                title: 'Confirm domain deletion',
                message:
                    'Enter your admin password to permanently delete ${domain.name}.',
                onConfirmed: () async {
                  await ref
                      .read(databaseRepositoryProvider)
                      .deleteDomain(domain.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${domain.name} deleted.')),
                    );
                  }
                },
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDomainDialog(
      BuildContext context, WidgetRef ref, DomainModel domain) {
    final nameCtrl = TextEditingController(text: domain.name);
    final descCtrl = TextEditingController(text: domain.description);
    final passCtrl = TextEditingController(text: domain.password);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Edit Domain Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Domain Name',
                    prefixIcon: Icon(Icons.label_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Domain Password (Optional)',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedName = nameCtrl.text.trim();
                final updatedDesc = descCtrl.text.trim();
                final updatedPass = passCtrl.text.trim();

                if (updatedName.isEmpty) return;

                Navigator.pop(dialogContext);
                final updatedDomain = domain.copyWith(
                  name: updatedName,
                  description: updatedDesc,
                  password: updatedPass,
                );
                await ref
                    .read(databaseRepositoryProvider)
                    .updateDomain(updatedDomain);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$updatedName updated.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAssignLeadDialog(
      BuildContext context, WidgetRef ref, DomainModel domain) {
    List<String> selectedLeadIds = List.from(domain.leadUserIds);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Assign Leads to ${domain.name}'),
              content: ref.watch(_membersStreamProvider).when(
                    data: (members) {
                      final leadsList = members
                          .where(
                            (m) =>
                                m.role == UserRole.lead ||
                                m.role == UserRole.admin ||
                                m.role == UserRole.developer,
                          )
                          .toList();
                      
                      return SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: leadsList.length,
                          itemBuilder: (context, index) {
                            final m = leadsList[index];
                            final isSelected = selectedLeadIds.contains(m.uid);
                            return CheckboxListTile(
                              title: Text('${m.name} (${m.role.name.toUpperCase()})'),
                              value: isSelected,
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    selectedLeadIds.add(m.uid);
                                  } else {
                                    selectedLeadIds.remove(m.uid);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, s) => Text('Error loading leads: $e'),
                  ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    final updatedDomain =
                        domain.copyWith(leadUserIds: selectedLeadIds);
                    await ref
                        .read(databaseRepositoryProvider)
                        .updateDomain(updatedDomain);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Leads updated for ${domain.name}.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdminOrDev =
        user?.role == UserRole.admin || user?.role == UserRole.developer;
    final domainsAsync = ref.watch(domainsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAdminOrDev) ...[
            Text(
              'Create New Domain',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _domainIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Domain ID (slug)',
                hintText: 'e.g. cyber_security',
                prefixIcon: Icon(Icons.key_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _domainNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Domain Name',
                hintText: 'e.g. Cyber Security',
                prefixIcon: Icon(Icons.label_outline, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _domainDescCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.description_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _domainPasswordCtrl,
              decoration: const InputDecoration(
                labelText: 'Domain Password (Optional)',
                hintText: 'Enter access password for members',
                prefixIcon: Icon(Icons.lock_outline, size: 20),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            ref
                .watch(_membersStreamProvider)
                .when(
                  data: (members) {
                    final leadsList = members
                        .where(
                          (m) =>
                              m.role == UserRole.lead ||
                              m.role == UserRole.admin ||
                              m.role == UserRole.developer,
                        )
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign Leads', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: leadsList.map((m) {
                            final isSelected = _selectedLeadIds.contains(m.uid);
                            return FilterChip(
                              label: Text(m.name),
                              selected: isSelected,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedLeadIds.add(m.uid);
                                  } else {
                                    _selectedLeadIds.remove(m.uid);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error loading leads: $e'),
                ),
            const SizedBox(height: 16),
            _isCreating
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _createDomain,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Create Domain'),
                      ),
                      if (user?.role == UserRole.developer) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _bulkGenerateDomains,
                          icon: Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text('Bulk Generate Domains (Dev Only)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
            const SizedBox(height: 28),
          ],
          Text(
            'Existing Domains',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          domainsAsync.when(
            data: (domains) {
              final editable = isAdminOrDev
                  ? domains
                  : domains.where((d) => d.leadUserIds.contains(user?.uid)).toList();

              if (editable.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No assigned domains for your account.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }

              return Column(
                children: editable
                    .map(
                      (d) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _showDomainDetailSheet(context, ref, d),
                          title: Text(
                            d.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            d.id,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          trailing: isAdminOrDev
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit Details',
                                      onPressed: () =>
                                          _showEditDomainDialog(context, ref, d),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Assign Lead',
                                      onPressed: () =>
                                          _showAssignLeadDialog(context, ref, d),
                                      icon: const Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete domain',
                                      onPressed: () =>
                                          _confirmDeleteDomain(context, d),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                )
                              : const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

// ── Domain Detail Editor Sheet ───────────────────────────────────────────────
class _DomainDetailEditorSheet extends ConsumerStatefulWidget {
  final DomainModel domain;
  const _DomainDetailEditorSheet({required this.domain});

  @override
  ConsumerState<_DomainDetailEditorSheet> createState() =>
      _DomainDetailEditorSheetState();
}

class _DomainDetailEditorSheetState extends ConsumerState<_DomainDetailEditorSheet> {
  final _moduleTitleCtrl = TextEditingController();
  final _youtubeLinkCtrl = TextEditingController();
  final _documentLinkCtrl = TextEditingController();
  final _resourceLinkCtrl = TextEditingController();

  void _addModule() async {
    final title = _moduleTitleCtrl.text.trim();
    if (title.isEmpty) return;

    try {
      final db = ref.read(databaseRepositoryProvider);
      final moduleId =
          'mod_${title.toLowerCase().replaceAll(' ', '_')}_${const Uuid().v4().substring(0, 4)}';
      final newModule = ModuleModel(
        id: moduleId,
        domainId: widget.domain.id,
        title: title,
        order: 1,
        topics: [],
        resources: [
          if (_youtubeLinkCtrl.text.trim().isNotEmpty)
            ResourceModel(
              title: 'YouTube lecture',
              url: _youtubeLinkCtrl.text.trim(),
              type: 'video',
            ),
          if (_documentLinkCtrl.text.trim().isNotEmpty)
            ResourceModel(
              title: 'Document / notes',
              url: _documentLinkCtrl.text.trim(),
              type: 'doc',
            ),
          if (_resourceLinkCtrl.text.trim().isNotEmpty)
            ResourceModel(
              title: 'Additional resource',
              url: _resourceLinkCtrl.text.trim(),
              type: 'link',
            ),
        ],
      );
      await db.createModule(widget.domain.id, newModule);
      ref.invalidate(modulesProvider(widget.domain.id));
      _moduleTitleCtrl.clear();
      _youtubeLinkCtrl.clear();
      _documentLinkCtrl.clear();
      _resourceLinkCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Module added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding module: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddModuleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Add New Module'),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => BulkModuleUploadDialog(
                    domainId: widget.domain.id,
                    domainName: widget.domain.name,
                  ),
                );
              },
              icon: const Icon(Icons.file_upload_outlined, size: 16, color: Color(0xFF10B981)),
              label: const Text(
                'Bulk JSON',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => BulkModuleUploadDialog(
                      domainId: widget.domain.id,
                      domainName: widget.domain.name,
                    ),
                  );
                },
                icon: const Icon(Icons.file_upload_outlined, size: 18),
                label: const Text('Or Upload Bulk Modules (JSON)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR MANUALLY', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _moduleTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Module Title',
                  hintText: 'e.g. Introduction to Arrays',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _youtubeLinkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'YouTube lecture link (optional)',
                  prefixIcon: Icon(Icons.play_circle_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentLinkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Document / notes link (optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _resourceLinkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Other resource link (optional)',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addModule, child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _deleteModule(ModuleModel m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Module?'),
        content: Text('Are you sure you want to delete "${m.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      )
    );
    if (confirm != true) return;

    try {
      final db = ref.read(databaseRepositoryProvider);
      await db.deleteModule(widget.domain.id, m.id);
      ref.invalidate(modulesProvider(widget.domain.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Module deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showEditModuleDialog(ModuleModel m) {
    _moduleTitleCtrl.text = m.title;
    _youtubeLinkCtrl.text = m.resources.where((r) => r.type == 'video').firstOrNull?.url ?? '';
    _documentLinkCtrl.text = m.resources.where((r) => r.type == 'doc').firstOrNull?.url ?? '';
    _resourceLinkCtrl.text = m.resources.where((r) => r.type == 'link').firstOrNull?.url ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Module'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _moduleTitleCtrl,
                decoration: const InputDecoration(labelText: 'Module Title'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _youtubeLinkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'YouTube link', prefixIcon: Icon(Icons.play_circle_outline)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentLinkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Document link', prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _resourceLinkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Other resource link', prefixIcon: Icon(Icons.link_rounded)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () { _moduleTitleCtrl.clear(); _youtubeLinkCtrl.clear(); _documentLinkCtrl.clear(); _resourceLinkCtrl.clear(); Navigator.pop(context); }, child: const Text('Cancel')),
          ElevatedButton(onPressed: () => _submitEditModule(m), child: const Text('Save')),
        ],
      ),
    );
  }

  void _submitEditModule(ModuleModel m) async {
    final title = _moduleTitleCtrl.text.trim();
    if (title.isEmpty) return;

    try {
      final db = ref.read(databaseRepositoryProvider);
      final updatedModule = m.copyWith(
        title: title,
        resources: [
          if (_youtubeLinkCtrl.text.trim().isNotEmpty)
            ResourceModel(title: 'YouTube lecture', url: _youtubeLinkCtrl.text.trim(), type: 'video'),
          if (_documentLinkCtrl.text.trim().isNotEmpty)
            ResourceModel(title: 'Document / notes', url: _documentLinkCtrl.text.trim(), type: 'doc'),
          if (_resourceLinkCtrl.text.trim().isNotEmpty)
            ResourceModel(title: 'Additional resource', url: _resourceLinkCtrl.text.trim(), type: 'link'),
        ],
      );
      await db.updateModule(widget.domain.id, updatedModule);
      ref.invalidate(modulesProvider(widget.domain.id));
      _moduleTitleCtrl.clear();
      _youtubeLinkCtrl.clear();
      _documentLinkCtrl.clear();
      _resourceLinkCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Module updated!'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _showAddTopicSheet(ModuleModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddTopicWithQuizForm(
        domainId: widget.domain.id,
        module: m,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(modulesProvider(widget.domain.id));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.domain.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Roadmap Modules & Verification Quizzes',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modules',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => BulkModuleUploadDialog(
                            domainId: widget.domain.id,
                            domainName: widget.domain.name,
                          ),
                        );
                      },
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: const Text('Bulk JSON'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddModuleDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Module'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: modulesAsync.when(
                data: (modules) {
                  if (modules.isEmpty) {
                    return const Center(
                      child: Text(
                        'No modules created yet. Add a module to start building!',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final m = modules[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showEditModuleDialog(m),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                                onPressed: () => _deleteModule(m),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          subtitle: Text(
                            'ID: ${m.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.all(12),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Topics',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showAddTopicSheet(m),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text(
                                    'Add Topic & Quiz',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Consumer(
                              builder: (context, ref, _) {
                                final topicsAsync = ref.watch(
                                  topicsProvider((
                                    domainId: widget.domain.id,
                                    moduleId: m.id,
                                  )),
                                );

                                return topicsAsync.when(
                                  data: (topics) {
                                    if (topics.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          'No topics created yet in this module.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: topics.map((t) {
                                        final quizCount = t.quizQuestions.isNotEmpty
                                            ? t.quizQuestions.length
                                            : (QuizDatabase.registry[t.id]?.length ?? 0);
                                        return ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            t.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            quizCount > 0
                                                ? 'Verified with $quizCount Quiz Questions'
                                                : 'No custom quiz (using fallback)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: quizCount > 0 ? AppColors.success : AppColors.textMuted,
                                              fontWeight: quizCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                          leading: const Icon(
                                            Icons.menu_book_rounded,
                                            size: 18,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                                label: Text(
                                                  quizCount > 0 ? 'Edit Quiz' : 'Set Quiz',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                onPressed: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor: AppColors.surface,
                                                    shape: const RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                                    ),
                                                    builder: (ctx) => _EditTopicWithQuizForm(
                                                      domainId: widget.domain.id,
                                                      moduleId: m.id,
                                                      topic: t,
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () => _confirmDeleteTopic(
                                                  context,
                                                  ref,
                                                  widget.domain.id,
                                                  m.id,
                                                  t.id,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (e, s) => Text('Error: $e'),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Topic with Quiz Form Stateful Widget ─────────────────────────────────
class _AddTopicWithQuizForm extends ConsumerStatefulWidget {
  final String domainId;
  final ModuleModel module;
  const _AddTopicWithQuizForm({
    required this.domainId,
    required this.module,
  });

  @override
  ConsumerState<_AddTopicWithQuizForm> createState() => _AddTopicWithQuizFormState();
}

class _AddTopicWithQuizFormState extends ConsumerState<_AddTopicWithQuizForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  // Quiz Q1
  final _q1Ctrl = TextEditingController();
  final _q1OptACtrl = TextEditingController();
  final _q1OptBCtrl = TextEditingController();
  final _q1OptCCtrl = TextEditingController();
  int _q1Correct = 0;

  // Quiz Q2
  final _q2Ctrl = TextEditingController();
  final _q2OptACtrl = TextEditingController();
  final _q2OptBCtrl = TextEditingController();
  final _q2OptCCtrl = TextEditingController();
  int _q2Correct = 0;

  // Quiz Q3
  final _q3Ctrl = TextEditingController();
  final _q3OptACtrl = TextEditingController();
  final _q3OptBCtrl = TextEditingController();
  final _q3OptCCtrl = TextEditingController();
  int _q3Correct = 0;

  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _q1Ctrl.dispose();
    _q1OptACtrl.dispose();
    _q1OptBCtrl.dispose();
    _q1OptCCtrl.dispose();
    _q2Ctrl.dispose();
    _q2OptACtrl.dispose();
    _q2OptBCtrl.dispose();
    _q2OptCCtrl.dispose();
    _q3Ctrl.dispose();
    _q3OptACtrl.dispose();
    _q3OptBCtrl.dispose();
    _q3OptCCtrl.dispose();
    super.dispose();
  }

  void _saveTopic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final db = ref.read(databaseRepositoryProvider);
      final topicId =
          'top_${_titleCtrl.text.toLowerCase().replaceAll(' ', '_')}_${const Uuid().v4().substring(0, 4)}';

      final quizQuestions = [
        QuizQuestionModel(
          question: _q1Ctrl.text.trim(),
          options: [
            _q1OptACtrl.text.trim(),
            _q1OptBCtrl.text.trim(),
            _q1OptCCtrl.text.trim(),
          ],
          correctIndex: _q1Correct,
        ),
        QuizQuestionModel(
          question: _q2Ctrl.text.trim(),
          options: [
            _q2OptACtrl.text.trim(),
            _q2OptBCtrl.text.trim(),
            _q2OptCCtrl.text.trim(),
          ],
          correctIndex: _q2Correct,
        ),
        QuizQuestionModel(
          question: _q3Ctrl.text.trim(),
          options: [
            _q3OptACtrl.text.trim(),
            _q3OptBCtrl.text.trim(),
            _q3OptCCtrl.text.trim(),
          ],
          correctIndex: _q3Correct,
        ),
      ];

      final newTopic = TopicModel(
        id: topicId,
        moduleId: widget.module.id,
        title: _titleCtrl.text.trim(),
        order: 1,
        resources: [],
        quizQuestions: quizQuestions,
      );

      // Register Quiz Questions in Registry for legacy fallback
      QuizDatabase.registry[topicId] = quizQuestions
          .map((q) => QuizQuestion(
                question: q.question,
                options: q.options,
                correctIndex: q.correctIndex,
              ))
          .toList();

      await db.createTopic(widget.domainId, widget.module.id, newTopic);
      ref.invalidate(
        topicsProvider((domainId: widget.domainId, moduleId: widget.module.id)),
      );

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Topic and custom Checkpoint Quiz created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error saving topic: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Topic & Verification Quiz',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'Add a roadmap checkpoint with 3 validation questions to verify user completion.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const Divider(height: 24),

                // Topic Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Topic Title',
                    hintText: 'e.g. Master Binary Search',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter topic title'
                      : null,
                ),
                const SizedBox(height: 20),

                // --- Question 1 ---
                Text(
                  'Quiz Question 1',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _q1Ctrl,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter question text'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _q1OptACtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option A',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option A' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q1OptBCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option B',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option B' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q1OptCCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option C',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option C' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _q1Correct,
                  decoration: const InputDecoration(
                    labelText: 'Correct Option Index',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Option A')),
                    DropdownMenuItem(value: 1, child: Text('Option B')),
                    DropdownMenuItem(value: 2, child: Text('Option C')),
                  ],
                  onChanged: (v) => setState(() => _q1Correct = v!),
                ),
                const SizedBox(height: 24),

                // --- Question 2 ---
                Text(
                  'Quiz Question 2',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _q2Ctrl,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter question text'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _q2OptACtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option A',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option A' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q2OptBCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option B',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option B' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q2OptCCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option C',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option C' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _q2Correct,
                  decoration: const InputDecoration(
                    labelText: 'Correct Option Index',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Option A')),
                    DropdownMenuItem(value: 1, child: Text('Option B')),
                    DropdownMenuItem(value: 2, child: Text('Option C')),
                  ],
                  onChanged: (v) => setState(() => _q2Correct = v!),
                ),
                const SizedBox(height: 24),

                // --- Question 3 ---
                Text(
                  'Quiz Question 3',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _q3Ctrl,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter question text'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _q3OptACtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option A',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option A' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q3OptBCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option B',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option B' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q3OptCCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option C',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option C' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _q3Correct,
                  decoration: const InputDecoration(
                    labelText: 'Correct Option Index',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Option A')),
                    DropdownMenuItem(value: 1, child: Text('Option B')),
                    DropdownMenuItem(value: 2, child: Text('Option C')),
                  ],
                  onChanged: (v) => setState(() => _q3Correct = v!),
                ),
                const SizedBox(height: 32),

                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveTopic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Topic & Quiz'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _confirmDeleteTopic(
  BuildContext context,
  WidgetRef ref,
  String domainId,
  String moduleId,
  String topicId,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Topic?'),
      content: const Text('Are you sure you want to delete this topic and its quiz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            final db = ref.read(databaseRepositoryProvider);
            await db.deleteTopic(domainId, moduleId, topicId);
            ref.invalidate(
              topicsProvider((domainId: domainId, moduleId: moduleId)),
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ── Edit Topic with Quiz Form Stateful Widget ─────────────────────────────────
class _EditTopicWithQuizForm extends ConsumerStatefulWidget {
  final String domainId;
  final String moduleId;
  final TopicModel topic;

  const _EditTopicWithQuizForm({
    required this.domainId,
    required this.moduleId,
    required this.topic,
  });

  @override
  ConsumerState<_EditTopicWithQuizForm> createState() =>
      _EditTopicWithQuizFormState();
}

class _EditTopicWithQuizFormState
    extends ConsumerState<_EditTopicWithQuizForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;

  // Quiz Q1
  final _q1Ctrl = TextEditingController();
  final _q1OptACtrl = TextEditingController();
  final _q1OptBCtrl = TextEditingController();
  final _q1OptCCtrl = TextEditingController();
  int _q1Correct = 0;

  // Quiz Q2
  final _q2Ctrl = TextEditingController();
  final _q2OptACtrl = TextEditingController();
  final _q2OptBCtrl = TextEditingController();
  final _q2OptCCtrl = TextEditingController();
  int _q2Correct = 0;

  // Quiz Q3
  final _q3Ctrl = TextEditingController();
  final _q3OptACtrl = TextEditingController();
  final _q3OptBCtrl = TextEditingController();
  final _q3OptCCtrl = TextEditingController();
  int _q3Correct = 0;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.topic.title);

    List<QuizQuestionModel> questions = List.from(widget.topic.quizQuestions);
    if (questions.isEmpty &&
        QuizDatabase.registry.containsKey(widget.topic.id)) {
      questions = QuizDatabase.registry[widget.topic.id]!
          .map((q) => QuizQuestionModel(
                question: q.question,
                options: q.options,
                correctIndex: q.correctIndex,
              ))
          .toList();
    }

    if (questions.isNotEmpty) {
      _q1Ctrl.text = questions[0].question;
      if (questions[0].options.isNotEmpty) {
        _q1OptACtrl.text = questions[0].options[0];
      }
      if (questions[0].options.length > 1) {
        _q1OptBCtrl.text = questions[0].options[1];
      }
      if (questions[0].options.length > 2) {
        _q1OptCCtrl.text = questions[0].options[2];
      }
      _q1Correct = questions[0].correctIndex.clamp(0, 2);
    }
    if (questions.length > 1) {
      _q2Ctrl.text = questions[1].question;
      if (questions[1].options.isNotEmpty) {
        _q2OptACtrl.text = questions[1].options[0];
      }
      if (questions[1].options.length > 1) {
        _q2OptBCtrl.text = questions[1].options[1];
      }
      if (questions[1].options.length > 2) {
        _q2OptCCtrl.text = questions[1].options[2];
      }
      _q2Correct = questions[1].correctIndex.clamp(0, 2);
    }
    if (questions.length > 2) {
      _q3Ctrl.text = questions[2].question;
      if (questions[2].options.isNotEmpty) {
        _q3OptACtrl.text = questions[2].options[0];
      }
      if (questions[2].options.length > 1) {
        _q3OptBCtrl.text = questions[2].options[1];
      }
      if (questions[2].options.length > 2) {
        _q3OptCCtrl.text = questions[2].options[2];
      }
      _q3Correct = questions[2].correctIndex.clamp(0, 2);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _q1Ctrl.dispose();
    _q1OptACtrl.dispose();
    _q1OptBCtrl.dispose();
    _q1OptCCtrl.dispose();
    _q2Ctrl.dispose();
    _q2OptACtrl.dispose();
    _q2OptBCtrl.dispose();
    _q2OptCCtrl.dispose();
    _q3Ctrl.dispose();
    _q3OptACtrl.dispose();
    _q3OptBCtrl.dispose();
    _q3OptCCtrl.dispose();
    super.dispose();
  }

  void _saveTopic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final db = ref.read(databaseRepositoryProvider);

      final quizQuestions = [
        QuizQuestionModel(
          question: _q1Ctrl.text.trim(),
          options: [
            _q1OptACtrl.text.trim(),
            _q1OptBCtrl.text.trim(),
            _q1OptCCtrl.text.trim(),
          ],
          correctIndex: _q1Correct,
        ),
        QuizQuestionModel(
          question: _q2Ctrl.text.trim(),
          options: [
            _q2OptACtrl.text.trim(),
            _q2OptBCtrl.text.trim(),
            _q2OptCCtrl.text.trim(),
          ],
          correctIndex: _q2Correct,
        ),
        QuizQuestionModel(
          question: _q3Ctrl.text.trim(),
          options: [
            _q3OptACtrl.text.trim(),
            _q3OptBCtrl.text.trim(),
            _q3OptCCtrl.text.trim(),
          ],
          correctIndex: _q3Correct,
        ),
      ];

      final updatedTopic = widget.topic.copyWith(
        title: _titleCtrl.text.trim(),
        quizQuestions: quizQuestions,
      );

      // Register Quiz Questions in Registry for legacy fallback
      QuizDatabase.registry[widget.topic.id] = quizQuestions
          .map((q) => QuizQuestion(
                question: q.question,
                options: q.options,
                correctIndex: q.correctIndex,
              ))
          .toList();

      await db.updateTopic(widget.domainId, widget.moduleId, updatedTopic);
      ref.invalidate(
        topicsProvider((domainId: widget.domainId, moduleId: widget.moduleId)),
      );

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Custom quiz updated for "${updatedTopic.title}"!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error updating topic: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Topic & Verification Quiz',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'Set or update the 3 checkpoint validation questions for this topic.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const Divider(height: 24),

                // Topic Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Topic Title',
                    hintText: 'e.g. Master Binary Search',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter topic title' : null,
                ),
                const SizedBox(height: 20),

                // --- Question 1 ---
                Text(
                  'Quiz Question 1',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _q1Ctrl,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter question text' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _q1OptACtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option A',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option A' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q1OptBCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option B',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option B' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q1OptCCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option C',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option C' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _q1Correct,
                  decoration: const InputDecoration(
                    labelText: 'Correct Option Index',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Option A')),
                    DropdownMenuItem(value: 1, child: Text('Option B')),
                    DropdownMenuItem(value: 2, child: Text('Option C')),
                  ],
                  onChanged: (v) => setState(() => _q1Correct = v!),
                ),
                const SizedBox(height: 24),

                // --- Question 2 ---
                Text(
                  'Quiz Question 2',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _q2Ctrl,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter question text' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _q2OptACtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option A',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option A' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q2OptBCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option B',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option B' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q2OptCCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option C',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option C' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _q2Correct,
                  decoration: const InputDecoration(
                    labelText: 'Correct Option Index',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Option A')),
                    DropdownMenuItem(value: 1, child: Text('Option B')),
                    DropdownMenuItem(value: 2, child: Text('Option C')),
                  ],
                  onChanged: (v) => setState(() => _q2Correct = v!),
                ),
                const SizedBox(height: 24),

                // --- Question 3 ---
                Text(
                  'Quiz Question 3',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _q3Ctrl,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter question text' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _q3OptACtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option A',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option A' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q3OptBCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option B',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option B' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _q3OptCCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Option C',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Option C' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _q3Correct,
                  decoration: const InputDecoration(
                    labelText: 'Correct Option Index',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Option A')),
                    DropdownMenuItem(value: 1, child: Text('Option B')),
                    DropdownMenuItem(value: 2, child: Text('Option C')),
                  ],
                  onChanged: (v) => setState(() => _q3Correct = v!),
                ),
                const SizedBox(height: 32),

                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveTopic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Update Topic & Quiz'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Analytics Tab ────────────────────────────────────────────────────────────
class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(_membersStreamProvider);
    final domainsAsync = ref.watch(domainsProvider);
    final user = ref.watch(currentUserProvider);

    return membersAsync.when(
      data: (members) {
        final totalMembers = members.length;
        final totalStreak = members.fold(0, (sum, m) => sum + m.streak.count);
        final averageStreak = totalMembers > 0
            ? (totalStreak / totalMembers).toStringAsFixed(1)
            : '0';

        final now = DateTime.now();
        final List<int> dailyActiveCounts = List.filled(7, 0);
        // Build a map of weekdayIndex -> ISO date string for the past 7 days
        // Mon=0 ... Sun=6 (matching DateTime.weekday - 1)
        final weekDates = <int, String>{};
        for (int i = 0; i < 7; i++) {
          final d = now.subtract(Duration(days: i));
          final iso = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final weekdayIdx = d.weekday - 1; // Mon=0..Sun=6
          weekDates[weekdayIdx] = iso;
        }

        for (final m in members) {
          for (final entry in weekDates.entries) {
            if (m.streak.activityDays.contains(entry.value)) {
              dailyActiveCounts[entry.key]++;
            }
          }
        }
        
        final weeklySpots = List.generate(7, (index) {
          return FlSpot(index.toDouble(), dailyActiveCounts[index].toDouble());
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary cards row
              Row(
                children: [
                  Expanded(
                    child: _AnalyticsCard(
                      title: 'Total Members',
                      value: '$totalMembers',
                      icon: Icons.groups_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticsCard(
                      title: 'Avg. Streak',
                      value: '$averageStreak days',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weekly active engagement line chart
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Active Members',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Active logins and activities logged over past 7 days.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  const days = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  if (value >= 0 && value < days.length) {
                                    return Text(
                                      days[value.toInt()],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: weeklySpots,
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context).colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 500), // animated
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Domain Popularity Bar Chart
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enrolled Members per Domain',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    domainsAsync.when(
                      data: (allDomains) {
                        final domains = user?.role == UserRole.lead
                            ? allDomains
                                  .where((d) => d.leadUserIds.contains(user?.uid))
                                  .toList()
                            : allDomains;
                        // Aggregate enrolments
                        final domainCounts = <String, int>{};
                        for (final m in members) {
                          for (final d in m.domainsFollowing) {
                            domainCounts[d] = (domainCounts[d] ?? 0) + 1;
                          }
                        }

                        final labels = domains
                            .map((d) => d.name.split(' ').first)
                            .toList();
                        final values = domains
                            .map((d) => (domainCounts[d.id] ?? 0).toDouble())
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 160,
                              child: BarChart(
                                BarChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 22,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          if (value >= 0 &&
                                              value < labels.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Text(
                                                labels[value.toInt()],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(
                                    values.length,
                                    (i) => BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: values[i],
                                          color: AppColors.secondary,
                                          width: 16,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading members stats: $e')),
    );
  }
}

// ── Analytics Summary Card Widget ───────────────────────────────────────────
class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Admissions & Profile Update Requests Tab ─────────────────────────────────
final _requestsStreamProvider = StreamProvider<List<AccessRequestModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getAccessRequests();
});

final _profileUpdateRequestsStreamProvider =
    StreamProvider<List<ProfileUpdateRequestModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getProfileUpdateRequests();
});

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(_requestsStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admission requests section
        requestsAsync.when(
          data: (requests) {
            final pending =
                requests.where((r) => r.status == 'pending').toList();
            final processed =
                requests.where((r) => r.status != 'pending').toList();

            if (requests.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No admission requests found.'),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pending.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Pending Admissions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  ...pending.map((r) => _buildRequestCard(context, ref, r)),
                  const SizedBox(height: 20),
                ],
                if (processed.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Processed Admissions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  ...processed.map((r) => _buildRequestCard(context, ref, r)),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) => Center(child: Text('Error loading requests: $e')),
        ),
      ],
    );
  }

  static Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    AccessRequestModel r,
  ) {
    final isPending = r.status == 'pending';
    final statusColor = r.status == 'approved'
        ? AppColors.success
        : r.status == 'rejected'
        ? AppColors.error
        : AppColors.accent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Father: ${r.fatherName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Phone: ${r.phoneNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Personal: ${r.personalEmail}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'KIET: ${r.kietEmail}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Passing Year / Batch: ${r.batch.startsWith('Batch of ') ? r.batch.replaceFirst('Batch of ', '') : r.batch}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Aadhar: ${r.aadharNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (r.githubId.isNotEmpty)
                    Text(
                      'GitHub: ${r.githubId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (r.linkedinId.isNotEmpty)
                    Text(
                      'LinkedIn: ${r.linkedinId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (r.instagramId.isNotEmpty)
                    Text(
                      'Instagram: ${r.instagramId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    'Requested Role: ${r.requestedRole.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    'Domains: ${r.domainInterest.join(', ').toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showApproveDialog(context, ref, r),
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 28,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          await _confirmAdminPassword(
                            context,
                            ref,
                            title: 'Confirm request rejection',
                            message:
                                'Enter your admin password to reject ${r.name}\'s admission request.',
                            onConfirmed: () async {
                              await ref
                                  .read(databaseRepositoryProvider)
                                  .rejectAccessRequest(r.id);
                              ref.invalidate(_requestsStreamProvider);
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.error,
                          size: 28,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _showApproveDialog(
    BuildContext context,
    WidgetRef ref,
    AccessRequestModel r,
  ) {
    final clubIdCtrl = TextEditingController(
      text: r.kietEmail.split('@').first.toUpperCase(),
    );
    final passwordCtrl = TextEditingController(text: 'password');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        title: const Text(
          'Approve Admission',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set credentials for ${r.name}:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: clubIdCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Club ID',
                hintText: 'e.g. KML2026001',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Initial Password',
                hintText: 'password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pass = passwordCtrl.text.trim();
              final clubId = clubIdCtrl.text.trim().toUpperCase();
              if (!RegExp(r'^[A-Z0-9_-]{4,30}$').hasMatch(clubId)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Club ID must use 4–30 letters, numbers, _ or -.',
                    ),
                  ),
                );
                return;
              }
              if (pass.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await ref
                    .read(databaseRepositoryProvider)
                    .approveAccessRequest(r.id, r.kietEmail, clubId, pass);
                ref.invalidate(_requestsStreamProvider);
                ref.invalidate(_membersStreamProvider);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Admitted ${r.name} successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e, stackTrace) {
                print('Approval Error: $e');
                print('Stack trace: $stackTrace');
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to admit: $e', maxLines: 3),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 10),
                  ),
                );
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}

class _ProfileRequestsTab extends ConsumerWidget {
  const _ProfileRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileReqsAsync = ref.watch(_profileUpdateRequestsStreamProvider);

    return profileReqsAsync.when(
      data: (pReqs) {
        final pending = pReqs.where((r) => r.status == 'pending').toList();
        final processed = pReqs.where((r) => r.status != 'pending').toList();

        if (pReqs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.manage_accounts_outlined,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 12),
                Text(
                  'No profile edit requests found.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.pending_actions_rounded,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pending Requests (${pending.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              ...pending.map((pr) => _buildProfileRequestCard(context, ref, pr)),
              const SizedBox(height: 20),
            ],
            if (processed.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Processed Requests (${processed.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              ...processed.map((pr) => _buildProfileRequestCard(context, ref, pr)),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) => Center(child: Text('Error loading profile requests: $e')),
    );
  }

  static Widget _buildProfileRequestCard(
    BuildContext context,
    WidgetRef ref,
    ProfileUpdateRequestModel pr,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showProfileRequestDetailsDialog(context, ref, pr),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Avatar
              AppAvatar(
                photoUrl: pr.requestedPhotoUrl,
                name: pr.requestedName,
                radius: 25,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pr.requestedName.isNotEmpty ? pr.requestedName : pr.currentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Club ID: ${pr.clubId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Passing Year / Batch: ${pr.requestedBatch.startsWith('Batch of ') ? pr.requestedBatch.replaceFirst('Batch of ', '') : pr.requestedBatch}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (pr.requestedBio.isNotEmpty)
                      Text(
                        'Bio: ${pr.requestedBio}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.touch_app_rounded, size: 12, color: AppColors.accent),
                        SizedBox(width: 4),
                        Text(
                          'Tap to view before & after changes',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (pr.status == 'approved'
                              ? AppColors.success
                              : pr.status == 'rejected'
                                  ? AppColors.error
                                  : AppColors.accent)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pr.status.toUpperCase(),
                      style: TextStyle(
                        color: pr.status == 'approved'
                            ? AppColors.success
                            : pr.status == 'rejected'
                                ? AppColors.error
                                : AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  if (pr.status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(databaseRepositoryProvider)
                                  .approveProfileUpdateRequest(pr.id);
                              ref.invalidate(_profileUpdateRequestsStreamProvider);
                              ref.invalidate(_membersStreamProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Profile update for ${pr.requestedName} approved! 🎉',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to approve: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 28,
                          ),
                          tooltip: 'Approve changes',
                        ),
                        IconButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(databaseRepositoryProvider)
                                  .rejectProfileUpdateRequest(pr.id);
                              ref.invalidate(_profileUpdateRequestsStreamProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile update rejected.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to reject: $e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.cancel_rounded,
                            color: AppColors.error,
                            size: 28,
                          ),
                          tooltip: 'Reject changes',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showProfileRequestDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    ProfileUpdateRequestModel pr,
  ) {
    Widget buildDiffRow(String label, String oldVal, String newVal) {
      final isChanged = oldVal.trim() != newVal.trim();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isChanged
                            ? AppColors.error.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      oldVal.isEmpty ? '(Not Set)' : oldVal,
                      style: TextStyle(
                        fontSize: 12,
                        color: oldVal.isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: isChanged ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.accent),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isChanged
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isChanged ? AppColors.success : AppColors.border,
                      ),
                    ),
                    child: Text(
                      newVal.isEmpty ? '(Not Set)' : newVal,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isChanged ? FontWeight.bold : FontWeight.normal,
                        color: isChanged ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

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
            const Icon(Icons.compare_arrows_rounded, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Changes for ${pr.requestedName.isNotEmpty ? pr.requestedName : pr.currentName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header legend
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'CURRENT / BEFORE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    SizedBox(width: 32),
                    Expanded(
                      child: Text(
                        'REQUESTED / AFTER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Avatar compare
                if (pr.currentPhotoUrl != pr.requestedPhotoUrl) ...[
                  const Text(
                    'Profile Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          AppAvatar(
                            photoUrl: pr.currentPhotoUrl,
                            name: pr.currentName,
                            radius: 25,
                          ),
                          const SizedBox(height: 4),
                          const Text('Original',
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.accent),
                      Column(
                        children: [
                          AppAvatar(
                            photoUrl: pr.requestedPhotoUrl,
                            name: pr.requestedName,
                            radius: 25,
                          ),
                          const SizedBox(height: 4),
                          const Text('New Photo',
                              style: TextStyle(fontSize: 10, color: AppColors.success)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                buildDiffRow('Full Name', pr.currentName, pr.requestedName),
                buildDiffRow('Batch / Group', pr.currentBatch, pr.requestedBatch),
                buildDiffRow('Bio', pr.currentBio, pr.requestedBio),
                buildDiffRow('GitHub', pr.currentGithubId, pr.requestedGithubId),
                buildDiffRow('LinkedIn', pr.currentLinkedinId, pr.requestedLinkedinId),
                buildDiffRow('Instagram', pr.currentInstagramId, pr.requestedInstagramId),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          if (pr.status == 'pending') ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(databaseRepositoryProvider)
                      .rejectProfileUpdateRequest(pr.id);
                  ref.invalidate(_profileUpdateRequestsStreamProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile update rejected.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to reject: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.cancel_rounded, size: 16),
              label: const Text('Reject'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(databaseRepositoryProvider)
                      .approveProfileUpdateRequest(pr.id);
                  ref.invalidate(_profileUpdateRequestsStreamProvider);
                  ref.invalidate(_membersStreamProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Profile update for ${pr.requestedName} approved! 🎉',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to approve: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Approve'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    AccessRequestModel r,
  ) {
    final isPending = r.status == 'pending';
    final statusColor = r.status == 'approved'
        ? AppColors.success
        : r.status == 'rejected'
        ? AppColors.error
        : AppColors.accent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Father: ${r.fatherName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Phone: ${r.phoneNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Personal: ${r.personalEmail}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'KIET: ${r.kietEmail}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Passing Year / Batch: ${r.batch.startsWith('Batch of ') ? r.batch.replaceFirst('Batch of ', '') : r.batch}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Aadhar: ${r.aadharNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (r.githubId.isNotEmpty)
                    Text(
                      'GitHub: ${r.githubId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (r.linkedinId.isNotEmpty)
                    Text(
                      'LinkedIn: ${r.linkedinId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (r.instagramId.isNotEmpty)
                    Text(
                      'Instagram: ${r.instagramId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    'Requested Role: ${r.requestedRole.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    'Domains: ${r.domainInterest.join(', ').toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showApproveDialog(context, ref, r),
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 28,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          await _confirmAdminPassword(
                            context,
                            ref,
                            title: 'Confirm request rejection',
                            message:
                                'Enter your admin password to reject ${r.name}\'s admission request.',
                            onConfirmed: () async {
                              await ref
                                  .read(databaseRepositoryProvider)
                                  .rejectAccessRequest(r.id);
                              ref.invalidate(_requestsStreamProvider);
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.error,
                          size: 28,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    WidgetRef ref,
    AccessRequestModel r,
  ) {
    final clubIdCtrl = TextEditingController(
      text: r.kietEmail.split('@').first.toUpperCase(),
    );
    final passwordCtrl = TextEditingController(text: 'password');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        title: const Text(
          'Approve Admission',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set credentials for ${r.name}:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: clubIdCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Club ID',
                hintText: 'e.g. KML2026001',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Initial Password',
                hintText: 'password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pass = passwordCtrl.text.trim();
              final clubId = clubIdCtrl.text.trim().toUpperCase();
              if (!RegExp(r'^[A-Z0-9_-]{4,30}$').hasMatch(clubId)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Club ID must use 4–30 letters, numbers, _ or -.',
                    ),
                  ),
                );
                return;
              }
              if (pass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await ref
                    .read(databaseRepositoryProvider)
                    .approveAccessRequest(r.id, r.kietEmail, clubId, pass);
                ref.invalidate(_requestsStreamProvider);
                ref.invalidate(_membersStreamProvider);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Admitted ${r.name} successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e, stackTrace) {
                print('Approval Error: $e');
                print('Stack trace: $stackTrace');
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to admit: $e', maxLines: 3),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 10),
                  ),
                );
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}

// ── Team Requests Tab ────────────────────────────────────────────────────────
class _TeamRequestsTab extends ConsumerWidget {
  const _TeamRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamRequestsAsync = ref.watch(teamRequestsProvider);

    return teamRequestsAsync.when(
      data: (requests) {
        final pending = requests.where((r) => r.status == 'pending').toList();
        final processed = requests.where((r) => r.status != 'pending').toList();

        if (requests.isEmpty) {
          return const Center(child: Text('No team requests found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Pending Approvals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...pending.map((r) => _buildTeamRequestCard(context, ref, r)),
              const SizedBox(height: 16),
            ],
            if (processed.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Processed Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              ...processed.map((r) => _buildTeamRequestCard(context, ref, r)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading requests: $e')),
    );
  }

  Widget _buildTeamRequestCard(BuildContext context, WidgetRef ref, TeamRequestModel req) {
    final isPending = req.status == 'pending';
    
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  req.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: req.status == 'pending' ? Colors.orange.withOpacity(0.2) : (req.status == 'approved' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  req.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: req.status == 'pending' ? Colors.orange : (req.status == 'approved' ? Colors.green : Colors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('By: ${req.creatorName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(req.purpose, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: req.techStack.map((tech) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: Text(
                tech,
                style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('Needs ${req.membersNeeded} members', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          if (isPending) ...[
            const Divider(height: 24, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(databaseRepositoryProvider).updateTeamRequestStatus(req.id, 'rejected');
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                  onPressed: () async {
                    await ref.read(databaseRepositoryProvider).updateTeamRequestStatus(req.id, 'approved');
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

// ── Hackathons Tab ────────────────────────────────────────────────────────────

class _HackathonsAdminTab extends ConsumerWidget {
  const _HackathonsAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingHackathonsAsync = ref.watch(pendingHackathonsProvider);

    return pendingHackathonsAsync.when(
      data: (hackathons) {
        if (hackathons.isEmpty) {
          return const Center(
            child: Text(
              'No pending hackathon requests.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hackathons.length,
          itemBuilder: (context, index) {
            final h = hackathons[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      h.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (h.participatingLink != null && h.participatingLink!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final trimmed = h.participatingLink!.trim();
                          String finalUrl = trimmed.startsWith('http') ? trimmed : 'https://$trimmed';
                          try {
                            final uri = Uri.parse(finalUrl);
                            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                              await launchUrl(uri, mode: LaunchMode.platformDefault);
                            }
                          } catch (_) {}
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Link: ${h.participatingLink}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await ref
                                  .read(databaseRepositoryProvider)
                                  .updateHackathonStatus(h.id, 'rejected');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Hackathon request rejected.')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await ref
                                  .read(databaseRepositoryProvider)
                                  .updateHackathonStatus(h.id, 'approved');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hackathon request approved!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

