import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

/// Bottom navigation: Home, Calendar, Analytics, Work, Plan.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    ('Home', HugeIcons.strokeRoundedHome01),
    ('Calendar', HugeIcons.strokeRoundedCalendar03),
    ('Analytics', HugeIcons.strokeRoundedChartHistogram),
    ('Work', HugeIcons.strokeRoundedBriefcase01),
    ('Plan', HugeIcons.strokeRoundedTarget02),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSize.navBar,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      label: _tabs[i].$1,
                      icon: _tabs[i].$2,
                      selected: shell.currentIndex == i,
                      onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconGlyph icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).textTheme;
    final color = selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? context.colors.fill : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: AppIcon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: scheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
