import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/assistant/viewmodels/assistant_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _inputController = TextEditingController();
  late final AssistantViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<AssistantViewModel>();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _send([String? query]) {
    final text = query ?? _inputController.text;
    if (text.trim().isEmpty) return;
    _viewModel.sendMessage(text);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Scaffold(
      appBar: const AppTopBar(title: 'Assistant', subtitle: 'Asks before it changes anything'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  if (_viewModel.messages.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(AppSpace.page),
                      children: [
                        Text('What can I do for you?', style: text.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Ask about your money, or tell me to do something.',
                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpace.xxl),

                        Text('Do', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpace.sm),
                        _PromptCard(
                          title: 'Add an expense',
                          subtitle: 'Spent 54.20 at Woolworths today',
                          icon: HugeIcons.strokeRoundedCoins01,
                          onTap: () => _send('Spent 54.20 at Woolworths today'),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _PromptCard(
                          title: 'Schedule a shift',
                          subtitle: 'Café Friday, 4 to 10 pm',
                          icon: HugeIcons.strokeRoundedCalendar03,
                          onTap: () => _send('Schedule a Café shift on Friday, 4 to 10 pm'),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _PromptCard(
                          title: 'Move money to a goal',
                          subtitle: r'Put A$50 into Emergency fund',
                          icon: HugeIcons.strokeRoundedTarget02,
                          onTap: () => _send(r'Put A$50 into Emergency fund'),
                        ),
                        const SizedBox(height: AppSpace.xl),

                        Text('Ask', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpace.sm),
                        _PromptCard(
                          title: 'How much did I spend on food?',
                          subtitle: 'This month so far',
                          icon: HugeIcons.strokeRoundedChartHistogram,
                          onTap: () => _send('How much did I spend on food this month?'),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _PromptCard(
                          title: r'Can I afford a A$300 purchase?',
                          subtitle: 'Based on your forecast',
                          icon: HugeIcons.strokeRoundedShieldCheck,
                          onTap: () => _send('Can I afford a 300 dollar purchase?'),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpace.page),
                    itemCount: _viewModel.messages.length,
                    itemBuilder: (context, i) {
                      final msg = _viewModel.messages[i];
                      if (msg.isUser) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSpace.md, left: 48),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                            decoration: BoxDecoration(
                              color: colors.hero,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Text(msg.text, style: text.bodyMedium?.copyWith(color: colors.onHero)),
                          ),
                        );
                      }

                      // Assistant message
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: AppSpace.md, right: 32),
                            padding: const EdgeInsets.all(AppSpace.lg),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (msg.headline != null && msg.headline!.isNotEmpty) ...[
                                  Text(msg.headline!, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: AppSpace.xs),
                                ],
                                Text(msg.text, style: text.bodyMedium),
                                if (msg.explanation != null) ...[
                                  const SizedBox(height: AppSpace.sm),
                                  Text(
                                    msg.explanation!,
                                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Pending confirmation card
                          if (msg.pendingAction != null && !msg.isConfirmed) ...[
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(msg.pendingAction!.title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                      const Spacer(),
                                      const StatusChip('Needs your OK', tone: ChipTone.warning),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpace.md),
                                  if (msg.pendingAction!.amountMinor != null)
                                    Text(
                                      MoneyFormatter.format(msg.pendingAction!.amountMinor!, _viewModel.baseCurrency),
                                      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  if (msg.pendingAction!.merchant != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Merchant: ${msg.pendingAction!.merchant}', style: text.bodySmall),
                                  ],
                                  if (msg.pendingAction!.jobName != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Job: ${msg.pendingAction!.jobName} · ${msg.pendingAction!.startTime}–${msg.pendingAction!.endTime}', style: text.bodySmall),
                                  ],
                                  if (msg.pendingAction!.goalName != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Goal: ${msg.pendingAction!.goalName}', style: text.bodySmall),
                                  ],
                                  const SizedBox(height: AppSpace.lg),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          'Confirm',
                                          onPressed: () => _viewModel.confirmAction(msg),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.md),
                          ],

                          // Confirmed status card
                          if (msg.isConfirmed) ...[
                            AppCard(
                              child: Row(
                                children: [
                                  IconTile(HugeIcons.strokeRoundedCheckmarkCircle02, size: 36),
                                  const SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: Text(
                                      msg.confirmedSummary ?? 'Action completed',
                                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpace.md),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Ask or tell me what to do',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const AppIcon(HugeIcons.strokeRoundedArrowRight01),
                    onPressed: () => _send(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconGlyph icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OptionTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      selected: false,
      onTap: onTap,
    );
  }
}
