import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/service_providers.dart';
import '../../../widgets/app_avatar.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../collaboration/collaboration_screen.dart';
import '../../community/community_screen.dart';
import '../../lead/lead_hub_screen.dart';
import '../../leaderboard/leaderboard_screen.dart';
import '../../profile/profile_screen.dart';
import '../dashboard/web_dashboard_view.dart';
import '../roadmap/web_roadmap_view.dart';
import '../web_responsive.dart';
import '../../complaints/complaint_box_dialog.dart';
import '../../authorities/authorities_screen.dart';

final webActiveTabProvider = StateProvider<int>((ref) => 0);
final webSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

class WebShell extends ConsumerStatefulWidget {
  final int initialTab;

  const WebShell({super.key, this.initialTab = 0});

  @override
  ConsumerState<WebShell> createState() => _WebShellState();
}

class _WebShellState extends ConsumerState<WebShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTab != 0) {
        ref.read(webActiveTabProvider.notifier).state = widget.initialTab;
      }
    });
  }

  void _showStreakBoard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Sign Out of KRIVA?'),
        content: const Text(
          'Are you sure you want to log out of your session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final activeTab = ref.watch(webActiveTabProvider);
    final isCollapsed = ref.watch(webSidebarCollapsedProvider);

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = WebResponsive.isMobile(context);
    final hasAdminAccess =
        user.role == UserRole.admin || user.role == UserRole.developer;
    final hasLeadAccess = user.role == UserRole.lead;

    // List of Nav Items
    final List<_WebShellNavItem> navItems = [
      const _WebShellNavItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      const _WebShellNavItem(
        title: 'Roadmaps',
        icon: Icons.map_outlined,
        selectedIcon: Icons.map_rounded,
      ),
      const _WebShellNavItem(
        title: 'Collaboration',
        icon: Icons.hub_outlined,
        selectedIcon: Icons.hub_rounded,
      ),
      const _WebShellNavItem(
        title: 'Community',
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_alt_rounded,
      ),
      const _WebShellNavItem(
        title: 'Profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
      if (hasAdminAccess)
        const _WebShellNavItem(
          title: 'Admin Panel',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings_rounded,
          accentColor: AppColors.error,
        )
      else if (hasLeadAccess)
        const _WebShellNavItem(
          title: 'Lead Hub',
          icon: Icons.star_outline_rounded,
          selectedIcon: Icons.star_rounded,
          accentColor: AppColors.success,
        ),
    ];

    // Screen Widgets
    final List<Widget> screens = [
      WebDashboardView(
        onNavigateToRoadmaps: () =>
            ref.read(webActiveTabProvider.notifier).state = 1,
        onNavigateToCollab: () =>
            ref.read(webActiveTabProvider.notifier).state = 2,
        onNavigateToCommunity: () =>
            ref.read(webActiveTabProvider.notifier).state = 3,
        onNavigateToAdmin: hasAdminAccess
            ? () => ref.read(webActiveTabProvider.notifier).state = 5
            : null,
        onNavigateToLead: hasLeadAccess
            ? () => ref.read(webActiveTabProvider.notifier).state = 5
            : null,
      ),
      const WebRoadmapView(),
      const CollaborationScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
      if (hasAdminAccess)
        const AdminDashboardScreen()
      else if (hasLeadAccess)
        const LeadHubScreen(),
    ];

    final clampedIndex = activeTab.clamp(0, screens.length - 1);
    final currentItem = navItems[clampedIndex];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isMobile
          ? Drawer(
              backgroundColor: AppColors.surface,
              child: _buildSidebarContent(
                context,
                user,
                clampedIndex,
                false,
                navItems,
                true,
              ),
            )
          : null,
      body: Row(
        children: [
          // Desktop & Tablet Persistent Sidebar
          if (!isMobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isCollapsed ? 76 : 250,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: _buildSidebarContent(
                context,
                user,
                clampedIndex,
                isCollapsed,
                navItems,
                false,
              ),
            ),

          // Main View Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildTopHeader(
                  context,
                  user,
                  currentItem,
                  isMobile,
                  hasAdminAccess,
                  hasLeadAccess,
                  clampedIndex,
                ),
                // Active Screen View
                Expanded(
                  child: IndexedStack(
                    index: clampedIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Modern Web Top Header ──────────────────────────────────────────────────
  Widget _buildTopHeader(
    BuildContext context,
    UserModel user,
    _WebShellNavItem currentItem,
    bool isMobile,
    bool hasAdminAccess,
    bool hasLeadAccess,
    int activeIndex,
  ) {
    Color roleColor = AppColors.primary;
    if (user.role == UserRole.lead) roleColor = AppColors.success;
    if (user.role == UserRole.admin || user.role == UserRole.developer) {
      roleColor = AppColors.error;
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          // Section Title / Breadcrumb
          Row(
            children: [
              Icon(
                currentItem.selectedIcon,
                size: 20,
                color: currentItem.accentColor ?? AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'KRIVA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '/',
                style: TextStyle(color: AppColors.border, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                currentItem.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Portal Quick Switcher (if Admin/Lead)
          if (!isMobile && (hasAdminAccess || hasLeadAccess)) ...[
            InkWell(
              onTap: () {
                final targetTab = activeIndex == 5 ? 0 : 5;
                ref.read(webActiveTabProvider.notifier).state = targetTab;
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (activeIndex == 5 ? AppColors.primary : roleColor)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (activeIndex == 5 ? AppColors.primary : roleColor)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      activeIndex == 5
                          ? Icons.home_rounded
                          : (hasAdminAccess
                              ? Icons.admin_panel_settings_rounded
                              : Icons.star_rounded),
                      size: 14,
                      color: activeIndex == 5 ? AppColors.primary : roleColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeIndex == 5
                          ? 'Switch to Member View'
                          : (hasAdminAccess
                              ? 'Admin Control Center'
                              : 'Lead Hub'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: activeIndex == 5 ? AppColors.primary : roleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Authorities Shortcut
          if (!isMobile) ...[
            Tooltip(
              message: 'Club Authorities, Leadership & Cells',
              child: InkWell(
                onTap: () => context.push('/authorities'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.account_balance_rounded,
                        size: 14,
                        color: Color(0xFF818CF8),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Authorities',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: 'Anonymous Grievance / Complaint Box',
              child: InkWell(
                onTap: () => ComplaintBoxDialog.show(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppColors.primaryLight,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Grievance Box',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Streak Flame Button
          Tooltip(
            message: 'View Streak Leaderboard',
            child: InkWell(
              onTap: () => _showStreakBoard(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${user.streak.count}d',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Developer attribution badge
          if (!isMobile) ...[
            InkWell(
              onTap: () async {
                final uri = Uri.parse('https://www.linkedin.com/in/abhisht-singh-71063b327/');
                // ignore: deprecated_member_use
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66C2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0A66C2).withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code_rounded, size: 13, color: Color(0xFF818CF8)),
                    SizedBox(width: 5),
                    Text(
                      'Developer: Abhisht Singh',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC7D2FE),
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF818CF8)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // User Profile Dropdown Menu
          PopupMenuButton<String>(
            tooltip: 'Profile & Settings',
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            offset: const Offset(0, 48),
            onSelected: (val) {
              if (val == 'profile') {
                ref.read(webActiveTabProvider.notifier).state = 4;
              } else if (val == 'authorities') {
                context.push('/authorities');
              } else if (val == 'grievance') {
                ComplaintBoxDialog.show(context);
              } else if (val == 'leaderboard') {
                _showStreakBoard(context);
              } else if (val == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${user.role.name.toUpperCase()} • ${user.batch}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(color: AppColors.border),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'authorities',
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 18,
                      color: Color(0xFF818CF8),
                    ),
                    SizedBox(width: 10),
                    Text('Club Authorities'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'grievance',
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                    SizedBox(width: 10),
                    Text('Anonymous Grievance Box'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leaderboard',
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Leaderboard'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                height: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.terminal_rounded, size: 13, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Developed by Abhisht Singh',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: AppAvatar(
              photoUrl: user.photoUrl,
              name: user.name,
              radius: 18,
              borderWidth: 1.5,
              borderColor: roleColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar Content ────────────────────────────────────────────────────────
  Widget _buildSidebarContent(
    BuildContext context,
    UserModel user,
    int activeIndex,
    bool isCollapsed,
    List<_WebShellNavItem> items,
    bool isDrawer,
  ) {
    Color roleColor = AppColors.primary;
    if (user.role == UserRole.lead) roleColor = AppColors.success;
    if (user.role == UserRole.admin || user.role == UserRole.developer) {
      roleColor = AppColors.error;
    }

    return Column(
      children: [
        // Sidebar Brand Header
        Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 14 : 18),
          alignment: Alignment.centerLeft,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KRIVA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ML Society',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!isDrawer)
                IconButton(
                  icon: Icon(
                    isCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  tooltip: isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                  onPressed: () {
                    ref.read(webSidebarCollapsedProvider.notifier).state =
                        !isCollapsed;
                  },
                ),
            ],
          ),
        ),

        // Navigation Items List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final item = items[idx];
              final isSelected = activeIndex == idx;
              final accent = item.accentColor ?? AppColors.primary;

              return Tooltip(
                message: isCollapsed ? item.title : '',
                child: InkWell(
                  onTap: () {
                    ref.read(webActiveTabProvider.notifier).state = idx;
                    if (isDrawer) Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCollapsed ? 12 : 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(
                              color: accent.withValues(alpha: 0.4),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          size: 22,
                          color: isSelected ? accent : AppColors.textMuted,
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Quick Action Shortcuts in Sidebar
        if (!isCollapsed) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      context.push('/authorities');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.account_balance_rounded, size: 14, color: Color(0xFF818CF8)),
                          SizedBox(width: 5),
                          Text(
                            'Authorities',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      ComplaintBoxDialog.show(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryLight),
                          SizedBox(width: 5),
                          Text(
                            'Grievance',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Bottom User Profile Card
        Container(
          padding: EdgeInsets.all(isCollapsed ? 10 : 14),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: isCollapsed
              ? Column(
                  children: [
                    AppAvatar(
                      photoUrl: user.photoUrl,
                      name: user.name,
                      radius: 16,
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      tooltip: 'Sign Out',
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        AppAvatar(
                          photoUrl: user.photoUrl,
                          name: user.name,
                          radius: 18,
                          borderWidth: 1.5,
                          borderColor: roleColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.role.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          tooltip: 'Sign Out',
                          onPressed: () => _handleLogout(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1).withValues(alpha: 0.12),
                            const Color(0xFFEC4899).withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.terminal_rounded, size: 12, color: Color(0xFF818CF8)),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Developed by Abhisht Singh',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC7D2FE),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _WebShellNavItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Color? accentColor;

  const _WebShellNavItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    this.accentColor,
  });
}
