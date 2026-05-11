class AppConstants {
  static const String appName = 'RepayIQ';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String loansCollection = 'loans';
  static const String paymentsCollection = 'payments';
  static const String familyMembersCollection = 'family_members';
  static const String documentsCollection = 'documents';
  static const String aiConversationsCollection = 'ai_conversations';

  // Loan types
  static const List<String> loanTypes = [
    'Home Loan',
    'Vehicle Loan',
    'Consumer Durable',
    'Personal Loan',
    'Education Loan',
    'Business Loan',
  ];

  // Loan statuses
  static const String statusActive = 'Active';
  static const String statusClosed = 'Closed';

  // Payment statuses
  static const String paymentPaid = 'Paid';
  static const String paymentOverdue = 'Overdue';
  static const String paymentUpcoming = 'Upcoming';

  // Calculation methods
  static const String flatRate = 'Flat Rate';
  static const String reducingBalance = 'Reducing Balance';

  // RepayIQ Score bands
  static const int scoreExcellentMin = 80;
  static const int scoreGoodMin = 60;
  static const int scoreFairMin = 40;

  // Budget stress threshold
  static const double stressThreshold = 0.5;

  // Reminder options (days before due)
  static const List<int> reminderDays = [1, 3, 7];

  // SQLite DB
  static const String dbName = 'repayiq.db';
  static const int dbVersion = 1;
}
