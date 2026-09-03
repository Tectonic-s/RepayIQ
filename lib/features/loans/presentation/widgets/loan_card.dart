import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../domain/entities/loan.dart';

class LoanCard extends ConsumerWidget {
  final Loan loan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LoanCard({
    super.key,
    required this.loan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.loanTypeColor(loan.loanType);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paidKeys = ref.watch(paidMonthKeysProvider(loan.id));
    final isOverdue = loan.isOverdueWithPayments(paidKeys);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — icon, name, badge, menu
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(AppColors.loanTypeIcon(loan.loanType), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.loanName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loan.loanType,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45)),
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Overdue',
                        style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: cs.onSurface.withValues(alpha: 0.35)),
                  onSelected: (v) { if (v == 'delete') onDelete(); },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(label: 'EMI', value: Formatters.currency(loan.monthlyEmi)),
                _Stat(label: 'Outstanding', value: Formatters.currency(loan.outstandingBalance)),
                _Stat(label: 'Remaining', value: '${loan.monthsRemaining} mo'),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: loan.progressPercent),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (ctx, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(loan.progressPercent * 100).toStringAsFixed(0)}% paid',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.38)),
                ),
                Text(
                  Formatters.currency(loan.principal),
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.38)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: cs.onSurface.withValues(alpha: 0.45),
            )),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            )),
      ],
    );
  }
}
