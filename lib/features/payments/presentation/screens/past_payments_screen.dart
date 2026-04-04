import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../domain/entities/loan_payment.dart';
import '../providers/payment_providers.dart';

class PastPaymentsScreen extends ConsumerStatefulWidget {
  final Loan loan;
  const PastPaymentsScreen({super.key, required this.loan});

  @override
  ConsumerState<PastPaymentsScreen> createState() => _PastPaymentsScreenState();
}

class _PastPaymentsScreenState extends ConsumerState<PastPaymentsScreen> {
  late final List<DateTime> _months;
  late List<bool> _paid;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final start = widget.loan.startDate;
    final elapsed = widget.loan.monthsElapsed;
    _months = List.generate(
      elapsed,
      (i) => DateTime(start.year, start.month + i + 1, widget.loan.dueDay),
    );
    _paid = List.filled(_months.length, true);
  }

  int get _paidCount => _paid.where((p) => p).length;
  int get _missedCount => _paid.where((p) => !p).length;

  Future<void> _save() async {
    setState(() => _saving = true);
    final months = _months;
    final payments = <LoanPayment>[];
    for (int i = 0; i < months.length; i++) {
      if (_paid[i]) {
        payments.add(LoanPayment(
          id: const Uuid().v4(),
          loanId: widget.loan.id,
          monthKey: LoanPayment.keyFromDate(months[i]),
          amountPaid: widget.loan.monthlyEmi,
          paidAt: months[i],
        ));
      }
    }
    if (payments.isNotEmpty) {
      await ref.read(paymentNotifierProvider.notifier).bulkMarkPaid(payments);
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final months = _months;
    final loan = widget.loan;
    final color = AppColors.loanTypeColor(loan.loanType);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Past Payment History',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 16),
              Text(loan.loanName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Started ${Formatters.date(loan.startDate)} · ${months.length} EMIs due so far',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 16),
              // Summary pills
              Row(children: [
                _Pill('$_paidCount Paid', AppColors.success),
                const SizedBox(width: 8),
                _Pill('$_missedCount Missed', _missedCount > 0 ? AppColors.error : Colors.white38),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _paid = List.filled(months.length, true)),
                  child: const Text('All Paid', style: TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.underline)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _paid = List.filled(months.length, false)),
                  child: const Text('All Missed', style: TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.underline)),
                ),
              ]),
            ]),
          ),

          // List
          Expanded(
            child: months.isEmpty
                ? Center(
                    child: Text('No past EMIs to record.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: months.length,
                    itemBuilder: (ctx, i) {
                      final month = months[i];
                      final isPaid = _paid[i];
                      return GestureDetector(
                        onTap: () => setState(() => _paid[i] = !_paid[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? AppColors.success.withValues(alpha: 0.06)
                                : AppColors.error.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPaid
                                  ? AppColors.success.withValues(alpha: 0.3)
                                  : AppColors.error.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(Formatters.monthYear(month),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(Formatters.currency(loan.monthlyEmi),
                                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                            ]),
                            const Spacer(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: isPaid ? AppColors.success : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPaid ? AppColors.success : AppColors.textHint,
                                  width: 2,
                                ),
                              ),
                              child: isPaid
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 16),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Save button
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Save · $_paidCount paid, $_missedCount missed',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}
