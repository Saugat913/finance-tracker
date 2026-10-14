import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/app_button.dart';
import 'package:finance_tracker/features/shared/widgets/app_icon.dart';

/// Header for pushed screens: round back button (and optional round actions)
/// on top, large title beneath. Matches Settings, Money, Accounts, etc. in the design.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.title, this.subtitle, this.actions = const [], this.onBack});

  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(
        title == null ? 56 : (subtitle == null ? 120 : 144),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xs, AppSpace.page, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RoundIconButton(
                  HugeIcons.strokeRoundedArrowLeft01,
                  onPressed: onBack ?? () => context.canPop() ? context.pop() : Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                for (final a in actions) ...[const SizedBox(width: AppSpace.sm), a],
              ],
            ),
            if (title != null) ...[
              const SizedBox(height: AppSpace.md),
              Text(title!, style: text.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(subtitle!, style: text.bodySmall),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Round 40px action for [AppTopBar.actions].
class TopBarAction extends StatelessWidget {
  const TopBarAction(this.glyph, {super.key, required this.onPressed});

  final IconGlyph glyph;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => RoundIconButton(glyph, onPressed: onPressed);
}
