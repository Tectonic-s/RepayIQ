import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/loan_local_datasource.dart';
import '../../data/datasources/loan_remote_datasource.dart';
import '../../data/repositories/loan_repository_impl.dart';
import '../../domain/entities/loan.dart';
import '../../domain/repositories/loan_repository.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/emi_calculator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/notification_service.dart';

final _localDsProvider = Provider((ref) => LoanLocalDataSource());

final _remoteDsProvider = Provider((ref) => LoanRemoteDataSource(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    ));

final _networkInfoProvider =
    Provider((ref) => NetworkInfo(Connectivity()));

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  final repo = LoanRepositoryImpl(
    ref.watch(_localDsProvider),
    ref.watch(_remoteDsProvider),
    ref.watch(_networkInfoProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final loansStreamProvider = StreamProvider<List<Loan>>((ref) {
  return ref.watch(loanRepositoryProvider).watchLoans();
});

final activeLoansProvider = Provider<List<Loan>>((ref) {
  return ref
      .watch(loansStreamProvider)
      .value
      ?.where((l) => l.status == AppConstants.statusActive)
      .toList() ?? [];
});

final closedLoansProvider = Provider<List<Loan>>((ref) {
  return ref
      .watch(loansStreamProvider)
      .value
      ?.where((l) => l.status == AppConstants.statusClosed)
      .toList() ?? [];
});

// Loan CRUD notifier
class LoanNotifier extends StateNotifier<AsyncValue<void>> {
  final LoanRepository _repo;
  LoanNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addLoan({
    required String loanName,
    required String loanType,
    required double principal,
    required double interestRate,
    required int tenureMonths,
    required DateTime startDate,
    required int dueDay,
    required int reminderDays,
    required String calculationMethod,
    String? memberId,
  }) async {
    state = const AsyncValue.loading();
    final emi = calculationMethod == AppConstants.flatRate
        ? EmiCalculator.flatRateEmi(principal: principal, annualRate: interestRate, tenureMonths: tenureMonths)
        : EmiCalculator.reducingBalanceEmi(principal: principal, annualRate: interestRate, tenureMonths: tenureMonths);

    final loan = Loan(
      id: const Uuid().v4(),
      loanName: loanName,
      loanType: loanType,
      principal: principal,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
      startDate: startDate,
      dueDay: dueDay,
      reminderDays: reminderDays,
      monthlyEmi: emi,
      calculationMethod: calculationMethod,
      memberId: memberId,
      status: AppConstants.statusActive,
      createdAt: DateTime.now(),
    );
    state = await AsyncValue.guard(() => _repo.addLoan(loan));
    await _scheduleNudgeIfNeeded();
  }

  Future<void> _scheduleNudgeIfNeeded() async {
    final loans = await _repo.watchLoans().first;
    final active = loans.where((l) => l.status == AppConstants.statusActive).toList();
    if (active.length < 2) return;
    final highest = active.reduce((a, b) => a.interestRate > b.interestRate ? a : b);
    final savings = highest.monthlyEmi * highest.monthsRemaining - highest.outstandingBalance;
    await NotificationService.scheduleWeeklyAiNudge(
      loanType: highest.loanType,
      estimatedSavings: savings.clamp(0, double.infinity),
    );
  }

  Future<void> updateLoan(Loan loan) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.updateLoan(loan));
  }

  Future<void> deleteLoan(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.deleteLoan(id));
  }

  Future<void> closeLoan(Loan loan) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.updateLoan(loan.copyWith(status: AppConstants.statusClosed)),
    );
  }

  void reset() => state = const AsyncValue.data(null);
}

final loanNotifierProvider =
    StateNotifierProvider<LoanNotifier, AsyncValue<void>>((ref) {
  return LoanNotifier(ref.watch(loanRepositoryProvider));
});
