import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'best_matches_screen.dart';
import 'discover_screen.dart';
import 'my_team_screen.dart';
import 'profile_screen.dart';
import 'request_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _labels = [
    'Discover',
    'Matches',
    'Requests',
    'My Team',
    'Profile',
  ];
  static const _icons = [
    Icons.explore_outlined,
    Icons.auto_awesome_outlined,
    Icons.mail_outline,
    Icons.groups_outlined,
    Icons.person_outline,
  ];
  static const _selectedIcons = [
    Icons.explore,
    Icons.auto_awesome,
    Icons.mail,
    Icons.groups,
    Icons.person,
  ];

  late int _index;

  @override
  void initState() {
    super.initState();
    // Profile nahi bana to seedha Profile tab
    _index = context.read<AppState>().me == null ? 4 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.select<AppState, int>(
      (s) => s.pendingReceivedCount,
    );
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      body: Row(
        children: [
          if (isWide) _buildSideNavigation(pending),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                DiscoverScreen(),
                BestMatchesScreen(),
                RequestsScreen(),
                MyTeamScreen(),
                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (var i = 0; i < _labels.length; i++)
                  NavigationDestination(
                    icon: _navigationIcon(i, pending),
                    selectedIcon: _navigationIcon(i, pending, selected: true),
                    label: _labels[i],
                  ),
              ],
            ),
    );
  }

  Widget _buildSideNavigation(int pending) {
    return Container(
      key: const ValueKey('side-navigation'),
      width: 268,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navSurface, Color(0xFF1D2D5A)],
        ),
        border: const Border(right: BorderSide(color: AppColors.navBorder)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TeamUp',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.white, fontSize: 22),
                        ),
                        Text(
                          'Find your people',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.navMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                children: [
                  _sectionLabel('WORKSPACE'),
                  for (var i = 0; i < _labels.length - 1; i++)
                    _sideNavigationItem(i, pending),
                  const SizedBox(height: AppSpacing.md),
                  _sectionLabel('ACCOUNT'),
                  _sideNavigationItem(_labels.length - 1, pending),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.navBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFFBBF24),
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Build together',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Great teams make great ideas.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.navMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.navMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _sideNavigationItem(int index, int pending) {
    final selected = _index == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: _labels[index],
        child: Material(
          color: selected ? const Color(0xFF2C3D72) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: InkWell(
            key: ValueKey(
              selected ? 'side-nav-active' : 'side-nav-item-$index',
            ),
            onTap: () => setState(() => _index = index),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            hoverColor: Colors.white.withValues(alpha: 0.06),
            splashColor: Colors.white.withValues(alpha: 0.1),
            child: SizedBox(
              height: 54,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 4,
                    height: selected ? 26 : 0,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(
                      selected ? _selectedIcons[index] : _icons[index],
                      size: 20,
                      color: selected ? Colors.white : AppColors.navMuted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _labels[index],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected ? Colors.white : AppColors.navText,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (index == 2 && pending > 0)
                    Container(
                      margin: const EdgeInsets.only(right: AppSpacing.md),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        '$pending',
                        style: const TextStyle(
                          color: Color(0xFF422006),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navigationIcon(int index, int pending, {bool selected = false}) {
    final icon = Icon(selected ? _selectedIcons[index] : _icons[index]);
    if (index != 2) return icon;
    return Badge(
      isLabelVisible: pending > 0,
      label: Text('$pending'),
      child: icon,
    );
  }
}
