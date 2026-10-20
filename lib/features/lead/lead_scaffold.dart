import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/service_providers.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../collaboration/collaboration_screen.dart';
import '../community/community_screen.dart';
import 'lead_hub_screen.dart';
import '../web/layout/web_shell.dart';

// Provider to manage Lead portal active tab
final leadTabProvider = StateProvider<int>((ref) => 0);

class LeadScaffold extends ConsumerWidget {
  const LeadScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return const WebShell(initialTab: 5);
    }
    final user = ref.watch(currentUserProvider);
    final currentIndex = ref.watch(leadTabProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!user.role.canAccessPortal(UserRole.lead)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const SizedBox.shrink();
    }

    // Lead portal: Hub | Admin Panel (scoped) | Collaboration | Community | Profile
    final List<Widget> screens = [
      const LeadHubScreen(),
      const _LeadPanelScreen(),
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
                    ref.read(leadTabProvider.notifier).state = index,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.hub_outlined),
                    selectedIcon: Icon(Icons.hub_rounded),
                    label: Text('Lead Hub'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.edit_note_outlined),
                    selectedIcon: Icon(Icons.edit_note_rounded),
                    label: Text('My Panel'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.hub_outlined),
                    selectedIcon: Icon(Icons.hub_rounded),
                    label: Text('Collab'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_alt_outlined),
                    selectedIcon: Icon(Icons.people_alt_rounded),
                    label: Text('Community'),
                  ),
                  NavigationRailDestination(
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
          ref.read(leadTabProvider.notifier).state = index;
        },
        backgroundColor: const Color(0xFF0B1F14).withValues(alpha: 0.97),
        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub_rounded, color: Color(0xFF10B981)),
            label: 'Lead Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(
              Icons.edit_note_rounded,
              color: Color(0xFF10B981),
            ),
            label: 'My Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(
              Icons.hub_rounded,
              color: Color(0xFF10B981),
            ),
            label: 'Collab',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF10B981),
            ),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF10B981)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Lead panel — surfaces the full AdminDashboardScreen which already
/// gates content by role (leads see Broadcast + Roadmaps only, no Requests tab)
class _LeadPanelScreen extends StatelessWidget {
  const _LeadPanelScreen();

  @override
  Widget build(BuildContext context) {
    return const AdminDashboardScreen();
  }
}
