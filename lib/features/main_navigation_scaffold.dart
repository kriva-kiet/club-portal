import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../services/service_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'roadmap/roadmap_list_screen.dart';
import 'collaboration/collaboration_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import '../core/localization/app_localizations.dart';

// Provider to manage active navigation tab globally
final navigationTabProvider = StateProvider<int>((ref) => 0);

class MainNavigationScaffold extends ConsumerWidget {
  const MainNavigationScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentIndex = ref.watch(navigationTabProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Modern 5-tab Bottom Navigation (Dashboard, Roadmaps, Collab, Community, Profile)
    final List<Widget> screens = [
      const DashboardScreen(),
      const RoadmapListScreen(),
      const CollaborationScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    // Dynamic labels based on role
    String firstTabLabel = AppLocalizations.of(context)?.translate('dashboard_title') ?? 'Dashboard';
    if (user.role == UserRole.lead) firstTabLabel = 'Lead Panel';
    if (user.role == UserRole.admin) firstTabLabel = 'Admin Panel';
    if (user.role == UserRole.developer) firstTabLabel = 'Dev Tools';

    final List<NavigationDestination> navDestinations = [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard_rounded),
        label: firstTabLabel,
      ),
      NavigationDestination(
        icon: const Icon(Icons.map_outlined),
        selectedIcon: const Icon(Icons.map_rounded),
        label: AppLocalizations.of(context)?.translate('roadmaps_title') ?? 'Roadmaps',
      ),
      NavigationDestination(
        icon: const Icon(Icons.hub_outlined),
        selectedIcon: const Icon(Icons.hub_rounded),
        label: AppLocalizations.of(context)?.translate('collab_title') ?? 'Collab',
      ),
      NavigationDestination(
        icon: const Icon(Icons.people_outline_rounded),
        selectedIcon: const Icon(Icons.people_alt_rounded),
        label: AppLocalizations.of(context)?.translate('community_title') ?? 'Community',
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person_rounded),
        label: AppLocalizations.of(context)?.translate('profile_title') ?? 'Profile',
      ),
    ];

    // Handle index out of bounds safely
    int activeIndex = currentIndex;
    if (activeIndex >= screens.length) {
      activeIndex = screens.length - 1;
    }

    return Scaffold(
      body: IndexedStack(index: activeIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (index) {
          ref.read(navigationTabProvider.notifier).state = index;
        },
        backgroundColor: AppColors.background.withValues(alpha: 0.95),
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: navDestinations,
      ),
    );
  }
}
