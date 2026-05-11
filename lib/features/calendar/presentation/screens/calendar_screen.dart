import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/presentation/providers/loan_providers.dart';
import '../../../payments/domain/entities/loan_payment.dart';
import '../../../payments/presentation/providers/payment_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(activeLoansProvider);
    final allPayments = ref.watch(allPaymentsProvider).value ?? [];
    final paidKeys = allPayments.map((p) => '${p.loanId}|${p.monthKey}').toSet();

    final events = _buildEvents(loans);
    final selected = _selectedDay ?? DateTime.now();
    final selectedLoans = events[_dayKey(selected)] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('EMI Calendar')),
      body: Column(
        children: [
          TableCalendar<Loan>(
            firstDay: DateTime(DateTime.now().year - 1),
            lastDay: DateTime(DateTime.now().year + 3),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            eventLoader: (day) => events[_dayKey(day)] ?? [],
            onDaySelected: (selected, focused) =>
                setState(() { _selectedDay = selected; _focusedDay = focused; }),
            onPageChanged: (focused) => setState(() => _focusedDay = focused),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (ctx, day, loans) {
                if (loans.isEmpty) return null;
                final monthKey = LoanPayment.keyFromDate(day);
                final allPaid = loans.every(
                    (l) => paidKeys.contains('${l.id}|$monthKey'));
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: allPaid ? AppColors.success : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              markersMaxCount: 1,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedLoans.isEmpty
                ? Center(
                    child: Text(
                      'No EMIs due on ${Formatters.date(selected)}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 13),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        '${selectedLoans.length} EMI${selectedLoans.length > 1 ? 's' : ''} due on ${Formatters.shortDate(selected)}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                      ),
                      const SizedBox(height: 10),
                      ...selectedLoans.map((loan) => _EmiDueTile(
                            loan: loan,
                            date: selected,
                            allPayments: allPayments,
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Loan>> _buildEvents(List<Loan> loans) {
    final map = <String, List<Loan>>{};
    final now = DateTime.now();
    for (final loan in loans) {
      for (int m = 0; m < loan.monthsRemaining; m++) {
        final dueDate = DateTime(now.year, now.month + m, loan.dueDay);
        map.putIfAbsent(_dayKey(dueDate), () => []).add(loan);
      }
      // Also include past months from start date
      for (int m = 1; m <= loan.monthsElapsed; m++) {
        final dueDate = DateTime(
            loan.startDate.year, loan.startDate.month + m, loan.dueDay);
        map.putIfAbsent(_dayKey(dueDate), () => []).add(loan);
      }
    }
    return map;
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

// ── EMI due tile with payment checkbox ───────────────────────────────────────

class _EmiDueTile extends ConsumerWidget {
  final Loan loan;
  final DateTime date;
  final List<LoanPayment> allPayments;

  const _EmiDueTile({
    required this.loan,
    required this.date,
    required this.allPayments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.loanTypeColor(loan.loanType);
    final now = DateTime.now();
    final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
    final isToday = isSameDay(date, now);
    final monthKey = LoanPayment.keyFromDate(date);

    final payment = allPayments
        .where((p) => p.loanId == loan.id && p.monthKey == monthKey)
        .firstOrNull;
    final isPaid = payment != null;

    String statusLabel;
    Color statusColor;
    if (isPaid) {
      statusLabel = 'Paid';
      statusColor = AppColors.success;
    } else if (isPast) {
      statusLabel = 'Missed';
      statusColor = AppColors.error;
    } else if (isToday) {
      statusLabel = 'Due Today';
      statusColor = AppColors.warning;
    } else {
      statusLabel = 'Upcoming';
      statusColor = AppColors.textHint;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid
              ? AppColors.success.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(AppColors.loanTypeIcon(loan.loanType), color: color, size: 18),
        ),
        title: Text(loan.loanName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: isPaid ? TextDecoration.lineThrough : null,
              color: isPaid ? AppColors.textSecondary : null,
            )),
        subtitle: Row(children: [
          Text(Formatters.currency(loan.monthlyEmi),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        trailing: GestureDetector(
          onTap: () => _toggle(context, ref, monthKey, payment),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: isPaid ? AppColors.success : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPaid ? AppColors.success : AppColors.textHint,
                width: 2,
              ),
            ),
            child: isPaid
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
      ),
    );
  }

  void _toggle(BuildContext context, WidgetRef ref, String monthKey,
      LoanPayment? existing) {
    if (existing != null) {
      // Already paid — confirm before unmarking
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unmark Payment'),
          content: Text(
              'Mark ${loan.loanName} ($monthKey) as unpaid?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(paymentNotifierProvider.notifier).togglePayment(
                      loanId: loan.id,
                      monthKey: monthKey,
                      emiAmount: loan.monthlyEmi,
                      existingPayments: [existing],
                    );
              },
              child: const Text('Unmark',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
    } else {
      ref.read(paymentNotifierProvider.notifier).togglePayment(
            loanId: loan.id,
            monthKey: monthKey,
            emiAmount: loan.monthlyEmi,
            existingPayments: const [],
          );
    }
  }
}
