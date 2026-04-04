class Loan {
  final String id;
  final String loanName;
  final String loanType;
  final double principal;
  final double interestRate;
  final int tenureMonths;
  final DateTime startDate;
  final int dueDay;
  final int reminderDays;
  final double monthlyEmi;
  final String calculationMethod;
  final String? memberId;
  final String status;
  final DateTime createdAt;

  const Loan({
    required this.id,
    required this.loanName,
    required this.loanType,
    required this.principal,
    required this.interestRate,
    required this.tenureMonths,
    required this.startDate,
    required this.dueDay,
    required this.reminderDays,
    required this.monthlyEmi,
    required this.calculationMethod,
    this.memberId,
    required this.status,
    required this.createdAt,
  });

  int get monthsElapsed {
    final now = DateTime.now();
    final raw = (now.year - startDate.year) * 12 + now.month - startDate.month;
    // Only count the current month if its due date has already passed
    final elapsed = now.day > dueDay ? raw : raw - 1;
    return elapsed.clamp(0, tenureMonths);
  }

  int get monthsRemaining => (tenureMonths - monthsElapsed).clamp(0, tenureMonths);

  double get amountPaid => monthlyEmi * monthsElapsed;

  double get outstandingBalance =>
      (principal - (principal / tenureMonths) * monthsElapsed).clamp(0, principal);

  double get progressPercent =>
      tenureMonths == 0 ? 0 : monthsElapsed / tenureMonths;

  bool get isOverdue {
    if (status != 'Active') return false;
    final now = DateTime.now();
    // Loan started this month — first due date is next month
    final startedThisMonth =
        now.year == startDate.year && now.month == startDate.month;
    if (startedThisMonth) return false;
    // Only overdue if today is strictly after the due day
    // (due day itself is not overdue — user still has the full day to pay)
    if (now.day <= dueDay) return false;
    return true;
  }

  /// Overdue check that accounts for recorded payments.
  /// Pass [paidMonthKeys] from the payment provider to avoid false positives.
  bool isOverdueWithPayments(Set<String> paidMonthKeys) {
    if (!isOverdue) return false;
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    // If current month is already marked paid, not overdue
    if (paidMonthKeys.contains(currentMonthKey)) return false;
    return true;
  }

  Loan copyWith({
    String? id,
    String? loanName,
    String? loanType,
    double? principal,
    double? interestRate,
    int? tenureMonths,
    DateTime? startDate,
    int? dueDay,
    int? reminderDays,
    double? monthlyEmi,
    String? calculationMethod,
    String? memberId,
    String? status,
    DateTime? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      loanName: loanName ?? this.loanName,
      loanType: loanType ?? this.loanType,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      startDate: startDate ?? this.startDate,
      dueDay: dueDay ?? this.dueDay,
      reminderDays: reminderDays ?? this.reminderDays,
      monthlyEmi: monthlyEmi ?? this.monthlyEmi,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      memberId: memberId ?? this.memberId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'loanName': loanName,
        'loanType': loanType,
        'principal': principal,
        'interestRate': interestRate,
        'tenureMonths': tenureMonths,
        'startDate': startDate.toIso8601String(),
        'dueDay': dueDay,
        'reminderDays': reminderDays,
        'monthlyEmi': monthlyEmi,
        'calculationMethod': calculationMethod,
        'memberId': memberId,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Loan.fromMap(Map<String, dynamic> map) => Loan(
        id: map['id'] as String,
        loanName: map['loanName'] as String,
        loanType: map['loanType'] as String,
        principal: (map['principal'] as num).toDouble(),
        interestRate: (map['interestRate'] as num).toDouble(),
        tenureMonths: map['tenureMonths'] as int,
        startDate: DateTime.parse(map['startDate'] as String),
        dueDay: map['dueDay'] as int,
        reminderDays: map['reminderDays'] as int,
        monthlyEmi: (map['monthlyEmi'] as num).toDouble(),
        calculationMethod: map['calculationMethod'] as String,
        memberId: map['memberId'] as String?,
        status: map['status'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
