import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../domain/entities/loan_payment.dart';
import '../providers/payment_providers.dart';

class PastPaymentsScreen extends ConsumerStatefulWidget {
  final Loan loan;
  const PastPaymentsScreen({super.key, required this.loan});

  @override
  ConsumerState<PastPaymentsScreen> createState() => _PastPaymentsScreenState();
}

class _PastPaymentsScreenState extends ConsumerState<PastPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late final List<DateTime> _months;
  late List<bool> _paid;
  bool _saving = false;
  late final AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    final start = widget.loan.startDate;
    final elapsed = widget.loan.monthsElapsed;
    _months = List.generate(
      elapsed,
      (i) => DateTime(start.year, start.month + i + 1, widget.loan.dueDay),
    );
    _paid = List.filled(_months.length, true);

    _listCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + _months.length.clamp(0, 20) * 30),
    )..forward();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  int get _paidCount => _paid.where((p) => p).length;
  int get _missedCount => _paid.where((p) => !p).length;
  double get _progressValue => _months.isEmpty ? 1.0 : _paidCount / _months.length;

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() => _paid[i] = !_paid[i]);
  }

  void _setAll(bool value) {
    HapticFeedback.mediumImpact();
    setState(() => _paid = List.filled(_months.length, value));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payments = <LoanPayment>[];
    for (int i = 0; i < _months.length; i++) {
      if (_paid[i]) {
        payments.add(LoanPayment(
          id: const Uuid().v4(),
          loanId: widget.loan.id,
          monthKey: LoanPayment.keyFromDate(_months[i]),
          amountPaid: widget.loan.monthlyEmi,
          paidAt: _months[i],
        ));
      }
    }
    if (payments.isNotEmpty) {
      await ref.read(paymentNotifierProvider.notifier).bulkMarkPaid(payments);
    }
    if (!mounted) return;
    await showLoanSavedOverlay(context, message: 'Loan added successfully');
    if (mounted) context.go('/home');
  }

  // Group months by year
  Map<int, List<int>> get _byYear {
    final map = <int, List<int>>{};
    for (int i = 0; i < _months.length; i++) {
      map.putIfAbsent(_months[i].year, () => []).add(i);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final color = AppColors.loanTypeColor(loan.loanType);
    final icon = AppColors.loanTypeIcon(loan.loanType);
    final topPad = MediaQuery.of(context).padding.top;
    final byYear = _byYear;
    final years = byYear.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(
            loan: loan,
            color: color,
            icon: icon,
            topPad: topPad,
            paidCount: _paidCount,
            missedCount: _missedCount,
            totalCount: _months.length,
            progressValue: _progressValue,
            onAllPaid: () => _setAll(true),
            onAllMissed: () => _setAll(false),
            onClose: () => context.go('/home'),
          ),
          Expanded(
            child: _months.isEmpty
                ? _EmptyState(color: color)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: years.length,
                    itemBuilder: (ctx, yi) {
                      final year = years[yi];
                      final indices = byYear[year]!;
                      return _YearSection(
                        year: year,
                        indices: indices,
                        months: _months,
                        paid: _paid,
                        emi: loan.monthlyEmi,
                        listCtrl: _listCtrl,
                        onToggle: _toggle,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _SaveBar(
        paidCount: _paidCount,
        missedCount: _missedCount,
        totalEmi: loan.monthlyEmi * _paidCount,
        saving: _saving,
        onSave: _save,
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Loan loan;
  final Color color;
  final IconData icon;
  final double topPad;
  final int paidCount, missedCount, totalCount;
  final double progressValue;
  final VoidCallback onAllPaid, onAllMissed, onClose;

  const _Header({
    required this.loan, required this.color, required this.icon,
    required this.topPad, required this.paidCount, required this.missedCount,
    required this.totalCount, required this.progressValue,
    required this.onAllPaid, required this.onAllMissed, required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row
        Row(children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mark Past Payments',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              Text(loan.loanName,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
            ]),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ]),
        const SizedBox(height: 20),

        // Stats row
        Row(children: [
          _StatChip(label: 'Paid', value: '$paidCount', color: Colors.white, bg: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Missed',
            value: '$missedCount',
            color: missedCount > 0 ? const Color(0xFFFFD6D6) : Colors.white.withValues(alpha: 0.6),
            bg: missedCount > 0 ? Colors.red.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 8),
          _StatChip(label: 'Total', value: '$totalCount', color: Colors.white.withValues(alpha: 0.7), bg: Colors.white.withValues(alpha: 0.1)),
          const Spacer(),
          // Quick actions
          GestureDetector(
            onTap: onAllPaid,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('All Paid', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onAllMissed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text('All Missed', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Progress bar
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${(progressValue * 100).toStringAsFixed(0)}% paid',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('Started ${Formatters.date(loan.startDate)}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progressValue),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color, bg;
  const _StatChip({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10)),
    ]),
  );
}

// ── Year section ──────────────────────────────────────────────────────────────

class _YearSection extends StatelessWidget {
  final int year;
  final List<int> indices;
  final List<DateTime> months;
  final List<bool> paid;
  final double emi;
  final AnimationController listCtrl;
  final void Function(int) onToggle;

  const _YearSection({
    required this.year, required this.indices, required this.months,
    required this.paid, required this.emi, required this.listCtrl,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final yearPaid = indices.where((i) => paid[i]).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(children: [
          Text('$year',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                letterSpacing: 0.5,
              )),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1))),
          const SizedBox(width: 8),
          Text('$yearPaid/${indices.length}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
        ]),
      ),
      ...indices.map((i) {
        final delay = (i / (months.isEmpty ? 1 : months.length)).clamp(0.0, 0.9);
        final itemAnim = CurvedAnimation(
          parent: listCtrl,
          curve: Interval(delay * 0.6, delay * 0.6 + 0.4, curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: itemAnim,
          builder: (_, child) => FadeTransition(
            opacity: itemAnim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(itemAnim),
              child: child,
            ),
          ),
          child: _MonthTile(
            month: months[i],
            isPaid: paid[i],
            emi: emi,
            onTap: () => onToggle(i),
          ),
        );
      }),
    ]);
  }
}

// ── Month tile ────────────────────────────────────────────────────────────────

class _MonthTile extends StatelessWidget {
  final DateTime month;
  final bool isPaid;
  final double emi;
  final VoidCallback onTap;

  const _MonthTile({required this.month, required this.isPaid, required this.emi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isPaid
              ? AppColors.success.withValues(alpha: isDark ? 0.12 : 0.07)
              : (isDark ? const Color(0xFF252830) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPaid
                ? AppColors.success.withValues(alpha: 0.35)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            width: isPaid ? 1.5 : 1,
          ),
          boxShadow: isPaid ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          // Month icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _shortMonth(month.month),
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: isPaid ? AppColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Formatters.monthYear(month),
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: isPaid ? 1.0 : 0.85),
                  )),
              const SizedBox(height: 2),
              Text(Formatters.currency(emi),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                  )),
            ]),
          ),
          // Animated check/cross
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isPaid ? AppColors.success : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPaid ? AppColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isPaid
                  ? const Icon(Icons.check_rounded, key: ValueKey(true), color: Colors.white, size: 17)
                  : Icon(Icons.remove, key: const ValueKey(false),
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25), size: 16),
            ),
          ),
        ]),
      ),
    );
  }

  static String _shortMonth(int m) {
    const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return months[m - 1];
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color color;
  const _EmptyState({required this.color});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.check_circle_outline, color: color, size: 36),
      ),
      const SizedBox(height: 16),
      const Text('No past EMIs to record',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Your loan starts fresh from today',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
    ]),
  );
}

// ── Save bar ──────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final int paidCount, missedCount;
  final double totalEmi;
  final bool saving;
  final VoidCallback onSave;

  const _SaveBar({
    required this.paidCount, required this.missedCount,
    required this.totalEmi, required this.saving, required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Summary row
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _SummaryBadge(
            icon: Icons.check_circle_outline,
            label: '$paidCount paid',
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          if (missedCount > 0) ...[
            _SummaryBadge(
              icon: Icons.cancel_outlined,
              label: '$missedCount missed',
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
          ],
          _SummaryBadge(
            icon: Icons.account_balance_wallet_outlined,
            label: Formatters.currency(totalEmi),
            color: AppColors.primary,
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.save_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Save & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
          ),
        ),
      ]),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SummaryBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]),
  );
}
