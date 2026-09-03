import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/emi_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../domain/entities/loan.dart';

class AmortisationScreen extends ConsumerWidget {
  final Loan loan;
  const AmortisationScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = EmiCalculator.amortisationSchedule(
      principal: loan.principal,
      annualRate: loan.interestRate,
      tenureMonths: loan.tenureMonths,
    );
    final paidKeys = ref.watch(paidMonthKeysProvider(loan.id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Amortisation Schedule')),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardTheme.color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: _Header('Due Date', cs, align: TextAlign.left)),
                Expanded(flex: 2, child: _Header('Principal', cs)),
                Expanded(flex: 2, child: _Header('Interest', cs)),
                Expanded(flex: 2, child: _Header('Balance', cs)),
                const Expanded(flex: 1, child: SizedBox()),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: schedule.length,
              itemBuilder: (_, i) {
                final row = schedule[i];
                final dueDate = DateTime(
                  loan.startDate.year,
                  loan.startDate.month + i + 1,
                  loan.dueDay,
                );
                final monthKey =
                    '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}';
                final isPaid = paidKeys.contains(monthKey);
                final now = DateTime.now();
                // A row is "past due" only if the due date has passed AND it's unpaid
                final dueDatePassed = dueDate.isBefore(DateTime(now.year, now.month, now.day));
                final isMissed = !isPaid && dueDatePassed;

                final rowColor = isPaid
                    ? AppColors.success
                    : isMissed
                        ? AppColors.error
                        : cs.onSurface;

                return Container(
                  color: isPaid
                      ? AppColors.success.withValues(alpha: 0.05)
                      : isMissed
                          ? AppColors.error.withValues(alpha: 0.03)
                          : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          Formatters.date(dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: rowColor,
                            fontWeight: isMissed ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          Formatters.currency(row['principal']!),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: rowColor),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          Formatters.currency(row['interest']!),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: rowColor),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          Formatters.currency(row['balance']!),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: rowColor),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: isPaid
                              ? const Icon(Icons.check_circle, color: AppColors.success, size: 16)
                              : isMissed
                                  ? const Icon(Icons.cancel_outlined, color: AppColors.error, size: 16)
                                  : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  final TextAlign align;
  const _Header(this.text, this.cs, {this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
      );
}
