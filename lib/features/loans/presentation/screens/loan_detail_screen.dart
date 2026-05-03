import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../payments/domain/entities/loan_payment.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../providers/loan_providers.dart';
import '../../domain/entities/loan.dart';

class LoanDetailScreen extends ConsumerWidget {
  final String loanId;
  const LoanDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final loan = loans.where((l) => l.id == loanId).firstOrNull;

    if (loan == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    final color = AppColors.loanTypeColor(loan.loanType);
    final paidCount = ref.watch(paymentsProvider(loan.id)).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(loan.loanName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/loans/${loan.id}/edit', extra: loan),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(loan: loan, color: color, paidCount: paidCount),
          const SizedBox(height: 12),
          _InfoGrid(loan: loan, paidCount: paidCount),
          const SizedBox(height: 12),
          _ThisMonthPayment(loan: loan),
          const SizedBox(height: 12),
          _ActionRow(loan: loan),
          if (loan.status == 'Active') ...[
            const SizedBox(height: 12),
            _CloseButton(loan: loan),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Header card (gradient — always white text, no fix needed) ─────────────────

class _HeaderCard extends StatelessWidget {
  final Loan loan;
  final Color color;
  final int paidCount;
  const _HeaderCard({required this.loan, required this.color, required this.paidCount});

  @override
  Widget build(BuildContext context) {
    // Use paidCount as source of truth so UI reacts immediately when payment is toggled
    final effectiveElapsed = paidCount.clamp(0, loan.tenureMonths);
    final effectiveRemaining = (loan.tenureMonths - effectiveElapsed).clamp(0, loan.tenureMonths);
    final effectiveProgress = loan.tenureMonths == 0 ? 0.0 : effectiveElapsed / loan.tenureMonths;
    final effectiveOutstanding = (loan.principal - (loan.principal / loan.tenureMonths) * effectiveElapsed)
        .clamp(0.0, loan.principal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loan.loanType, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(loan.loanName,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderStat('Principal', Formatters.currency(loan.principal)),
              _HeaderStat('Monthly EMI', Formatters.currency(loan.monthlyEmi)),
              _HeaderStat('Outstanding', Formatters.currency(effectiveOutstanding), animated: true),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: effectiveProgress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (ctx, v, child) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedValue(
            '$effectiveElapsed of ${loan.tenureMonths} months • $effectiveRemaining remaining',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label, value;
  final bool animated;
  const _HeaderStat(this.label, this.value, {this.animated = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        animated
            ? AnimatedValue(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))
            : Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Info grid ─────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final Loan loan;
  final int paidCount;
  const _InfoGrid({required this.loan, required this.paidCount});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final duableMonths = loan.monthsElapsed == 0
        ? 0
        : now.day > loan.dueDay
            ? loan.monthsElapsed
            : (loan.monthsElapsed - 1).clamp(0, loan.tenureMonths);
    final missedCount = (duableMonths - paidCount).clamp(0, duableMonths);
    final remaining = (loan.tenureMonths - paidCount).clamp(0, loan.tenureMonths);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _InfoRow('Interest Rate', '${loan.interestRate}% p.a.'),
          _InfoRow('Calculation', loan.calculationMethod),
          _InfoRow('Start Date', Formatters.date(loan.startDate)),
          _InfoRow('Due Day', 'Day ${loan.dueDay} of every month'),
          _InfoRow('Reminder', '${loan.reminderDays} days before due'),
          _InfoRow('Status', loan.status),
          _InfoRow('Amount Paid', Formatters.currency(loan.monthlyEmi * paidCount)),
          if (loan.totalAdditionalCharges > 0) ...[
            const Divider(height: 20),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Additional Charges', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning)),
            ),
            if (loan.processingFee > 0) _InfoRow('Processing Fee', Formatters.currency(loan.processingFee)),
            if (loan.bounceCharges > 0) _InfoRow('Bounce Charges', Formatters.currency(loan.bounceCharges)),
            if (loan.latePaymentCharges > 0) _InfoRow('Late Payment Charges', Formatters.currency(loan.latePaymentCharges)),
            _InfoRowColoured('Total Additional Charges', Formatters.currency(loan.totalAdditionalCharges), AppColors.warning),
          ],
          const Divider(height: 20),
          _InfoRowColoured('Dues Completed', '$paidCount / $duableMonths', AppColors.success, animated: true),
          if (missedCount > 0)
            _InfoRowColoured('Dues Missed', '$missedCount', AppColors.error, animated: true),
          _InfoRowColoured('Dues Remaining', '$remaining', AppColors.primary, animated: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _InfoRowColoured extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool animated;
  const _InfoRowColoured(this.label, this.value, this.color, {this.animated = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: animated
                ? AnimatedValue(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color))
                : Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final Loan loan;
  const _ActionRow({required this.loan});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionButton(icon: Icons.table_chart_outlined, label: 'Amortisation',
            onTap: () => context.push('/loans/${loan.id}/amortisation', extra: loan))),
        const SizedBox(width: 8),
        Expanded(child: _ActionButton(icon: Icons.savings_outlined, label: 'Prepayment',
            onTap: () => context.push('/loans/${loan.id}/prepayment', extra: loan))),
        const SizedBox(width: 8),
        Expanded(child: _ActionButton(icon: Icons.folder_outlined, label: 'Documents',
            onTap: () => context.push('/loans/${loan.id}/documents', extra: loan.loanName))),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── This month payment ──────────────────────────────────────────────────────────

class _ThisMonthPayment extends ConsumerWidget {
  final Loan loan;
  const _ThisMonthPayment({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthKey = LoanPayment.keyFromDate(DateTime.now());
    final payments = ref.watch(paymentsProvider(loan.id)).value ?? [];
    final isPaid = payments.any((p) => p.monthKey == monthKey);
    final now = DateTime.now();
    final monthName = _monthName(now.month);

    return GestureDetector(
      onTap: () async {
        await ref.read(paymentNotifierProvider.notifier).togglePayment(
          loanId: loan.id,
          monthKey: monthKey,
          emiAmount: loan.monthlyEmi,
          existingPayments: payments,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPaid
              ? AppColors.success.withValues(alpha: 0.07)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPaid
                ? AppColors.success.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isPaid ? AppColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '$monthName EMI',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPaid ? AppColors.success : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isPaid ? 'Marked as paid — tap to undo' : 'Tap to mark as paid',
              style: TextStyle(
                fontSize: 12,
                color: isPaid
                    ? AppColors.success.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ])),
          Text(
            Formatters.currency(loan.monthlyEmi),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isPaid ? AppColors.success : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ]),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }
}

// ── Close button ──────────────────────────────────────────────────────────────

class _CloseButton extends ConsumerWidget {
  final Loan loan;
  const _CloseButton({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _confirm(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          SizedBox(width: 8),
          Text('Mark as Closed',
              style: TextStyle(fontSize: 14, color: AppColors.success, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Loan'),
        content: const Text('Mark this loan as fully repaid? It will move to your Cleared Loans archive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(loanNotifierProvider.notifier).closeLoan(loan);
              context.pop();
            },
            child: const Text('Close Loan', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}
