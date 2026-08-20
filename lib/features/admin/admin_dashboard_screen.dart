import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_providers.dart';
import '../../models/broadcast_model.dart';
import '../../models/domain_model.dart';
import '../../models/user_model.dart';
import '../../models/access_request_model.dart';
import '../roadmap/roadmap_detail_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdminOrDev =
        user?.role == UserRole.admin || user?.role == UserRole.developer;
    final tabsCount = isAdminOrDev ? 5 : 4;

    if (_tabController.length != tabsCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabsCount, vsync: this);
    }

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
                        color: AppColors.primary.withValues(alpha: 0.3),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              isScrollable: true,
              tabs: [
                const Tab(text: 'Members'),
                if (isAdminOrDev) const Tab(text: 'Requests'),
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
class _MembersTab extends ConsumerWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(_membersStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final domains = ref.watch(domainsProvider).valueOrNull ?? [];
    final ledDomain = domains.firstWhere(
      (d) => d.leadUserId == currentUser?.uid,
      orElse: () => DomainModel(
        id: '',
        name: '',
        description: '',
        leadUserId: '',
        password: '',
        modules: [],
      ),
    );

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return const Center(child: Text('No members found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final m = members[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (currentUser?.role == UserRole.lead) {
                    _showStudentProgressSheet(context, ref, m, ledDomain);
                  } else {
                    _showRoleSheet(context, ref, m);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: m.photoUrl.isNotEmpty
                            ? NetworkImage(m.photoUrl)
                            : null,
                        backgroundColor: AppColors.surfaceLight,
                        child: m.photoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage Member Role',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Select role for ${member.name}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const Divider(height: 24),
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
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(databaseRepositoryProvider)
                      .updateUserRole(member.uid, role);

                  // Also force local refresh if using mock state
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
                ref.read(currentUserProvider)?.role == UserRole.developer) ...[
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
            ],
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel member,
  ) {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set new password for ${member.name}:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: '••••••••',
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
              final newPass = passwordCtrl.text.trim();
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await ref
                  .read(databaseRepositoryProvider)
                  .changeUserPassword(member.uid, newPass);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Password reset successfully for ${member.name}!',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
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
                      CircleAvatar(
                        backgroundImage: student.photoUrl.isNotEmpty
                            ? NetworkImage(student.photoUrl)
                            : null,
                        radius: 24,
                        child: student.photoUrl.isEmpty
                            ? const Icon(Icons.person, size: 24)
                            : null,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
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
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, s) => Text('Error loading progress: $e'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Checkpoint & Module Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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
                                  final isCompleted = progressAsync.valueOrNull
                                          ?.topicsCompleted
                                          .containsKey(t.id) ??
                                      false;
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
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
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
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
      UserRole.developer => AppColors.primary,
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
            .where((d) => d.leadUserId == user.uid)
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
                    return AppColors.primary.withValues(alpha: 0.2);
                  }
                  return AppColors.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
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
                    label: const Text('Send Broadcast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
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
  String? _selectedLeadId;
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
      leadUserId: _selectedLeadId ?? user?.uid ?? '',
      password: _domainPasswordCtrl.text.trim(),
      modules: [],
    );

    try {
      await ref.read(databaseRepositoryProvider).createDomain(domain);
      _domainIdCtrl.clear();
      _domainNameCtrl.clear();
      _domainDescCtrl.clear();
      _domainPasswordCtrl.clear();
      setState(() => _selectedLeadId = null);
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
        description: 'Learn ethical hacking, network security, penetration testing, and cryptography.',
        leadUserId: 'user_led001',
        password: 'hackme123',
        modules: [],
      ),
      DomainModel(
        id: 'cloud_computing',
        name: 'Cloud Infrastructure',
        description: 'Master AWS, Google Cloud, Docker, Kubernetes, and modern DevOps practices.',
        leadUserId: 'user_adm001',
        password: '',
        modules: [],
      ),
      DomainModel(
        id: 'blockchain',
        name: 'Web3 & Blockchain',
        description: 'Explore Ethereum, solidity smart contracts, decentralized apps, and cryptography.',
        leadUserId: 'user_adm001',
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
            content: Text('Bulk Domains (Cyber, Cloud, Blockchain) generated successfully!'),
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
      builder: (context) => _DomainDetailEditorSheet(domain: domain, ref: ref),
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
            ref.watch(_membersStreamProvider).when(
                  data: (members) {
                    final leadsList = members
                        .where((m) =>
                            m.role == UserRole.lead ||
                            m.role == UserRole.admin ||
                            m.role == UserRole.developer)
                        .toList();
                    return DropdownButtonFormField<String>(
                      value: _selectedLeadId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Lead',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      dropdownColor: AppColors.surface,
                      items: leadsList.map((m) {
                        return DropdownMenuItem<String>(
                          value: m.uid,
                          child: Text('${m.name} (${m.role.name.toUpperCase()})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedLeadId = val);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
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
                          icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                          label: const Text('Bulk Generate Domains (Dev Only)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
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
                  : domains
                        .where((d) => d.leadUserId == user?.uid)
                        .toList();

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
                          trailing: const Icon(
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
class _DomainDetailEditorSheet extends StatefulWidget {
  final DomainModel domain;
  final WidgetRef ref;
  const _DomainDetailEditorSheet({required this.domain, required this.ref});

  @override
  State<_DomainDetailEditorSheet> createState() =>
      _DomainDetailEditorSheetState();
}

class _DomainDetailEditorSheetState extends State<_DomainDetailEditorSheet> {
  final _moduleTitleCtrl = TextEditingController();

  void _addModule() async {
    final title = _moduleTitleCtrl.text.trim();
    if (title.isEmpty) return;

    try {
      final db = widget.ref.read(databaseRepositoryProvider);
      final moduleId =
          'mod_${title.toLowerCase().replaceAll(' ', '_')}_${const Uuid().v4().substring(0, 4)}';
      final newModule = ModuleModel(
        id: moduleId,
        domainId: widget.domain.id,
        title: title,
        order: 1,
        topics: [],
      );
      await db.createModule(widget.domain.id, newModule);
      widget.ref.invalidate(modulesProvider(widget.domain.id));
      _moduleTitleCtrl.clear();
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
        title: const Text('Add New Module'),
        content: TextFormField(
          controller: _moduleTitleCtrl,
          decoration: const InputDecoration(
            labelText: 'Module Title',
            hintText: 'e.g. Introduction to Arrays',
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
        ref: widget.ref,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = widget.ref.watch(modulesProvider(widget.domain.id));
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
                TextButton.icon(
                  onPressed: _showAddModuleDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Module'),
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
                          title: Text(
                            m.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                        final quizCount =
                                            QuizDatabase
                                                .registry[t.id]
                                                ?.length ??
                                            0;
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
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          leading: const Icon(
                                            Icons.menu_book_rounded,
                                            size: 18,
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
class _AddTopicWithQuizForm extends StatefulWidget {
  final String domainId;
  final ModuleModel module;
  final WidgetRef ref;
  const _AddTopicWithQuizForm({
    required this.domainId,
    required this.module,
    required this.ref,
  });

  @override
  State<_AddTopicWithQuizForm> createState() => _AddTopicWithQuizFormState();
}

class _AddTopicWithQuizFormState extends State<_AddTopicWithQuizForm> {
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
      final db = widget.ref.read(databaseRepositoryProvider);
      final topicId =
          'top_${_titleCtrl.text.toLowerCase().replaceAll(' ', '_')}_${const Uuid().v4().substring(0, 4)}';

      final newTopic = TopicModel(
        id: topicId,
        moduleId: widget.module.id,
        title: _titleCtrl.text.trim(),
        order: 1,
        resources: [],
      );

      // Register Quiz Questions in Registry
      QuizDatabase.registry[topicId] = [
        QuizQuestion(
          question: _q1Ctrl.text.trim(),
          options: [
            _q1OptACtrl.text.trim(),
            _q1OptBCtrl.text.trim(),
            _q1OptCCtrl.text.trim(),
          ],
          correctIndex: _q1Correct,
        ),
        QuizQuestion(
          question: _q2Ctrl.text.trim(),
          options: [
            _q2OptACtrl.text.trim(),
            _q2OptBCtrl.text.trim(),
            _q2OptCCtrl.text.trim(),
          ],
          correctIndex: _q2Correct,
        ),
        QuizQuestion(
          question: _q3Ctrl.text.trim(),
          options: [
            _q3OptACtrl.text.trim(),
            _q3OptBCtrl.text.trim(),
            _q3OptCCtrl.text.trim(),
          ],
          correctIndex: _q3Correct,
        ),
      ];

      await db.createTopic(widget.domainId, widget.module.id, newTopic);
      widget.ref.invalidate(
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
                const Text(
                  'Quiz Question 1',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                const Text(
                  'Quiz Question 2',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                const Text(
                  'Quiz Question 3',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                          backgroundColor: AppColors.primary,
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
                      color: AppColors.primary,
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
                              spots: const [
                                FlSpot(0, 12),
                                FlSpot(1, 18),
                                FlSpot(2, 15),
                                FlSpot(3, 24),
                                FlSpot(4, 28),
                                FlSpot(5, 20),
                                FlSpot(6, 32),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(
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
                            ? allDomains.where((d) => d.leadUserId == user?.uid).toList()
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

// ── Admissions Requests Tab ──────────────────────────────────────────────────
final _requestsStreamProvider = StreamProvider<List<AccessRequestModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getAccessRequests();
});

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(_requestsStreamProvider);

    return requestsAsync.when(
      data: (requests) {
        final pending = requests.where((r) => r.status == 'pending').toList();
        final processed = requests.where((r) => r.status != 'pending').toList();

        if (requests.isEmpty) {
          return const Center(child: Text('No admission requests found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Pending Requests',
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
                  'Processed Requests',
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading requests: $e')),
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
                    'Aadhar: ${r.aadharNumber}',
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                          await ref
                              .read(databaseRepositoryProvider)
                              .rejectAccessRequest(r.id);
                          ref.invalidate(_requestsStreamProvider);
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
            Text(
              'Email (Club ID): ${r.kietEmail}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
              if (pass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await ref
                  .read(databaseRepositoryProvider)
                  .approveAccessRequest(r.id, r.kietEmail, pass);
              ref.invalidate(_requestsStreamProvider);
              ref.invalidate(_membersStreamProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Admitted ${r.name} successfully!'),
                    backgroundColor: AppColors.success,
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
