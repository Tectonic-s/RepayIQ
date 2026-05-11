import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import 'quick_add_sheet.dart';

class LoanTypeChooserScreen extends StatelessWidget {
  const LoanTypeChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.go('/loans'),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Add a Loan',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Is this a new loan or one you already have?',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 40),

            // Quick Add
            _ChoiceCard(
              icon: Icons.bolt_outlined,
              color: AppColors.success,
              title: 'Quick Add',
              subtitle: 'Just EMI + due date — takes 10 seconds',
              onTap: () async {
                final loan = await showQuickAddSheet(context);
                if (!context.mounted) return;
                if (loan != null) {
                  await showInsightSheet(context, loan);
                  if (context.mounted) context.go('/loans');
                }
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _ChoiceCard(
              icon: Icons.add_circle_outline,
              color: AppColors.primary,
              title: 'New Loan',
              subtitle: 'Just taken or about to take a loan',
              onTap: () => context.push('/loans/add/new'),
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _ChoiceCard(
              icon: Icons.history_outlined,
              color: AppColors.vehicle,
              title: 'Existing Loan',
              subtitle: 'Already paying EMIs — track your progress',
              onTap: () => context.push('/loans/add/existing'),
              isDark: isDark,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _ChoiceCard({
    required this.icon, required this.color, required this.title,
    required this.subtitle, required this.onTap, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          ])),
          Icon(Icons.arrow_forward_ios, size: 14, color: color),
        ]),
      ),
    );
  }
}
