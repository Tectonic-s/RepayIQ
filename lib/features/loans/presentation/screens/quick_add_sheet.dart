import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/loan_templates.dart';
import '../../../../core/utils/emi_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../providers/loan_providers.dart';
import '../widgets/loan_form_widgets.dart';
import '../../domain/entities/loan.dart';

/// Shows the Quick Add bottom sheet. Returns the saved loan or null.
Future<Loan?> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<Loan>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _QuickAddSheet(),
  );
}

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet();
  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emiCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();

  String _loanType = AppConstants.loanTypes.first;
  int _dueDay = 1;
  bool _showDetails = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emiCtrl.dispose();
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _tenureCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(String type) {
    setState(() {
      _loanType = type;
      final t = LoanTemplates.of(type);
      if (t != null) {
        if (_rateCtrl.text.isEmpty) _rateCtrl.text = t.defaultRate.toString();
        if (_tenureCtrl.text.isEmpty) _tenureCtrl.text = t.defaultTenure.toString();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final emi = double.parse(_emiCtrl.text);
    final template = LoanTemplates.of(_loanType);
    final principal = double.tryParse(_principalCtrl.text) ?? emi * 12;
    final rate = double.tryParse(_rateCtrl.text) ?? template?.defaultRate ?? 10.0;
    final tenure = int.tryParse(_tenureCtrl.text) ?? template?.defaultTenure ?? 36;
    final name = _nameCtrl.text.trim().isEmpty ? _loanType : _nameCtrl.text.trim();

    await ref.read(loanNotifierProvider.notifier).addLoan(
      loanName: name,
      loanType: _loanType,
      principal: principal,
      interestRate: rate,
      tenureMonths: tenure,
      startDate: DateTime.now(),
      dueDay: _dueDay,
      reminderDays: 3,
      calculationMethod: AppConstants.reducingBalance,
    );

    if (!mounted) return;
    final loans = ref.read(loansStreamProvider).value ?? [];
    final saved = loans.isNotEmpty
        ? (List.from(loans)..sort((a, b) => b.createdAt.compareTo(a.createdAt))).first
        : null;
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final template = LoanTemplates.of(_loanType);
    final isLoading = ref.watch(loanNotifierProvider).isLoading;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Quick Add Loan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Just 3 fields to get started',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                  ]),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close, size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            LoanFormLabel('Loan Type'),
            const SizedBox(height: 8),
            LoanTypeSelector(selected: _loanType, onChanged: _onTypeChanged),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Monthly EMI (₹) *',
              hint: 'e.g. 15000',
              controller: _emiCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'EMI amount is required';
                if ((double.tryParse(v) ?? 0) <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            LoanFormLabel('EMI Due Day *'),
            const SizedBox(height: 8),
            _DueDayPicker(value: _dueDay, onChanged: (d) => setState(() => _dueDay = d)),
            const SizedBox(height: 16),

            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Add more details (optional)',
                    style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                trailing: Icon(_showDetails ? Icons.expand_less : Icons.expand_more, color: AppColors.primary),
                onExpansionChanged: (v) => setState(() => _showDetails = v),
                children: [
                  const SizedBox(height: 8),
                  AppTextField(label: 'Loan Name', hint: 'e.g. SBI Home Loan', controller: _nameCtrl),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Principal Amount (₹)',
                    hint: 'e.g. 500000',
                    controller: _principalCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Annual Interest Rate (%)',
                    hint: template?.rateHint ?? '10%',
                    controller: _rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Tenure (months)',
                    hint: template?.tenureHint ?? '36 months',
                    controller: _tenureCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Save Loan', onPressed: _submit, isLoading: isLoading),
          ]),
        ),
      ),
    );
  }
}

class _DueDayPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DueDayPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [1, 5, 7, 10, 15, 20, 25, 28].map((d) {
        final sel = value == d;
        return GestureDetector(
          onTap: () => onChanged(d),
          child: Container(
            width: 44, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sel ? AppColors.primary : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB)),
            ),
            child: Text('$d', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface,
            )),
          ),
        );
      }).toList(),
    );
  }
}

// ── Instant Insight Cards ─────────────────────────────────────────────────────

Future<void> showInsightSheet(BuildContext context, Loan loan) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _InsightSheet(loan: loan),
  );
}

class _InsightSheet extends StatefulWidget {
  final Loan loan;
  const _InsightSheet({required this.loan});
  @override
  State<_InsightSheet> createState() => _InsightSheetState();
}

class _InsightSheetState extends State<_InsightSheet> {
  double _income = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _income = p.getDouble('monthly_income') ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final totalInterest = (loan.monthlyEmi * loan.tenureMonths - loan.principal).clamp(0.0, double.infinity);
    final prepay = EmiCalculator.prepaymentImpact(
      currentBalance: loan.outstandingBalance,
      annualRate: loan.interestRate,
      remainingMonths: loan.monthsRemaining,
      lumpSum: 50000,
    );
    final interestSaved = (prepay['interestSaved'] as double).clamp(0.0, double.infinity);
    final monthsSaved = (prepay['monthsSaved'] as int).clamp(0, 999);
    final pct = _income > 0 ? (loan.monthlyEmi / _income * 100) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text('Loan Insights', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, size: 20)),
        ]),
        const SizedBox(height: 16),
        _InsightCard(
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.error,
          title: 'Total interest you will pay',
          value: Formatters.currency(totalInterest),
        ),
        const SizedBox(height: 10),
        _InsightCard(
          icon: Icons.savings_outlined,
          color: AppColors.success,
          title: 'Prepaying ₹50,000 today saves',
          value: interestSaved > 0
              ? '${Formatters.currency(interestSaved)} & $monthsSaved months'
              : 'Balance is below ₹50,000',
        ),
        const SizedBox(height: 10),
        _InsightCard(
          icon: Icons.pie_chart_outline,
          color: AppColors.warning,
          title: 'This loan contributes to your debt load',
          value: _income > 0
              ? '${pct.toStringAsFixed(1)}% of your monthly income'
              : 'Set income in Budget Analyser to see this',
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Got it'),
          ),
        ),
      ]),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, value;
  const _InsightCard({required this.icon, required this.color, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ])),
      ]),
    );
  }
}
