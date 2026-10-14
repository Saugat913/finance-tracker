import 'package:flutter/material.dart';

/// Boxed input (job name, account name, search) with the design's underline.
class UnderlineField extends StatelessWidget {
  const UnderlineField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.onChanged,
    this.obscure = false,
    this.autofocus = false,
    this.style,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final bool autofocus;
  final TextStyle? style;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label!, style: text.bodySmall),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscure,
          autofocus: autofocus,
          keyboardType: keyboardType,
          style: style ?? text.titleLarge,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
