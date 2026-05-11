import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/emi_calculator.dart';
import '../../../loans/presentation/providers/loan_providers.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _incomeCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController();
  final _newLoanCtrl = TextEditingController();
  final _newRateCtrl = TextEditingController();
  final _newTenureCtrl = TextEditingController();

  double _income = 0, _expenses = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final inc = prefs.getDouble('monthly_income') ?? 0;
    final exp = prefs.getDouble('monthly_expenses') ?? 0;
    setState(() {
      _income = inc;
      _expenses = exp;
      if (inc > 0) _incomeCtrl.text = inc.toStringAsFixed(0);
      if (exp > 0) _expensesCtrl.text = exp.toStringAsFixed(0);
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final inc = double.tryParse(_incomeCtrl.text) ?? 0;
    final exp = double.tryParse(_expensesCtrl.text) ?? 0;
    await prefs.setDouble('monthly_income', inc);
    await prefs.setDouble('monthly_expenses', exp);
    if (!mounted) return;
    setState(() { _income = inc; _expenses = exp; });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    for (final c in [_incomeCtrl, _expensesCtrl, _newLoanCtrl, _newRateCtrl, _newTenureCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(activeLoansProvider);
    final totalEmi = loans.fold(0.0, (s, l) => s + l.monthlyEmi);
    final disposable = _income - _expenses - totalEmi;
    final emiRatio = _income == 0 ? 0.0 : totalEmi / _income;
    final isStressed = emiRatio > 0.5;

    // New loan impact
    final newPrincipal = double.tryParse(_newLoanCtrl.text) ?? 0;
    final newRate = double.tryParse(_newRateCtrl.text) ?? 0;
    final newTenure = int.tryParse(_newTenureCtrl.text) ?? 0;
    double newEmi = 0;
    if (newPrincipal > 0 && newRate > 0 && newTenure > 0) {
      newEmi = EmiCalculator.reducingBalanceEmi(principal: newPrincipal, annualRate: newRate, tenureMonths: newTenure);
    }
    final newRatio = _income == 0 ? 0.0 : (totalEmi + newEmi) / _income;
    final newDisposable = disposable - newEmi;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Analyser')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Income & expenses input
          _InputCard(
            incomeCtrl: _incomeCtrl,
            expensesCtrl: _expensesCtrl,
            onSave: _save,
          ),
          const SizedBox(height: 16),

          // Current budget breakdown
          if (_income > 0) ...[
            const Text('Current Budget', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _BudgetBreakdown(
              income: _income,
              expenses: _expenses,
              totalEmi: totalEmi,
              disposable: disposable,
              emiRatio: emiRatio,
              isStressed: isStressed,
            ),
            const SizedBox(height: 20),

            // New loan impact simulator
            const Text('New Loan Impact', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('See how a new loan would affect your budget', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 12),
            _NewLoanSimulator(
              principalCtrl: _newLoanCtrl,
              rateCtrl: _newRateCtrl,
              tenureCtrl: _newTenureCtrl,
              newEmi: newEmi,
              newRatio: newRatio,
              newDisposable: newDisposable,
              income: _income,
              onChanged: () => setState(() {}),
            ),
          ],
        ]),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController incomeCtrl, expensesCtrl;
  final VoidCallback onSave;
  const _InputCard({required this.incomeCtrl, required this.expensesCtrl, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Monthly Finances', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _Field(ctrl: incomeCtrl, label: 'Monthly Income (₹)', hint: '80000'),
        const SizedBox(height: 10),
        _Field(ctrl: expensesCtrl, label: 'Monthly Expenses (₹)', hint: '30000'),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                minimumSize: const Size(0, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Update'),
          ),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  const _Field({required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixText: '₹ ',
        filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}

class _BudgetBreakdown extends StatelessWidget {
  final double income, expenses, totalEmi, disposable, emiRatio;
  final bool isStressed;
  const _BudgetBreakdown({required this.income, required this.expenses, required this.totalEmi,
      required this.disposable, required this.emiRatio, required this.isStressed});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          _BRow('Monthly Income', Formatters.currency(income), AppColors.success),
          _BRow('Monthly Expenses', '− ${Formatters.currency(expenses)}', AppColors.error),
          _BRow('Total EMI', '− ${Formatters.currency(totalEmi)}', AppColors.warning),
          const Divider(height: 20),
          _BRow('Disposable Income', Formatters.currency(disposable),
              disposable >= 0 ? AppColors.primary : AppColors.error, bold: true),
        ]),
      ),
      const SizedBox(height: 10),
      // EMI ratio bar
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isStressed ? AppColors.error.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isStressed ? AppColors.error.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isStressed ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isStressed ? AppColors.error : AppColors.success, size: 18),
            const SizedBox(width: 8),
            Text(isStressed ? 'Financial Stress Detected' : 'Healthy EMI Ratio',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isStressed ? AppColors.error : AppColors.success)),
            const Spacer(),
            Text('${(emiRatio * 100).toStringAsFixed(0)}% of income',
                style: TextStyle(fontSize: 12, color: isStressed ? AppColors.error : AppColors.success)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: emiRatio.clamp(0.0, 1.0), minHeight: 6,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation(isStressed ? AppColors.error : AppColors.success),
            ),
          ),
          const SizedBox(height: 6),
          Text(isStressed
              ? 'Your EMIs exceed 50% of income. Avoid new loans until this reduces.'
              : 'Your EMI-to-income ratio is within the safe 50% threshold.',
              style: TextStyle(fontSize: 11, color: isStressed ? AppColors.error : AppColors.success)),
        ]),
      ),
    ]);
  }
}

class _BRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _BRow(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: bold ? AppColors.textPrimary : AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _NewLoanSimulator extends StatelessWidget {
  final TextEditingController principalCtrl, rateCtrl, tenureCtrl;
  final double newEmi, newRatio, newDisposable, income;
  final VoidCallback onChanged;
  const _NewLoanSimulator({required this.principalCtrl, required this.rateCtrl, required this.tenureCtrl,
      required this.newEmi, required this.newRatio, required this.newDisposable,
      required this.income, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final wouldStress = newRatio > 0.5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _SimField(ctrl: principalCtrl, label: 'Principal (₹)', onChanged: onChanged)),
          const SizedBox(width: 10),
          Expanded(child: _SimField(ctrl: rateCtrl, label: 'Rate (%)', onChanged: onChanged)),
          const SizedBox(width: 10),
          Expanded(child: _SimField(ctrl: tenureCtrl, label: 'Tenure (mo)', onChanged: onChanged)),
        ]),
        if (newEmi > 0) ...[
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          _BRow('New Loan EMI', Formatters.currency(newEmi), AppColors.warning),
          _BRow('New Disposable', Formatters.currency(newDisposable),
              newDisposable >= 0 ? AppColors.primary : AppColors.error),
          _BRow('New EMI Ratio', '${(newRatio * 100).toStringAsFixed(0)}% of income',
              wouldStress ? AppColors.error : AppColors.success),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: wouldStress ? AppColors.error.withValues(alpha: 0.08) : AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(wouldStress ? Icons.cancel_outlined : Icons.check_circle_outline,
                  color: wouldStress ? AppColors.error : AppColors.success, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                wouldStress
                    ? 'Taking this loan would push your EMI ratio above 50%. Not recommended.'
                    : 'This loan is within safe limits. You can afford it.',
                style: TextStyle(fontSize: 12, color: wouldStress ? AppColors.error : AppColors.success),
              )),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _SimField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final VoidCallback onChanged;
  const _SimField({required this.ctrl, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(fontSize: 11),
        filled: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
