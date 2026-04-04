import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/loan_payment.dart';

class PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PaymentRemoteDataSource(this._firestore, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col => _uid == null
      ? null
      : _firestore.collection('users').doc(_uid).collection('payments');

  Stream<List<LoanPayment>> watchPayments(String loanId) {
    if (_col == null) return const Stream.empty();
    return _col!
        .where('loanId', isEqualTo: loanId)
        .snapshots()
        .map((s) => s.docs.map((d) => LoanPayment.fromMap(d.data())).toList());
  }

  Stream<List<LoanPayment>> watchAllPayments() {
    if (_col == null) return const Stream.empty();
    return _col!.snapshots()
        .map((s) => s.docs.map((d) => LoanPayment.fromMap(d.data())).toList());
  }

  Future<void> markPaid(LoanPayment payment) async {
    await _col?.doc(payment.id).set(payment.toMap());
  }

  Future<void> markUnpaid(String paymentId) async {
    await _col?.doc(paymentId).delete();
  }

  Future<void> bulkMarkPaid(List<LoanPayment> payments) async {
    if (_col == null) return;
    final batch = _firestore.batch();
    for (final p in payments) {
      batch.set(_col!.doc(p.id), p.toMap());
    }
    await batch.commit();
  }
}
