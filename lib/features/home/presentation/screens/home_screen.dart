import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/profile_photo_provider.dart';
import '../../../../core/services/overdue_detector.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../loans/domain/entities/loan.dart';
import '../../../loans/presentation/providers/loan_providers.dart';
import '../../../payments/domain/entities/loan_payment.dart';
import '../../../payments/presentation/providers/payment_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OverdueDetector.check(ref.read(loanRepositoryProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final active = loans.where((l) => l.status == 'Active').toList();
    final closed = loans.where((l) => l.status == 'Closed').length;
    final totalEmi = active.fold(0.0, (s, l) => s + l.monthlyEmi);
    final totalOutstanding = active.fold(0.0, (s, l) => s + l.outstandingBalance);
    final photoBase64 = ref.watch(profilePhotoProvider).value;
    final paidKeysByLoan = ref.watch(allPaidKeysByLoanProvider);
    final overdue = active.where((l) => l.isOverdueWithPayments(paidKeysByLoan[l.id] ?? {})).toList();
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Top bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _TopBar(
              top: top,
              photoBase64: photoBase64,
              onCalcTap: () => context.push('/calculator'),
              onAiTap: () => context.push('/ai'),
              onProfileTap: () => context.push('/settings'),
            ),
          ),

          // ── Hero balance ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroBalance(
              totalOutstanding: totalOutstanding,
              totalEmi: totalEmi,
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),

                // ── Overdue banner ────────────────────────────────────────
                if (overdue.isNotEmpty) ...[
                  _OverdueBanner(count: overdue.length, onTap: () => context.go('/loans')),
                  const SizedBox(height: 16),
                ],

                // ── Stats row ─────────────────────────────────────────────
                _StatsRow(
                  activeCount: active.length,
                  overdueCount: overdue.length,
                  closedCount: closed,
                ),
                const SizedBox(height: 32),

                // ── Active loans ──────────────────────────────────────────
                if (active.isEmpty)
                  const _EmptyState()
                else ...[
                  _SectionHeader(
                    title: 'Active Loans',
                    action: 'See all',
                    onAction: () => context.go('/loans'),
                  ),
                  const SizedBox(height: 12),
                  AnimatedDataSwitch(
                    key: ValueKey(active.length),
                    child: Column(
                      key: ValueKey(active.map((l) => l.id).join()),
                      children: active.take(3).map((l) => _LoanTile(loan: l)).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final double top;
  final String? photoBase64;
  final VoidCallback onCalcTap, onAiTap, onProfileTap;

  const _TopBar({
    required this.top,
    required this.photoBase64,
    required this.onCalcTap,
    required this.onAiTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'RepayIQ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ),
          _IconBtn(icon: Icons.calculate_outlined, onTap: onCalcTap),
          _IconBtn(icon: Icons.auto_awesome_outlined, onTap: onAiTap),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: photoBase64 != null
                  ? MemoryImage(base64Decode(photoBase64!))
                  : null,
              child: photoBase64 == null
                  ? const Icon(Icons.person_outline, color: AppColors.primary, size: 18)
                  : null,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(icon,
          size: 20,
          color: isDark ? Colors.white60 : AppColors.textSecondary),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Hero balance ──────────────────────────────────────────────────────────────

class _HeroBalance extends StatelessWidget {
  final double totalOutstanding, totalEmi;
  const _HeroBalance({required this.totalOutstanding, required this.totalEmi});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TOTAL OUTSTANDING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: isDark ? Colors.white38 : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedValue(
            Formatters.currency(totalOutstanding),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Center(child: _EmiPill(totalEmi: totalEmi)),
        ],
      ),
    );
  }
}

class _EmiPill extends StatelessWidget {
  final double totalEmi;
  const _EmiPill({required this.totalEmi});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedValue(
                '${Formatters.currency(totalEmi)} / month',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overdue banner ────────────────────────────────────────────────────────────

class _OverdueBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _OverdueBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$count loan${count > 1 ? 's are' : ' is'} overdue — tap to review',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.error, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int activeCount, overdueCount, closedCount;
  const _StatsRow({
    required this.activeCount,
    required this.overdueCount,
    required this.closedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(label: 'Active', value: '$activeCount', color: AppColors.primary),
        _Divider(),
        _StatItem(
          label: 'Overdue',
          value: '$overdueCount',
          color: overdueCount > 0 ? AppColors.error : AppColors.textHint,
        ),
        _Divider(),
        _StatItem(label: 'Closed', value: '$closedCount', color: AppColors.success),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          AnimatedValue(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: isDark ? Colors.white38 : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 40,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title, action;
  final VoidCallback onAction;
  const _SectionHeader({required this.title, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Loan tile ─────────────────────────────────────────────────────────────────

class _LoanTile extends ConsumerWidget {
  final Loan loan;
  const _LoanTile({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.loanTypeColor(loan.loanType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final currentMonthKey = LoanPayment.keyFromDate(DateTime.now());
    final payments = ref.watch(paymentsProvider(loan.id)).value ?? [];
    final isPaid = payments.any((p) => p.monthKey == currentMonthKey);

    return GestureDetector(
      onTap: () => context.push('/loans/${loan.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(AppColors.loanTypeIcon(loan.loanType), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.loanName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.currency(loan.monthlyEmi)}/mo · ${loan.monthsRemaining} mo left',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(loan.outstandingBalance),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    if (loan.isOverdue && !isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Overdue',
                          style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Text(
                        '${(loan.progressPercent * 100).toStringAsFixed(0)}% paid',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.38)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: loan.progressPercent),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (ctx, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // This month payment toggle
            GestureDetector(
              onTap: () => _togglePayment(ref, loan, payments, currentMonthKey, isPaid),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.success.withValues(alpha: 0.08)
                      : cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPaid
                        ? AppColors.success.withValues(alpha: 0.25)
                        : cs.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: isPaid ? AppColors.success : cs.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPaid ? 'This month paid' : 'Mark this month as paid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? AppColors.success : cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePayment(
    WidgetRef ref,
    Loan loan,
    List<LoanPayment> payments,
    String monthKey,
    bool isPaid,
  ) async {
    await ref.read(paymentNotifierProvider.notifier).togglePayment(
      loanId: loan.id,
      monthKey: monthKey,
      emiAmount: loan.monthlyEmi,
      existingPayments: payments,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_outlined, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No active loans',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add your first loan',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.38)),
          ),
        ],
      ),
    );
  }
}
