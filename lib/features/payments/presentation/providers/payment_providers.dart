import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../domain/entities/loan_payment.dart';

final _paymentDsProvider = Provider((ref) => PaymentRemoteDataSource(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    ));

/// Stream payments for a specific loan
final paymentsProvider =
    StreamProvider.family<List<LoanPayment>, String>((ref, loanId) {
  return ref.watch(_paymentDsProvider).watchPayments(loanId);
});

/// Stream all payments — used in calendar to show paid status across all loans
final allPaymentsProvider = StreamProvider<List<LoanPayment>>((ref) {
  return ref.watch(_paymentDsProvider).watchAllPayments();
});

/// Set of paid monthKeys for a loan — fast O(1) lookup
final paidMonthKeysProvider =
    Provider.family<Set<String>, String>((ref, loanId) {
  final payments = ref.watch(paymentsProvider(loanId)).value ?? [];
  return payments.map((p) => p.monthKey).toSet();
});

/// Map of loanId -> set of paid monthKeys — used for overdue checking across all loans
final allPaidKeysByLoanProvider = Provider<Map<String, Set<String>>>((ref) {
  final payments = ref.watch(allPaymentsProvider).value ?? [];
  final map = <String, Set<String>>{};
  for (final p in payments) {
    map.putIfAbsent(p.loanId, () => {}).add(p.monthKey);
  }
  return map;
});

class PaymentNotifier extends StateNotifier<AsyncValue<void>> {
  final PaymentRemoteDataSource _ds;
  PaymentNotifier(this._ds) : super(const AsyncValue.data(null));

  Future<void> togglePayment({
    required String loanId,
    required String monthKey,
    required double emiAmount,
    required List<LoanPayment> existingPayments,
  }) async {
    state = const AsyncValue.loading();
    final existing = existingPayments
        .where((p) => p.loanId == loanId && p.monthKey == monthKey)
        .firstOrNull;

    state = await AsyncValue.guard(() async {
      if (existing != null) {
        await _ds.markUnpaid(existing.id);
      } else {
        await _ds.markPaid(LoanPayment(
          id: const Uuid().v4(),
          loanId: loanId,
          monthKey: monthKey,
          amountPaid: emiAmount,
          paidAt: DateTime.now(),
        ));
      }
    });
  }

  Future<void> bulkMarkPaid(List<LoanPayment> payments) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ds.bulkMarkPaid(payments));
  }
}

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<void>>((ref) {
  return PaymentNotifier(ref.watch(_paymentDsProvider));
});
