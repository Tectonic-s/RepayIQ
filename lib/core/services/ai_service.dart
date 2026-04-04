import 'package:google_generative_ai/google_generative_ai.dart';
export 'package:google_generative_ai/google_generative_ai.dart' show TextPart;
import '../../features/loans/domain/entities/loan.dart';
import 'gemini_prompt_builder.dart';

class AiService {
  static const _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyDlnohujwH94ZLRA4x_ya8nTboylPkS4uo',
  );

  static GenerativeModel get _model {
    if (_apiKey.isEmpty) throw StateError('Gemini API key not configured.');
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(GeminiPromptBuilder.systemInstruction),
    );
  }

  // ── Feature 1: Loan Coach chat ──────────────────────────────────────────────

  static Future<String> chat({
    required List<Loan> loans,
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    final portfolioContext = GeminiPromptBuilder.chatContext(loans);
    final chat = _model.startChat(history: [
      Content.text('Here is my anonymous loan portfolio:\n$portfolioContext'),
      Content.model([TextPart('Got it! I have your portfolio loaded. How can I help?')]),
      ...history.map((m) => m.isUser
          ? Content.text(m.text)
          : Content.model([TextPart(m.text)])),
    ]);
    final response = await chat.sendMessage(Content.text(userMessage));
    return response.text ?? 'Sorry, I could not generate a response.';
  }

  // ── Feature 2: Loan Comparison ──────────────────────────────────────────────

  static Future<String> compareLoanOffers({
    required LoanOffer offerA,
    required LoanOffer offerB,
  }) async {
    final emiA = _calcEmi(offerA.principal, offerA.rate, offerA.tenureMonths);
    final emiB = _calcEmi(offerB.principal, offerB.rate, offerB.tenureMonths);
    final prompt = GeminiPromptBuilder.loanComparison(
      labelA: 'Offer A',
      principalA: offerA.principal,
      rateA: offerA.rate,
      tenureA: offerA.tenureMonths,
      emiA: emiA,
      interestA: emiA * offerA.tenureMonths - offerA.principal,
      labelB: 'Offer B',
      principalB: offerB.principal,
      rateB: offerB.rate,
      tenureB: offerB.tenureMonths,
      emiB: emiB,
      interestB: emiB * offerB.tenureMonths - offerB.principal,
    );
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Could not generate comparison.';
  }

  // ── Feature 3: Repayment Strategist ────────────────────────────────────────

  static Future<String> repaymentStrategy({
    required List<Loan> loans,
    required double extraMonthlyBudget,
  }) async {
    if (loans.isEmpty) return 'No active loans to analyse.';
    final prompt = GeminiPromptBuilder.repaymentStrategy(
      loans: loans,
      extraMonthlyBudget: extraMonthlyBudget,
    );
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Could not generate strategy.';
  }

  static double _calcEmi(double principal, double rate, int tenure) {
    if (rate == 0) return principal / tenure;
    final r = rate / 12 / 100;
    double compound = 1.0;
    for (int i = 0; i < tenure; i++) { compound *= (1 + r); }
    return principal * r * compound / (compound - 1);
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser})
      : timestamp = DateTime.now();
}

class LoanOffer {
  final String label;
  final double principal;
  final double rate;
  final int tenureMonths;
  const LoanOffer({
    required this.label,
    required this.principal,
    required this.rate,
    required this.tenureMonths,
  });
}
