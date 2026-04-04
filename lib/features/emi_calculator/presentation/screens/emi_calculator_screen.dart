import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/emi_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';

enum LoanType {
  home('Home Loan', Icons.home_outlined, AppColors.home),
  vehicle('Vehicle Loan', Icons.directions_car_outlined, AppColors.vehicle),
  consumerDurable('Consumer Durable', Icons.devices_outlined, AppColors.appliance),
  personal('Personal Loan', Icons.person_outline, AppColors.personal),
  education('Education Loan', Icons.school_outlined, AppColors.primary),
  business('Business Loan', Icons.business_outlined, AppColors.creditCard);

  final String label;
  final IconData icon;
  final Color color;
  const LoanType(this.label, this.icon, this.color);
}

class EmiCalculatorScreen extends ConsumerStatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  ConsumerState<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends ConsumerState<EmiCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();
  final _moratoriumCtrl = TextEditingController(text: '0');
  final _processingFeeCtrl = TextEditingController(text: '0');

  LoanType _loanType = LoanType.home;
  _CalcResult? _result;

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _tenureCtrl.dispose();
    _moratoriumCtrl.dispose();
    _processingFeeCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final principal = double.parse(_principalCtrl.text);
    final rate = double.parse(_rateCtrl.text);
    final tenure = int.parse(_tenureCtrl.text);

    double emi;
    double totalInterest;
    double? moratoriumInterest;
    double? effectiveRate;

    if (_loanType == LoanType.education) {
      final moratorium = int.tryParse(_moratoriumCtrl.text) ?? 0;
      final res = EmiCalculator.educationLoanResult(
        principal: principal,
        annualRate: rate,
        tenureMonths: tenure,
        moratoriumMonths: moratorium,
      );
      emi = res['emi']!;
      totalInterest = res['totalInterest']!;
      moratoriumInterest = res['moratoriumInterest'];
    } else if (_loanType == LoanType.consumerDurable) {
      final processingFee = double.tryParse(_processingFeeCtrl.text) ?? 0;
      emi = EmiCalculator.reducingBalanceEmi(principal: principal, annualRate: rate, tenureMonths: tenure);
      totalInterest = EmiCalculator.totalInterest(emi: emi, tenureMonths: tenure, principal: principal);
      if (processingFee > 0) {
        effectiveRate = (processingFee / principal) * (12 / tenure) * 100;
      }
    } else {
      emi = EmiCalculator.reducingBalanceEmi(principal: principal, annualRate: rate, tenureMonths: tenure);
      totalInterest = EmiCalculator.totalInterest(emi: emi, tenureMonths: tenure, principal: principal);
    }

    setState(() {
      _result = _CalcResult(
        loanType: _loanType,
        principal: principal,
        rate: rate,
        tenure: tenure,
        emi: emi,
        totalInterest: totalInterest,
        totalRepayment: emi * tenure,
        moratoriumInterest: moratoriumInterest,
        effectiveRate: effectiveRate,
      );
    });
  }

  void _saveAsLoan() {
    context.push('/loans/add/new', extra: {
      'principal': _result!.principal,
      'rate': _result!.rate,
      'tenure': _result!.tenure,
      'method': 'Reducing Balance',
      'loanType': _result!.loanType.label,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EMI Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan type selector
            Text('Loan Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LoanType.values.map((type) {
                final selected = _loanType == type;
                return GestureDetector(
                  onTap: () => setState(() { _loanType = type; _result = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? type.color.withValues(alpha: 0.12) : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? type.color : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(type.icon, size: 14, color: selected ? type.color : AppColors.textHint),
                      const SizedBox(width: 6),
                      Text(type.label, style: TextStyle(
                        fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? type.color : AppColors.textSecondary,
                      )),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(children: [
                AppTextField(
                  label: 'Loan Amount (₹)', hint: '500000',
                  controller: _principalCtrl, keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Annual Interest Rate (%)', hint: '8.5',
                  controller: _rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.percent,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (double.tryParse(v) == null || double.parse(v) < 0) return 'Invalid rate';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Tenure (months)', hint: '240',
                  controller: _tenureCtrl, keyboardType: TextInputType.number,
                  prefixIcon: Icons.calendar_month_outlined,
                  textInputAction: _loanType == LoanType.education || _loanType == LoanType.consumerDurable
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) => _calculate(),
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Invalid tenure';
                    return null;
                  },
                ),

                // Education — moratorium field
                if (_loanType == LoanType.education) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Moratorium Period (months)', hint: '24',
                    controller: _moratoriumCtrl, keyboardType: TextInputType.number,
                    prefixIcon: Icons.pause_circle_outline,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _calculate(),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ],

                // Consumer Durable — processing fee field
                if (_loanType == LoanType.consumerDurable) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Processing Fee (₹) — for No-Cost EMI', hint: '0',
                    controller: _processingFeeCtrl, keyboardType: TextInputType.number,
                    prefixIcon: Icons.receipt_outlined,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _calculate(),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 20),
                PrimaryButton(label: 'Calculate', onPressed: _calculate),
              ]),
            ),

            if (_result != null) ...[
              const SizedBox(height: 28),
              _ResultSection(result: _result!, onSave: _saveAsLoan),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Result section ────────────────────────────────────────────────────────────

class _ResultSection extends StatefulWidget {
  final _CalcResult result;
  final VoidCallback onSave;
  const _ResultSection({required this.result, required this.onSave});

  @override
  State<_ResultSection> createState() => _ResultSectionState();
}

class _ResultSectionState extends State<_ResultSection> {
  bool _showSchedule = false;

  void _share() {
    final r = widget.result;
    final schedule = EmiCalculator.amortisationSchedule(
      principal: r.principal,
      annualRate: r.rate,
      tenureMonths: r.tenure,
    );

    final sep = '-' * 40;
    final buf = StringBuffer();

    buf.writeln('REPAYIQ - EMI CALCULATION REPORT');
    buf.writeln(sep);
    buf.writeln('Loan Type    : ${r.loanType.label}');
    buf.writeln('Principal    : ${Formatters.currency(r.principal)}');
    buf.writeln('Interest Rate: ${r.rate}% p.a.');
    buf.writeln('Tenure       : ${Formatters.tenure(r.tenure)}');
    buf.writeln(sep);
    buf.writeln('Monthly EMI      : ${Formatters.currency(r.emi)}');
    buf.writeln('Total Interest   : ${Formatters.currency(r.totalInterest)}');
    buf.writeln('Total Repayment  : ${Formatters.currency(r.totalRepayment)}');
    if (r.moratoriumInterest != null && r.moratoriumInterest! > 0) {
      buf.writeln('Moratorium Int.  : ${Formatters.currency(r.moratoriumInterest!)}');
    }
    if (r.effectiveRate != null) {
      buf.writeln('Effective Rate   : ${Formatters.percentage(r.effectiveRate!)} p.a.');
    }
    buf.writeln(sep);
    buf.writeln('AMORTISATION SCHEDULE');
    buf.writeln(sep);
    buf.writeln('Mo.  Principal    Interest    Balance');
    buf.writeln(sep);
    for (final row in schedule) {
      final mo = row['month']!.toInt().toString().padLeft(3);
      final pr = Formatters.compactCurrency(row['principal']!).padLeft(10);
      final int = Formatters.compactCurrency(row['interest']!).padLeft(10);
      final bal = Formatters.compactCurrency(row['balance']!).padLeft(12);
      buf.writeln('$mo  $pr  $int  $bal');
    }
    buf.writeln(sep);
    buf.writeln('Generated by RepayIQ');

    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      buf.toString(),
      subject: 'EMI Calculation - ${r.loanType.label} - RepayIQ',
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.result.loanType.color;
    final r = widget.result;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final schedule = _showSchedule
        ? EmiCalculator.amortisationSchedule(
            principal: r.principal,
            annualRate: r.rate,
            tenureMonths: r.tenure,
          )
        : <Map<String, double>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Results — ${r.loanType.label}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
                blurRadius: 12, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // EMI hero
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Monthly EMI',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
              Text(Formatters.currency(r.emi),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            ]),
            const SizedBox(height: 12),
            Divider(color: cs.onSurface.withValues(alpha: 0.07), height: 1),
            const SizedBox(height: 12),
            _Row('Principal', Formatters.currency(r.principal)),
            _Row('Total Interest', Formatters.currency(r.totalInterest)),
            _Row('Total Repayment', Formatters.currency(r.totalRepayment)),
            _Row('Tenure', Formatters.tenure(r.tenure)),

            if (r.moratoriumInterest != null && r.moratoriumInterest! > 0) ...[
              const SizedBox(height: 12),
              _Callout(
                icon: Icons.pause_circle_outline,
                color: AppColors.warning,
                text: 'Interest of ${Formatters.currency(r.moratoriumInterest!)} accrues during the moratorium period.',
              ),
            ],
            if (r.effectiveRate != null) ...[
              const SizedBox(height: 12),
              _Callout(
                icon: Icons.info_outline,
                color: AppColors.warning,
                text: 'No-Cost EMI hidden cost: effective rate is ${Formatters.percentage(r.effectiveRate!)} p.a.',
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons row
            Row(children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.table_chart_outlined,
                  label: _showSchedule ? 'Hide Schedule' : 'View Schedule',
                  color: color,
                  onTap: () => setState(() => _showSchedule = !_showSchedule),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: AppColors.primary,
                  onTap: _share,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.save_outlined,
                  label: 'Save Loan',
                  color: AppColors.success,
                  onTap: widget.onSave,
                ),
              ),
            ]),
          ]),
        ),

        // ── Amortisation schedule ─────────────────────────────────────────
        if (_showSchedule) ...[
          const SizedBox(height: 16),
          Container(
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
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(children: [
                    const Expanded(flex: 1, child: _ColHeader('Mo.')),
                    const Expanded(flex: 2, child: _ColHeader('Principal')),
                    const Expanded(flex: 2, child: _ColHeader('Interest')),
                    const Expanded(flex: 2, child: _ColHeader('Balance')),
                  ]),
                ),
                Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.07)),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: schedule.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: cs.onSurface.withValues(alpha: 0.05),
                  ),
                  itemBuilder: (_, i) {
                    final row = schedule[i];
                    final isLast = i == schedule.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: isLast
                            ? const BorderRadius.vertical(bottom: Radius.circular(18))
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${row['month']!.toInt()}',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            Formatters.compactCurrency(row['principal']!),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            Formatters.compactCurrency(row['interest']!),
                            style: TextStyle(fontSize: 12, color: AppColors.warning.withValues(alpha: 0.9)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            Formatters.compactCurrency(row['balance']!),
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Callout({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, height: 1.4))),
      ]),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _CalcResult {
  final LoanType loanType;
  final double principal, rate, emi, totalInterest, totalRepayment;
  final int tenure;
  final double? moratoriumInterest;
  final double? effectiveRate;

  const _CalcResult({
    required this.loanType,
    required this.principal,
    required this.rate,
    required this.tenure,
    required this.emi,
    required this.totalInterest,
    required this.totalRepayment,
    this.moratoriumInterest,
    this.effectiveRate,
  });
}
