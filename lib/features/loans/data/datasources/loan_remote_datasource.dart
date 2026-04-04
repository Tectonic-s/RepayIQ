import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/loan.dart';

class LoanRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LoanRemoteDataSource(this._firestore, this._auth);

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col => _uid == null
      ? null
      : _firestore.collection('users').doc(_uid).collection('loans');

  Stream<List<Loan>> watchLoans() {
    if (_col == null) return const Stream.empty();
    return _col!.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => Loan.fromMap(d.data())).toList(),
        );
  }

  Future<List<Loan>> getLoans() async {
    if (_col == null) return [];
    final snap = await _col!.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Loan.fromMap(d.data())).toList();
  }

  Future<void> setLoan(Loan loan) async {
    await _col?.doc(loan.id).set(loan.toMap());
  }

  Future<void> deleteLoan(String id) async {
    await _col?.doc(id).delete();
  }
}
