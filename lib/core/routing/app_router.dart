import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/service_providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/setup_profile_screen.dart';
import '../../features/main_navigation_scaffold.dart';
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
      final isLoggingIn = state.matchedLocation == '/login';

      // 1. User is NOT authenticated
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 2. User IS authenticated, check if profile is complete (e.g. name or batch is empty)
      final isProfileIncomplete =
          user.name.trim().isEmpty || user.batch.trim().isEmpty;
      if (isProfileIncomplete) {
        if (state.matchedLocation == '/setup-profile') return null;
        return '/setup-profile';
      }

      // 3. Check if onboarding is needed
      final prefs = ref.read(sharedPreferencesProvider);
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
        if (state.matchedLocation == '/onboarding') return null;
        return '/onboarding';
      }

      // 4. User is authenticated and complete, prevent visiting auth/onboarding screens
      if (isLoggingIn ||
          state.matchedLocation == '/setup-profile' ||
          state.matchedLocation == '/onboarding') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/setup-profile',
        builder: (context, state) => const SetupProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScaffold(),
      ),
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

/// Helper class to bridge Riverpod state changes to GoRouter refresh notifier
class _RiverpodRouterRefreshListenable extends ChangeNotifier {
  final Ref _ref;

  _RiverpodRouterRefreshListenable(this._ref) {
    _ref.listen(authStateChangesProvider, (prev, next) {
      notifyListeners();
    });
  }
}
