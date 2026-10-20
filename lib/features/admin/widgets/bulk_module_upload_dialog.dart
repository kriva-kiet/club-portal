import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:uuid/uuid.dart';

import '../../../models/domain_model.dart';
import '../../../models/standalone_quiz_model.dart';
import '../../../services/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../roadmap/roadmap_detail_screen.dart';

class BulkModuleUploadDialog extends ConsumerStatefulWidget {
  final String domainId;
  final String domainName;

  const BulkModuleUploadDialog({
    super.key,
    required this.domainId,
    required this.domainName,
  });

  @override
  ConsumerState<BulkModuleUploadDialog> createState() =>
      _BulkModuleUploadDialogState();
}

class _BulkModuleUploadDialogState extends ConsumerState<BulkModuleUploadDialog> {
  bool _isProcessing = false;
  String? _statusMessage;
  List<Map<String, dynamic>>? _parsedModules;

  static const String _templateJson = '''[
  {
    "title": "Module 1: Foundations & Setup",
    "order": 1,
    "resources": [
      {
        "title": "Module Overview Doc",
        "url": "https://example.com/overview.pdf",
        "type": "doc"
      }
    ],
    "topics": [
      {
        "title": "Topic 1.1: Git & GitHub Workflow",
        "order": 1,
        "resources": [
          {
            "title": "Git Basics Tutorial",
            "url": "https://www.youtube.com/watch?v=example",
            "type": "video"
          },
          {
            "title": "Interactive Git Sandbox",
            "url": "https://learngitbranching.js.org/",
            "type": "practice"
          }
        ],
        "quizQuestions": [
          {
            "question": "Which command initializes a new local Git repository?",
            "options": [
              "git start",
              "git init",
              "git clone",
              "git branch"
            ],
            "correctOptionIndex": 1
          }
        ]
      },
      {
        "title": "Topic 1.2: Terminal & Command Line Basics",
        "order": 2
      }
    ]
  },
  {
    "title": "Module 2: Core Concepts & Practice",
    "order": 2,
    "topics": [
      {
        "title": "Topic 2.1: Fundamentals",
        "order": 1
      }
    ]
  }
]''';

  Future<void> _downloadTemplate() async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(_templateJson));
      await FileSaver.instance.saveFile(
        name: 'roadmap_modules_template.json',
        bytes: bytes,
        mimeType: MimeType.json,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template downloaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading template: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickAndParseJson() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.isEmpty) return;

      final fileBytes = await result.single.readAsBytes();
      if (fileBytes == null) {
        throw Exception("Could not read the uploaded file.");
      }

      final jsonString = utf8.decode(fileBytes);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw Exception(
            "Invalid JSON format. Root structure must be a JSON Array [ ... ] of modules.");
      }

      if (decoded.isEmpty) {
        throw Exception("The uploaded JSON array contains no modules.");
      }

      // Validate required keys: module.title, module.order, module.topics
      for (int i = 0; i < decoded.length; i++) {
        final mod = decoded[i];
        if (mod is! Map) {
          throw Exception("Module at position ${i + 1} is not a valid JSON object.");
        }
        if (mod['title'] == null || mod['title'].toString().trim().isEmpty) {
          throw Exception("Module at position ${i + 1} is missing required 'title'.");
        }
        if (mod['topics'] == null || mod['topics'] is! List || (mod['topics'] as List).isEmpty) {
          throw Exception("Module '${mod['title']}' must have a required non-empty 'topics' array.");
        }
        final topicsList = mod['topics'] as List;
        for (int j = 0; j < topicsList.length; j++) {
          final top = topicsList[j];
          if (top is! Map) {
            throw Exception("Topic at position ${j + 1} in Module '${mod['title']}' is not a valid JSON object.");
          }
          if (top['title'] == null || top['title'].toString().trim().isEmpty) {
            throw Exception("Topic ${j + 1} in Module '${mod['title']}' is missing required 'title'.");
          }
        }
      }

      setState(() {
        _parsedModules = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _statusMessage = "Found ${_parsedModules!.length} valid module(s) ready for creation.";
      });
    } catch (e) {
      setState(() {
        _parsedModules = null;
        _statusMessage = null;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text('JSON Validation Error'),
              ],
            ),
            content: Text(
              e.toString().replaceAll("Exception: ", ""),
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _executeBulkUpload() async {
    if (_parsedModules == null || _parsedModules!.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Creating modules and topics in Firestore...";
    });

    final db = ref.read(databaseRepositoryProvider);
    final uuid = const Uuid();
    int createdModuleCount = 0;
    int createdTopicCount = 0;

    try {
      for (int i = 0; i < _parsedModules!.length; i++) {
        final modMap = _parsedModules![i];
        final String modTitle = modMap['title'].toString().trim();
        final int modOrder = int.tryParse(modMap['order']?.toString() ?? '') ?? (i + 1);

        // Parse optional module resources
        List<ResourceModel> moduleResources = [];
        if (modMap['resources'] != null && modMap['resources'] is List) {
          for (final res in modMap['resources']) {
            if (res is Map && res['title'] != null && res['url'] != null) {
              moduleResources.add(ResourceModel(
                title: res['title'].toString(),
                url: res['url'].toString(),
                type: res['type']?.toString() ?? 'link',
              ));
            }
          }
        }

        final sanitizedModTitle = modTitle.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        final moduleId = 'mod_${sanitizedModTitle}_${uuid.v4().substring(0, 5)}';

        final module = ModuleModel(
          id: moduleId,
          domainId: widget.domainId,
          title: modTitle,
          order: modOrder,
          topics: [],
          resources: moduleResources,
        );

        // Create module
        await db.createModule(widget.domainId, module);
        createdModuleCount++;

        // Parse and create topics under this module
        final topicsRaw = modMap['topics'] as List;
        for (int j = 0; j < topicsRaw.length; j++) {
          final topMap = topicsRaw[j] as Map;
          final String topTitle = topMap['title'].toString().trim();
          final int topOrder = int.tryParse(topMap['order']?.toString() ?? '') ?? (j + 1);

          // Parse optional topic resources
          List<ResourceModel> topicResources = [];
          if (topMap['resources'] != null && topMap['resources'] is List) {
            for (final res in topMap['resources']) {
              if (res is Map && res['title'] != null && res['url'] != null) {
                topicResources.add(ResourceModel(
                  title: res['title'].toString(),
                  url: res['url'].toString(),
                  type: res['type']?.toString() ?? 'link',
                ));
              }
            }
          }

          // Parse optional quiz questions
          List<QuizQuestionModel> topicQuizzes = [];
          if (topMap['quizQuestions'] != null && topMap['quizQuestions'] is List) {
            for (final q in topMap['quizQuestions']) {
              if (q is Map && q['question'] != null && q['options'] is List) {
                final optionsList = (q['options'] as List).map((o) => o.toString()).toList();
                final correctIdx = int.tryParse(q['correctOptionIndex']?.toString() ?? '0') ?? 0;

                topicQuizzes.add(QuizQuestionModel(
                  question: q['question'].toString(),
                  options: optionsList,
                  correctIndex: correctIdx >= 0 && correctIdx < optionsList.length ? correctIdx : 0,
                ));
              }
            }
          }

          final sanitizedTopTitle = topTitle.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
          final topicId = 'top_${sanitizedTopTitle}_${uuid.v4().substring(0, 5)}';

          final topic = TopicModel(
            id: topicId,
            moduleId: moduleId,
            title: topTitle,
            order: topOrder,
            resources: topicResources,
            quizQuestions: topicQuizzes,
          );

          await db.createTopic(widget.domainId, moduleId, topic);
          createdTopicCount++;
        }
      }

      ref.invalidate(modulesProvider(widget.domainId));
      ref.invalidate(domainsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully created $createdModuleCount module(s) and $createdTopicCount topic(s)!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = "Upload error: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload modules: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.file_upload_outlined, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bulk Upload Modules',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.domainName,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
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
            const Text(
              'Upload a JSON file containing modules and topics. Resources & Quizzes are optional, but Module and Topic titles & ordering are required.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _downloadTemplate,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download JSON Template'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickAndParseJson,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Select JSON File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _parsedModules != null
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _parsedModules != null
                        ? const Color(0xFF10B981)
                        : AppColors.error,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _parsedModules != null ? const Color(0xFF10B981) : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (_parsedModules != null && _parsedModules!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: _parsedModules!.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, i) {
                    final m = _parsedModules![i];
                    final String titleStr = m['title']?.toString() ?? 'Untitled';
                    final topics = (m['topics'] as List?)?.length ?? 0;
                    return Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            titleStr,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$topics topic(s)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_parsedModules == null || _isProcessing)
              ? null
              : _executeBulkUpload,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Upload & Create'),
        ),
      ],
    );
  }
}
