import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<SettingsViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppTopBar(title: 'Settings'),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.xxxl),
              children: [
                // Theme selection
                Text('Appearance', style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                SegmentedTabs<ThemeMode>(
                  options: const {
                    ThemeMode.system: 'System',
                    ThemeMode.light: 'Light',
                    ThemeMode.dark: 'Dark',
                  },
                  value: viewModel.themeMode,
                  onChanged: viewModel.setThemeMode,
                ),
                const SizedBox(height: AppSpace.xl),

                // Money section
                Text('Money', style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListRow(
                        title: 'Accounts',
                        leading: const IconTile(HugeIcons.strokeRoundedWallet01),
                        trailing: _Value('${viewModel.accountsCount}'),
                        onTap: () => context.push(AppRoutes.accounts),
                      ),
                      const RowDivider(),
                      ListRow(
                        title: 'Currency',
                        leading: const IconTile(HugeIcons.strokeRoundedWallet01),
                        trailing: _Value(viewModel.baseCurrency),
                        onTap: () => context.push(AppRoutes.currencySettings),
                      ),
                      const RowDivider(),
                      ListRow(
                        title: 'Jobs',
                        leading: const IconTile(HugeIcons.strokeRoundedBriefcase01),
                        trailing: _Value('${viewModel.jobsCount}'),
                        onTap: () => context.go(AppRoutes.work),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Alerts section
                Text('Alerts', style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListRow(
                    title: 'Alerts',
                    leading: const IconTile(HugeIcons.strokeRoundedNotification01),
                    trailing: _Value(viewModel.settings.shiftReminders ? 'On' : 'Off'),
                    onTap: () => context.push(AppRoutes.alerts),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Data section
                Text('Data', style: text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListRow(
                        title: 'Backup to Google Drive',
                        leading: const IconTile(HugeIcons.strokeRoundedCloud),
                        trailing: _Value(viewModel.settings.backupEnabled ? 'On' : 'Off'),
                        onTap: () => context.push(AppRoutes.backup),
                      ),
                      const RowDivider(),
                      ListRow(
                        title: 'Export data',
                        leading: const IconTile(HugeIcons.strokeRoundedArrowUpRight01),
                        trailing: const Chevron(),
                        onTap: () async {
                          final json = await viewModel.exportData();
                          if (context.mounted) {
                            showToast(context, 'Data exported (${json.length} bytes)');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),

                // Danger zone
                Text('Danger zone', style: text.bodySmall?.copyWith(color: scheme.error)),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListRow(
                    title: 'Erase all data',
                        leading: IconTile(HugeIcons.strokeRoundedDelete02, color: scheme.error, background: scheme.error.withValues(alpha: 0.1)),
                    trailing: const Chevron(),
                    onTap: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Erase all data?',
                        message: 'This removes accounts, jobs, shifts and goals from this phone. It cannot be undone.',
                        confirmLabel: 'Erase everything',
                        cancelLabel: 'Cancel',
                      );
                      if (confirmed && context.mounted) {
                        await viewModel.eraseAllData();
                        if (context.mounted) {
                          showToast(context, 'All data erased');
                          context.go(AppRoutes.home);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                Center(
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/brand/tilvane-logo-dark.svg'
                            : 'assets/brand/tilvane-logo-light.svg',
                        height: 22,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        'v1.0.0 · personal finance & shift planner',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Muted value + chevron shown at the end of a settings row.
class _Value extends StatelessWidget {
  const _Value(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: AppSpace.xs),
          const Chevron(),
        ],
      );
}
