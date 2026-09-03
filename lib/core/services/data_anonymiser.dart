import '../../features/loans/domain/entities/loan.dart';

/// Strips all PII from loans before sending to Gemini.
/// Only numerical values are retained. Names replaced with generic labels.
class DataAnonymiser {
  /// Returns a list of anonymised loan maps with type included in label.
  static List<Map<String, dynamic>> anonymiseLoans(List<Loan> loans) {
    return List.generate(loans.length, (i) {
      final l = loans[i];
      return {
        'label': 'Loan ${String.fromCharCode(65 + i)} (${l.loanType})',
        'loanName': l.loanName, // kept locally for legend — never sent to AI
        'principal': l.principal,
        'annualRatePercent': l.interestRate,
        'tenureMonths': l.tenureMonths,
        'monthsRemaining': l.monthsRemaining,
        'monthlyEmi': l.monthlyEmi,
        'outstandingBalance': l.outstandingBalance,
      };
    });
  }

  /// Builds a legend map of label → actual loan name for UI display only.
  /// This is NEVER sent to the AI.
  static Map<String, String> buildLegend(List<Loan> loans) {
    final anon = anonymiseLoans(loans);
    return {for (final l in anon) l['label'] as String: l['loanName'] as String};
  }

  /// Builds a plain-text portfolio summary from anonymised data only.
  static String buildAnonymisedPortfolio(List<Loan> loans) {
    if (loans.isEmpty) return 'The user has no active loans.';
    final anon = anonymiseLoans(loans);
    final buffer = StringBuffer('Anonymous loan portfolio:\n');
    for (final l in anon) {
      buffer.writeln(
        '- ${l['label']}: Principal ₹${l['principal']}, '
        '${l['annualRatePercent']}% p.a., '
        '${l['monthsRemaining']} months remaining, '
        'EMI ₹${l['monthlyEmi']}, '
        'Outstanding ₹${l['outstandingBalance']}',
      );
    }    final totalEmi = loans.fold(0.0, (s, l) => s + l.monthlyEmi);
    final totalOutstanding = loans.fold(0.0, (s, l) => s + l.outstandingBalance);
    buffer.writeln('\nTotal monthly EMI: ₹${totalEmi.toStringAsFixed(0)}');
    buffer.writeln('Total outstanding: ₹${totalOutstanding.toStringAsFixed(0)}');
    return buffer.toString();
  }
}
