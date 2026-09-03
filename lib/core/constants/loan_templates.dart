class LoanTemplate {
  final String rateHint;
  final String tenureHint;
  final double defaultRate;
  final int defaultTenure;
  const LoanTemplate({required this.rateHint, required this.tenureHint, required this.defaultRate, required this.defaultTenure});
}

class LoanTemplates {
  const LoanTemplates._();

  static const Map<String, LoanTemplate> templates = {
    'Home Loan': LoanTemplate(rateHint: '7–9%', tenureHint: '120–360 months (10–30 yrs)', defaultRate: 8.5, defaultTenure: 240),
    'Vehicle Loan': LoanTemplate(rateHint: '8–12%', tenureHint: '12–84 months (1–7 yrs)', defaultRate: 9.5, defaultTenure: 60),
    'Personal Loan': LoanTemplate(rateHint: '10–24%', tenureHint: '12–60 months (1–5 yrs)', defaultRate: 14.0, defaultTenure: 36),
    'Consumer Durable': LoanTemplate(rateHint: '0–15% (No-cost EMI available)', tenureHint: '3–24 months', defaultRate: 0, defaultTenure: 12),
    'Education Loan': LoanTemplate(rateHint: '8–15%', tenureHint: '60–180 months (5–15 yrs)', defaultRate: 10.0, defaultTenure: 120),
    'Business Loan': LoanTemplate(rateHint: '12–24%', tenureHint: '12–60 months (1–5 yrs)', defaultRate: 16.0, defaultTenure: 36),
  };

  static LoanTemplate? of(String loanType) => templates[loanType];
}
