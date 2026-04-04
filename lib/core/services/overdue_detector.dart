import '../../../features/loans/domain/repositories/loan_repository.dart';
import 'notification_service.dart';

class OverdueDetector {
  static Future<void> check(LoanRepository repo) async {
    try {
      final loans = await repo.getLoans();
      for (final loan in loans) {
        if (loan.isOverdue) {
          await NotificationService.showOverdueNotification(
            loanId: loan.id,
            loanName: loan.loanName,
          );
        }
      }
    } catch (_) {
      // Silently ignore — permission errors or offline state
      // should not crash the home screen
    }
  }
}
