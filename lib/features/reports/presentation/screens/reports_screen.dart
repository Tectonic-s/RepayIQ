import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/emi_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/report_generator.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/presentation/providers/loan_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _touchedBar = -1;

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final active = loans.where((l) => l.status == 'Active').toList();

    final totalOutstanding = active.fold(0.0, (s, l) => s + l.outstandingBalance);
    final totalEmi = active.fold(0.0, (s, l) => s + l.monthlyEmi);
    final totalInterest = active.fold(0.0, (s, l) =>
        s + (l.monthlyEmi * l.tenureMonths - l.principal).clamp(0, double.infinity));
    final totalPaid = active.fold(0.0, (s, l) => s + l.amountPaid);

    final monthlyData = _buildMonthlyData(active);

    return Scaffold(
      body: active.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bar_chart_outlined, size: 40, color: AppColors.warning),
                  ),
                  const SizedBox(height: 20),
                  const Text('No Reports Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Add loans to generate interest reports and export PDFs',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                ]),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ReportsHeader(
                    totalInterest: totalInterest,
                    totalPaid: totalPaid,
                    onExport: active.isNotEmpty
                        ? () => ReportGenerator.exportLoanSummaryPdf(loans)
                        : null,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SummaryGrid(
                        totalOutstanding: totalOutstanding,
                        totalEmi: totalEmi,
                        totalInterest: totalInterest,
                        totalPaid: totalPaid,
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Monthly Interest Paid'),
                      const SizedBox(height: 4),
                      Text(
                        'Interest component of your EMI over the next 12 months',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                      ),
                      const SizedBox(height: 12),
                      _MonthlyBarChart(
                        data: monthlyData,
                        touched: _touchedBar,
                        onTouch: (i) => setState(() => _touchedBar = i),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Interest Breakdown by Loan'),
                      const SizedBox(height: 12),
                      ...active.map((l) => _LoanInterestTile(loan: l)),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  /// Builds 12 months of combined interest data across all active loans
  List<_MonthPoint> _buildMonthlyData(List<Loan> loans) {
    final now = DateTime.now();
    final points = <_MonthPoint>[];

    for (int m = 0; m < 12; m++) {
      final month = DateTime(now.year, now.month + m);
      double totalInterest = 0;

      for (final loan in loans) {
        final elapsed = loan.monthsElapsed + m;
        if (elapsed >= loan.tenureMonths) continue;

        final schedule = EmiCalculator.amortisationSchedule(
          principal: loan.principal,
          annualRate: loan.interestRate,
          tenureMonths: loan.tenureMonths,
        );
        if (elapsed < schedule.length) {
          totalInterest += schedule[elapsed]['interest'] ?? 0;
        }
      }

      points.add(_MonthPoint(
        label: DateFormat('MMM').format(month),
        interest: totalInterest,
      ));
    }
    return points;
  }
}

// ── Reports header ───────────────────────────────────────────────────────────

class _ReportsHeader extends StatelessWidget {
  final double totalInterest;
  final double totalPaid;
  final VoidCallback? onExport;
  const _ReportsHeader({required this.totalInterest, required this.totalPaid, this.onExport});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Reports',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              if (onExport != null)
                GestureDetector(
                  onTap: onExport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Export PDF', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStat(label: 'Total Interest Cost', value: Formatters.currency(totalInterest)),
              const SizedBox(width: 24),
              _HeaderStat(label: 'Amount Paid So Far', value: Formatters.currency(totalPaid)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label, value;
  const _HeaderStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Monthly bar chart ─────────────────────────────────────────────────────────

class _MonthlyBarChart extends StatelessWidget {
  final List<_MonthPoint> data;
  final int touched;
  final ValueChanged<int> onTouch;

  const _MonthlyBarChart({required this.data, required this.touched, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold(0.0, (m, p) => p.interest > m ? p.interest : m);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.25,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (spot) => isDark ? AppColors.darkCard : Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                '${data[group.x].label}\n${Formatters.currency(rod.toY)}',
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            touchCallback: (event, response) {
              onTouch(response?.spot?.touchedBarGroupIndex ?? -1);
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, _) => Text(
                  Formatters.currency(v),
                  style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[v.toInt()].label,
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38).withValues(alpha: 0.2),
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            final selected = touched == i;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].interest,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  color: selected ? AppColors.warning : AppColors.primary.withValues(alpha: 0.75),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Summary grid ──────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final double totalOutstanding, totalEmi, totalInterest, totalPaid;
  const _SummaryGrid({
    required this.totalOutstanding,
    required this.totalEmi,
    required this.totalInterest,
    required this.totalPaid,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _StatCard(label: 'Total Outstanding', value: Formatters.currency(totalOutstanding), color: AppColors.error),
        _StatCard(label: 'Monthly EMI', value: Formatters.currency(totalEmi), color: AppColors.primary),
        _StatCard(label: 'Total Interest', value: Formatters.currency(totalInterest), color: AppColors.warning),
        _StatCard(label: 'Amount Paid', value: Formatters.currency(totalPaid), color: AppColors.success),
      ],
    );
  }
}

// ── Per-loan interest tile ────────────────────────────────────────────────────

class _LoanInterestTile extends StatelessWidget {
  final Loan loan;
  const _LoanInterestTile({required this.loan});

  @override
  Widget build(BuildContext context) {
    final totalInterest = (loan.monthlyEmi * loan.tenureMonths - loan.principal).clamp(0.0, double.infinity);
    final interestPaid = (loan.monthlyEmi * loan.monthsElapsed - (loan.principal - loan.outstandingBalance))
        .clamp(0.0, double.infinity);
    final color = AppColors.loanTypeColor(loan.loanType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(loan.loanName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text(loan.loanType,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(label: 'Rate', value: '${loan.interestRate}%'),
              _MiniStat(label: 'Interest Paid', value: Formatters.currency(interestPaid)),
              _MiniStat(label: 'Total Interest', value: Formatters.currency(totalInterest)),
              _MiniStat(label: 'Remaining', value: '${loan.monthsRemaining} mo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _MonthPoint {
  final String label;
  final double interest;
  const _MonthPoint({required this.label, required this.interest});
}
