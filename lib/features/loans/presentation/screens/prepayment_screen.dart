import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/emi_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../domain/entities/loan.dart';

class PrepaymentScreen extends StatefulWidget {
  final Loan loan;
  const PrepaymentScreen({super.key, required this.loan});

  @override
  State<PrepaymentScreen> createState() => _PrepaymentScreenState();
}

class _PrepaymentScreenState extends State<PrepaymentScreen> {
  final _lumpSumCtrl = TextEditingController();
  final _prepayChargeCtrl = TextEditingController(text: '0');
  final _foreclosureChargeCtrl = TextEditingController(text: '0');
  Map<String, dynamic>? _result;

  void _calculate() {
    final lumpSum = double.tryParse(_lumpSumCtrl.text);
    if (lumpSum == null || lumpSum <= 0) return;
    final prepayCharge = double.tryParse(_prepayChargeCtrl.text) ?? 0;
    final foreclosureCharge = double.tryParse(_foreclosureChargeCtrl.text) ?? 0;
    setState(() {
      _result = EmiCalculator.prepaymentImpact(
        currentBalance: widget.loan.outstandingBalance,
        annualRate: widget.loan.interestRate,
        remainingMonths: widget.loan.monthsRemaining,
        lumpSum: lumpSum,
        prepaymentChargePercent: prepayCharge,
        foreclosureChargePercent: foreclosureCharge,
      );
    });
  }

  @override
  void dispose() {
    _lumpSumCtrl.dispose();
    _prepayChargeCtrl.dispose();
    _foreclosureChargeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isForeclosure = _result?['isForeclosure'] == true;
    final netSavings = (_result?['netSavings'] as double?) ?? 0;
    final resultColor = netSavings >= 0 ? AppColors.success : AppColors.warning;

    return Scaffold(
      appBar: AppBar(title: const Text('Prepayment Simulator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoTile('Outstanding Balance', Formatters.currency(widget.loan.outstandingBalance)),
            _InfoTile('Remaining Months', '${widget.loan.monthsRemaining} months'),
            _InfoTile('Interest Rate', '${widget.loan.interestRate}% p.a.'),
            const SizedBox(height: 24),

            AppTextField(
              label: 'Lump Sum Amount (₹)',
              hint: 'Enter prepayment amount',
              controller: _lumpSumCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _calculate(),
            ),
            const SizedBox(height: 16),

            // Charge inputs
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 15),
                    SizedBox(width: 6),
                    Text('Bank Charges (% of prepayment amount)',
                        style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _ChargeField(
                      label: 'Prepayment Charge %',
                      hint: 'e.g. 2',
                      controller: _prepayChargeCtrl,
                      onChanged: (_) => setState(() {}),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ChargeField(
                      label: 'Foreclosure Charge %',
                      hint: 'e.g. 3',
                      controller: _foreclosureChargeCtrl,
                      onChanged: (_) => setState(() {}),
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Foreclosure charge applies when paying off the full balance.',
                    style: TextStyle(fontSize: 11, color: AppColors.warning.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            PrimaryButton(label: 'Calculate Impact', onPressed: _calculate),

            if (_result != null) ...[ 
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: resultColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      isForeclosure ? Icons.lock_open_outlined : Icons.savings_outlined,
                      color: resultColor, size: 40,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isForeclosure ? 'Foreclosure' : 'Partial Prepayment',
                      style: TextStyle(fontSize: 12, color: resultColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _ResultRow('Months Saved', '${_result!['monthsSaved']} months', AppColors.primary),
                    _ResultRow('Interest Saved', Formatters.currency(_result!['interestSaved']), AppColors.success),
                    if ((_result!['chargeAmount'] as double) > 0) ...[ 
                      const Divider(height: 20),
                      _ResultRow('Bank Charge', '− ${Formatters.currency(_result!['chargeAmount'])}', AppColors.error),
                    ],
                    const Divider(height: 20),
                    _ResultRow(
                      'Net Savings',
                      Formatters.currency(netSavings),
                      resultColor,
                      bold: true,
                    ),
                    if (netSavings < 0) ...[ 
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 15),
                          SizedBox(width: 8),
                          Expanded(child: Text(
                            'Bank charges exceed interest savings. Prepayment may not be beneficial.',
                            style: TextStyle(fontSize: 11, color: AppColors.warning),
                          )),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ChargeField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _ChargeField({required this.label, required this.hint, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        hintText: hint,
        suffixText: '%',
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 14)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      );
}

class _ResultRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _ResultRow(this.label, this.value, this.color, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: bold ? 14 : 13,
            )),
            Text(value, style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              fontSize: bold ? 17 : 15,
            )),
          ],
        ),
      );
}
