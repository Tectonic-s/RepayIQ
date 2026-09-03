import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/presentation/providers/loan_providers.dart';
import '../../domain/entities/loan_payment.dart';
import '../providers/payment_providers.dart';

class PaymentConfirmScreen extends ConsumerStatefulWidget {
  final String loanId;
  const PaymentConfirmScreen({super.key, required this.loanId});

  @override
  ConsumerState<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends ConsumerState<PaymentConfirmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  bool _saving = false;
  bool? _answered; // null = not answered, true = paid, false = not paid

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _markPaid(Loan loan) async {
    setState(() { _answered = true; _saving = true; });
    final monthKey = LoanPayment.keyFromDate(DateTime.now());
    final existing = ref.read(paymentsProvider(loan.id)).value ?? [];
    await ref.read(paymentNotifierProvider.notifier).togglePayment(
      loanId: loan.id,
      monthKey: monthKey,
      emiAmount: loan.monthlyEmi,
      existingPayments: existing,
    );
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go('/home');
  }

  Future<void> _markUnpaid() async {
    setState(() { _answered = false; _saving = true; });
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final loan = loans.where((l) => l.id == widget.loanId).firstOrNull;

    if (loan == null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading loan...'),
            const SizedBox(height: 16),
            TextButton(onPressed: () => context.go('/home'), child: const Text('Go Home')),
          ]),
        ),
      );
    }

    final color = AppColors.loanTypeColor(loan.loanType);
    final monthKey = LoanPayment.keyFromDate(DateTime.now());
    final payments = ref.watch(paymentsProvider(loan.id)).value ?? [];
    final alreadyPaid = payments.any((p) => p.monthKey == monthKey);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.08), Theme.of(context).scaffoldBackgroundColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Close
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ),
                ),
                const Spacer(),

                // Animated loan icon
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(AppColors.loanTypeIcon(loan.loanType), color: color, size: 40),
                  ),
                ),
                const SizedBox(height: 24),

                Text(loan.loanName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  alreadyPaid
                      ? 'Already marked as paid this month ✓'
                      : 'EMI due this month',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: alreadyPaid ? AppColors.success : AppColors.textSecondary,
                    fontWeight: alreadyPaid ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 32),

                // EMI amount card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    Text('EMI Amount', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                    const SizedBox(height: 6),
                    Text(Formatters.currency(loan.monthlyEmi),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color)),
                    const SizedBox(height: 4),
                    Text('Due on day ${loan.dueDay} every month',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                  ]),
                ),
                const SizedBox(height: 16),

                // Answer feedback
                if (_answered != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: (_answered! ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_answered! ? Icons.check_circle : Icons.cancel_outlined,
                          color: _answered! ? AppColors.success : AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _answered! ? 'Payment recorded! Redirecting...' : 'Noted. We\'ll remind you again.',
                        style: TextStyle(
                          color: _answered! ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600, fontSize: 13,
                        ),
                      ),
                    ]),
                  ),

                const Spacer(),

                // Action buttons
                if (_answered == null && !alreadyPaid) ...[
                  _ActionButton(
                    label: 'Yes, I\'ve Paid',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    onTap: _saving ? null : () => _markPaid(loan),
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    label: 'Not Yet',
                    icon: Icons.schedule_outlined,
                    color: AppColors.error,
                    outlined: true,
                    onTap: _saving ? null : _markUnpaid,
                  ),
                ] else if (alreadyPaid && _answered == null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Go to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.outlined = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }
}
