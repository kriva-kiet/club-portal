import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import '../../../models/standalone_quiz_model.dart';
import '../../../models/domain_model.dart';
import '../../../services/service_providers.dart';
import '../../../core/theme/app_colors.dart';

class QuizBuilderSheet extends ConsumerStatefulWidget {
  final List<DomainModel> domains;
  final String userId;

  const QuizBuilderSheet({super.key, required this.domains, required this.userId});

  @override
  ConsumerState<QuizBuilderSheet> createState() => _QuizBuilderSheetState();
}

class _QuizBuilderSheetState extends ConsumerState<QuizBuilderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  
  String? _selectedDomainId;
  String _quizType = 'simple'; // 'simple' or 'timed'
  int _timeLimitMinutes = 15;
  int _questionTimeLimitSeconds = 0; // 0 means no limit

  List<QuizQuestionModel> _questions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _addEmptyQuestion() {
    if (_questions.length >= 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 50 questions allowed.')));
      return;
    }
    setState(() {
      _questions.add(QuizQuestionModel(question: '', options: ['', '', '', ''], correctIndex: 0));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _downloadTemplate() async {
    const csvData = "Question,Option 1,Option 2,Option 3,Option 4,Correct Option Index (0 to 3)\n"
        "What is Flutter?,A Bird,An OS,A UI Toolkit,A Database,2\n"
        "What language does Flutter use?,Java,Dart,Kotlin,Swift,1\n";
    
    final bytes = utf8.encode(csvData);
    try {
      await FilePicker.saveFile(
        fileName: 'quiz_template.csv',
        bytes: Uint8List.fromList(bytes),
        mimeType: 'text/csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template downloaded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading template: $e')));
      }
    }
  }

  Future<void> _uploadCSV() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.isNotEmpty) {
        final bytes = await result.single.readAsBytes();
        final csvString = utf8.decode(bytes);
        List<List<dynamic>> rowsAsListOfValues = const CsvDecoder().convert(csvString);
        
        if (rowsAsListOfValues.isEmpty || rowsAsListOfValues.length == 1) {
          throw Exception("CSV is empty or missing data.");
        }

        List<QuizQuestionModel> importedQuestions = [];
        // Skip header row
        for (var i = 1; i < rowsAsListOfValues.length; i++) {
          if (importedQuestions.length >= 50) break; // enforce 50 questions max
          var row = rowsAsListOfValues[i];
          if (row.length >= 6) {
            String q = row[0].toString();
            List<String> options = [
              row[1].toString(),
              row[2].toString(),
              row[3].toString(),
              row[4].toString()
            ];
            int correctIndex = int.tryParse(row[5].toString()) ?? 0;
            if (correctIndex < 0 || correctIndex > 3) correctIndex = 0;
            
            if (q.isNotEmpty) {
              importedQuestions.add(QuizQuestionModel(
                question: q,
                options: options,
                correctIndex: correctIndex,
              ));
            }
          }
        }

        setState(() {
          _questions = importedQuestions;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${_questions.length} questions')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading CSV: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _submitQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDomainId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a domain.')));
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one question.')));
      return;
    }

    // Validate that questions are filled
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.question.trim().isEmpty || q.options.any((o) => o.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields for Question ${i + 1}')));
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(databaseRepositoryProvider);
      final quiz = StandaloneQuizModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        domainId: _selectedDomainId!,
        title: _titleCtrl.text.trim(),
        type: _quizType,
        timeLimitMinutes: _quizType == 'timed' ? _timeLimitMinutes : null,
        questionTimeLimitSeconds: (_quizType == 'timed' && _questionTimeLimitSeconds > 0) ? _questionTimeLimitSeconds : null,
        questions: _questions,
        createdBy: widget.userId,
        createdAt: DateTime.now(),
      );

      await repo.createStandaloneQuiz(quiz);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz created successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create New Quiz',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDomainId,
                decoration: InputDecoration(
                  labelText: 'Target Domain',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.domains.map((d) {
                  return DropdownMenuItem(value: d.id, child: Text(d.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDomainId = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Quiz Title',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Unlimited Time'),
                      value: 'simple',
                      groupValue: _quizType,
                      onChanged: (val) => setState(() => _quizType = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Timed'),
                      value: 'timed',
                      groupValue: _quizType,
                      onChanged: (val) => setState(() => _quizType = val!),
                    ),
                  ),
                ],
              ),
              if (_quizType == 'timed')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Total Quiz Time Limit (mins):'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: _timeLimitMinutes.toDouble(),
                              min: 5,
                              max: 120,
                              divisions: 23,
                              label: '$_timeLimitMinutes mins',
                              activeColor: const Color(0xFF6366F1),
                              onChanged: (val) => setState(() => _timeLimitMinutes = val.toInt()),
                            ),
                          ),
                          Text('$_timeLimitMinutes m', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Per-Question Time Limit (secs):'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: _questionTimeLimitSeconds.toDouble(),
                              min: 0,
                              max: 120,
                              divisions: 12,
                              label: _questionTimeLimitSeconds == 0 ? 'None' : '$_questionTimeLimitSeconds secs',
                              activeColor: const Color(0xFFF59E0B),
                              onChanged: (val) => setState(() => _questionTimeLimitSeconds = val.toInt()),
                            ),
                          ),
                          Text(_questionTimeLimitSeconds == 0 ? 'None' : '$_questionTimeLimitSeconds s', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${_questions.length}/50', style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Template'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadCSV,
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('Upload CSV'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addEmptyQuestion,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_questions.length, (index) {
                final q = _questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Question ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                              onPressed: () => _removeQuestion(index),
                            ),
                          ],
                        ),
                        TextFormField(
                          initialValue: q.question,
                          onChanged: (val) => _questions[index] = QuizQuestionModel(question: val, options: q.options, correctIndex: q.correctIndex),
                          decoration: const InputDecoration(labelText: 'Question Text'),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(4, (optIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: optIndex,
                                  groupValue: q.correctIndex,
                                  activeColor: AppColors.success,
                                  onChanged: (val) {
                                    setState(() {
                                      _questions[index] = QuizQuestionModel(question: q.question, options: q.options, correctIndex: val!);
                                    });
                                  },
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: q.options[optIndex],
                                    onChanged: (val) {
                                      final newOpts = List<String>.from(q.options);
                                      newOpts[optIndex] = val;
                                      _questions[index] = QuizQuestionModel(question: q.question, options: newOpts, correctIndex: q.correctIndex);
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Option ${optIndex + 1}',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Create Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
