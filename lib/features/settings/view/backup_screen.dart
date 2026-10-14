import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _restoreController = TextEditingController();

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<SettingsViewModel>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppTopBar(title: 'Backup'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Back up your data', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'Optional. Your data stays on your phone. A backup copies it to your Google Drive, encrypted so only you can read it.',
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _FeaturePoint(
                    icon: HugeIcons.strokeRoundedLockPassword,
                    title: 'Encrypted before upload',
                    subtitle: 'It leaves your phone unreadable',
                  ),
                  const SizedBox(height: AppSpace.md),
                  _FeaturePoint(
                    icon: HugeIcons.strokeRoundedGoogleDrive,
                    title: 'Stored in your own Drive',
                    subtitle: 'We never see it',
                  ),
                  const SizedBox(height: AppSpace.md),
                  _FeaturePoint(
                    icon: HugeIcons.strokeRoundedSmartPhone01,
                    title: 'Restore on a new phone',
                    subtitle: 'Sign in and enter your password',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListRow(
                    title: 'Google Drive',
                    subtitle: 'Cloud synchronization',
                    trailing: const StatusChip('Coming soon', tone: ChipTone.neutral),
                  ),
                  const RowDivider(),
                  ListRow(
                    title: 'Export local backup (JSON)',
                    subtitle: 'Save a copy to your device',
                    trailing: const Chevron(),
                    onTap: () async {
                      final json = await viewModel.exportData();
                      if (context.mounted) {
                        showToast(context, 'Exported ${json.length} characters');
                      }
                    },
                  ),
                  const RowDivider(),
                  ListRow(
                    title: 'Restore from JSON backup',
                    subtitle: 'Replace data from an exported file',
                    trailing: const Chevron(),
                    onTap: () {
                      _showRestoreDialog(context, viewModel);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl),

            AppButton(
              'Done',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, SettingsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from JSON'),
        content: TextField(
          controller: _restoreController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste exported JSON string here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final str = _restoreController.text.trim();
              if (str.isEmpty) return;
              try {
                await viewModel.importData(str);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) showToast(context, 'Data restored successfully');
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Invalid JSON: $e')));
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  const _FeaturePoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconGlyph icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        IconTile(icon, size: 36),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
