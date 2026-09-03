import 'dart:math';

class EmiCalculator {
  /// Reducing balance (standard) monthly EMI
  static double reducingBalanceEmi({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    if (annualRate == 0) return principal / tenureMonths;
    final r = annualRate / 12 / 100;
    final emi = principal * r * pow(1 + r, tenureMonths) /
        (pow(1 + r, tenureMonths) - 1);
    return emi;
  }

  /// Flat rate monthly EMI
  static double flatRateEmi({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    final totalInterest = principal * annualRate / 100 * tenureMonths / 12;
    return (principal + totalInterest) / tenureMonths;
  }

  static double totalInterest({
    required double emi,
    required int tenureMonths,
    required double principal,
  }) => (emi * tenureMonths) - principal;

  static double totalRepayment({
    required double emi,
    required int tenureMonths,
  }) => emi * tenureMonths;

  /// Education loan — interest accrues during moratorium, EMI on capitalised amount
  static Map<String, double> educationLoanResult({
    required double principal,
    required double annualRate,
    required int tenureMonths,
    required int moratoriumMonths,
  }) {
    final r = annualRate / 12 / 100;
    final moratoriumInterest = principal * r * moratoriumMonths;
    final capitalisedPrincipal = principal + moratoriumInterest;
    final emi = reducingBalanceEmi(
      principal: capitalisedPrincipal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );
    return {
      'emi': emi,
      'moratoriumInterest': moratoriumInterest,
      'capitalisedPrincipal': capitalisedPrincipal,
      'totalInterest': moratoriumInterest + (emi * tenureMonths - capitalisedPrincipal),
      'totalRepayment': moratoriumInterest + emi * tenureMonths,
    };
  }

  /// Amortisation schedule — returns list of monthly breakdown maps
  static List<Map<String, double>> amortisationSchedule({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    final schedule = <Map<String, double>>[];
    if (annualRate == 0) {
      final emi = principal / tenureMonths;
      for (int i = 1; i <= tenureMonths; i++) {
        schedule.add({
          'month': i.toDouble(),
          'emi': emi,
          'principal': emi,
          'interest': 0,
          'balance': principal - emi * i,
        });
      }
      return schedule;
    }
    final r = annualRate / 12 / 100;
    final emi = reducingBalanceEmi(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );
    double balance = principal;
    for (int i = 1; i <= tenureMonths; i++) {
      final interest = balance * r;
      final principalPart = emi - interest;
      balance -= principalPart;
      schedule.add({
        'month': i.toDouble(),
        'emi': emi,
        'principal': principalPart,
        'interest': interest,
        'balance': balance < 0 ? 0 : balance,
      });
    }
    return schedule;
  }

  /// Prepayment impact — returns months saved, interest saved, charges, and net savings
  static Map<String, dynamic> prepaymentImpact({
    required double currentBalance,
    required double annualRate,
    required int remainingMonths,
    required double lumpSum,
    double prepaymentChargePercent = 0,
    double foreclosureChargePercent = 0,
  }) {
    final isForeclosure = lumpSum >= currentBalance;
    final chargePercent = isForeclosure ? foreclosureChargePercent : prepaymentChargePercent;
    final chargeAmount = lumpSum * chargePercent / 100;
    final effectiveLumpSum = lumpSum - chargeAmount;
    final newBalance = currentBalance - effectiveLumpSum;

    if (newBalance <= 0) {
      return {
        'monthsSaved': remainingMonths,
        'interestSaved': 0.0,
        'chargeAmount': chargeAmount,
        'netSavings': -chargeAmount,
        'isForeclosure': isForeclosure,
      };
    }
    final emi = reducingBalanceEmi(
      principal: currentBalance,
      annualRate: annualRate,
      tenureMonths: remainingMonths,
    );
    if (annualRate == 0) {
      final newMonths = (newBalance / emi).ceil();
      return {
        'monthsSaved': remainingMonths - newMonths,
        'interestSaved': 0.0,
        'chargeAmount': chargeAmount,
        'netSavings': -chargeAmount,
        'isForeclosure': isForeclosure,
      };
    }
    final r = annualRate / 12 / 100;
    final newMonths = (-log(1 - (newBalance * r / emi)) / log(1 + r)).ceil();
    final oldInterest = emi * remainingMonths - currentBalance;
    final newInterest = emi * newMonths - newBalance;
    final interestSaved = oldInterest - newInterest;
    return {
      'monthsSaved': remainingMonths - newMonths,
      'interestSaved': interestSaved,
      'chargeAmount': chargeAmount,
      'netSavings': interestSaved - chargeAmount,
      'isForeclosure': isForeclosure,
    };
  }
}
