import '../../features/loans/domain/entities/loan.dart';
import 'data_anonymiser.dart';

/// Builds Gemini prompts using only anonymised numerical data.
/// Never includes: user name, UID, bank names, account numbers, phone numbers.
class GeminiPromptBuilder {
  const GeminiPromptBuilder._();

  static const String systemInstruction =
      'You are RepayIQ\'s AI financial co-pilot. You are a friendly, concise, '
      'and knowledgeable loan advisor. Always give practical, actionable advice. '
      'Format responses clearly using short paragraphs. ALWAYS use ₹ (Indian Rupee) '
      'for ALL currency values — never use \$ or USD. '
      'Never give generic disclaimers — give real, specific answers. '
      'You only receive anonymous numerical loan data — no names or bank details.';

  /// Chat prompt — portfolio context + user message, no PII.
  static String chatContext(List<Loan> loans) =>
      DataAnonymiser.buildAnonymisedPortfolio(loans);

  /// Loan comparison prompt — only numerical offer data.
  static String loanComparison({
    required String labelA,
    required double principalA,
    required double rateA,
    required int tenureA,
    required double emiA,
    required double interestA,
    required String labelB,
    required double principalB,
    required double rateB,
    required int tenureB,
    required double emiB,
    required double interestB,
  }) =>
      '''
Compare these two loan offers and give a clear recommendation:

$labelA:
- Principal: ₹${principalA.toStringAsFixed(0)}
- Interest Rate: $rateA% p.a.
- Tenure: $tenureA months
- Monthly EMI: ₹${emiA.toStringAsFixed(0)}
- Total Interest: ₹${interestA.toStringAsFixed(0)}
- Total Repayment: ₹${(emiA * tenureA).toStringAsFixed(0)}

$labelB:
- Principal: ₹${principalB.toStringAsFixed(0)}
- Interest Rate: $rateB% p.a.
- Tenure: $tenureB months
- Monthly EMI: ₹${emiB.toStringAsFixed(0)}
- Total Interest: ₹${interestB.toStringAsFixed(0)}
- Total Repayment: ₹${(emiB * tenureB).toStringAsFixed(0)}

Analyse: EMI difference, total interest burden, flexibility, and risk.
End with a clear "I recommend $labelA/$labelB because..." statement.
Keep it under 200 words.
''';

  /// Repayment strategy prompt — anonymised portfolio + extra budget.
  static String repaymentStrategy({
    required List<Loan> loans,
    required double extraMonthlyBudget,
  }) {
    final portfolio = DataAnonymiser.buildAnonymisedPortfolio(loans);
    final anon = DataAnonymiser.anonymiseLoans(loans);
    final avalanche = List.of(anon)
      ..sort((a, b) =>
          (b['annualRatePercent'] as double).compareTo(a['annualRatePercent'] as double));
    final snowball = List.of(anon)
      ..sort((a, b) =>
          (a['outstandingBalance'] as double).compareTo(b['outstandingBalance'] as double));

    return '''
$portfolio

The user has an extra ₹${extraMonthlyBudget.toStringAsFixed(0)} per month available for loan repayment.

Avalanche order (highest interest first): ${avalanche.map((l) => l['label']).join(' → ')}
Snowball order (smallest balance first): ${snowball.map((l) => l['label']).join(' → ')}

Do the following:
1. Briefly explain Avalanche vs Snowball in 2 sentences each.
2. Recommend which strategy suits THIS user's specific portfolio and why.
3. Give a concrete month-by-month roadmap for the first 6 months showing which loan gets the extra payment each month and the projected balance reduction.
4. Estimate total interest saved vs paying minimum EMIs only.

Be specific with numbers. Use ₹ for all amounts.
''';
  }
}
