import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Confirm dialog (Discard / Delete / Erase / End shift). Returns true on confirm.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpace.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: AppSpace.sm),
            Text(message, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: AppSpace.xl),
            AppButton(
              confirmLabel,
              kind: destructive ? AppButtonKind.danger : AppButtonKind.primary,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: AppSpace.xs),
            AppButton(cancelLabel, kind: AppButtonKind.text, onPressed: () => Navigator.pop(ctx, false)),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Dark confirmation toast with an optional action ("Undo", "View").
void showToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = context.colors;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        margin: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
        content: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: colors.income, shape: BoxShape.circle),
              child: const Center(child: AppIcon(HugeIcons.strokeRoundedTick02, size: 14, color: Colors.white)),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(child: Text(message)),
            if (actionLabel != null)
              GestureDetector(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                child: Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onHero,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
}
