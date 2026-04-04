import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/statement_import_service.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../providers/loan_providers.dart';
import '../widgets/loan_form_widgets.dart';
import '../../../payments/domain/entities/loan_payment.dart';
import '../../../payments/presentation/providers/payment_providers.dart';

class AddExistingLoanScreen extends ConsumerStatefulWidget {
  const AddExistingLoanScreen({super.key});

  @override
  ConsumerState<AddExistingLoanScreen> createState() => _AddExistingLoanScreenState();
}

class _AddExistingLoanScreenState extends ConsumerState<AddExistingLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();
  final _emisCompletedCtrl = TextEditingController();
  final _processingFeeCtrl = TextEditingController(text: '0');

  String _loanType = AppConstants.loanTypes.first;
  String _method = AppConstants.reducingBalance;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  int _dueDay = 1;
  int _reminderDays = 3;
  bool _importing = false;

  bool get _isConsumerDurable => _loanType == 'Consumer Durable';
  bool get _isZeroRate => double.tryParse(_rateCtrl.text) == 0;
  bool get _showProcessingFee => _isConsumerDurable && _isZeroRate;

  @override
  void initState() {
    super.initState();
    _rateCtrl.addListener(() => setState(() {}));
    // Auto-compute EMIs completed when start date or tenure changes
    _tenureCtrl.addListener(_autoFillEmisCompleted);
  }

  void _autoFillEmisCompleted() {
    final now = DateTime.now();
    final elapsed = ((now.year - _startDate.year) * 12 + now.month - _startDate.month)
        .clamp(0, int.tryParse(_tenureCtrl.text) ?? 999);
    if (elapsed > 0) {
      _emisCompletedCtrl.text = elapsed.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _tenureCtrl.dispose();
    _emisCompletedCtrl.dispose();
    _processingFeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _importFromStatement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import from Statement'),
        content: const Text('The text from your PDF will be sent to Google Gemini AI to extract loan details.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _importing = true);
    try {
      final data = await StatementImportService.importFromPdf();
      if (data == null) return;
      setState(() {
        if (data['loanName'] != null || data['lenderName'] != null) {
          _nameCtrl.text = '${data['lenderName'] ?? ''} ${data['loanName'] ?? ''}'.trim();
        }
        if (data['principal'] != null) _principalCtrl.text = (data['principal'] as num).toStringAsFixed(0);
        if (data['interestRate'] != null) _rateCtrl.text = (data['interestRate'] as num).toString();
        if (data['tenureMonths'] != null) _tenureCtrl.text = (data['tenureMonths'] as num).toInt().toString();
        if (data['startDate'] != null) {
          final parsed = DateTime.tryParse(data['startDate'] as String);
          if (parsed != null) {
            _startDate = parsed;
            _autoFillEmisCompleted();
          }
        }
      });
      if (mounted) {
        final filled = <String>[];
        if (data['principal'] != null) filled.add('amount');
        if (data['interestRate'] != null) filled.add('rate');
        if (data['tenureMonths'] != null) filled.add('tenure');
        if (data['startDate'] != null) filled.add('date');
        final msg = filled.isEmpty
            ? 'No details found — please fill in manually'
            : 'Extracted: ${filled.join(', ')} — review before saving';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: filled.isEmpty ? AppColors.warning : null,
          ));
      }
    } on StatementImportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _pickDueDay() async {
    final picked = await showDueDaySheet(context, _dueDay);
    if (picked != null) setState(() => _dueDay = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      _autoFillEmisCompleted();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(loanNotifierProvider.notifier);

    await notifier.addLoan(
      loanName: _nameCtrl.text.trim(),
      loanType: _loanType,
      principal: double.parse(_principalCtrl.text),
      interestRate: double.parse(_rateCtrl.text),
      tenureMonths: int.parse(_tenureCtrl.text),
      startDate: _startDate,
      dueDay: _dueDay,
      reminderDays: _reminderDays,
      calculationMethod: _method,
    );

    if (!mounted) return;

    // Get the newly added loan
    final loans = ref.read(loansStreamProvider).value ?? [];
    final loan = loans.isNotEmpty
        ? (List.from(loans)..sort((a, b) => b.createdAt.compareTo(a.createdAt))).first
        : null;

    if (loan == null) { context.go('/loans'); return; }

    final emisCompleted = int.tryParse(_emisCompletedCtrl.text) ?? 0;

    // Auto-mark current month as paid if today is past the due day
    // (user is adding an existing loan mid-month after already paying)
    final now = DateTime.now();
    final currentMonthDue = DateTime(now.year, now.month, _dueDay);
    final currentMonthAlreadyPaid = now.isAfter(currentMonthDue);
    final currentMonthKey = LoanPayment.keyFromDate(now);

    if (currentMonthAlreadyPaid) {
      await ref.read(paymentNotifierProvider.notifier).togglePayment(
        loanId: loan.id,
        monthKey: currentMonthKey,
        emiAmount: loan.monthlyEmi,
        existingPayments: const [],
      );
    }

    if (!mounted) return;
    if (emisCompleted > 0) {
      context.push('/past-payments', extra: loan);
    } else {
      context.go('/loans');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loanNotifierProvider).isLoading;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_back, size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Existing Loan',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Import from statement
              GestureDetector(
                onTap: _importing ? null : _importFromStatement,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _importing
                          ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file_outlined, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Import from Statement',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      Text('Scan a PDF or image to auto-fill',
                          style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.7))),
                    ])),
                    Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.primary.withValues(alpha: 0.5)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // ── Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.vehicle.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.vehicle.withValues(alpha: 0.25)),
                ),
                child: const Row(children: [
                  Icon(Icons.history_outlined, color: AppColors.vehicle, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Enter your loan details as they were at the start. We\'ll ask about past payments next.',
                      style: TextStyle(fontSize: 12, color: AppColors.vehicle))),
                ]),
              ),
              const SizedBox(height: 20),

              AppTextField(
                label: 'Loan Name',
                hint: 'e.g. Home Loan - SBI',
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Loan name is required' : null,
              ),
              const SizedBox(height: 16),
              LoanFormLabel('Loan Type'),
              const SizedBox(height: 8),
              LoanTypeSelector(
                selected: _loanType,
                onChanged: (t) => setState(() => _loanType = t),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Original Principal Amount (₹)',
                hint: '500000',
                controller: _principalCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Principal amount is required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid amount greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Annual Interest Rate (%)',
                hint: _isConsumerDurable ? '0 for No-Cost EMI' : '8.5',
                controller: _rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Interest rate is required';
                  final n = double.tryParse(v);
                  if (n == null || n < 0) return 'Enter a valid rate (0 or above)';
                  if (n > 100) return 'Rate cannot exceed 100%';
                  return null;
                },
              ),
              if (_showProcessingFee) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                    SizedBox(width: 8),
                    Expanded(child: Text('No-Cost EMI detected. Enter processing fee to calculate true cost.',
                        style: TextStyle(fontSize: 12, color: AppColors.warning))),
                  ]),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Processing Fee (₹)',
                  hint: '2999',
                  controller: _processingFeeCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter processing fee (0 if none)';
                    if (double.tryParse(v) == null) return 'Invalid amount';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Total Tenure (months)',
                hint: '240',
                controller: _tenureCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Tenure is required';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid tenure greater than 0';
                  if (n > 360) return 'Tenure cannot exceed 360 months';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // EMIs completed — key field for existing loans
              AppTextField(
                label: 'EMIs Completed So Far',
                hint: 'e.g. 24',
                controller: _emisCompletedCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter number of EMIs completed (0 if none)';
                  final n = int.tryParse(v);
                  if (n == null || n < 0) return 'Enter a valid number (0 or above)';
                  final tenure = int.tryParse(_tenureCtrl.text) ?? 0;
                  if (tenure > 0 && n > tenure) return 'Cannot exceed total tenure of $tenure months';
                  return null;
                },
              ),
              const SizedBox(height: 6),
              Text('We\'ll ask you to confirm which of these were paid on the next screen.',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
              const SizedBox(height: 16),

              LoanFormLabel('Calculation Method'),
              const SizedBox(height: 6),
              Row(
                children: [AppConstants.reducingBalance, AppConstants.flatRate].map((m) {
                  final selected = _method == m;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _method = m),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE5E7EB)),
                        ),
                        child: Text(m, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                color: selected ? AppColors.primary : AppColors.textSecondary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              LoanFormLabel('Loan Start Date'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                    const SizedBox(width: 10),
                    Text('${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: const TextStyle(fontSize: 15)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              LoanFormLabel('EMI Due Date'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDueDay,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(children: [
                    Icon(Icons.event_outlined, size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                    const SizedBox(width: 10),
                    Text('Every month on the ${ordinal(_dueDay)}',
                        style: const TextStyle(fontSize: 15)),
                    const Spacer(),
                    Text('Day $_dueDay',
                        style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              LoanFormLabel('Reminder'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _reminderDays,
                decoration: const InputDecoration(),
                items: AppConstants.reminderDays
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d day${d > 1 ? 's' : ''} before')))
                    .toList(),
                onChanged: (v) => setState(() => _reminderDays = v!),
                validator: (v) => v == null ? 'Select reminder days' : null,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Next — Mark Past Payments',
                onPressed: _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
