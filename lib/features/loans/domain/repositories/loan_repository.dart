import '../entities/loan.dart';

abstract class LoanRepository {
  Stream<List<Loan>> watchLoans();
  Future<List<Loan>> getLoans();
  Future<Loan> getLoan(String id);
  Future<void> addLoan(Loan loan);
  Future<void> updateLoan(Loan loan);
  Future<void> deleteLoan(String id);
  Future<void> syncFromFirestore();
}
