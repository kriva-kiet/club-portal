import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../web/auth/web_login_screen.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../models/access_request_model.dart';
import '../../models/user_model.dart';
import '../../services/service_providers.dart';

// ── Portal definitions ─────────────────────────────────────────────────────────
enum _PortalType { member, lead, admin }

UserRole _roleForPortal(_PortalType portal) {
  switch (portal) {
    case _PortalType.member:
      return UserRole.member;
    case _PortalType.lead:
      return UserRole.lead;
    case _PortalType.admin:
      return UserRole.admin;
  }
}

class _PortalConfig {
  final String label;
  final String subtitle;
  final String hint;
  final IconData icon;
  final Color accent;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  const _PortalConfig({
    required this.label,
    required this.subtitle,
    required this.hint,
    required this.icon,
    required this.accent,
    required this.cardGradientStart,
    required this.cardGradientEnd,
  });
}

const _portals = {
  _PortalType.member: _PortalConfig(
    label: 'Member',
    subtitle: 'Student Portal',
    hint: 'Enter your Member Club ID or email',
    icon: Icons.person_rounded,
    accent: Color(0xFF6366F1),
    cardGradientStart: Color(0xFF1E1B4B),
    cardGradientEnd: Color(0xFF312E81),
  ),
  _PortalType.lead: _PortalConfig(
    label: 'Lead',
    subtitle: 'Educator Portal',
    hint: 'Enter your Lead Club ID or email',
    icon: Icons.star_rounded,
    accent: Color(0xFF10B981),
    cardGradientStart: Color(0xFF064E3B),
    cardGradientEnd: Color(0xFF065F46),
  ),
  _PortalType.admin: _PortalConfig(
    label: 'Admin',
    subtitle: 'Admin Control Center',
    hint: 'Enter your Admin Club ID',
    icon: Icons.admin_panel_settings_rounded,
    accent: Color(0xFFEF4444),
    cardGradientStart: Color(0xFF450A0A),
    cardGradientEnd: Color(0xFF7F1D1D),
  ),
};

final _loginErrorProvider = StateProvider<String?>((ref) => null);
final _loginPortalProvider = StateProvider<_PortalType>((ref) => _PortalType.admin);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  late TabController _tabController;
  _PortalType _selectedPortal = _PortalType.admin;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialPortal = ref.read(_loginPortalProvider);
    _selectedPortal = initialPortal;
    _errorMessage = ref.read(_loginErrorProvider);
    
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialPortal.index,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _selectedPortal = _PortalType.values[_tabController.index];
        ref.read(_loginPortalProvider.notifier).state = _selectedPortal;
        _errorMessage = null;
        ref.read(_loginErrorProvider.notifier).state = null;
        _loginIdController.clear();
        _passwordController.clear();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    final errorNotifier = ref.read(_loginErrorProvider.notifier);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signIn(
        _loginIdController.text.trim(),
        _passwordController.text.trim(),
        expectedRole: _roleForPortal(_selectedPortal),
      );
      // GoRouter redirect triggers and routes to the correct role portal
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      errorNotifier.state = errorMsg;
      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebLoginScreen();
    }
    final config = _portals[_selectedPortal]!;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated background ──────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.background,
                  config.cardGradientStart.withValues(alpha: 0.3),
                  AppColors.background,
                ],
              ),
            ),
          ),

          // Top glow orb
          Positioned(
            top: -80,
            right: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          // Bottom glow orb
          Positioned(
            bottom: -60,
            left: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.accent.withValues(alpha: 0.08),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // KRIVA logo text
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'KRIVA',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Secure Login',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // ── Logo & Branding ──────────────────────────────────
                        Center(
                          child: Hero(
                            tag: 'app_logo',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.background,
                                border: Border.all(
                                  color: config.accent.withValues(alpha: 0.5),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: config.accent.withValues(alpha: 0.3),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 82,
                                  height: 82,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Welcome to KRIVA',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'KML Machine Learning Society',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                        ),
                        const SizedBox(height: 28),

                        // ── Portal Tab Switcher ─────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: TabBar(
                            controller: _tabController,
                            padding: EdgeInsets.zero,
                            indicator: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  config.cardGradientStart,
                                  config.cardGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: config.accent.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            dividerColor: Colors.transparent,
                            labelColor: config.accent,
                            unselectedLabelColor: AppColors.textMuted,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                            tabs: const [
                              Tab(
                                height: 44,
                                icon: Icon(Icons.person_rounded),
                                text: 'Member',
                              ),
                              Tab(
                                height: 44,
                                icon: Icon(Icons.star_rounded),
                                text: 'Lead',
                              ),
                              Tab(
                                height: 44,
                                icon: Icon(Icons.admin_panel_settings_rounded),
                                text: 'Admin',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Portal Label ────────────────────────────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Row(
                            key: ValueKey(_selectedPortal),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: config.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  config.icon,
                                  color: config.accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    config.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: config.accent,
                                    ),
                                  ),
                                  Text(
                                    config.subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Login Card ──────────────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                config.cardGradientStart.withValues(alpha: 0.6),
                                config.cardGradientEnd.withValues(alpha: 0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: config.accent.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: config.accent.withValues(alpha: 0.08),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ID field
                                TextFormField(
                                  controller: _loginIdController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Club ID or Email',
                                    hintText: config.hint,
                                    prefixIcon: Icon(
                                      Icons.badge_outlined,
                                      size: 20,
                                      color: config.accent,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: config.accent,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your Club ID or Email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: '••••••••',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      size: 20,
                                      color: config.accent,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: config.accent,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _handleLogin(),
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

                                // Error message
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.error.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Login Button
                                _isLoading
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          color: config.accent,
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: config.accent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          elevation: 0,
                                          shadowColor: config.accent.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(config.icon, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Sign in as ${config.label}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: AppColors.surface,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (context) =>
                                  AccessRequestFormSheet(ref: ref),
                            );
                          },
                          icon: const Icon(Icons.how_to_reg_rounded),
                          label: const Text(
                            'New here? Request access from Admin',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: config.accent,
                            side: BorderSide(
                              color: config.accent.withValues(alpha: 0.65),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: config.accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.terminal_rounded, size: 13, color: config.accent),
                              const SizedBox(width: 6),
                              const Text(
                                'Developed by ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Abhisht Singh',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: config.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
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
}

// ── Access Request Form Sheet ─────────────────────────────────────────────────
class AccessRequestFormSheet extends StatefulWidget {
  final WidgetRef ref;
  const AccessRequestFormSheet({super.key, required this.ref});

  @override
  State<AccessRequestFormSheet> createState() =>
      _AccessRequestFormSheetState();
}

class _AccessRequestFormSheetState extends State<AccessRequestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _personalEmailCtrl = TextEditingController();
  final _kietEmailCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _batchCtrl = TextEditingController(text: 'Batch of 2028');

  String _selectedRole = 'member';
  final List<String> _selectedDomains = [];
  bool _isSaving = false;
  String? _submissionError;

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
    _githubCtrl.dispose();
    _linkedinCtrl.dispose();
    _instagramCtrl.dispose();
    _batchCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _submissionError = null);
    if (_currentStep == 0) {
      if (_nameCtrl.text.trim().isEmpty ||
          _fatherNameCtrl.text.trim().isEmpty ||
          _phoneCtrl.text.length < 10) {
        setState(
          () => _submissionError = 'Please fill all basic details correctly.',
        );
        return;
      }
    } else if (_currentStep == 1) {
      final kietEmail = _kietEmailCtrl.text.trim().toLowerCase();
      final aadhar = _aadharCtrl.text.replaceAll(RegExp(r'\s'), '');
      if (!_personalEmailCtrl.text.trim().contains('@') ||
          !RegExp(r'^[^@\s]+@kiet\.edu$').hasMatch(kietEmail) ||
          !RegExp(r'^\d{12}$').hasMatch(aadhar)) {
        setState(
          () => _submissionError =
              'Enter valid emails and a 12-digit Aadhar number.',
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

  Future<void> _submitRequest() async {
    setState(() => _submissionError = null);
    if (!_formKey.currentState!.validate()) {
      setState(() => _submissionError = 'Please correct the form details.');
      return;
    }

    if (_selectedDomains.isEmpty) {
      setState(
        () => _submissionError = 'Please select at least one Domain Interest.',
      );
      return;
    }

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final reqId = 'req_${const Uuid().v4().substring(0, 8)}';
      final request = AccessRequestModel(
        id: reqId,
        name: _nameCtrl.text.trim(),
        fatherName: _fatherNameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        personalEmail: _personalEmailCtrl.text.trim(),
        kietEmail: _kietEmailCtrl.text.trim(),
        aadharNumber: _aadharCtrl.text.replaceAll(RegExp(r'\s'), ''),
        githubId: _githubCtrl.text.trim(),
        linkedinId: _linkedinCtrl.text.trim(),
        instagramId: _instagramCtrl.text.trim(),
        requestedRole: _selectedRole,
        batch: _batchCtrl.text.trim().startsWith('Batch')
            ? _batchCtrl.text.trim()
            : 'Batch of ${_batchCtrl.text.trim()}',
        domainInterest: _selectedDomains,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      final db = widget.ref.read(databaseRepositoryProvider);
      await db.submitAccessRequest(request);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Access Request submitted! Admins will review and grant credentials.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(
          () => _submissionError =
              'Could not submit your request: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
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
            color: isActive || isPassed ? Theme.of(context).colorScheme.primary : AppColors.border,
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _batchCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Batch of',
                            hintText: 'e.g. 2028 or Passing Year',
                            prefixIcon: Icon(Icons.school_outlined, size: 20),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter passing year or batch'
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _githubCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'GitHub username (optional)',
                            hintText: 'e.g. octocat',
                            prefixIcon: Icon(Icons.code_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _linkedinCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'LinkedIn username or URL (optional)',
                            hintText: 'e.g. in/your-name',
                            prefixIcon: Icon(
                              Icons.business_center_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _instagramCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Instagram username (optional)',
                            hintText: 'e.g. your_handle',
                            prefixIcon: Icon(
                              Icons.camera_alt_outlined,
                              size: 20,
                            ),
                          ),
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
                              selectedColor: Theme.of(context).colorScheme.primary.withValues(
                                alpha: 0.25,
                              ),
                              checkmarkColor: Theme.of(context).colorScheme.primary,
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
            if (_submissionError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  _submissionError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                          backgroundColor: Theme.of(context).colorScheme.primary,
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
