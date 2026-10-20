import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/hackathon_model.dart';
import '../../models/session_model.dart';
import '../../models/team_request_model.dart';
import '../../services/service_providers.dart';
import '../../services/notification_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glowing_card.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/linkable_text.dart';
import '../../core/localization/app_localizations.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeColor = user?.role == UserRole.lead
        ? AppColors.success
        : user?.role == UserRole.admin || user?.role == UserRole.developer
            ? AppColors.error
            : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Icon(
                    Icons.hub_rounded,
                    color: themeColor,
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
              indicatorColor: themeColor,
              labelColor: themeColor,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Sessions'),
                Tab(text: 'Hackathons'),
                Tab(text: 'Teams'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const _SessionsTab(),
                  _HackathonsTab(
                    onNavigateToTeams: () {
                      _tabController.animateTo(2);
                    },
                  ),
                  const _TeamsTab(),
                ],
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



  void _showAttendanceQR(BuildContext context, SessionModel session) {
    final code = session.id.substring(5, 11).toUpperCase();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Attendance QR', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 200.0,
                  height: 200.0,
                  child: QrImageView(
                    data: 'attendance:${session.id}',
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Or enter code manually:', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMarkAttendanceDialog(BuildContext context, WidgetRef ref, SessionModel session, UserModel user) {
    final codeCtrl = TextEditingController();
    bool isScanning = false;
    final expectedCode = session.id.substring(5, 11).toUpperCase();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Mark Attendance', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isScanning)
                    SizedBox(
                      height: 250,
                      width: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _ScannerWidget(
                          onDetect: (value) async {
                            if (value == 'attendance:${session.id}') {
                              Navigator.pop(context);
                              await ref.read(databaseRepositoryProvider).markAttendance(session.id, user.uid);
                              ref.invalidate(sessionsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked successfully! 🎉'), backgroundColor: AppColors.success));
                              }
                            }
                          },
                        ),
                      ),
                    )
                  else ...[
                    ElevatedButton.icon(
                      onPressed: () => setState(() => isScanning = true),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('OR', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-digit Code',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (codeCtrl.text.trim().toUpperCase() == expectedCode) {
                          Navigator.pop(context);
                          await ref.read(databaseRepositoryProvider).markAttendance(session.id, user.uid);
                          ref.invalidate(sessionsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked successfully! 🎉'), backgroundColor: AppColors.success));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: const Text('Submit Code'),
                    ),
                  ],
                ],
              ),
              actions: [
                if (isScanning)
                  TextButton(
                    onPressed: () => setState(() => isScanning = false),
                    child: const Text('Back'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    WidgetRef ref,
    SessionModel session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Scheduled Class'),
        content: Text(
          'Are you sure you want to delete "${session.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(databaseRepositoryProvider).deleteSession(session.id);
        ref.invalidate(sessionsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scheduled class deleted successfully! 🗑️'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete scheduled class: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

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
              heroTag: 'sessions_fab',
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
    final venueCtrl = TextEditingController();
    final Set<String> selectedDomains = {'web_dev'};
    String targetRole = 'both'; // 'both', 'member', 'lead'
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));
    bool isOnline = true;

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
                  const Text(
                    'Target Domains (Select multiple):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      {'id': 'dsa', 'name': 'Data Structures & Algorithms'},
                      {'id': 'web_dev', 'name': 'Web Development'},
                      {'id': 'ml', 'name': 'Machine Learning'},
                      {'id': 'mobile', 'name': 'Mobile App Dev'},
                      {'id': 'cloud', 'name': 'Cloud & DevOps'},
                      {'id': 'general', 'name': 'All / General'},
                    ].map((domain) {
                      final isSelected = selectedDomains.contains(domain['id']);
                      return FilterChip(
                        label: Text(
                          domain['name']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              selectedDomains.add(domain['id']!);
                            } else {
                              if (selectedDomains.length > 1) {
                                selectedDomains.remove(domain['id']!);
                              }
                            }
                          });
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Target Audience / Role:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Both (Members & Leads)'),
                        selected: targetRole == 'both',
                        onSelected: (val) => setState(() => targetRole = 'both'),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      ChoiceChip(
                        label: const Text('Members Only'),
                        selected: targetRole == 'member',
                        onSelected: (val) => setState(() => targetRole = 'member'),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      ChoiceChip(
                        label: const Text('Leads Only'),
                        selected: targetRole == 'lead',
                        onSelected: (val) => setState(() => targetRole = 'lead'),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ],
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
                  Row(
                    children: [
                      const Text('Class Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('Online'),
                        selected: isOnline,
                        onSelected: (val) => setState(() => isOnline = true),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Offline'),
                        selected: !isOnline,
                        onSelected: (val) => setState(() => isOnline = false),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isOnline)
                    TextFormField(
                      controller: linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Link (Jitsi / Meet)',
                        prefixIcon: Icon(Icons.link),
                      ),
                    )
                  else
                    TextFormField(
                      controller: venueCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Venue / Room Location',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty ||
                          (isOnline ? linkCtrl.text.isEmpty : venueCtrl.text.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please fill in all required fields',
                            ),
                          ),
                        );
                        return;
                      }
                      final newSession = SessionModel(
                        id: 'sess_${const Uuid().v4().substring(0, 8)}',
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        domainTag: selectedDomains.first,
                        domainTags: selectedDomains.toList(),
                        targetRole: targetRole,
                        dateTime: selectedDateTime,
                        link: isOnline ? linkCtrl.text.trim() : '',
                        venue: isOnline ? '' : venueCtrl.text.trim(),
                        isOnline: isOnline,
                        createdBy: host?.name ?? 'Lead/Educator',
                        rsvps: [],
                        attendees: [],
                      );
                      Navigator.pop(context);
                      await ref
                          .read(databaseRepositoryProvider)
                          .createSession(newSession);
                      ref.invalidate(sessionsProvider);

                      // Trigger scheduled class notification
                      await NotificationService.showSessionNotification(
                        title: newSession.title,
                        body: newSession.description.isNotEmpty
                            ? newSession.description
                            : 'A new class session has been scheduled for ${DateFormat('MMM dd, hh:mm a').format(newSession.dateTime)}.',
                      );
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

                    final isLeadOrAdmin = currentUser != null &&
                        (currentUser.role == UserRole.lead ||
                            currentUser.role == UserRole.admin ||
                            currentUser.role == UserRole.developer);

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
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: session.allDomainTags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: domainColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '#${tag.toUpperCase()}',
                                        style: TextStyle(
                                          color: domainColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              if (isLeadOrAdmin) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  tooltip: 'Delete Scheduled Class',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmDeleteSession(context, ref, session),
                                ),
                              ],
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
                    onPressed: () async {
                      try {
                        await ref
                            .read(databaseRepositoryProvider)
                            .toggleRSVP(currentUser.uid, session.id, !hasRsvpd);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to RSVP: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      hasRsvpd ? Icons.check_circle : Icons.add_alert_rounded,
                      size: 16,
                      color: hasRsvpd
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    label: Text(
                      hasRsvpd ? 'RSVP\'d' : 'RSVP',
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
                  child: session.isOnline
                      ? ElevatedButton.icon(
                          onPressed: () => _launchExternalUrl(context, session.link),
                          icon: const Icon(Icons.video_call_rounded, size: 18),
                          label: const Text('Join Room'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  session.venue.isNotEmpty ? session.venue : 'TBD',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            if (currentUser != null && !isPast) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final isLeadOrAdmin = currentUser.role == UserRole.lead ||
                      currentUser.role == UserRole.admin ||
                      currentUser.role == UserRole.developer;
                  final hasAttended = session.attendees.contains(currentUser.uid);

                  if (isLeadOrAdmin) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showAttendanceQR(context, session),
                                icon: const Icon(Icons.qr_code, size: 16),
                                label: const Text('Show QR'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showTargetDomainAttendanceSheet(context, ref, session),
                                icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
                                label: const Text('Domain Roster'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: hasAttended
                            ? null
                            : () => _showMarkAttendanceDialog(context, ref, session, currentUser),
                        icon: Icon(hasAttended ? Icons.how_to_reg : Icons.qr_code_scanner, size: 18),
                        label: Text(hasAttended ? 'Attendance Marked' : 'Mark Attendance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasAttended ? AppColors.success : AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.success.withValues(alpha: 0.2),
                          disabledForegroundColor: AppColors.success,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Selected Event Provider for Collaboration ─────────────────────────────────
final selectedEventIdProvider = StateProvider<String?>((ref) => null);

// ── Participation Status Helper Widgets ───────────────────────────────────────
Widget _buildParticipationStatusBadge(String status) {
  final normStatus = status.toLowerCase();
  Color bg;
  Color fg;
  IconData icon;
  String label;

  switch (normStatus) {
    case 'shortlisted':
      bg = Colors.amber.withValues(alpha: 0.18);
      fg = Colors.amber.shade400;
      icon = Icons.checklist_rounded;
      label = 'SHORTLISTED';
      break;
    case 'selected':
      bg = Colors.purple.withValues(alpha: 0.18);
      fg = Colors.purpleAccent.shade200;
      icon = Icons.verified_rounded;
      label = 'SELECTED';
      break;
    case 'hired':
      bg = AppColors.success.withValues(alpha: 0.18);
      fg = AppColors.success;
      icon = Icons.celebration_rounded;
      label = 'HIRED';
      break;
    case 'applied':
    default:
      bg = Colors.blue.withValues(alpha: 0.18);
      fg = Colors.blue.shade300;
      icon = Icons.send_rounded;
      label = 'APPLIED';
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: fg.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: fg),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatusDescriptionBox(String status, String description) {
  final normStatus = status.toLowerCase();
  Color accentColor;
  switch (normStatus) {
    case 'shortlisted':
      accentColor = Colors.amber.shade400;
      break;
    case 'selected':
      accentColor = Colors.purpleAccent.shade200;
      break;
    case 'hired':
      accentColor = AppColors.success;
      break;
    default:
      accentColor = Colors.blue.shade300;
      break;
  }

  final displayText = description.trim().isNotEmpty
      ? description.trim()
      : 'Status: ${status.toUpperCase()}. No additional details provided yet.';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: accentColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: accentColor.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notes_rounded, size: 14, color: accentColor),
            const SizedBox(width: 6),
            Text(
              'Status Update & Description:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          displayText,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textPrimary,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}

void _showUpdateTeamStatusDialog(
  BuildContext context,
  WidgetRef ref,
  String hackathonId,
  TeamModel team,
) {
  String selectedStatus = team.participationStatus;
  final descController = TextEditingController(text: team.statusDescription);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update Team Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team: ${team.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Participation Status:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in ['applied', 'shortlisted', 'selected', 'hired'])
                        ChoiceChip(
                          label: Text(
                            s.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: selectedStatus == s ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          selected: selectedStatus == s,
                          selectedColor: s == 'hired'
                              ? AppColors.success
                              : s == 'selected'
                                  ? Colors.purple
                                  : s == 'shortlisted'
                                      ? Colors.amber.shade700
                                      : Colors.blue,
                          backgroundColor: AppColors.surfaceLight,
                          onSelected: (val) {
                            if (val) setState(() => selectedStatus = s);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Description of Status / Updates:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g. Cleared round 1 online assessment! Shortlisted for interview.',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(databaseRepositoryProvider).updateTeamParticipationStatus(
                    hackathonId,
                    team.id,
                    selectedStatus,
                    descController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Team status updated successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Save Update'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showCreateTeamDialog(
  BuildContext context,
  WidgetRef ref,
  String hackathonId,
  String myUid, {
  required int maxTeamSize,
}) {
  final nameController = TextEditingController();
  final skillsController = TextEditingController();
  final descController = TextEditingController();
  String initialStatus = 'applied';

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.group_add_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Form a Team',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Team Name',
                      hintText: 'e.g. Byte Busters',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skillsController,
                    decoration: const InputDecoration(
                      labelText: 'Required Skills (comma separated)',
                      hintText: 'e.g. Flutter, Firebase, Python',
                      prefixIcon: Icon(Icons.code_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initial Status:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in ['applied', 'shortlisted', 'selected', 'hired'])
                        ChoiceChip(
                          label: Text(
                            s.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: initialStatus == s ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          selected: initialStatus == s,
                          selectedColor: s == 'hired'
                              ? AppColors.success
                              : s == 'selected'
                                  ? Colors.purple
                                  : s == 'shortlisted'
                                      ? Colors.amber.shade700
                                      : Colors.blue,
                          backgroundColor: AppColors.surfaceLight,
                          onSelected: (val) {
                            if (val) setState(() => initialStatus = s);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Status Description / Notes',
                      hintText: 'e.g. Applied via official portal on Oct 16.',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a team name')),
                    );
                    return;
                  }
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
                    status: maxTeamSize <= 1 ? 'full' : 'open',
                    participationStatus: initialStatus,
                    statusDescription: descController.text.trim(),
                  );

                  await ref.read(databaseRepositoryProvider).createTeam(hackathonId, team);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Team formed successfully! 🎉'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Create Team'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ── Mark Application Dialog with Confirmations ────────────────────────────────
void _showMarkAppliedDialog(
  BuildContext context,
  WidgetRef ref,
  HackathonModel h,
  UserModel user, {
  VoidCallback? onAppliedSuccess,
}) {
  final isInternship = h.type.toLowerCase() == 'internship';
  final canBeTeam = !isInternship && h.teamSizeLimit > 1;
  bool isTeam = canBeTeam;
  final nameController = TextEditingController(text: isTeam ? '${user.name}\'s Team' : user.name);
  final descController = TextEditingController();
  String selectedStatus = 'applied';

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  Icons.how_to_reg_rounded,
                  color: isInternship ? Colors.cyanAccent : AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Confirm Application',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (h.company != null && h.company!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            h.company!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (canBeTeam) ...[
                    const Text('Application Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('With a Team'),
                          selected: isTeam,
                          selectedColor: AppColors.primary,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                isTeam = true;
                                if (nameController.text == user.name) {
                                  nameController.text = '${user.name}\'s Team';
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Individual'),
                          selected: !isTeam,
                          selectedColor: AppColors.primary,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                isTeam = false;
                                nameController.text = user.name;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: isTeam ? 'Team Name' : 'Applicant Name',
                      hintText: isTeam ? 'e.g. Byte Busters' : user.name,
                      prefixIcon: Icon(isTeam ? Icons.groups_rounded : Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Participation Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in ['applied', 'shortlisted', 'selected', 'hired'])
                        ChoiceChip(
                          label: Text(
                            s.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: selectedStatus == s ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          selected: selectedStatus == s,
                          selectedColor: s == 'hired'
                              ? AppColors.success
                              : s == 'selected'
                                  ? Colors.purple
                                  : s == 'shortlisted'
                                      ? Colors.amber.shade700
                                      : Colors.blue,
                          backgroundColor: AppColors.surfaceLight,
                          onSelected: (val) {
                            if (val) setState(() => selectedStatus = s);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Status Description / Notes (Optional)',
                      hintText: 'e.g. Applied via official portal, waiting for online assessment.',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final finalName = nameController.text.trim().isNotEmpty
                      ? nameController.text.trim()
                      : (isTeam ? '${user.name}\'s Team' : user.name);

                  final team = TeamModel(
                    id: const Uuid().v4(),
                    name: finalName,
                    leadUid: user.uid,
                    memberUids: [user.uid],
                    requiredSkills: [],
                    pendingRequests: [],
                    status: (isTeam && h.teamSizeLimit > 1) ? 'open' : 'full',
                    participationStatus: selectedStatus,
                    statusDescription: descController.text.trim(),
                  );

                  await ref.read(databaseRepositoryProvider).createTeam(h.id, team);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Marked as applied! Visible in Teams section. 🎉'),
                        backgroundColor: AppColors.success,
                        action: onAppliedSuccess != null
                            ? SnackBarAction(
                                label: 'View Teams',
                                textColor: Colors.white,
                                onPressed: onAppliedSuccess,
                              )
                            : null,
                      ),
                    );
                  }
                },
                child: const Text('Confirm & Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ── Manage/Update Application Status or Withdraw (Mark as Not Applied) ─────────
void _showManageAppliedDialog(
  BuildContext context,
  WidgetRef ref,
  HackathonModel h,
  TeamModel myTeam,
  UserModel user,
) {
  String selectedStatus = myTeam.participationStatus;
  final descController = TextEditingController(text: myTeam.statusDescription);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Application: ${myTeam.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event: ${h.title}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  const Text('Update Participation Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in ['applied', 'shortlisted', 'selected', 'hired'])
                        ChoiceChip(
                          label: Text(
                            s.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: selectedStatus == s ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          selected: selectedStatus == s,
                          selectedColor: s == 'hired'
                              ? AppColors.success
                              : s == 'selected'
                                  ? Colors.purple
                                  : s == 'shortlisted'
                                      ? Colors.amber.shade700
                                      : Colors.blue,
                          backgroundColor: AppColors.surfaceLight,
                          onSelected: (val) {
                            if (val) setState(() => selectedStatus = s);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Status Description / Notes',
                      hintText: 'e.g. Cleared technical interview round on Oct 16.',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const Divider(height: 28),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(40),
                    ),
                    onPressed: () async {
                      final confirmWithdraw = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Mark as Not Applied?'),
                          content: Text(
                            'Are you sure you want to remove your application for "${h.title}"? You will no longer appear on the teams/participant list.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Yes, Remove Application'),
                            ),
                          ],
                        ),
                      );
                      if (confirmWithdraw == true) {
                        if (myTeam.memberUids.length > 1) {
                          await ref.read(databaseRepositoryProvider).leaveTeam(h.id, myTeam.id, user.uid);
                        } else {
                          await ref.read(databaseRepositoryProvider).deleteTeam(h.id, myTeam.id);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Application marked as not applied.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Mark as Not Applied (Withdraw)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(databaseRepositoryProvider).updateTeamParticipationStatus(
                    h.id,
                    myTeam.id,
                    selectedStatus,
                    descController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Application status updated!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Save Update'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ── Hackathons Tab ────────────────────────────────────────────────────────────
class _HackathonsTab extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToTeams;

  const _HackathonsTab({this.onNavigateToTeams});

  @override
  ConsumerState<_HackathonsTab> createState() => _HackathonsTabState();
}

class _HackathonsTabState extends ConsumerState<_HackathonsTab> {
  String _typeFilter = 'all'; // 'all', 'hackathon', 'internship'
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedDescriptions = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateHackathonSheet(BuildContext context, WidgetRef ref, UserModel user) {
    String selectedType = 'hackathon';
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkController = TextEditingController();
    final teamSizeController = TextEditingController(text: '4');
    final stipendController = TextEditingController();
    String selectedMode = 'Remote';
    DateTime? startDate;
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          final isLeadOrAdmin = user.role == UserRole.admin ||
              user.role == UserRole.lead ||
              user.role == UserRole.developer;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isLeadOrAdmin ? 'Post Opportunity' : 'Request Hackathon / Internship',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Type Selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Hackathon', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          selected: selectedType == 'hackathon',
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceLight,
                          onSelected: (val) {
                            if (val) setSheetState(() {
                              selectedType = 'hackathon';
                              if (teamSizeController.text == '1') teamSizeController.text = '4';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Internship', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          selected: selectedType == 'internship',
                          selectedColor: Colors.indigoAccent,
                          backgroundColor: AppColors.surfaceLight,
                          onSelected: (val) {
                            if (val) setSheetState(() {
                              selectedType = 'internship';
                              teamSizeController.text = '1';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: selectedType == 'hackathon' ? 'Hackathon Title' : 'Internship Role / Title',
                      hintText: selectedType == 'hackathon' ? 'e.g. Smart India Hackathon' : 'e.g. Software Engineering Intern',
                      prefixIcon: Icon(selectedType == 'hackathon' ? Icons.emoji_events_outlined : Icons.work_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company / Organization (Optional)',
                      hintText: 'e.g. Microsoft, Google, KML Club',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description & Eligibility',
                      hintText: 'Details, eligibility, rounds, syllabus...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: linkController,
                    decoration: const InputDecoration(
                      labelText: 'Application / Registration Link',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: teamSizeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: selectedType == 'hackathon' ? 'Max Team Size' : 'Positions',
                            prefixIcon: const Icon(Icons.groups_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stipendController,
                          decoration: InputDecoration(
                            labelText: selectedType == 'hackathon' ? 'Prizes (Optional)' : 'Stipend (Optional)',
                            hintText: selectedType == 'hackathon' ? 'e.g. ₹50k' : 'e.g. ₹40k/mo',
                            prefixIcon: const Icon(Icons.payments_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Mode chips
                  Row(
                    children: [
                      const Text('Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      for (final mode in ['Remote', 'On-site', 'Hybrid'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(mode, style: const TextStyle(fontSize: 11)),
                            selected: selectedMode == mode,
                            selectedColor: AppColors.primary.withValues(alpha: 0.3),
                            onSelected: (val) { if (val) setSheetState(() => selectedMode = mode); },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (date != null) setSheetState(() => startDate = date);
                          },
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(startDate == null ? 'Start Date' : DateFormat('MMM dd, yyyy').format(startDate!)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (date != null) setSheetState(() => endDate = date);
                          },
                          icon: const Icon(Icons.event_available_rounded, size: 16),
                          label: Text(endDate == null ? 'Deadline / End' : DateFormat('MMM dd, yyyy').format(endDate!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          descriptionController.text.trim().isEmpty ||
                          startDate == null || endDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields (title, description, dates)')),
                        );
                        return;
                      }
                      final hackathon = HackathonModel(
                        id: const Uuid().v4(),
                        title: titleController.text.trim(),
                        company: companyController.text.trim().isEmpty ? null : companyController.text.trim(),
                        description: descriptionController.text.trim(),
                        participatingLink: linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                        startDate: startDate!,
                        endDate: endDate!,
                        teamSizeLimit: int.tryParse(teamSizeController.text) ?? (selectedType == 'hackathon' ? 4 : 1),
                        status: isLeadOrAdmin ? 'approved' : 'pending',
                        requestedBy: user.uid,
                        type: selectedType,
                        location: selectedMode,
                        stipendOrPrize: stipendController.text.trim().isEmpty ? null : stipendController.text.trim(),
                      );
                      await ref.read(databaseRepositoryProvider).createHackathon(hackathon);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isLeadOrAdmin
                                ? '${selectedType == 'hackathon' ? 'Hackathon' : 'Internship'} posted!'
                                : 'Request submitted for approval!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: Text(isLeadOrAdmin ? 'Post Opportunity' : 'Submit Request'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showEditHackathonSheet(BuildContext context, WidgetRef ref, HackathonModel h) {
    String selectedType = h.type;
    final titleController = TextEditingController(text: h.title);
    final companyController = TextEditingController(text: h.company ?? '');
    final descriptionController = TextEditingController(text: h.description);
    final linkController = TextEditingController(text: h.participatingLink ?? '');
    final teamSizeController = TextEditingController(text: h.teamSizeLimit.toString());
    final stipendController = TextEditingController(text: h.stipendOrPrize ?? '');
    String selectedMode = h.location ?? 'Remote';
    DateTime? startDate = h.startDate;
    DateTime? endDate = h.endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Edit Opportunity (Admin)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Type Selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Hackathon', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          selected: selectedType == 'hackathon',
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceLight,
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() {
                                selectedType = 'hackathon';
                                if (teamSizeController.text == '1') teamSizeController.text = '4';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.work_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Internship', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          selected: selectedType == 'internship',
                          selectedColor: Colors.indigoAccent,
                          backgroundColor: AppColors.surfaceLight,
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() {
                                selectedType = 'internship';
                                teamSizeController.text = '1';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: selectedType == 'hackathon' ? 'Hackathon Title' : 'Internship Role / Title',
                      prefixIcon: Icon(selectedType == 'hackathon' ? Icons.emoji_events_outlined : Icons.work_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company / Organization (Optional)',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description & Eligibility',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: linkController,
                    decoration: const InputDecoration(
                      labelText: 'Application / Registration Link',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: teamSizeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: selectedType == 'hackathon' ? 'Max Team Size' : 'Positions',
                            prefixIcon: const Icon(Icons.groups_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stipendController,
                          decoration: InputDecoration(
                            labelText: selectedType == 'hackathon' ? 'Prizes (Optional)' : 'Stipend (Optional)',
                            prefixIcon: const Icon(Icons.payments_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Mode chips
                  Row(
                    children: [
                      const Text('Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      for (final mode in ['Remote', 'On-site', 'Hybrid'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(mode, style: const TextStyle(fontSize: 11)),
                            selected: selectedMode == mode,
                            selectedColor: AppColors.primary.withValues(alpha: 0.3),
                            onSelected: (val) { if (val) setSheetState(() => selectedMode = mode); },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (date != null) setSheetState(() => startDate = date);
                          },
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(startDate == null ? 'Start Date' : DateFormat('MMM dd, yyyy').format(startDate!)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? (startDate ?? DateTime.now()),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 730)),
                            );
                            if (date != null) setSheetState(() => endDate = date);
                          },
                          icon: const Icon(Icons.event_available_rounded, size: 16),
                          label: Text(endDate == null ? 'Deadline / End' : DateFormat('MMM dd, yyyy').format(endDate!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          descriptionController.text.trim().isEmpty ||
                          startDate == null || endDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields (title, description, dates)')),
                        );
                        return;
                      }
                      final updated = h.copyWith(
                        title: titleController.text.trim(),
                        company: companyController.text.trim().isEmpty ? null : companyController.text.trim(),
                        description: descriptionController.text.trim(),
                        participatingLink: linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                        startDate: startDate!,
                        endDate: endDate!,
                        teamSizeLimit: int.tryParse(teamSizeController.text) ?? (selectedType == 'hackathon' ? 4 : 1),
                        type: selectedType,
                        location: selectedMode,
                        stipendOrPrize: stipendController.text.trim().isEmpty ? null : stipendController.text.trim(),
                      );
                      await ref.read(databaseRepositoryProvider).updateHackathon(updated);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opportunity updated successfully! 🎉'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hackathonsAsync = ref.watch(hackathonsProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Center(child: CircularProgressIndicator());

    final isLeadOrAdmin = user.role == UserRole.admin ||
        user.role == UserRole.lead ||
        user.role == UserRole.developer;
    final isAdmin = user.role == UserRole.admin || user.role == UserRole.developer;

    return Column(
      children: [
        // Post / Request Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateHackathonSheet(context, ref, user),
            icon: Icon(isLeadOrAdmin ? Icons.add_circle_outline_rounded : Icons.post_add_rounded),
            label: Text(
              isLeadOrAdmin ? '+ Post Hackathon / Internship' : 'Request Hackathon / Internship',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),

        // Search & Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search hackathons, internships, companies...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () { _searchController.clear(); setState(() {}); },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Opportunities'),
                      selected: _typeFilter == 'all',
                      onSelected: (_) => setState(() => _typeFilter = 'all'),
                      selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.amber),
                      label: const Text('Hackathons'),
                      selected: _typeFilter == 'hackathon',
                      onSelected: (_) => setState(() => _typeFilter = 'hackathon'),
                      selectedColor: Colors.amber.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.work_rounded, size: 16, color: Colors.cyanAccent),
                      label: const Text('Internships'),
                      selected: _typeFilter == 'internship',
                      onSelected: (_) => setState(() => _typeFilter = 'internship'),
                      selectedColor: Colors.cyan.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // List of Hackathons & Internships
        Expanded(
          child: hackathonsAsync.when(
            data: (allHackathons) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = allHackathons.where((h) {
                if (_typeFilter != 'all') {
                  final isIntern = h.type.toLowerCase() == 'internship';
                  if (_typeFilter == 'internship' && !isIntern) return false;
                  if (_typeFilter == 'hackathon' && isIntern) return false;
                }
                if (query.isNotEmpty) {
                  return h.title.toLowerCase().contains(query) ||
                      h.description.toLowerCase().contains(query) ||
                      (h.company ?? '').toLowerCase().contains(query);
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _typeFilter == 'internship' ? Icons.work_off_rounded : Icons.emoji_events_outlined,
                          size: 54,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          query.isNotEmpty
                              ? 'No opportunities match "$query"'
                              : 'No ${_typeFilter == 'internship' ? 'internships' : _typeFilter == 'hackathon' ? 'hackathons' : 'opportunities'} yet.',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showCreateHackathonSheet(context, ref, user),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Post the First One'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final h = filtered[index];
                  final isInternship = h.type.toLowerCase() == 'internship';
                  final isExpanded = _expandedDescriptions.contains(h.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: GlowingCard(
                      glowColor: isInternship ? Colors.indigoAccent : AppColors.accent,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.surface,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Type badge + Company + Actions
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isInternship ? Colors.indigoAccent : AppColors.accent).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: (isInternship ? Colors.indigoAccent : AppColors.accent).withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isInternship ? Icons.work_rounded : Icons.emoji_events_rounded,
                                        size: 13,
                                        color: isInternship ? Colors.cyanAccent : AppColors.accent,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isInternship ? 'INTERNSHIP' : 'HACKATHON',
                                        style: TextStyle(
                                          color: isInternship ? Colors.cyanAccent : AppColors.accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (h.company != null && h.company!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        h.company!,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (isAdmin)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                                    color: AppColors.surfaceLight,
                                    onSelected: (val) async {
                                      if (val == 'edit') {
                                        _showEditHackathonSheet(context, ref, h);
                                      } else if (val == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: AppColors.surface,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Delete Opportunity?'),
                                            content: Text('Permanently delete "${h.title}"? This action cannot be undone.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ref.read(databaseRepositoryProvider).deleteHackathon(h.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Opportunity deleted.')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                            SizedBox(width: 8),
                                            Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Title
                            Text(
                              h.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),

                            // Description with expand/collapse
                            LinkableText(
                              h.description,
                              maxLines: isExpanded ? null : 3,
                              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                            ),
                            if (h.description.length > 120)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedDescriptions.remove(h.id);
                                    } else {
                                      _expandedDescriptions.add(h.id);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    isExpanded ? 'Show less' : 'Read more...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isInternship ? Colors.cyanAccent : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),

                            // Link
                            if (h.participatingLink != null && h.participatingLink!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => _launchExternalUrl(context, h.participatingLink!),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: (isInternship ? Colors.indigoAccent : AppColors.primary).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: (isInternship ? Colors.indigoAccent : AppColors.primary).withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.link_rounded, size: 15, color: isInternship ? Colors.cyanAccent : AppColors.primary),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Apply Link: ${h.participatingLink}',
                                          style: TextStyle(
                                            color: isInternship ? Colors.cyanAccent : AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                            fontSize: 12.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.open_in_new_rounded, size: 13, color: isInternship ? Colors.cyanAccent : AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            // Metadata
                            Wrap(
                              spacing: 14,
                              runSpacing: 6,
                              children: [
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.date_range_rounded, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('Starts: ${DateFormat('MMM dd, yyyy').format(h.startDate)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ]),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.event_available_rounded, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('Deadline: ${DateFormat('MMM dd, yyyy').format(h.endDate)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ]),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.groups_rounded, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    isInternship && h.teamSizeLimit == 1 ? 'Individual' : 'Team Size: ${h.teamSizeLimit}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ]),
                                if (h.stipendOrPrize != null && h.stipendOrPrize!.isNotEmpty)
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.payments_outlined, size: 14, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(h.stipendOrPrize!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
                                  ]),
                                if (h.location != null && h.location!.isNotEmpty)
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(h.location!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ]),
                              ],
                            ),

                            const Divider(height: 20),
                            // Bottom Actions & Application Status
                            _HackathonCardApplicationFooter(
                              h: h,
                              user: user,
                              onNavigateToTeams: () {
                                ref.read(selectedEventIdProvider.notifier).state = h.id;
                                widget.onNavigateToTeams?.call();
                              },
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
            error: (e, s) => Center(child: Text('Error loading opportunities: $e')),
          ),
        ),
      ],
    );
  }
}

// ── Reactive Card Application Footer ─────────────────────────────────────────
class _HackathonCardApplicationFooter extends ConsumerWidget {
  final HackathonModel h;
  final UserModel user;
  final VoidCallback onNavigateToTeams;

  const _HackathonCardApplicationFooter({
    required this.h,
    required this.user,
    required this.onNavigateToTeams,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider(h.id));
    final isInternship = h.type.toLowerCase() == 'internship';

    return teamsAsync.when(
      data: (teams) {
        TeamModel? myTeam;
        for (final t in teams) {
          if (t.memberUids.contains(user.uid) || t.leadUid == user.uid) {
            myTeam = t;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (myTeam != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'You applied: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade200,
                                ),
                              ),
                              _buildParticipationStatusBadge(myTeam.participationStatus),
                            ],
                          ),
                          if (myTeam.statusDescription.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              myTeam.statusDescription,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showManageAppliedDialog(context, ref, h, myTeam!, user),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note_rounded, size: 14, color: Colors.blueAccent),
                            SizedBox(width: 3),
                            Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigateToTeams,
                    icon: const Icon(Icons.group_rounded, size: 17),
                    label: Text(
                      teams.isNotEmpty ? 'Applied (${teams.length})' : 'Applications & Status',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (myTeam == null) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showMarkAppliedDialog(
                      context,
                      ref,
                      h,
                      user,
                      onAppliedSuccess: onNavigateToTeams,
                    ),
                    icon: const Icon(Icons.how_to_reg_rounded, size: 16, color: AppColors.success),
                    label: const Text('I Applied', style: TextStyle(color: AppColors.success)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (h.participatingLink != null && h.participatingLink!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _launchExternalUrl(context, h.participatingLink!),
                    icon: const Icon(Icons.launch_rounded, size: 16),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInternship ? Colors.indigoAccent : AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onNavigateToTeams,
              icon: const Icon(Icons.group_rounded, size: 17),
              label: const Text('Teams & Status'),
            ),
          ),
          if (h.participatingLink != null && h.participatingLink!.isNotEmpty) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _launchExternalUrl(context, h.participatingLink!),
              icon: const Icon(Icons.launch_rounded, size: 16),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isInternship ? Colors.indigoAccent : AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
      error: (_, __) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onNavigateToTeams,
              icon: const Icon(Icons.group_rounded, size: 17),
              label: const Text('Teams & Status'),
            ),
          ),
        ],
      ),
    );
  }
}

final membersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(databaseRepositoryProvider).getMembers();
});

// ── Teams Tab ─────────────────────────────────────────────────────────────

class _TeamsTab extends ConsumerStatefulWidget {
  const _TeamsTab();

  @override
  ConsumerState<_TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends ConsumerState<_TeamsTab> {
  String _activeSection = 'event_teams'; // 'event_teams' | 'project_requests'
  String _statusFilter = 'all'; // 'all', 'applied', 'shortlisted', 'selected', 'hired'

  void _showRequestTeamSheet(BuildContext context, UserModel currentUser) {
    final titleCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final techStackCtrl = TextEditingController();
    int membersNeeded = 1;

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
                        'Request Team',
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
                      labelText: 'Project Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: purposeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Purpose / Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: techStackCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tech Stack (comma separated)',
                      prefixIcon: Icon(Icons.code),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Members Needed:',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                        onPressed: () {
                          if (membersNeeded > 1) setState(() => membersNeeded--);
                        },
                      ),
                      Text(
                        '$membersNeeded',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onPressed: () {
                          if (membersNeeded < 10) setState(() => membersNeeded++);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;

                      final request = TeamRequestModel(
                        id: const Uuid().v4(),
                        creatorId: currentUser.uid,
                        creatorName: currentUser.name,
                        title: titleCtrl.text.trim(),
                        purpose: purposeCtrl.text.trim(),
                        techStack: techStackCtrl.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        membersNeeded: membersNeeded,
                        interestedMemberIds: [],
                        status: 'pending',
                        createdAt: DateTime.now(),
                      );

                      try {
                        await ref
                            .read(databaseRepositoryProvider)
                            .createTeamRequest(request);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Team request submitted for approval!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit request: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Submit Request'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeColor = user?.role == UserRole.lead
        ? AppColors.success
        : user?.role == UserRole.admin || user?.role == UserRole.developer
            ? AppColors.error
            : AppColors.primary;

    return Column(
      children: [
        // Section selector: Event Teams vs Project Requests
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  avatar: const Icon(Icons.emoji_events_rounded, size: 16),
                  label: const Text('Applications & Roster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  selected: _activeSection == 'event_teams',
                  selectedColor: themeColor.withValues(alpha: 0.25),
                  onSelected: (val) {
                    if (val) setState(() => _activeSection = 'event_teams');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  avatar: const Icon(Icons.handshake_rounded, size: 16),
                  label: const Text('Project Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  selected: _activeSection == 'project_requests',
                  selectedColor: AppColors.secondary.withValues(alpha: 0.25),
                  onSelected: (val) {
                    if (val) setState(() => _activeSection = 'project_requests');
                  },
                ),
              ),
            ],
          ),
        ),

        // Section Content
        Expanded(
          child: _activeSection == 'event_teams'
              ? _buildEventTeamsSection(context, user)
              : _buildProjectRequestsSection(context, user, themeColor),
        ),
      ],
    );
  }

  Widget _buildEventTeamsSection(BuildContext context, UserModel? user) {
    final hackathonsAsync = ref.watch(hackathonsProvider);

    return hackathonsAsync.when(
      data: (hackathons) {
        if (hackathons.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('No opportunities available right now.', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          );
        }

        final selectedId = ref.watch(selectedEventIdProvider);
        HackathonModel currentEvent = hackathons.first;
        for (final h in hackathons) {
          if (h.id == selectedId) {
            currentEvent = h;
            break;
          }
        }

        return Column(
          children: [
            // Event Selector Chips
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hackathons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final h = hackathons[i];
                  final isSelected = h.id == currentEvent.id;
                  final isInternship = h.type.toLowerCase() == 'internship';

                  return ChoiceChip(
                    avatar: Icon(
                      isInternship ? Icons.work_rounded : Icons.emoji_events_rounded,
                      size: 14,
                      color: isSelected ? Colors.white : (isInternship ? Colors.cyanAccent : AppColors.accent),
                    ),
                    label: Text(
                      h.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    selectedColor: isInternship ? Colors.indigoAccent : AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onSelected: (val) {
                      if (val) {
                        ref.read(selectedEventIdProvider.notifier).state = h.id;
                      }
                    },
                  );
                },
              ),
            ),

            // Event Details & Teams List
            Expanded(
              child: _EventRosterView(
                event: currentEvent,
                user: user,
                statusFilter: _statusFilter,
                onFilterChanged: (f) => setState(() => _statusFilter = f),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading events: $e')),
    );
  }

  Widget _buildProjectRequestsSection(BuildContext context, UserModel? user, Color themeColor) {
    final teamRequestsAsync = ref.watch(teamRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              heroTag: 'teams_fab',
              onPressed: () => _showRequestTeamSheet(context, user),
              label: const Text('Request Team'),
              icon: const Icon(Icons.group_add_rounded),
              backgroundColor: themeColor,
            )
          : null,
      body: teamRequestsAsync.when(
        data: (requests) {
          final visibleRequests = requests.where((r) {
            return r.status == 'approved' || r.creatorId == user?.uid;
          }).toList();

          if (visibleRequests.isEmpty) {
            return const Center(
              child: Text(
                'No team requests found.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visibleRequests.length,
            itemBuilder: (context, index) {
              final req = visibleRequests[index];
              final isCreator = user?.uid == req.creatorId;
              final hasExpressedInterest = user != null && req.interestedMemberIds.contains(user.uid);

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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (req.status != 'approved')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: req.status == 'pending' ? Colors.orange.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: req.status == 'pending' ? Colors.orange : Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested by: ${req.creatorName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      req.purpose,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
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
                        Text(
                          'Needs ${req.membersNeeded} members',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        if (req.status == 'approved' && !isCreator)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasExpressedInterest ? AppColors.surfaceLight : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () async {
                              if (user == null) return;
                              await ref.read(databaseRepositoryProvider).toggleTeamInterest(
                                user.uid,
                                req.id,
                                !hasExpressedInterest,
                              );
                            },
                            icon: Icon(hasExpressedInterest ? Icons.check : Icons.handshake, size: 16),
                            label: Text(hasExpressedInterest ? 'Interested' : 'I\'m Interested'),
                          ),
                      ],
                    ),
                    if (isCreator && req.interestedMemberIds.isNotEmpty) ...[
                      const Divider(color: AppColors.border, height: 24),
                      Text(
                        '${req.interestedMemberIds.length} members interested!',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Event Roster View (Teams & Members) ────────────────────────────────────────
class _EventRosterView extends ConsumerWidget {
  final HackathonModel event;
  final UserModel? user;
  final String statusFilter;
  final Function(String) onFilterChanged;

  const _EventRosterView({
    required this.event,
    required this.user,
    required this.statusFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider(event.id));
    final membersAsync = ref.watch(membersStreamProvider);
    final isInternship = event.type.toLowerCase() == 'internship';
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.developer;
    final isLeadOrAdmin = user?.role == UserRole.lead || user?.role == UserRole.admin || user?.role == UserRole.developer;

    return teamsAsync.when(
      data: (teams) {
        // Find if current user has applied
        TeamModel? myTeam;
        if (user != null) {
          for (final t in teams) {
            if (t.memberUids.contains(user!.uid) || t.leadUid == user!.uid) {
              myTeam = t;
              break;
            }
          }
        }

        // Calculate aggregate application metrics
        final totalCount = teams.length;
        final appliedCount = teams.where((t) => t.participationStatus.toLowerCase() == 'applied').length;
        final shortlistedCount = teams.where((t) => t.participationStatus.toLowerCase() == 'shortlisted').length;
        final selectedCount = teams.where((t) => t.participationStatus.toLowerCase() == 'selected').length;
        final hiredCount = teams.where((t) => t.participationStatus.toLowerCase() == 'hired').length;

        // Filter teams
        final filteredTeams = statusFilter == 'all'
            ? teams
            : teams.where((t) => t.participationStatus.toLowerCase() == statusFilter.toLowerCase()).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Event Summary Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isInternship ? Colors.indigoAccent : AppColors.primary).withValues(alpha: 0.18),
                    AppColors.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isInternship ? Colors.indigoAccent : AppColors.primary).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isInternship ? Colors.indigoAccent : AppColors.accent).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isInternship ? 'INTERNSHIP' : 'HACKATHON',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isInternship ? Colors.cyanAccent : AppColors.accent,
                          ),
                        ),
                      ),
                      if (event.company != null && event.company!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          event.company!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        'Deadline: ${DateFormat('MMM dd').format(event.endDate)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Application Numbers Overview (Visible to everyone)
            _buildApplicationStatsCard(
              totalCount: totalCount,
              appliedCount: appliedCount,
              shortlistedCount: shortlistedCount,
              selectedCount: selectedCount,
              hiredCount: hiredCount,
              isInternship: isInternship,
            ),
            const SizedBox(height: 12),

            // Current User Application Card
            if (user != null) ...[
              if (myTeam != null)
                Builder(
                  builder: (context) {
                    final activeTeam = myTeam!;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your Application: ${activeTeam.name}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildParticipationStatusBadge(activeTeam.participationStatus),
                            ],
                          ),
                          if (activeTeam.statusDescription.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              activeTeam.statusDescription,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showManageAppliedDialog(context, ref, event, activeTeam, user!),
                                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                                  label: const Text('Update Status / Notes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final confirmWithdraw = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Mark as Not Applied?'),
                                      content: Text(
                                        'Are you sure you want to remove your application for "${event.title}"? Your details will no longer appear on the teams list.',
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Yes, Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmWithdraw == true) {
                                    if (activeTeam.memberUids.length > 1) {
                                      await ref.read(databaseRepositoryProvider).leaveTeam(event.id, activeTeam.id, user!.uid);
                                    } else {
                                      await ref.read(databaseRepositoryProvider).deleteTeam(event.id, activeTeam.id);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Application marked as not applied.')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                                label: const Text('Not Applied', style: TextStyle(color: AppColors.error)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Have you applied for this opportunity?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mark your application so mentors, leads, and peers can see your status, team up, or track selections!',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showMarkAppliedDialog(context, ref, event, user!),
                              icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                              label: const Text('Mark as Applied'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          if (!isInternship && event.teamSizeLimit > 1) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showCreateTeamDialog(
                                  context,
                                  ref,
                                  event.id,
                                  user!.uid,
                                  maxTeamSize: event.teamSizeLimit,
                                ),
                                icon: const Icon(Icons.group_add_rounded, size: 16),
                                label: const Text('Form a Team'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Candidate Roster Section:
            // Regular members only see aggregate numbers above and confidentiality notice.
            // Full candidate profiles, who applied, and notes are restricted to Leads and Admins only.
            if (!isLeadOrAdmin)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Applicant Info Restricted to Leads & Admins',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Candidate identities, profiles, and shortlist status notes are strictly confidential and shared only with club leads and administrators. Aggregate numbers are displayed in the insights panel above.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              myTeam != null
                                  ? 'Your personal application is securely recorded above. Leads can review your status.'
                                  : 'Mark your application above if you have applied so leads and mentors can track your progress.',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Filter Chips Header (Only for Leads & Admins)
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Candidate Roster (${filteredTeams.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LEAD / ADMIN',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: statusFilter,
                    dropdownColor: AppColors.surface,
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'applied', child: Text('Applied')),
                      DropdownMenuItem(value: 'shortlisted', child: Text('Shortlisted')),
                      DropdownMenuItem(value: 'selected', child: Text('Selected')),
                      DropdownMenuItem(value: 'hired', child: Text('Hired')),
                    ],
                    onChanged: (val) {
                      if (val != null) onFilterChanged(val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Teams List (Visible to Leads & Admins)
              if (filteredTeams.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.group_off_rounded, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          statusFilter == 'all'
                              ? 'No teams or applicants recorded yet for this event.'
                              : 'No applications found with status "$statusFilter".',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                membersAsync.when(
                data: (allMembers) {
                  final memberMap = {for (final m in allMembers) m.uid: m};

                  return Column(
                    children: filteredTeams.map((team) {
                      final isLead = user?.uid == team.leadUid;
                      final canManage = isLead || isAdmin;

                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Team Header
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        team.memberUids.length > 1 ? Icons.groups_rounded : Icons.person_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          team.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildParticipationStatusBadge(team.participationStatus),
                                if (canManage) ...[
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                                    color: AppColors.surfaceLight,
                                    onSelected: (val) async {
                                      if (val == 'update_status') {
                                        _showUpdateTeamStatusDialog(context, ref, event.id, team);
                                      } else if (val == 'delete_team') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: AppColors.surface,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Remove Team?'),
                                            content: Text('Remove "${team.name}" from ${event.title}?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ref.read(databaseRepositoryProvider).deleteTeam(event.id, team.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Team removed from roster.')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'update_status',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
                                            SizedBox(width: 8),
                                            Text('Update Status / Notes'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete_team',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                            SizedBox(width: 8),
                                            Text('Remove from Roster', style: TextStyle(color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            // Status Description Box
                            if (team.statusDescription.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildStatusDescriptionBox(team.participationStatus, team.statusDescription),
                            ],

                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            // Members Roster
                            const Text(
                              'Members:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: team.memberUids.map((uid) {
                                final member = memberMap[uid];
                                final isTeamLead = uid == team.leadUid;

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isTeamLead ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppAvatar(
                                        name: member?.name ?? 'User',
                                        photoUrl: member?.photoUrl,
                                        radius: 10,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        member?.name ?? 'Member',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isTeamLead ? FontWeight.bold : FontWeight.normal,
                                          color: isTeamLead ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                      ),
                                      if (isTeamLead) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('LEAD', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                            // Team Joining Actions (for open teams)
                            if (team.status == 'open' &&
                                team.memberUids.length < event.teamSizeLimit &&
                                user != null &&
                                !team.memberUids.contains(user!.uid)) ...[
                              const SizedBox(height: 10),
                              Builder(
                                builder: (ctx) {
                                  final hasRequested = team.pendingRequests.contains(user!.uid);
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed: hasRequested
                                          ? null
                                          : () async {
                                              await ref.read(databaseRepositoryProvider).requestToJoinTeam(event.id, team.id, user!.uid);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Join request sent to team lead!')),
                                                );
                                              }
                                            },
                                      icon: Icon(hasRequested ? Icons.hourglass_top_rounded : Icons.group_add_rounded, size: 14),
                                      label: Text(hasRequested ? 'Request Sent' : 'Request to Join Team', style: const TextStyle(fontSize: 11)),
                                    ),
                                  );
                                },
                              ),
                            ],

                            // Pending requests for Team Lead to manage
                            if (isLead && team.pendingRequests.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pending Join Requests:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                                    const SizedBox(height: 6),
                                    for (final reqUid in team.pendingRequests) ...[
                                      Row(
                                        children: [
                                          Text(memberMap[reqUid]?.name ?? 'Applicant', style: const TextStyle(fontSize: 12)),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.check, size: 16, color: AppColors.success),
                                            onPressed: () async {
                                              await ref.read(databaseRepositoryProvider).manageJoinRequest(event.id, team.id, reqUid, true);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                                            onPressed: () async {
                                              await ref.read(databaseRepositoryProvider).manageJoinRequest(event.id, team.id, reqUid, false);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading member profiles: $e'),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading teams: $e')),
    );
  }

  Widget _buildApplicationStatsCard({
    required int totalCount,
    required int appliedCount,
    required int shortlistedCount,
    required int selectedCount,
    required int hiredCount,
    required bool isInternship,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Application Numbers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: $totalCount',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Applied',
                  count: appliedCount,
                  color: Colors.blueAccent,
                  icon: Icons.assignment_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  label: 'Shortlisted',
                  count: shortlistedCount,
                  color: Colors.amberAccent,
                  icon: Icons.star_border_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  label: 'Selected',
                  count: selectedCount,
                  color: Colors.greenAccent,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  label: isInternship ? 'Hired' : 'Winners',
                  count: hiredCount,
                  color: Colors.purpleAccent,
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ScannerWidget extends StatefulWidget {
  final Function(String) onDetect;
  const _ScannerWidget({required this.onDetect});

  @override
  State<_ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<_ScannerWidget> {
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      errorBuilder: (BuildContext context, MobileScannerException error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Camera error: ${error.errorCode.name}\n${error.errorDetails?.message ?? "Check browser permissions"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        );
      },
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            widget.onDetect(barcode.rawValue!);
            break;
          }
        }
      },
    );
  }
}

String _convertToCsvString(List<List<dynamic>> rows) {
  final buffer = StringBuffer();
  for (final row in rows) {
    final line = row.map((cell) {
      if (cell == null) return '';
      final str = cell.toString().replaceAll('"', '""');
      if (str.contains(',') || str.contains('\n') || str.contains('\r') || str.contains('"')) {
        return '"$str"';
      }
      return str;
    }).join(',');
    buffer.writeln(line);
  }
  return buffer.toString();
}

Future<void> _exportAsCsv(
  BuildContext context,
  SessionModel session,
  List<UserModel> displayList,
  List<UserModel> presentStudents,
  List<UserModel> absentStudents,
  String attendanceRate,
) async {
  final targetRoleLabel = session.targetRole == 'member'
      ? 'Members Only'
      : session.targetRole == 'lead'
          ? 'Leads Only'
          : 'Both (Members & Leads)';

  final List<List<dynamic>> rows = [
    ['Session Title', session.title],
    ['Date & Time', DateFormat('yyyy-MM-dd HH:mm').format(session.dateTime)],
    ['Host', session.createdBy],
    ['Target Domains', session.allDomainTags.join(', ')],
    ['Target Audience', targetRoleLabel],
    ['Total Target Students', displayList.length],
    ['Present Count', presentStudents.length],
    ['Absent Count', absentStudents.length],
    ['Attendance Rate', '$attendanceRate%'],
    [],
    ['S.No', 'Student Name', 'Email', 'Batch', 'Role', 'Domains Following', 'Attendance Status'],
  ];

  for (int i = 0; i < displayList.length; i++) {
    final student = displayList[i];
    final isPresent = session.attendees.contains(student.uid);
    rows.add([
      i + 1,
      student.name,
      student.email,
      student.batch,
      student.role.name.toUpperCase(),
      student.domainsFollowing.join('; '),
      isPresent ? 'PRESENT' : 'ABSENT',
    ]);
  }

  final csvData = _convertToCsvString(rows);
  final bytes = Uint8List.fromList(utf8.encode(csvData));
  final cleanTitle = session.title.replaceAll(RegExp(r'[^\w\s]+'), '_').trim();
  final fileName = '${cleanTitle}_Attendance.csv';

  try {
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      mimeType: MimeType.csv,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel (CSV) file exported: $fileName! 📊'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export Excel: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

Future<void> _exportAsPdfReport(
  BuildContext context,
  SessionModel session,
  List<UserModel> displayList,
  List<UserModel> presentStudents,
  List<UserModel> absentStudents,
  String attendanceRate,
) async {
  final targetRoleLabel = session.targetRole == 'member'
      ? 'Members Only'
      : session.targetRole == 'lead'
          ? 'Leads Only'
          : 'Both (Members & Leads)';

  final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${session.title} - Attendance Report</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 24px; background: #0f141c; color: #f0f4f8; }
    .header { border-bottom: 2px solid #e53935; padding-bottom: 16px; margin-bottom: 24px; display: flex; justify-content: space-between; align-items: flex-end; }
    .brand { font-size: 24px; font-weight: 900; color: #e53935; letter-spacing: 1px; }
    .sub-brand { font-size: 12px; color: #8a99ad; margin-top: 2px; }
    .title { font-size: 20px; font-weight: bold; color: #ffffff; margin-top: 10px; }
    .meta { font-size: 12px; color: #8a99ad; margin-top: 4px; }
    .stats { display: flex; gap: 16px; margin-bottom: 24px; }
    .stat-card { background: #1b2430; padding: 14px 20px; border-radius: 12px; border: 1px solid #2b384a; flex: 1; text-align: center; }
    .stat-num { font-size: 22px; font-weight: 800; }
    .stat-num.present { color: #00e676; }
    .stat-num.absent { color: #ff1744; }
    .stat-label { font-size: 11px; color: #8a99ad; text-transform: uppercase; margin-top: 4px; font-weight: 600; }
    table { width: 100%; border-collapse: collapse; background: #1b2430; border-radius: 12px; overflow: hidden; border: 1px solid #2b384a; }
    th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid #2b384a; font-size: 13px; }
    th { background: #141b24; color: #8a99ad; text-transform: uppercase; font-size: 11px; letter-spacing: 0.6px; font-weight: 700; }
    tr:hover { background: #222d3d; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 20px; font-weight: bold; font-size: 11px; letter-spacing: 0.5px; }
    .badge-present { background: rgba(0, 230, 118, 0.15); color: #00e676; border: 1px solid rgba(0, 230, 118, 0.4); }
    .badge-absent { background: rgba(255, 23, 68, 0.15); color: #ff1744; border: 1px solid rgba(255, 23, 68, 0.4); }
    .footer { margin-top: 30px; text-align: center; font-size: 11px; color: #627284; }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="brand">KRIVA COMMUNITY ACADEMY</div>
      <div class="title">${session.title}</div>
      <div class="meta">Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(session.dateTime)} | Host: ${session.createdBy} | Domains: ${session.allDomainTags.join(', ')} | Audience: $targetRoleLabel</div>
    </div>
    <div style="text-align: right;">
      <div class="sub-brand">OFFICIAL ATTENDANCE REPORT</div>
      <div style="font-size: 11px; color: #8a99ad; margin-top: 4px;">Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}</div>
    </div>
  </div>

  <div class="stats">
    <div class="stat-card">
      <div class="stat-num">${displayList.length}</div>
      <div class="stat-label">Target Students</div>
    </div>
    <div class="stat-card">
      <div class="stat-num present">${presentStudents.length}</div>
      <div class="stat-label">Present</div>
    </div>
    <div class="stat-card">
      <div class="stat-num absent">${absentStudents.length}</div>
      <div class="stat-label">Absent</div>
    </div>
    <div class="stat-card">
      <div class="stat-num" style="color: #ffb300;">${attendanceRate}%</div>
      <div class="stat-label">Attendance Rate</div>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th>#</th>
        <th>Student Name</th>
        <th>Email</th>
        <th>Batch</th>
        <th>Domains</th>
        <th>Attendance Status</th>
      </tr>
    </thead>
    <tbody>
      ${displayList.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final s = entry.value;
        final isPresent = session.attendees.contains(s.uid);
        return '''
        <tr>
          <td>$idx</td>
          <td><strong>${s.name}</strong></td>
          <td>${s.email}</td>
          <td>${s.batch.isNotEmpty ? s.batch : 'Member'}</td>
          <td>${s.domainsFollowing.isEmpty ? 'General' : s.domainsFollowing.join(', ')}</td>
          <td><span class="badge ${isPresent ? 'badge-present' : 'badge-absent'}">${isPresent ? 'PRESENT' : 'ABSENT'}</span></td>
        </tr>
        ''';
      }).join()}
    </tbody>
  </table>

  <div class="footer">
    Developed by Abhisht | © 2026 KRIVA Community. All rights reserved.
  </div>
</body>
</html>
''';

  final bytes = Uint8List.fromList(utf8.encode(htmlContent));
  final cleanTitle = session.title.replaceAll(RegExp(r'[^\w\s]+'), '_').trim();
  final fileName = '${cleanTitle}_Attendance_Report.html';

  try {
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      mimeType: MimeType.other,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printable PDF/HTML report exported: $fileName! 📄'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export report: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ── Target Domain Attendance Roster Sheet ────────────────────────────────────
void _showTargetDomainAttendanceSheet(
  BuildContext context,
  WidgetRef ref,
  SessionModel session,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return _TargetDomainRosterSheet(session: session);
    },
  );
}

class _TargetDomainRosterSheet extends ConsumerStatefulWidget {
  final SessionModel session;
  const _TargetDomainRosterSheet({required this.session});

  @override
  ConsumerState<_TargetDomainRosterSheet> createState() => _TargetDomainRosterSheetState();
}

class _TargetDomainRosterSheetState extends ConsumerState<_TargetDomainRosterSheet> {
  String _selectedFilter = 'all'; // 'all', 'present', 'absent'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersStreamProvider);
    final sessionsAsync = ref.watch(sessionsProvider);

    final currentSession = sessionsAsync.maybeWhen(
      data: (sessions) => sessions.firstWhere(
        (s) => s.id == widget.session.id,
        orElse: () => widget.session,
      ),
      orElse: () => widget.session,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Domain Attendance Roster',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          currentSession.title,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  membersAsync.maybeWhen(
                    data: (allMembers) {
                      String normalizeDomain(String d) {
                        final lower = d.trim().toLowerCase();
                        if (lower.contains('web')) return 'web_dev';
                        if (lower.contains('dsa') || lower.contains('structure') || lower.contains('algorithm')) return 'dsa';
                        if (lower.contains('ml') || lower.contains('machine') || lower.contains('learning')) return 'ml';
                        if (lower.contains('mobile') || lower.contains('android') || lower.contains('flutter')) return 'mobile';
                        if (lower.contains('cloud') || lower.contains('devops')) return 'cloud';
                        return lower;
                      }

                      final targetTags = currentSession.allDomainTags.map((t) => normalizeDomain(t)).toSet();
                      final isGeneral = targetTags.contains('general') || targetTags.contains('all');

                      final targetStudents = allMembers.where((m) {
                        // Role check
                        if (currentSession.targetRole == 'member' && m.role != UserRole.member) return false;
                        if (currentSession.targetRole == 'lead' && m.role != UserRole.lead) return false;

                        // Domain check
                        if (isGeneral) return true;
                        final studentDomains = m.domainsFollowing.map((d) => normalizeDomain(d)).toSet();
                        return studentDomains.intersection(targetTags).isNotEmpty;
                      }).toList();

                      final displayList = targetStudents;
                      final presentStudents = displayList.where((m) => currentSession.attendees.contains(m.uid)).toList();
                      final absentStudents = displayList.where((m) => !currentSession.attendees.contains(m.uid)).toList();
                      final attendanceRate = displayList.isNotEmpty
                          ? (presentStudents.length / displayList.length * 100).toStringAsFixed(0)
                          : '0';

                      return PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Export',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        tooltip: 'Export Attendance',
                        color: AppColors.surface,
                        onSelected: (value) {
                          if (value == 'excel') {
                            _exportAsCsv(context, currentSession, displayList, presentStudents, absentStudents, attendanceRate);
                          } else if (value == 'pdf') {
                            _exportAsPdfReport(context, currentSession, displayList, presentStudents, absentStudents, attendanceRate);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'excel',
                            child: Row(
                              children: [
                                Icon(Icons.table_chart_rounded, color: AppColors.success, size: 18),
                                SizedBox(width: 8),
                                Text('Export to Excel (.csv)', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'pdf',
                            child: Row(
                              children: [
                                Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 18),
                                SizedBox(width: 8),
                                Text('Export PDF / HTML Report', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Target Domain & Audience Badges
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...currentSession.allDomainTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '#${tag.toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        currentSession.targetRole == 'member'
                            ? '👥 MEMBERS ONLY'
                            : currentSession.targetRole == 'lead'
                                ? '⭐ LEADS ONLY'
                                : '👥 ALL (MEMBERS & LEADS)',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: membersAsync.when(
                  data: (allMembers) {
                    String normalizeDomain(String d) {
                      final lower = d.trim().toLowerCase();
                      if (lower.contains('web')) return 'web_dev';
                      if (lower.contains('dsa') || lower.contains('structure') || lower.contains('algorithm')) return 'dsa';
                      if (lower.contains('ml') || lower.contains('machine') || lower.contains('learning')) return 'ml';
                      if (lower.contains('mobile') || lower.contains('android') || lower.contains('flutter')) return 'mobile';
                      if (lower.contains('cloud') || lower.contains('devops')) return 'cloud';
                      return lower;
                    }

                    final targetTags = currentSession.allDomainTags.map((t) => normalizeDomain(t)).toSet();
                    final isGeneral = targetTags.contains('general') || targetTags.contains('all');

                    final targetStudents = allMembers.where((m) {
                      // Role check
                      if (currentSession.targetRole == 'member' && m.role != UserRole.member) return false;
                      if (currentSession.targetRole == 'lead' && m.role != UserRole.lead) return false;

                      // Domain check
                      if (isGeneral) return true;
                      final studentDomains = m.domainsFollowing.map((d) => normalizeDomain(d)).toSet();
                      return studentDomains.intersection(targetTags).isNotEmpty;
                    }).toList();

                    final displayList = targetStudents;

                    final presentStudents = displayList.where((m) => currentSession.attendees.contains(m.uid)).toList();
                    final absentStudents = displayList.where((m) => !currentSession.attendees.contains(m.uid)).toList();

                    final query = _searchController.text.trim().toLowerCase();
                    var filteredList = displayList.where((m) {
                      final matchesQuery = query.isEmpty ||
                          m.name.toLowerCase().contains(query) ||
                          m.batch.toLowerCase().contains(query);
                      if (!matchesQuery) return false;

                      if (_selectedFilter == 'present') {
                        return currentSession.attendees.contains(m.uid);
                      } else if (_selectedFilter == 'absent') {
                        return !currentSession.attendees.contains(m.uid);
                      }
                      return true;
                    }).toList();

                    filteredList.sort((a, b) {
                      final aPresent = currentSession.attendees.contains(a.uid);
                      final bPresent = currentSession.attendees.contains(b.uid);
                      if (aPresent && !bPresent) return -1;
                      if (!aPresent && bPresent) return 1;
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    });

                    final attendanceRate = displayList.isNotEmpty
                        ? (presentStudents.length / displayList.length * 100).toStringAsFixed(0)
                        : '0';

                    return Column(
                      children: [
                        // Stats summary bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Target Students', '${displayList.length}', AppColors.textPrimary),
                              _buildStatItem('Present', '${presentStudents.length}', AppColors.success),
                              _buildStatItem('Absent', '${absentStudents.length}', AppColors.error),
                              _buildStatItem('Rate', '$attendanceRate%', AppColors.accent),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Search input
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search student name or batch...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            fillColor: AppColors.background,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Filter choice chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: Text('All Target (${displayList.length})'),
                                selected: _selectedFilter == 'all',
                                onSelected: (val) {
                                  if (val) setState(() => _selectedFilter = 'all');
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.25),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('Present (${presentStudents.length})'),
                                selected: _selectedFilter == 'present',
                                onSelected: (val) {
                                  if (val) setState(() => _selectedFilter = 'present');
                                },
                                selectedColor: AppColors.success.withValues(alpha: 0.25),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('Absent (${absentStudents.length})'),
                                selected: _selectedFilter == 'absent',
                                onSelected: (val) {
                                  if (val) setState(() => _selectedFilter = 'absent');
                                },
                                selectedColor: AppColors.error.withValues(alpha: 0.25),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Student List
                        Expanded(
                          child: filteredList.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No students match the current filter.',
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final student = filteredList[index];
                                    final isPresent = currentSession.attendees.contains(student.uid);

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      color: AppColors.surface,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        leading: AppAvatar(
                                          photoUrl: student.photoUrl,
                                          name: student.name,
                                          radius: 20,
                                        ),
                                        title: Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${student.batch.isNotEmpty ? student.batch : "Member"} • ${student.domainsFollowing.isEmpty ? "No domain" : student.domainsFollowing.join(", ")}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: ElevatedButton.icon(
                                          onPressed: () async {
                                            await ref.read(databaseRepositoryProvider).toggleAttendance(
                                                  currentSession.id,
                                                  student.uid,
                                                  !isPresent,
                                                );
                                            ref.invalidate(sessionsProvider);
                                          },
                                          icon: Icon(
                                            isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                            size: 16,
                                          ),
                                          label: Text(isPresent ? 'PRESENT' : 'ABSENT'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isPresent ? AppColors.success : AppColors.error.withValues(alpha: 0.2),
                                            foregroundColor: isPresent ? Colors.white : AppColors.error,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            textStyle: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error loading members: $e')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
