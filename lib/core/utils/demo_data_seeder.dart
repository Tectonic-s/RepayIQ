import 'package:shared_preferences/shared_preferences.dart';
import '../../features/loans/domain/entities/loan.dart';
import '../../features/loans/domain/repositories/loan_repository.dart';

/// Seeds demo data on first launch for quick demo setup
class DemoDataSeeder {
  static const _seededKey = 'demo_data_seeded';

  /// Seeds demo data only if not already seeded
  static Future<void> seedIfNeeded(LoanRepository repo) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeeded = prefs.getBool(_seededKey) ?? false;
    
    if (alreadySeeded) return;

    await _seedDemoLoans(repo);
    await prefs.setBool(_seededKey, true);
  }

  /// Force seeds demo data regardless of flag (for demo reset)
  static Future<void> forceSeed(LoanRepository repo) async {
    await _seedDemoLoans(repo);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seededKey, true);
  }

  /// Internal method that actually creates the demo loans
  static Future<void> _seedDemoLoans(LoanRepository repo) async {
    // Add 3 realistic demo loans
    final now = DateTime.now();
    
    // 1. Home Loan - largest, longest tenure
    await repo.addLoan(Loan(
      id: 'demo_home_001',
      loanName: 'HDFC Home Loan',
      loanType: 'Home',
      principal: 5000000,
      interestRate: 8.5,
      tenureMonths: 240,
      startDate: DateTime(now.year - 2, now.month, 15),
      dueDay: 15,
      reminderDays: 3,
      monthlyEmi: 43391,
      calculationMethod: 'Reducing',
      status: 'Active',
      createdAt: now,
      processingFee: 25000,
      bounceCharges: 0,
      latePaymentCharges: 0,
    ));

    // 2. Vehicle Loan - mid-range
    await repo.addLoan(Loan(
      id: 'demo_vehicle_001',
      loanName: 'Axis Car Loan',
      loanType: 'Vehicle',
      principal: 800000,
      interestRate: 9.25,
      tenureMonths: 60,
      startDate: DateTime(now.year - 1, now.month, 5),
      dueDay: 5,
      reminderDays: 3,
      monthlyEmi: 16632,
      calculationMethod: 'Reducing',
      status: 'Active',
      createdAt: now,
      processingFee: 5000,
      bounceCharges: 1200,
      latePaymentCharges: 240,
    ));

    // 3. Personal Loan - smaller, higher rate
    await repo.addLoan(Loan(
      id: 'demo_personal_001',
      loanName: 'ICICI Personal Loan',
      loanType: 'Personal',
      principal: 300000,
      interestRate: 12.5,
      tenureMonths: 36,
      startDate: DateTime(now.year, now.month - 6, 10),
      dueDay: 10,
      reminderDays: 3,
      monthlyEmi: 10042,
      calculationMethod: 'Reducing',
      status: 'Active',
      createdAt: now,
      processingFee: 3000,
      bounceCharges: 2400,
      latePaymentCharges: 360,
    ));
  }

  /// Clear demo data flag to re-seed on next launch
  static Future<void> clearSeedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seededKey);
  }
}
