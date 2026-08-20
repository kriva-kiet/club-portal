import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/access_request_model.dart';
import '../../services/service_providers.dart';
import '../../core/localization/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signIn(
        _loginIdController.text.trim(),
        _passwordController.text.trim(),
      );
      // GoRouter redirect will automatically trigger and route to setup-profile or home
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final useMock = ref.watch(useMockModeProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Elegant dark background with gradient overlays
          Container(
            color: AppColors.background,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.12),
              ),
            ),
          ),

          // Main scrollable contents
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top header actions
                SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              useMock ? 'Mock Server' : 'Firebase Prod',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: useMock
                                        ? AppColors.accent
                                        : AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 24,
                              width: 36,
                              child: Switch(
                                value: useMock,
                                onChanged: (val) {
                                  ref
                                      .read(useMockModeProvider.notifier)
                                      .toggle(val);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        val
                                            ? 'Switched to local Mock Server'
                                            : 'Switched to live Firebase Production',
                                      ),
                                      backgroundColor: AppColors.surface,
                                    ),
                                  );
                                },
                                activeThumbColor: AppColors.accent,
                                activeTrackColor: AppColors.accent.withValues(
                                  alpha: 0.3,
                                ),
                                inactiveThumbColor: AppColors.success,
                                inactiveTrackColor: AppColors.success
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Form contents
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        // Logo & Brand Header
                        Center(
                          child: Hero(
                            tag: 'app_logo',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.background,
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                                context,
                              )?.translate('login_title') ??
                              'Welcome to KRIVA',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                                context,
                              )?.translate('login_subtitle') ??
                              'Club Technical Community Hub',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                        ),
                        const Spacer(),

                        // Glassmorphic Login Container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                              width: 1.5,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Authentication',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 20),

                                // ID/Email Field
                                TextFormField(
                                  controller: _loginIdController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Club ID or Email',
                                    hintText: 'e.g. MEM001 or name@kriva.app',
                                    prefixIcon: Icon(
                                      Icons.badge_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your Club ID or Email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    hintText: '••••••••',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],

                                if (useMock) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '💡 Demo hint: Log in with "DEV001", "ADM001", "LED001" or "MEM001" and password "password".',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 11,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Submit Button
                                _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : ElevatedButton(
                                        onPressed: _handleLogin,
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Log In'),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Google Sign-In button
                        if (!_isLoading) ...[
                          OutlinedButton(
                            onPressed: _handleGoogleSignIn,
                            style: Theme.of(context).outlinedButtonTheme.style
                                ?.copyWith(
                                  side: WidgetStateProperty.all(
                                    BorderSide(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  backgroundColor: WidgetStateProperty.all(
                                    AppColors.surface.withValues(alpha: 0.3),
                                  ),
                                ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                  height: 18,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.g_mobiledata,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(
                                        context,
                                      )?.translate('login_button') ??
                                      'Sign In with Google',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Request Admission / Access option
                        if (!_isLoading)
                          TextButton(
                            onPressed: () => _showAccessRequestForm(context),
                            child: Text(
                              AppLocalizations.of(
                                    context,
                                  )?.translate('login_request_access') ??
                                  'Request Club Admission',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessRequestForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AccessRequestFormSheet(ref: ref),
    );
  }
}

// ── Access Request Form Sheet Widget ─────────────────────────────────────────
class _AccessRequestFormSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AccessRequestFormSheet({required this.ref});

  @override
  State<_AccessRequestFormSheet> createState() =>
      _AccessRequestFormSheetState();
}

class _AccessRequestFormSheetState extends State<_AccessRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _personalEmailCtrl = TextEditingController();
  final _kietEmailCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();

  String _selectedRole = 'member';
  final List<String> _selectedDomains = [];
  bool _isSaving = false;

  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _phoneCtrl.dispose();
    _personalEmailCtrl.dispose();
    _kietEmailCtrl.dispose();
    _aadharCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.isEmpty ||
          _fatherNameCtrl.text.isEmpty ||
          _phoneCtrl.text.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all basic details correctly'),
          ),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (!_personalEmailCtrl.text.contains('@') ||
          !_kietEmailCtrl.text.endsWith('kiet.edu') ||
          _aadharCtrl.text.length < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill valid emails and Aadhar')),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitRequest();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDomains.isEmpty && _selectedRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one Domain Interest'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final reqId = 'req_${const Uuid().v4().substring(0, 8)}';
      final request = AccessRequestModel(
        id: reqId,
        name: _nameCtrl.text.trim(),
        fatherName: _fatherNameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        personalEmail: _personalEmailCtrl.text.trim(),
        kietEmail: _kietEmailCtrl.text.trim(),
        aadharNumber: _aadharCtrl.text.trim(),
        requestedRole: _selectedRole,
        domainInterest: _selectedDomains,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      final db = widget.ref.read(databaseRepositoryProvider);
      await db.submitAccessRequest(request);

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Access Request submitted! Admins will review and grant credentials.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isPassed = index < _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive || isPassed ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Admission Request',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStepIndicator(),
            const SizedBox(height: 24),
            SizedBox(
              height: 320,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Basic Info
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _fatherNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Father\'s Name',
                            prefixIcon: Icon(
                              Icons.family_restroom_outlined,
                              size: 20,
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter father\'s name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          ),
                          validator: (v) => v == null || v.length < 10
                              ? 'Enter valid phone number'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  // Step 2: Verification Info
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _personalEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Personal Email',
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              size: 20,
                            ),
                          ),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Enter valid personal email'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _kietEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'KIET Email',
                            prefixIcon: Icon(Icons.school_outlined, size: 20),
                          ),
                          validator: (v) => v == null || !v.endsWith('kiet.edu')
                              ? 'Enter official @kiet.edu email'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _aadharCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Aadhar Card Number',
                            prefixIcon: Icon(
                              Icons.credit_card_outlined,
                              size: 20,
                            ),
                          ),
                          validator: (v) => v == null || v.trim().length < 12
                              ? 'Enter valid 12-digit Aadhar'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  // Step 3: Role & Domains
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Requested Role',
                            prefixIcon: Icon(
                              Icons.assignment_ind_outlined,
                              size: 20,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'member',
                              child: Text('Normal Member'),
                            ),
                            DropdownMenuItem(
                              value: 'lead',
                              child: Text('Educator / Mentor / Lead'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _selectedRole = v!),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Domain Interests',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['dsa', 'web_dev', 'ml'].map((domain) {
                            final isSelected = _selectedDomains.contains(
                              domain,
                            );
                            return FilterChip(
                              label: Text(domain.toUpperCase()),
                              selected: isSelected,
                              selectedColor: AppColors.primary.withValues(
                                alpha: 0.25,
                              ),
                              checkmarkColor: AppColors.primary,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedDomains.add(domain);
                                  } else {
                                    _selectedDomains.remove(domain);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(onPressed: _prevStep, child: const Text('Back'))
                else
                  const SizedBox.shrink(),
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: Text(_currentStep == 2 ? 'Submit' : 'Next'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
