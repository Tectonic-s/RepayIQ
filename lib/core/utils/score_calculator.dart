import '../../features/loans/domain/entities/loan.dart';

class RepayIQScore {
  final int score;
  final String band;
  final double paymentHistoryScore;
  final double debtToIncomeScore;
  final double utilisationScore;
  final double activeLoanScore;

  const RepayIQScore({
    required this.score,
    required this.band,
    required this.paymentHistoryScore,
    required this.debtToIncomeScore,
    required this.utilisationScore,
    required this.activeLoanScore,
  });
}

class ScoreCalculator {
  /// Calculates RepayIQ score from 0–100.
  /// [monthlyIncome] — user's declared monthly income
  static RepayIQScore calculate({
    required List<Loan> loans,
    required double monthlyIncome,
  }) {
    final active = loans.where((l) => l.status == 'Active').toList();

    // Factor 1 — Payment history (40%)
    // Overdue loans reduce score. Uses date-based check (payment data not available here).
    final overdueCount = active.where((l) => l.isOverdue).length;
    final paymentRaw = active.isEmpty
        ? 1.0
        : (active.length - overdueCount) / active.length;
    final paymentScore = (paymentRaw * 40).clamp(0.0, 40.0);

    // Factor 2 — Debt-to-income ratio (30%)
    // Total EMI / monthly income. Below 30% = full marks, above 60% = 0.
    final totalEmi = active.fold(0.0, (s, l) => s + l.monthlyEmi);
    final dtiRatio = monthlyIncome == 0 ? 1.0 : totalEmi / monthlyIncome;
    final dtiRaw = dtiRatio <= 0.3
        ? 1.0
        : dtiRatio >= 0.6
            ? 0.0
            : 1.0 - ((dtiRatio - 0.3) / 0.3);
    final dtiScore = dtiRaw * 30;

    // Factor 3 — Loan utilisation (20%)
    // Outstanding / original principal. Lower = better.
    final totalPrincipal = active.fold(0.0, (s, l) => s + l.principal);
    final totalOutstanding = active.fold(0.0, (s, l) => s + l.outstandingBalance);
    final utilRaw = totalPrincipal == 0
        ? 1.0
        : 1.0 - (totalOutstanding / totalPrincipal);
    final utilScore = utilRaw * 20;

    // Factor 4 — Number of active loans (10%)
    // 0–2 loans = full marks, 5+ = 0.
    final loanCountRaw = active.length <= 2
        ? 1.0
        : active.length >= 5
            ? 0.0
            : 1.0 - ((active.length - 2) / 3);
    final loanCountScore = loanCountRaw * 10;

    final total = (paymentScore + dtiScore + utilScore + loanCountScore).round().clamp(0, 100);

    return RepayIQScore(
      score: total,
      band: _band(total),
      paymentHistoryScore: paymentScore,
      debtToIncomeScore: dtiScore,
      utilisationScore: utilScore,
      activeLoanScore: loanCountScore,
    );
  }

  static String _band(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }
}
