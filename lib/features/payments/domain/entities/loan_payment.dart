class LoanPayment {
  final String id;
  final String loanId;
  final String monthKey; // format: "YYYY-MM" e.g. "2025-06"
  final double amountPaid;
  final DateTime paidAt;

  const LoanPayment({
    required this.id,
    required this.loanId,
    required this.monthKey,
    required this.amountPaid,
    required this.paidAt,
  });

  /// Generates a stable monthKey from a DateTime
  static String keyFromDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'loanId': loanId,
    'monthKey': monthKey,
    'amountPaid': amountPaid,
    'paidAt': paidAt.toIso8601String(),
  };

  factory LoanPayment.fromMap(Map<String, dynamic> m) => LoanPayment(
    id: m['id'] as String,
    loanId: m['loanId'] as String,
    monthKey: m['monthKey'] as String,
    amountPaid: (m['amountPaid'] as num).toDouble(),
    paidAt: DateTime.parse(m['paidAt'] as String),
  );
}
