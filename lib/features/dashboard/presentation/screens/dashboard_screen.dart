import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/presentation/providers/loan_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final active = loans.where((l) => l.status == 'Active').toList();
    final totalOutstanding = active.fold(0.0, (s, l) => s + l.outstandingBalance);
    final totalEmi = active.fold(0.0, (s, l) => s + l.monthlyEmi);
    final totalPrincipal = active.fold(0.0, (s, l) => s + l.principal);
    final totalInterest = active.fold(0.0,
        (s, l) => s + (l.monthlyEmi * l.tenureMonths - l.principal).clamp(0, double.infinity));
    final Map<String, double> byType = {};
    for (final loan in active) {
      byType[loan.loanType] = (byType[loan.loanType] ?? 0) + loan.outstandingBalance;
    }
    final top = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: active.isEmpty
          ? _EmptyDashboard()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, top + 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── Summary row ─────────────────────────────────────
                      _SummaryRow(
                        totalOutstanding: totalOutstanding,
                        totalEmi: totalEmi,
                      ),
                      const SizedBox(height: 24),

                      // ── Principal vs Interest ────────────────────────────
                      _SectionHeader('Principal vs Interest'),
                      const SizedBox(height: 12),
                      _PrincipalInterestChart(
                        principal: totalPrincipal,
                        interest: totalInterest,
                      ),
                      const SizedBox(height: 24),

                      // ── Debt by Category ─────────────────────────────────
                      _SectionHeader('Debt by Category'),
                      const SizedBox(height: 12),
                      _CategoryChart(byType: byType, total: totalOutstanding),
                      const SizedBox(height: 24),

                      // ── Loan Breakdown ───────────────────────────────────
                      _SectionHeader('Loan Breakdown'),
                      const SizedBox(height: 12),
                      ...active.map((l) => _LoanBreakdownTile(
                            loan: l,
                            totalOutstanding: totalOutstanding,
                          )),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dashboard_outlined, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No Data Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Add your first loan to see your debt dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final double totalOutstanding, totalEmi;
  const _SummaryRow({required this.totalOutstanding, required this.totalEmi});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'TOTAL DEBT',
            value: Formatters.currency(totalOutstanding),
            color: AppColors.error,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'MONTHLY EMI',
            value: Formatters.currency(totalEmi),
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
            blurRadius: 12, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            )),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color,
            )),
      ]),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      );
}

// ── Principal vs Interest chart ───────────────────────────────────────────────

class _PrincipalInterestChart extends StatefulWidget {
  final double principal, interest;
  const _PrincipalInterestChart({required this.principal, required this.interest});

  @override
  State<_PrincipalInterestChart> createState() => _PrincipalInterestChartState();
}

class _PrincipalInterestChartState extends State<_PrincipalInterestChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.principal + widget.interest;
    final principalPct = total == 0 ? 0.0 : widget.principal / total * 100;
    final interestPct = total == 0 ? 0.0 : widget.interest / total * 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
            blurRadius: 12, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 140, width: 140,
            child: PieChart(PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) => setState(() {
                  _touched = response?.touchedSection?.touchedSectionIndex ?? -1;
                }),
              ),
              sectionsSpace: 3,
              centerSpaceRadius: 38,
              sections: [
                PieChartSectionData(
                  value: widget.principal,
                  color: AppColors.primary,
                  title: '${principalPct.toStringAsFixed(0)}%',
                  radius: _touched == 0 ? 52 : 44,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                PieChartSectionData(
                  value: widget.interest,
                  color: AppColors.warning.withValues(alpha: 0.8),
                  title: '${interestPct.toStringAsFixed(0)}%',
                  radius: _touched == 1 ? 52 : 44,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ChartLegend(color: AppColors.primary, label: 'Principal', value: Formatters.currency(widget.principal)),
              const SizedBox(height: 12),
              _ChartLegend(color: AppColors.warning, label: 'Total Interest', value: Formatters.currency(widget.interest)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: cs.onSurface.withValues(alpha: 0.08), height: 1),
              ),
              _ChartLegend(
                color: cs.onSurface.withValues(alpha: 0.4),
                label: 'Total Repayment',
                value: Formatters.currency(widget.principal + widget.interest),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _ChartLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ])),
    ]);
  }
}

// ── Category chart ────────────────────────────────────────────────────────────

class _CategoryChart extends StatelessWidget {
  final Map<String, double> byType;
  final double total;
  const _CategoryChart({required this.byType, required this.total});

  @override
  Widget build(BuildContext context) {
    final sorted = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
            blurRadius: 12, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: sorted.map((entry) {
          final pct = total == 0 ? 0.0 : entry.value / total;
          final color = AppColors.loanTypeColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                  Text(
                    '${Formatters.currency(entry.value)}  ${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (ctx, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Loan breakdown tile ───────────────────────────────────────────────────────

class _LoanBreakdownTile extends StatelessWidget {
  final Loan loan;
  final double totalOutstanding;
  const _LoanBreakdownTile({required this.loan, required this.totalOutstanding});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.loanTypeColor(loan.loanType);
    final share = totalOutstanding == 0 ? 0.0 : loan.outstandingBalance / totalOutstanding * 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
            blurRadius: 12, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(AppColors.loanTypeIcon(loan.loanType), color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loan.loanName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${loan.interestRate}% · ${loan.monthsRemaining} mo left',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(Formatters.currency(loan.outstandingBalance),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${share.toStringAsFixed(0)}% of debt',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
        ]),
      ]),
    );
  }
}
