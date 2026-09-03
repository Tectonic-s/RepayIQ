import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/loans/domain/repositories/loan_repository.dart';
import 'notification_service.dart';

class OverdueDetector {
  static DateTime? _lastCheck;
  static const _checkInterval = Duration(hours: 1); // Only check once per hour
  
  static Future<void> check(LoanRepository repo) async {
    // Debounce - don't check if we checked in the last hour
    if (_lastCheck != null && DateTime.now().difference(_lastCheck!) < _checkInterval) {
      return;
    }
    
    try {
      final loans = await repo.getLoans();
      final prefs = await SharedPreferences.getInstance();
      final notifiedIds = prefs.getStringList('overdue_notified') ?? [];
      
      for (final loan in loans) {
        if (loan.isOverdue && !notifiedIds.contains(loan.id)) {
          await NotificationService.showOverdueNotification(
            loanId: loan.id,
            loanName: loan.loanName,
          );
          notifiedIds.add(loan.id);
        }
      }
      
      await prefs.setStringList('overdue_notified', notifiedIds);
      _lastCheck = DateTime.now();
    } catch (_) {
      // Silently ignore — permission errors or offline state
      // should not crash the home screen
    }
  }
}
