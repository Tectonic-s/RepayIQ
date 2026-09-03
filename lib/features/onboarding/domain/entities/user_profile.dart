class UserProfile {
  final String userId;
  final double monthlyIncome;
  final double monthlyExpenses;
  final String? debtFreeGoalDate;
  final bool enableReminders;
  final bool enableAiNudges;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.userId,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    this.debtFreeGoalDate,
    required this.enableReminders,
    required this.enableAiNudges,
    required this.createdAt,
    required this.updatedAt,
  });

  double get disposableIncome => (monthlyIncome - monthlyExpenses).clamp(0, double.infinity);

  UserProfile copyWith({
    String? userId,
    double? monthlyIncome,
    double? monthlyExpenses,
    String? debtFreeGoalDate,
    bool? enableReminders,
    bool? enableAiNudges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      debtFreeGoalDate: debtFreeGoalDate ?? this.debtFreeGoalDate,
      enableReminders: enableReminders ?? this.enableReminders,
      enableAiNudges: enableAiNudges ?? this.enableAiNudges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'monthlyIncome': monthlyIncome,
        'monthlyExpenses': monthlyExpenses,
        'debtFreeGoalDate': debtFreeGoalDate,
        'enableReminders': enableReminders,
        'enableAiNudges': enableAiNudges,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        userId: map['userId'] as String,
        monthlyIncome: (map['monthlyIncome'] as num).toDouble(),
        monthlyExpenses: (map['monthlyExpenses'] as num).toDouble(),
        debtFreeGoalDate: map['debtFreeGoalDate'] as String?,
        enableReminders: map['enableReminders'] as bool,
        enableAiNudges: map['enableAiNudges'] as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
