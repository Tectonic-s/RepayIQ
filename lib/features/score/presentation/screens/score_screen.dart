import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../loans/presentation/providers/loan_providers.dart';
import '../providers/score_providers.dart';

class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final profile = ref.watch(userProfileProvider).value;
    final monthlyIncome = profile?.monthlyIncome ?? 0.0;
    final result = ScoreCalculator.calculate(loans: loans, monthlyIncome: monthlyIncome);
    final bandColor = _bandColor(result.band);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ScoreHeader(
              score: result.score,
              band: result.band,
              color: bandColor,
              monthlyIncome: monthlyIncome,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Factor breakdown
                const Text('Score Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _FactorCard(label: 'Payment History', weight: '40%', score: result.paymentHistoryScore, max: 40,
                    icon: Icons.check_circle_outline, description: 'Based on overdue vs on-time loans'),
                const SizedBox(height: 10),
                _FactorCard(label: 'Debt-to-Income Ratio', weight: '30%', score: result.debtToIncomeScore, max: 30,
                    icon: Icons.account_balance_wallet_outlined, description: 'Total EMI vs monthly income'),
                const SizedBox(height: 10),
                _FactorCard(label: 'Loan Utilisation', weight: '20%', score: result.utilisationScore, max: 20,
                    icon: Icons.pie_chart_outline, description: 'Outstanding vs original principal'),
                const SizedBox(height: 10),
                _FactorCard(label: 'Active Loan Count', weight: '10%', score: result.activeLoanScore, max: 10,
                    icon: Icons.format_list_numbered, description: 'Fewer active loans = better score'),
                const SizedBox(height: 20),

                // Score bands legend
                const Text('Score Bands', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _BandLegend(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _bandColor(String band) => switch (band) {
    'Excellent' => AppColors.scoreExcellent,
    'Good'      => AppColors.scoreGood,
    'Fair'      => AppColors.scoreFair,
    _           => AppColors.scorePoor,
  };
}

// ── Header with animated score gauge ─────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  final int score;
  final String band;
  final Color color;
  final double monthlyIncome;
  
  const _ScoreHeader({
    required this.score,
    required this.band,
    required this.color,
    required this.monthlyIncome,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Back button and title row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text(
                  'RepayIQ Score',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 16),
          // Score display
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (ctx, val, child) => Text(
              '$val',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              band,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (ctx, v, child) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text('100', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          // Monthly income info
          if (monthlyIncome > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Monthly Income: ₹${monthlyIncome.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/settings/edit-profile'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Add monthly income for accurate score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Factor card ───────────────────────────────────────────────────────────────

class _FactorCard extends StatelessWidget {
  final String label, weight, description;
  final double score, max;
  final IconData icon;
  const _FactorCard({required this.label, required this.weight, required this.score,
      required this.max, required this.icon, required this.description});

  @override
  Widget build(BuildContext context) {
    final pct = max == 0 ? 0.0 : score / max;
    final color = pct >= 0.7 ? AppColors.success : pct >= 0.4 ? AppColors.warning : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(description, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${score.toStringAsFixed(1)} / $max', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(weight, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
          ]),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (ctx, v, child) => LinearProgressIndicator(
              value: v, minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Band legend ───────────────────────────────────────────────────────────────

class _BandLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const bands = [
      ('Excellent', '80–100', AppColors.scoreExcellent),
      ('Good', '60–79', AppColors.scoreGood),
      ('Fair', '40–59', AppColors.scoreFair),
      ('Poor', 'Below 40', AppColors.scorePoor),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: bands.map((b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: b.$3, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(b.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(b.$2, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          ]),
        )).toList(),
      ),
    );
  }
}
