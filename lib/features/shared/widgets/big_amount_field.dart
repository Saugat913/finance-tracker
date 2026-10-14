import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';

/// Large number entry: currency prefix + display-size input on an underline.
class BigAmountField extends StatelessWidget {
  const BigAmountField({
    super.key,
    required this.controller,
    required this.currencySymbol,
    this.label,
    this.onChanged,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String currencySymbol;
  final String? label;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label!, style: text.bodySmall),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(currencySymbol, style: text.titleLarge?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                style: text.displayMedium,
                decoration: const InputDecoration(hintText: '0.00'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
