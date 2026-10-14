import 'package:flutter/material.dart';

import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';

/// The near-black card ("Net position", forecast, accounts total).
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.xl),
        decoration: BoxDecoration(
          color: context.colors.hero,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: child,
      );
}
