import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/standalone_quiz_model.dart';
import '../../services/service_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/glass_container.dart';

class QuizRuntimeScreen extends ConsumerStatefulWidget {
  final StandaloneQuizModel quiz;

  const QuizRuntimeScreen({super.key, required this.quiz});

  @override
  ConsumerState<QuizRuntimeScreen> createState() => _QuizRuntimeScreenState();
}

class _QuizRuntimeScreenState extends ConsumerState<QuizRuntimeScreen> {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionIndex -> selectedOptionIndex
  bool _isSubmitted = false;
  int _score = 0;

  Timer? _globalTimer;
  Timer? _questionTimer;

  int _remainingGlobalSeconds = 0;
  int _remainingQuestionSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  void _startQuiz() {
    if (widget.quiz.type == 'timed') {
      if (widget.quiz.timeLimitMinutes != null && widget.quiz.timeLimitMinutes! > 0) {
        _remainingGlobalSeconds = widget.quiz.timeLimitMinutes! * 60;
        _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_remainingGlobalSeconds > 0) {
            setState(() => _remainingGlobalSeconds--);
          } else {
            _submitQuiz();
          }
        });
      }

      if (widget.quiz.questionTimeLimitSeconds != null && widget.quiz.questionTimeLimitSeconds! > 0) {
        _startQuestionTimer();
      }
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _remainingQuestionSeconds = widget.quiz.questionTimeLimitSeconds!;
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingQuestionSeconds > 0) {
        setState(() => _remainingQuestionSeconds--);
      } else {
        _nextQuestionOrSubmit();
      }
    });
  }

  void _nextQuestionOrSubmit() {
    if (!_selectedAnswers.containsKey(_currentIndex)) return;

    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      if (widget.quiz.type == 'timed' && widget.quiz.questionTimeLimitSeconds != null && widget.quiz.questionTimeLimitSeconds! > 0) {
        _startQuestionTimer();
      }
    } else {
      _submitQuiz();
    }
  }

  void _submitQuiz() async {
    _globalTimer?.cancel();
    _questionTimer?.cancel();

    int score = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_selectedAnswers[i] == widget.quiz.questions[i].correctIndex) {
        score++;
      }
    }

    setState(() {
      _score = score;
      _isSubmitted = true;
    });

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final db = ref.read(databaseRepositoryProvider);
      await db.submitQuizResult(
        user.uid,
        widget.quiz.id,
        score,
        widget.quiz.questions.length,
      );
    }
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _questionTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Result'),
        ),
        body: Center(
          child: GlassContainer(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 64, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  'Quiz Completed!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You scored $_score out of ${widget.quiz.questions.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                AnimatedButton(
                  onPressed: () => Navigator.pop(context),
                  text: 'Return to Dashboard',
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: const Center(child: Text('This quiz has no questions.')),
      );
    }

    final question = widget.quiz.questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          if (_globalTimer != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: AppColors.error, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_remainingGlobalSeconds),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.quiz.questions.length,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            
            if (_questionTimer != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1}/${widget.quiz.questions.length}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.hourglass_bottom, color: AppColors.accent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_remainingQuestionSeconds}s',
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Question ${_currentIndex + 1}/${widget.quiz.questions.length}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.question,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    ...List.generate(question.options.length, (index) {
                      final isSelected = _selectedAnswers[_currentIndex] == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedAnswers[_currentIndex] = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedButton(
                onPressed: _selectedAnswers.containsKey(_currentIndex) ? _nextQuestionOrSubmit : () {},
                text: _currentIndex == widget.quiz.questions.length - 1 ? 'Submit' : 'Next',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
