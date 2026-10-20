import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/service_providers.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard_screen.dart';
import '../collaboration/collaboration_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../web/layout/web_shell.dart';

// Provider to manage Admin portal active tab
final adminTabProvider = StateProvider<int>((ref) => 0);

class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return const WebShell(initialTab: 5);
    }
    final user = ref.watch(currentUserProvider);
    final currentIndex = ref.watch(adminTabProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!user.role.canAccessPortal(UserRole.admin)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const SizedBox.shrink();
    }

    final bool isDeveloper = user.role == UserRole.developer;

    final List<Widget> screens = [
      const AdminDashboardScreen(), // Full admin panel with all tabs
      const CollaborationScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    final int activeIndex = currentIndex.clamp(0, screens.length - 1);

    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: activeIndex,
                onDestinationSelected: (index) =>
                    ref.read(adminTabProvider.notifier).state = index,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    selectedIcon: const Icon(
                      Icons.admin_panel_settings_rounded,
                    ),
                    label: Text(isDeveloper ? 'Dev Panel' : 'Control Center'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.hub_outlined),
                    selectedIcon: Icon(Icons.hub_rounded),
                    label: Text('Collab'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.people_alt_outlined),
                    selectedIcon: Icon(Icons.people_alt_rounded),
                    label: Text('Community'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Profile'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: IndexedStack(index: activeIndex, children: screens),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: activeIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (index) {
          ref.read(adminTabProvider.notifier).state = index;
        },
        backgroundColor: const Color(0xFF1A0B0B).withValues(alpha: 0.97),
        indicatorColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFFEF4444),
            ),
            label: isDeveloper ? 'Dev Panel' : 'Admin',
          ),
          const NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub_rounded, color: Color(0xFFEF4444)),
            label: 'Collab',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded, color: Color(0xFFEF4444)),
            label: 'Community',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFEF4444)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
