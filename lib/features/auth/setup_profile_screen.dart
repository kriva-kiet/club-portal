import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_providers.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedBatch = 'Batch of 2026';
  final List<String> _selectedDomains = [];
  String _avatarSeed = '';
  bool _isSaving = false;

  final List<String> _batchOptions = [
    'Batch of 2024',
    'Batch of 2025',
    'Batch of 2026',
    'Batch of 2027',
    'Batch of 2028',
  ];

  @override
  void initState() {
    super.initState();
    // Generate initial avatar seed
    _nameController.addListener(() {
      setState(() {
        _avatarSeed = _nameController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final photoUrl =
          'https://api.dicebear.com/7.x/avataaars/png?seed=${_avatarSeed.isEmpty ? "kriva" : _avatarSeed}';

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.completeProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        batch: _selectedBatch,
        domains: _selectedDomains,
        photoUrl: photoUrl,
      );

      // GoRouter authState changes will automatically trigger redirection to home
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to complete profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainsAsync = ref.watch(domainsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar display
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              color: AppColors.surface,
                            ),
                            child: ClipOval(
                              child: Image.network(
                                'https://api.dicebear.com/7.x/avataaars/png?seed=${_avatarSeed.isEmpty ? "kriva" : _avatarSeed}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.account_circle_outlined,
                                      size: 80,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type your name below to randomize avatar seed!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bio Field
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText:
                            'Share your background, interests, or what you want to learn...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 40.0),
                          child: Icon(Icons.description_outlined, size: 20),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please write a short bio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Batch Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBatch,
                      decoration: const InputDecoration(
                        labelText: 'Batch',
                        prefixIcon: Icon(Icons.school_outlined, size: 20),
                      ),
                      dropdownColor: AppColors.surface,
                      items: _batchOptions.map((batch) {
                        return DropdownMenuItem<String>(
                          value: batch,
                          child: Text(batch),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBatch = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Interests Section
                    Text(
                      'Technical Domain Interests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Domain loader
                    domainsAsync.when(
                      data: (domains) {
                        if (domains.isEmpty) {
                          return const Text('No domains configured yet.');
                        }
                        return Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: domains.map((domain) {
                            final isSelected = _selectedDomains.contains(
                              domain.id,
                            );
                            return FilterChip(
                              label: Text(domain.name),
                              selected: isSelected,
                              selectedColor: Theme.of(context).colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              checkmarkColor: Theme.of(context).colorScheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : AppColors.border,
                                  width: 1,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedDomains.add(domain.id);
                                  } else {
                                    _selectedDomains.remove(domain.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: LinearProgressIndicator()),
                      error: (e, s) => Text('Error loading interests: $e'),
                    ),

                    const SizedBox(height: 36),

                    // Save Button
                    _isSaving
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _handleSave,
                            child: const Text('Complete Onboarding'),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
