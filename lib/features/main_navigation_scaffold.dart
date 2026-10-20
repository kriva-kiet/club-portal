import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../services/service_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'roadmap/roadmap_list_screen.dart';
import 'collaboration/collaboration_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import '../core/localization/app_localizations.dart';
import 'web/layout/web_shell.dart';

// Provider to manage active navigation tab globally
final navigationTabProvider = StateProvider<int>((ref) => 0);

class MainNavigationScaffold extends ConsumerWidget {
  const MainNavigationScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return const WebShell(initialTab: 0);
    }
    final user = ref.watch(currentUserProvider);
    final currentIndex = ref.watch(navigationTabProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!user.role.canAccessPortal(UserRole.member)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(user.role == UserRole.lead ? '/lead' : '/admin');
      });
      return const SizedBox.shrink();
    }

    final List<Widget> screens = [
      const DashboardScreen(),
      const RoadmapListScreen(),
      const CollaborationScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    String firstTabLabel =
        AppLocalizations.of(context)?.translate('dashboard_title') ??
        'Dashboard';
    if (user.role == UserRole.lead) firstTabLabel = 'Lead Panel';
    if (user.role == UserRole.admin) firstTabLabel = 'Admin Panel';
    if (user.role == UserRole.developer) firstTabLabel = 'Dev Tools';

    int activeIndex = currentIndex;
    if (activeIndex >= screens.length) {
      activeIndex = screens.length - 1;
    }

    final List<_NavItem> navItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: firstTabLabel,
      ),
      _NavItem(
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
        label: AppLocalizations.of(context)?.translate('roadmaps_title') ?? 'Roadmaps',
      ),
      _NavItem(
        icon: Icons.hub_outlined,
        selectedIcon: Icons.hub_rounded,
        label: 'Collab',
      ),
      _NavItem(
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_alt_rounded,
        label: AppLocalizations.of(context)?.translate('community_title') ?? 'Community',
      ),
      _NavItem(
        icon: Icons.person_outline,
        selectedIcon: Icons.person_rounded,
        label: AppLocalizations.of(context)?.translate('profile_title') ?? 'Profile',
      ),
    ];

    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: activeIndex,
                onDestinationSelected: (index) =>
                    ref.read(navigationTabProvider.notifier).state = index,
                labelType: NavigationRailLabelType.all,
                backgroundColor: AppColors.background,
                selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 26),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                destinations: navItems
                    .map((item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ))
                    .toList(),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Dev: Abhisht',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '© 2026 KRIVA',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppColors.border),
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
      bottomNavigationBar: _KrivaNavBar(
        currentIndex: activeIndex,
        items: navItems,
        onTap: (i) => ref.read(navigationTabProvider.notifier).state = i,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Premium animated KRIVA bottom nav bar
// ─────────────────────────────────────────────────────────────────────────────
class _KrivaNavBar extends StatefulWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _KrivaNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  State<_KrivaNavBar> createState() => _KrivaNavBarState();
}

class _KrivaNavBarState extends State<_KrivaNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.navGradient,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(widget.items.length, (i) {
              final item = widget.items[i];
              final isSelected = widget.currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: _NavBarItem(
                    item: item,
                    isSelected: isSelected,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;

  const _NavBarItem({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0x33E53935), Color(0x11E53935)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Icon(
            isSelected ? item.selectedIcon : item.icon,
            size: isSelected ? 26 : 22,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          )
              .animate(target: isSelected ? 1 : 0)
              .scaleXY(end: 1.15, duration: 200.ms, curve: Curves.easeOut)
              .then()
              .scaleXY(end: 1.0, duration: 100.ms),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontSize: isSelected ? 10.5 : 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: isSelected ? 0.3 : 0,
          ),
          child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
