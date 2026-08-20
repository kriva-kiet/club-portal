import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/hackathon_model.dart';
import '../../models/session_model.dart';
import '../../services/service_providers.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glowing_card.dart';
import '../../core/localization/app_localizations.dart';

class CollaborationScreen extends ConsumerStatefulWidget {
  const CollaborationScreen({super.key});

  @override
  ConsumerState<CollaborationScreen> createState() =>
      _CollaborationScreenState();
}

class _CollaborationScreenState extends ConsumerState<CollaborationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.hub_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)?.translate('collab_title') ??
                        'Collaboration',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Sessions'),
                Tab(text: 'Hackathons'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_SessionsTab(), _HackathonsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sessions Tab ──────────────────────────────────────────────────────────────
class _SessionsTab extends ConsumerWidget {
  const _SessionsTab();

  static const _domainIcons = {
    'dsa': Icons.data_array_rounded,
    'web_dev': Icons.web_rounded,
    'ml': Icons.psychology_rounded,
  };

  static const _domainColors = {
    'dsa': AppColors.primary,
    'web_dev': AppColors.secondary,
    'ml': AppColors.success,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final user = ref.watch(currentUserProvider);
    final isLeadOrAdmin =
        user != null &&
        (user.role == UserRole.lead ||
            user.role == UserRole.admin ||
            user.role == UserRole.developer);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isLeadOrAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showScheduleSessionSheet(context, ref, user),
              label: const Text('Schedule Class'),
              icon: const Icon(Icons.add_rounded),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                'No interactive sessions scheduled yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          // Sort: upcoming first, past sessions at the bottom
          final now = DateTime.now();
          final upcoming = sessions
              .where((s) => s.dateTime.isAfter(now))
              .toList();
          final past = sessions.where((s) => s.dateTime.isBefore(now)).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Upcoming Sessions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ...upcoming.map(
                  (session) => _buildSessionCard(
                    context,
                    ref,
                    session,
                    user,
                    isPast: false,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (past.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Past Sessions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                ...past.map(
                  (session) => _buildSessionCard(
                    context,
                    ref,
                    session,
                    user,
                    isPast: true,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading sessions: $e')),
      ),
    );
  }

  void _showScheduleSessionSheet(
    BuildContext context,
    WidgetRef ref,
    UserModel? host,
  ) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String selectedDomain = 'web_dev';
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Schedule New Session',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Session Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDomain,
                    decoration: const InputDecoration(
                      labelText: 'Domain Tag',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'dsa',
                        child: Text('Data Structures & Algorithms'),
                      ),
                      DropdownMenuItem(
                        value: 'web_dev',
                        child: Text('Web Development'),
                      ),
                      DropdownMenuItem(
                        value: 'ml',
                        child: Text('Machine Learning'),
                      ),
                    ],
                    onChanged: (val) => setState(() => selectedDomain = val!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_month,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null && context.mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              selectedDateTime,
                            ),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: const Text('Pick Time'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: linkCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Link (Jitsi / Meet)',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty || linkCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter Title and Meeting Link',
                            ),
                          ),
                        );
                        return;
                      }
                      final newSession = SessionModel(
                        id: 'sess_${const Uuid().v4().substring(0, 8)}',
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        domainTag: selectedDomain,
                        dateTime: selectedDateTime,
                        link: linkCtrl.text.trim(),
                        createdBy: host?.name ?? 'Lead/Educator',
                        rsvps: [],
                        attendees: [],
                      );
                      Navigator.pop(context);
                      await ref
                          .read(databaseRepositoryProvider)
                          .createSession(newSession);
                      ref.invalidate(sessionsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Class session scheduled successfully!',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: const Text('Schedule Class'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    SessionModel session,
    UserModel? currentUser, {
    required bool isPast,
  }) {
    final domainColor = _domainColors[session.domainTag] ?? AppColors.primary;
    final domainIcon = _domainIcons[session.domainTag] ?? Icons.event_rounded;
    final hasRsvpd =
        currentUser != null && session.rsvps.contains(currentUser.uid);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: domainColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: domainColor.withValues(alpha: 0.3)),
                ),
                child: Icon(domainIcon, color: domainColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPast
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: isPast ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Host: ${session.createdBy}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPast)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: domainColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session.domainTag.toUpperCase(),
                    style: TextStyle(
                      color: domainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM dd, hh:mm a').format(session.dateTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '${session.rsvps.length} RSVP${session.rsvps.length == 1 ? "" : "s"}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (!isPast && currentUser != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(databaseRepositoryProvider)
                          .toggleRSVP(currentUser.uid, session.id, !hasRsvpd);
                    },
                    icon: Icon(
                      hasRsvpd ? Icons.check_circle : Icons.add_alert_rounded,
                      size: 16,
                      color: hasRsvpd
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    label: Text(
                      hasRsvpd ? 'RSVP\'d (Going)' : 'RSVP',
                      style: TextStyle(
                        color: hasRsvpd
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: hasRsvpd
                            ? AppColors.success.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                      backgroundColor: hasRsvpd
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to Jitsi/Google Meet link
                    },
                    icon: const Icon(Icons.video_call_rounded, size: 18),
                    label: const Text('Join Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hackathons Tab ────────────────────────────────────────────────────────────
class _HackathonsTab extends ConsumerStatefulWidget {
  const _HackathonsTab();

  @override
  ConsumerState<_HackathonsTab> createState() => _HackathonsTabState();
}

class _HackathonsTabState extends ConsumerState<_HackathonsTab> {
  String? _selectedHackathonId;

  void _showCreateTeamDialog(
    BuildContext context,
    String hackathonId,
    String myUid,
  ) {
    final nameController = TextEditingController();
    final skillsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Create Hackathon Team',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  hintText: 'e.g. Code Commandos',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: skillsController,
                decoration: const InputDecoration(
                  labelText: 'Required Skills (comma separated)',
                  hintText: 'e.g. Flutter, UI/UX, Firebase',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final skills = skillsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final team = TeamModel(
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  leadUid: myUid,
                  memberUids: [myUid],
                  requiredSkills: skills,
                  pendingRequests: [],
                  status: 'open',
                );

                await ref
                    .read(databaseRepositoryProvider)
                    .createTeam(hackathonId, team);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hackathonsAsync = ref.watch(hackathonsProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Center(child: CircularProgressIndicator());

    return hackathonsAsync.when(
      data: (hackathons) {
        if (hackathons.isEmpty) {
          return const Center(
            child: Text(
              'No active hackathons at the moment.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        // Set default selection
        _selectedHackathonId ??= hackathons.first.id;

        final currentHackathon = hackathons.firstWhere(
          (h) => h.id == _selectedHackathonId,
        );
        final teamsAsync = ref.watch(teamsProvider(_selectedHackathonId!));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hackathon Details Glowing Card
              GlowingCard(
                glowColor: AppColors.accent,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.accent,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentHackathon.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentHackathon.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.date_range_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Starts: ${DateFormat('MMM dd, yyyy').format(currentHackathon.startDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.groups_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Max Team Size: ${currentHackathon.teamSizeLimit}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Teams Roster',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCreateTeamDialog(
                      context,
                      currentHackathon.id,
                      user.uid,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Create Team'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              teamsAsync.when(
                data: (teams) {
                  if (teams.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text(
                          'No teams formed yet. Be the first to create one!',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: teams.map((team) {
                      final isLead = team.leadUid == user.uid;
                      final isMember = team.memberUids.contains(user.uid);
                      final hasRequested = team.pendingRequests.contains(
                        user.uid,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      team.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: team.status == 'open'
                                          ? AppColors.success.withValues(
                                              alpha: 0.15,
                                            )
                                          : AppColors.error.withValues(
                                              alpha: 0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      team.status.toUpperCase(),
                                      style: TextStyle(
                                        color: team.status == 'open'
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Members: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Expanded(
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final membersAsync = ref.watch(
                                          membersStreamProvider,
                                        );
                                        return membersAsync.when(
                                          data: (allMembers) {
                                            final rosterNames = allMembers
                                                .where(
                                                  (m) => team.memberUids
                                                      .contains(m.uid),
                                                )
                                                .map((m) => m.name)
                                                .join(', ');
                                            return Text(
                                              rosterNames.isEmpty
                                                  ? 'Loading roster...'
                                                  : rosterNames,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            );
                                          },
                                          loading: () => const Text(
                                            '...',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          error: (e, s) => const Text(
                                            'Error loading names',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: team.requiredSkills
                                    .map(
                                      (skill) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          skill,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const Divider(height: 24),
                              if (isLead) ...[
                                // Show Join Requests Approval Flow
                                if (team.pendingRequests.isEmpty)
                                  const Text(
                                    'No pending join requests',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else ...[
                                  const Text(
                                    'Pending Join Requests:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final membersAsync = ref.watch(
                                        membersStreamProvider,
                                      );
                                      return membersAsync.when(
                                        data: (allMembers) {
                                          final pendingUsers = allMembers
                                              .where(
                                                (m) => team.pendingRequests
                                                    .contains(m.uid),
                                              )
                                              .toList();
                                          return Column(
                                            children: pendingUsers.map((pUser) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12,
                                                      backgroundImage:
                                                          pUser
                                                              .photoUrl
                                                              .isNotEmpty
                                                          ? NetworkImage(
                                                              pUser.photoUrl,
                                                            )
                                                          : null,
                                                      child:
                                                          pUser.photoUrl.isEmpty
                                                          ? const Icon(
                                                              Icons.person,
                                                              size: 10,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        pUser.name,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        ref
                                                            .read(
                                                              databaseRepositoryProvider,
                                                            )
                                                            .manageJoinRequest(
                                                              currentHackathon
                                                                  .id,
                                                              team.id,
                                                              pUser.uid,
                                                              true, // approve
                                                            );
                                                      },
                                                      icon: const Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color:
                                                            AppColors.success,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        ref
                                                            .read(
                                                              databaseRepositoryProvider,
                                                            )
                                                            .manageJoinRequest(
                                                              currentHackathon
                                                                  .id,
                                                              team.id,
                                                              pUser.uid,
                                                              false, // reject
                                                            );
                                                      },
                                                      icon: const Icon(
                                                        Icons.cancel_rounded,
                                                        color: AppColors.error,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                        loading: () =>
                                            const LinearProgressIndicator(),
                                        error: (e, s) => const Text(
                                          'Error loading requests',
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ] else if (isMember) ...[
                                const Center(
                                  child: Text(
                                    'You are a member of this team 🎉',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        (hasRequested || team.status == 'full')
                                        ? null
                                        : () {
                                            ref
                                                .read(
                                                  databaseRepositoryProvider,
                                                )
                                                .requestToJoinTeam(
                                                  currentHackathon.id,
                                                  team.id,
                                                  user.uid,
                                                );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasRequested
                                          ? AppColors.surfaceLight
                                          : AppColors.primary,
                                    ),
                                    child: Text(
                                      hasRequested
                                          ? 'Join Request Pending'
                                          : 'Request to Join',
                                      style: TextStyle(
                                        color: hasRequested
                                            ? AppColors.textMuted
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error loading teams: $e')),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading hackathons: $e')),
    );
  }
}

final membersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getMembers();
});
