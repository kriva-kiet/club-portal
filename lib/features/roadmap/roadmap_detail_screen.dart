import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/domain_model.dart';
import '../../models/user_model.dart';
import '../../services/service_providers.dart';

// Providers scoped to a domain for modules and topics
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
        leadUserId: '',
        password: '',
        modules: [],
      ),
    );

    final isFollowing = user?.domainsFollowing.contains(domainId) ?? false;
    final isGated = user?.role == UserRole.member && !isFollowing;

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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                   .shimmer(duration: 2.seconds, color: AppColors.primary.withValues(alpha: 0.3))
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Module header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${moduleIndex + 1}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          module.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

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
                          return Column(
                            children: topics.map((topic) {
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
                                        AnimatedContainer(
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
                                              if (topic.resources.isNotEmpty)
                                                Text(
                                                  '${topic.resources.length} resource${topic.resources.length > 1 ? "s" : ""}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.textMuted,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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
    dynamic topic,
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
                      : AppColors.primary;

                  return Container(
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
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close current topic sheet
                      _showQuizSheet(
                        context,
                        ref,
                        topic.id,
                        topic.title,
                        domainId,
                        totalTopics,
                        uid,
                      );
                    },
                    icon: const Icon(Icons.quiz_rounded, size: 20),
                    label: const Text('Take Checkpoint Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
    String topicId,
    String topicTitle,
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
      builder: (context) => _CheckpointQuizFlow(
        topicId: topicId,
        topicTitle: topicTitle,
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
  final String topicId;
  final String topicTitle;
  final String domainId;
  final int totalTopics;
  final String uid;
  final WidgetRef ref;

  const _CheckpointQuizFlow({
    required this.topicId,
    required this.topicTitle,
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

  List<QuizQuestion> get _questions {
    return QuizDatabase.registry[widget.topicId] ??
        QuizDatabase.fallbackQuestions;
  }

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
    final passed = _score >= 2;
    if (passed) {
      final db = widget.ref.read(databaseRepositoryProvider);
      await db.toggleTopicCompletion(
        widget.uid,
        widget.domainId,
        widget.topicId,
        true,
        widget.totalTopics,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_quizFinished) {
      final passed = _score >= 2;
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
              'You scored $_score out of ${_questions.length} questions correctly.',
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
                backgroundColor: passed ? AppColors.success : AppColors.primary,
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
            widget.topicTitle,
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
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
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
                            ? AppColors.primary
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
  static final Map<String, List<QuizQuestion>> registry = {
    'dsa_top1': [
      QuizQuestion(
        question:
            'What is the optimal time complexity to solve "Contains Duplicate" using a Set?',
        options: ['O(1)', 'O(N)', 'O(N log N)', 'O(N^2)'],
        correctIndex: 1,
      ),
      QuizQuestion(
        question:
            'What is the space complexity of the optimal hash set approach?',
        options: ['O(1)', 'O(N)', 'O(log N)'],
        correctIndex: 1,
      ),
      QuizQuestion(
        question:
            'If the input array is sorted, how can you solve it in O(1) space?',
        options: [
          'Compare adjacent elements',
          'Use a binary search tree',
          'Use two pointers',
        ],
        correctIndex: 0,
      ),
    ],
    'dsa_top2': [
      QuizQuestion(
        question:
            'What is the optimal time complexity of the Two Sum problem using a hash map?',
        options: ['O(N^2)', 'O(N log N)', 'O(N)'],
        correctIndex: 2,
      ),
      QuizQuestion(
        question:
            'In the hash map solution, what do we store as the key in our map?',
        options: [
          'The index of element',
          'The complement (target - nums[i])',
          'The actual element value',
        ],
        correctIndex: 2,
      ),
      QuizQuestion(
        question:
            'What is the space complexity of the optimal Two Sum solution?',
        options: ['O(1)', 'O(N)', 'O(N log N)'],
        correctIndex: 1,
      ),
    ],
    'web_top1': [
      QuizQuestion(
        question:
            'Which HTML tag represents self-contained content, like a blog post or news story?',
        options: ['<section>', '<article>', '<aside>', '<div>'],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'What is the main purpose of semantic HTML tags?',
        options: [
          'To make styling easier',
          'To improve SEO and accessibility',
          'To increase loading speed',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        question: 'Which of the following is NOT a semantic HTML5 tag?',
        options: ['<header>', '<nav>', '<span>', '<footer>'],
        correctIndex: 2,
      ),
    ],
  };

  static final List<QuizQuestion> fallbackQuestions = [
    QuizQuestion(
      question:
          'Which time complexity represents linear logarithmic complexity?',
      options: ['O(N)', 'O(N log N)', 'O(log N)', 'O(N^2)'],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'What is the purpose of Git version control?',
      options: [
        'Compile code',
        'Track changes in source code',
        'Deploy websites automatically',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      question: 'Which of these is a database management system?',
      options: ['JSON', 'PostgreSQL', 'HTML5'],
      correctIndex: 1,
    ),
  ];
}
