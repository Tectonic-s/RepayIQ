import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../loans/presentation/providers/loan_providers.dart';
import '../../../onboarding/data/datasources/user_profile_local_datasource.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final userProfileDataSourceProvider = Provider((ref) => UserProfileLocalDataSource());

final userProfileProvider = FutureProvider((ref) async {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return null;
  
  final dataSource = ref.watch(userProfileDataSourceProvider);
  return await dataSource.getUserProfile(userId);
});

final repayIQScoreProvider = Provider((ref) {
  final loans = ref.watch(loansStreamProvider).value ?? [];
  final profile = ref.watch(userProfileProvider).value;
  
  final monthlyIncome = profile?.monthlyIncome ?? 0.0;
  
  return ScoreCalculator.calculate(
    loans: loans,
    monthlyIncome: monthlyIncome,
  );
});
