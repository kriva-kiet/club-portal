import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/service_providers.dart';
import '../../models/user_model.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/setup_profile_screen.dart';
import '../../features/main_navigation_scaffold.dart';
import '../../features/lead/lead_scaffold.dart';
import '../../features/admin/admin_scaffold.dart';
import '../../features/roadmap/roadmap_detail_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch the auth state to trigger redirect evaluations when it changes
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    // Listening to state changes to refresh the router
    refreshListenable: _RiverpodRouterRefreshListenable(ref),
    redirect: (context, state) {
      // Async state loading
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final loc = state.matchedLocation;
      final isOnAuth = loc == '/login';
      final isOnSetup = loc == '/setup-profile';
      final isOnOnboarding = loc == '/onboarding';

      // 1. User is NOT authenticated — send to login
      if (user == null) {
        return isOnAuth ? null : '/login';
      }

      // 2. Profile incomplete
      final isProfileIncomplete =
          user.name.trim().isEmpty || user.batch.trim().isEmpty;
      if (isProfileIncomplete) {
        return isOnSetup ? null : '/setup-profile';
      }

      // 3. Onboarding
      final prefs = ref.read(sharedPreferencesProvider);
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
        return isOnOnboarding ? null : '/onboarding';
      }

      // 4. Determine the correct home route for this user's role
      final String homeRoute = _homeRouteForRole(user.role);

      // If user is on an auth/onboarding screen, send to their home
      if (isOnAuth || isOnSetup || isOnOnboarding) {
        return homeRoute;
      }

      // If user is on the wrong portal for their role, redirect to correct one
      final portals = ['/', '/lead', '/admin'];
      for (final portal in portals) {
        if (loc.startsWith(portal) && portal != homeRoute) {
          // Only redirect if they're at the root of a wrong portal
          // Allow /roadmap/:id for all roles
          if (!loc.startsWith('/roadmap')) {
            return homeRoute;
          }
        }
      }

      return null;
    },
    routes: [
      // ── Auth / Onboarding ──────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/setup-profile',
        builder: (context, state) => const SetupProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Member Portal ──────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScaffold(),
      ),

      // ── Lead Portal ────────────────────────────────────────────────────────
      GoRoute(
        path: '/lead',
        builder: (context, state) => const LeadScaffold(),
      ),

      // ── Admin / Developer Portal ───────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScaffold(),
      ),

      // ── Shared Deep Links ──────────────────────────────────────────────────
      GoRoute(
        path: '/roadmap/:id',
        builder: (context, state) {
          final domainId = state.pathParameters['id']!;
          return RoadmapDetailScreen(domainId: domainId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Error: Route not found!\n${state.error}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
});

/// Returns the correct home route based on user role
String _homeRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
    case UserRole.developer:
      return '/admin';
    case UserRole.lead:
      return '/lead';
    case UserRole.member:
      return '/';
  }
}

/// Helper class to bridge Riverpod state changes to GoRouter refresh notifier
class _RiverpodRouterRefreshListenable extends ChangeNotifier {
  final Ref _ref;

  _RiverpodRouterRefreshListenable(this._ref) {
    _ref.listen(authStateChangesProvider, (prev, next) {
      notifyListeners();
    });
  }
}
