import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/domain_model.dart';
import '../../models/standalone_quiz_model.dart';
import '../../models/user_model.dart';
import '../../services/service_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../admin/widgets/bulk_module_upload_dialog.dart';
final modulesProvider = StreamProvider.family<List<ModuleModel>, String>((
  ref,
  domainId,
) {
  final db = ref.watch(databaseRepositoryProvider);
  return db.getModules(domainId);
});

final topicsProvider =
    StreamProvider.family<
      List<TopicModel>,
      ({String domainId, String moduleId})
    >((ref, args) {
      final db = ref.watch(databaseRepositoryProvider);
      return db.getTopics(args.domainId, args.moduleId);
    });

class RoadmapDetailScreen extends ConsumerWidget {
  final String domainId;
  const RoadmapDetailScreen({super.key, required this.domainId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainsAsync = ref.watch(domainsProvider);
    final modulesAsync = ref.watch(modulesProvider(domainId));
    final user = ref.watch(currentUserProvider);
    final progressAsync = ref.watch(userProgressProvider(domainId));

    final domain = domainsAsync.valueOrNull?.firstWhere(
      (d) => d.id == domainId,
      orElse: () => DomainModel(
        id: domainId,
        name: domainId,
        description: '',
        leadUserIds: [],
        password: '',
        modules: [],
      ),
    );

    final isFollowing = user?.domainsFollowing.contains(domainId) ?? false;
    final isGated = user?.role == UserRole.member && !isFollowing;
    final isEditor = user?.role == UserRole.admin || (domain?.leadUserIds.contains(user?.uid) ?? false);

    if (isGated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(domain?.name ?? 'Roadmap'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    color: AppColors.accent,
                    size: 64,
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .shimmer(duration: 2.seconds, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
                   .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds, curve: Curves.easeInOut),
                  const SizedBox(height: 20),
                  Text(
                    'Roadmap Locked',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This curriculum is locked. Follow the "${domain?.name ?? 'Domain'}" track to unlock topics, quizzes, and start learning!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (user == null) return;
                      
                      // Handle password if any
                      if (domain != null && domain.password.isNotEmpty) {
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
                                  Text('Enter password to unlock "${domain.name}"'),
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

                      final updated = List<String>.from(user.domainsFollowing);
                      updated.add(domainId);
                      
                      await ref
                          .read(databaseRepositoryProvider)
                          .updateFollowedDomains(user.uid, updated);
                          
                      final authRepo = ref.read(authRepositoryProvider);
                      await authRepo.completeProfile(
                        name: user.name,
                        bio: user.bio,
                        batch: user.batch,
                        domains: updated,
                        photoUrl: user.photoUrl,
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Follow Domain to Unlock'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'domain_card_$domainId',
          child: Material(
            color: Colors.transparent,
            child: Text(
              domain?.name ?? 'Roadmap',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: isEditor
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'bulk_upload_fab',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => BulkModuleUploadDialog(
                        domainId: domainId,
                        domainName: domain?.name ?? 'Domain',
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Bulk JSON'),
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'add_module_fab',
                  onPressed: () => _showModuleEditorSheet(context, ref, domainId),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Module'),
                ),
              ],
            )
          : null,
      body: modulesAsync.when(
        data: (modules) {
          if (modules.isEmpty) {
            return const Center(
              child: Text(
                'No modules configured for this domain yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: modules.length,
            itemBuilder: (context, moduleIndex) {
              final module = modules[moduleIndex];

              return Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(vertical: 4),
                  title: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${moduleIndex + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          module.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isEditor) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          onPressed: () => _showModuleEditorSheet(context, ref, domainId, module: module),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
                          onPressed: () => _confirmDeleteModule(context, ref, domainId, module.id),
                        ),
                      ],
                    ],
                  ),
                  children: [
                    // Topics in module
                    Consumer(
                      builder: (context, ref, _) {
                        final topicsAsync = ref.watch(
                          topicsProvider((
                            domainId: domainId,
                            moduleId: module.id,
                          )),
                        );

                        return topicsAsync.when(
                          data: (topics) {
                            if (topics.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 42, bottom: 16, top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'No topics added yet.',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (isEditor) ...[
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: () => _showTopicEditorSheet(context, ref, domainId, module.id),
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        label: const Text('Add Topic'),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: [
                                ...topics.map((topic) {
                                final progress = progressAsync.valueOrNull;
                                final isCompleted =
                                    progress?.topicsCompleted.containsKey(
                                      topic.id,
                                    ) ??
                                    false;

                                // Count total topics across all modules (approximate)
                                final totalTopics = modules.fold(
                                  0,
                                  (sum, m) => sum + (m.topics.length),
                                );
                                final approxTotal = totalTopics > 0
                                    ? totalTopics
                                    : topics.length;

                                return Card(
                                  margin: const EdgeInsets.only(
                                    left: 16,
                                    bottom: 8,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _showTopicSheet(
                                      context,
                                      ref,
                                      topic,
                                      isCompleted,
                                      domainId,
                                      approxTotal,
                                      user?.uid ?? '',
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Completion checkbox
                                          InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () async {
                                              if (user?.uid == null || user!.uid.isEmpty) return;
                                              if (!isCompleted && topic.quizQuestions.isNotEmpty) {
                                                _showQuizSheet(
                                                  context,
                                                  ref,
                                                  topic,
                                                  domainId,
                                                  approxTotal,
                                                  user.uid,
                                                );
                                              } else {
                                                final db = ref.read(databaseRepositoryProvider);
                                                await db.toggleTopicCompletion(
                                                  user.uid,
                                                  domainId,
                                                  topic.id,
                                                  !isCompleted,
                                                  approxTotal,
                                                );
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 250,
                                              ),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isCompleted
                                                    ? AppColors.success
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: isCompleted
                                                      ? AppColors.success
                                                      : AppColors.border,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isCompleted
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 14,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  topic.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: isCompleted
                                                        ? AppColors.textMuted
                                                        : AppColors.textPrimary,
                                                    decoration: isCompleted
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                    decorationColor:
                                                        AppColors.textMuted,
                                                  ),
                                                ),
                                                if (topic.resources.isNotEmpty || topic.quizQuestions.isNotEmpty)
                                                  Row(
                                                    children: [
                                                      if (topic.resources.isNotEmpty)
                                                        Text(
                                                          '${topic.resources.length} resource${topic.resources.length > 1 ? "s" : ""}',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors.textMuted,
                                                          ),
                                                        ),
                                                      if (topic.resources.isNotEmpty && topic.quizQuestions.isNotEmpty)
                                                        const Text(
                                                          ' • ',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors.textMuted,
                                                          ),
                                                        ),
                                                      if (topic.quizQuestions.isNotEmpty)
                                                        Text(
                                                          '${topic.quizQuestions.length} quiz Qs',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors.accent,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isEditor) ...[
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, size: 20),
                                              onPressed: () => _showTopicEditorSheet(context, ref, domainId, module.id, topic: topic),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
                                              onPressed: () => _confirmDeleteTopic(context, ref, domainId, module.id, topic.id),
                                            ),
                                          ] else ...[
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppColors.textMuted,
                                              size: 20,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (isEditor)
                                Padding(
                                  padding: const EdgeInsets.only(left: 42, bottom: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => _showTopicEditorSheet(context, ref, domainId, module.id),
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: const Text('Add Topic'),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: LinearProgressIndicator(),
                            ),
                          ),
                          error: (e, s) => Text('Error: $e'),
                        );
                      },
                    ),
                    if (moduleIndex < modules.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Divider(),
                      ),
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

  void _showTopicSheet(
    BuildContext context,
    WidgetRef ref,
    TopicModel topic,
    bool isCompleted,
    String domainId,
    int totalTopics,
    String uid,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(topic.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isCompleted
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted ? 'Completed' : 'Not started',
                    style: TextStyle(
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Resources
              if (topic.resources.isNotEmpty) ...[
                Text(
                  'Resources',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...topic.resources.map<Widget>((resource) {
                  final icon = resource.type == 'video'
                      ? Icons.play_circle_outline_rounded
                      : resource.type == 'practice'
                      ? Icons.sports_esports_outlined
                      : resource.type == 'doc'
                      ? Icons.article_outlined
                      : Icons.link_rounded;
                  final color = resource.type == 'video'
                      ? Colors.redAccent
                      : resource.type == 'practice'
                      ? AppColors.accent
                      : resource.type == 'doc'
                      ? AppColors.secondary
                      : Theme.of(context).colorScheme.primary;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        String finalUrl = resource.url.trim();
                        if (finalUrl.isEmpty) return;
                        if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
                          finalUrl = 'https://$finalUrl';
                        }
                        try {
                          final uri = Uri.parse(finalUrl);
                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                            final fallback = await launchUrl(
                              uri,
                              mode: LaunchMode.platformDefault,
                            );
                            if (!fallback && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not open ${resource.url}')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open ${resource.url}')),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resource.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    resource.url,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],

              // Mark Complete / Undo button / Take Quiz flow
              if (uid.isNotEmpty) ...[
                if (isCompleted)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final db = ref.read(databaseRepositoryProvider);
                      await db.toggleTopicCompletion(
                        uid,
                        domainId,
                        topic.id,
                        false,
                        totalTopics,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    label: const Text('Mark Incomplete (Reset)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                  )
                else if (topic.quizQuestions.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close current topic sheet
                      _showQuizSheet(
                        context,
                        ref,
                        topic,
                        domainId,
                        totalTopics,
                        uid,
                      );
                    },
                    icon: const Icon(Icons.quiz_rounded, size: 20),
                    label: Text('Take Checkpoint Quiz (${topic.quizQuestions.length} Qs)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      final db = ref.read(databaseRepositoryProvider);
                      await db.toggleTopicCompletion(
                        uid,
                        domainId,
                        topic.id,
                        true,
                        totalTopics,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQuizSheet(
    BuildContext context,
    WidgetRef ref,
    TopicModel topic,
    String domainId,
    int totalTopics,
    String uid,
  ) {
    if (topic.quizQuestions.isEmpty) {
      final db = ref.read(databaseRepositoryProvider);
      db.toggleTopicCompletion(uid, domainId, topic.id, true, totalTopics);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CheckpointQuizFlow(
        topic: topic,
        domainId: domainId,
        totalTopics: totalTopics,
        uid: uid,
        ref: ref,
      ),
    );
  }
}

// ── Checkpoint Quiz Flow Stateful Widget ──────────────────────────────────────
class _CheckpointQuizFlow extends StatefulWidget {
  final TopicModel topic;
  final String domainId;
  final int totalTopics;
  final String uid;
  final WidgetRef ref;

  const _CheckpointQuizFlow({
    required this.topic,
    required this.domainId,
    required this.totalTopics,
    required this.uid,
    required this.ref,
  });

  @override
  State<_CheckpointQuizFlow> createState() => _CheckpointQuizFlowState();
}

class _CheckpointQuizFlowState extends State<_CheckpointQuizFlow> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _quizFinished = false;

  List<QuizQuestionModel> get _questions => widget.topic.quizQuestions;

  void _submitAnswer() {
    if (_selectedAnswerIndex == null) return;

    if (_selectedAnswerIndex == _questions[_currentIndex].correctIndex) {
      _score++;
    }

    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _selectedAnswerIndex = null;
      } else {
        _quizFinished = true;
      }
    });
  }

  void _completeVerification() async {
    final passingCutoff =
        (_questions.length * 0.6).ceil().clamp(1, _questions.length);
    final passed = _score >= passingCutoff;
    if (passed) {
      final db = widget.ref.read(databaseRepositoryProvider);
      await db.toggleTopicCompletion(
        widget.uid,
        widget.domainId,
        widget.topic.id,
        true,
        widget.totalTopics,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final passingCutoff =
        (_questions.length * 0.6).ceil().clamp(1, _questions.length);
    final passed = _score >= passingCutoff;

    if (_quizFinished) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Icon(
                passed ? Icons.verified_rounded : Icons.cancel_rounded,
                color: passed ? AppColors.success : AppColors.error,
                size: 72,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              passed ? 'Verification Passed! 🎉' : 'Quiz Failed ❌',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'You scored $_score out of ${_questions.length} questions correctly. (Passing: $passingCutoff/${_questions.length})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _completeVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: passed
                    ? AppColors.success
                    : Theme.of(context).colorScheme.primary,
              ),
              child: Text(passed ? 'Unlock Progress' : 'Close & Retry'),
            ),
          ],
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Checkpoint Challenge',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.accent,
                ),
              ),
              Text(
                'Question ${_currentIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.topic.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 24),
          Text(
            currentQuestion.question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(currentQuestion.options.length, (idx) {
            final option = currentQuestion.options[idx];
            final isSelected = _selectedAnswerIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedAnswerIndex = idx);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedAnswerIndex == null ? null : _submitAnswer,
            child: Text(
              _currentIndex < _questions.length - 1
                  ? 'Next Question'
                  : 'Submit Challenge',
            ),
          ),
        ],
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class QuizDatabase {
  static final Map<String, List<QuizQuestion>> registry = {};
  static final List<QuizQuestion> fallbackQuestions = [];
}

// ── Admin/Lead Editors ────────────────────────────────────────────────────────

void _showModuleEditorSheet(
  BuildContext context,
  WidgetRef ref,
  String domainId, {
  ModuleModel? module,
}) {
  final titleCtrl = TextEditingController(text: module?.title ?? '');
  final orderCtrl = TextEditingController(text: module?.order.toString() ?? '1');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
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
            Text(
              module == null ? 'Add Module' : 'Edit Module',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Module Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Order (e.g. 1)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;

                final newModule = module?.copyWith(
                      title: titleCtrl.text.trim(),
                      order: int.tryParse(orderCtrl.text.trim()) ?? 1,
                    ) ??
                    ModuleModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      domainId: domainId,
                      title: titleCtrl.text.trim(),
                      order: int.tryParse(orderCtrl.text.trim()) ?? 1,
                      topics: [],
                    );

                final db = ref.read(databaseRepositoryProvider);
                if (module == null) {
                  await db.createModule(domainId, newModule);
                } else {
                  await db.updateModule(domainId, newModule);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Module'),
            ),
          ],
        ),
      );
    },
  );
}

void _confirmDeleteModule(
  BuildContext context,
  WidgetRef ref,
  String domainId,
  String moduleId,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Module?'),
      content: const Text('This will delete the module and all its topics.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            await ref.read(databaseRepositoryProvider).deleteModule(domainId, moduleId);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

Future<QuizQuestionModel?> _showQuizQuestionDialog(
  BuildContext context, {
  QuizQuestionModel? initialQuestion,
}) async {
  final qCtrl = TextEditingController(text: initialQuestion?.question ?? '');
  final optCtrls = List.generate(
    4,
    (i) => TextEditingController(
      text: initialQuestion != null && i < initialQuestion.options.length
          ? initialQuestion.options[i]
          : '',
    ),
  );
  int correctIdx = initialQuestion?.correctIndex ?? 0;
  final formKey = GlobalKey<FormState>();

  return showDialog<QuizQuestionModel>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              initialQuestion == null ? 'Add Quiz Question' : 'Edit Quiz Question',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: qCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Question Prompt *',
                          hintText: 'e.g. What is Bayes Theorem used for?',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Question cannot be empty' : null,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Options (Select radio for correct answer):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(4, (i) {
                        final isCorrect = correctIdx == i;
                        final label = String.fromCharCode(65 + i); // A, B, C, D
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setDialogState(() => correctIdx = i);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Radio<int>(
                                        value: i,
                                        groupValue: correctIdx,
                                        onChanged: (val) {
                                          if (val != null) {
                                            setDialogState(() => correctIdx = val);
                                          }
                                        },
                                        activeColor: AppColors.success,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      Text(
                                        '$label.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isCorrect ? AppColors.success : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextFormField(
                                  controller: optCtrls[i],
                                  decoration: InputDecoration(
                                    hintText: 'Option $label${i < 2 ? " *" : " (optional)"}',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (i < 2 && (v == null || v.trim().isEmpty)) {
                                      return 'Option $label is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final options = optCtrls
                      .map((c) => c.text.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  if (options.length < 2) return;

                  final finalCorrectIdx = correctIdx.clamp(0, options.length - 1);

                  Navigator.pop(
                    dialogCtx,
                    QuizQuestionModel(
                      question: qCtrl.text.trim(),
                      options: options,
                      correctIndex: finalCorrectIdx,
                    ),
                  );
                },
                child: const Text('Save Question'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showTopicEditorSheet(
  BuildContext context,
  WidgetRef ref,
  String domainId,
  String moduleId, {
  TopicModel? topic,
}) {
  final titleCtrl = TextEditingController(text: topic?.title ?? '');
  final orderCtrl = TextEditingController(text: topic?.order.toString() ?? '1');
  
  // Quick dynamic fields for resources
  List<ResourceModel> resources = List.from(topic?.resources ?? []);
  List<QuizQuestionModel> quizQuestions = List.from(topic?.quizQuestions ?? []);
  if (quizQuestions.isEmpty && topic != null && QuizDatabase.registry.containsKey(topic.id)) {
    quizQuestions = QuizDatabase.registry[topic.id]!
        .map((q) => QuizQuestionModel(
              question: q.question,
              options: q.options,
              correctIndex: q.correctIndex,
            ))
        .toList();
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  topic == null ? 'Add Topic' : 'Edit Topic',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Topic Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Order (e.g. 1)'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Resources',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...resources.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  return Row(
                    children: [
                      Expanded(child: Text('${r.type.toUpperCase()}: ${r.title}')),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            resources.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  );
                }),
                TextButton.icon(
                  onPressed: () async {
                    // Simple dialog to add resource
                    final rTitleCtrl = TextEditingController();
                    final rUrlCtrl = TextEditingController();
                    String rType = 'video';
                    
                    final result = await showDialog<ResourceModel>(
                      context: context,
                      builder: (ctx) {
                        return StatefulBuilder(builder: (ctx, setDialogState) {
                          return AlertDialog(
                            title: const Text('Add Resource'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: rTitleCtrl,
                                  decoration: const InputDecoration(labelText: 'Resource Title'),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: rUrlCtrl,
                                  decoration: const InputDecoration(labelText: 'URL'),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: rType,
                                  items: ['video', 'link', 'doc', 'practice'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => rType = val);
                                  },
                                  decoration: const InputDecoration(labelText: 'Type'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  if (rTitleCtrl.text.trim().isEmpty || rUrlCtrl.text.trim().isEmpty) return;
                                  Navigator.pop(ctx, ResourceModel(title: rTitleCtrl.text.trim(), url: rUrlCtrl.text.trim(), type: rType));
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          );
                        });
                      }
                    );
                    
                    if (result != null) {
                      setState(() {
                        resources.add(result);
                      });
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Resource'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.quiz_rounded, size: 18, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          'Checkpoint Quiz Questions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${quizQuestions.length} added',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Custom quiz challenge users must pass to complete this topic.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                if (quizQuestions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'No custom questions yet. Will use default checkpoint questions until you add custom ones.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  )
                else
                  ...quizQuestions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;
                    final correctOpt = q.options.isNotEmpty && q.correctIndex < q.options.length
                        ? q.options[q.correctIndex]
                        : 'Option ${q.correctIndex + 1}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.question,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  final updated = await _showQuizQuestionDialog(
                                    context,
                                    initialQuestion: q,
                                  );
                                  if (updated != null) {
                                    setState(() {
                                      quizQuestions[idx] = updated;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    quizQuestions.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(
                              '✓ Correct: $correctOpt (${q.options.length} options)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final newQ = await _showQuizQuestionDialog(context);
                      if (newQ != null) {
                        setState(() {
                          quizQuestions.add(newQ);
                        });
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: const Text('Add Quiz Question'),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;

                    final newTopic = topic?.copyWith(
                          title: titleCtrl.text.trim(),
                          order: int.tryParse(orderCtrl.text.trim()) ?? 1,
                          resources: resources,
                          quizQuestions: quizQuestions,
                        ) ??
                        TopicModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          moduleId: moduleId,
                          title: titleCtrl.text.trim(),
                          order: int.tryParse(orderCtrl.text.trim()) ?? 1,
                          resources: resources,
                          quizQuestions: quizQuestions,
                        );

                    final db = ref.read(databaseRepositoryProvider);
                    if (topic == null) {
                      await db.createTopic(domainId, moduleId, newTopic);
                    } else {
                      await db.updateTopic(domainId, moduleId, newTopic);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Topic'),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
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
    builder: (context) => AlertDialog(
      title: const Text('Delete Topic?'),
      content: const Text('This will permanently delete this topic.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            await ref.read(databaseRepositoryProvider).deleteTopic(domainId, moduleId, topicId);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
