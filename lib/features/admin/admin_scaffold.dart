import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/service_providers.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/profile_screen.dart';

// Provider to manage Admin portal active tab
final adminTabProvider = StateProvider<int>((ref) => 0);

class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentIndex = ref.watch(adminTabProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isDeveloper = user.role == UserRole.developer;

    final List<Widget> screens = [
      const AdminDashboardScreen(),   // Full admin panel with all tabs
      const ProfileScreen(),
    ];

    final int activeIndex = currentIndex.clamp(0, screens.length - 1);

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
            label: isDeveloper ? 'Dev Panel' : 'Control Center',
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
