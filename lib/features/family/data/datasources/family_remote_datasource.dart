import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/family_member.dart';

class FamilyRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FamilyRemoteDataSource(this._firestore, this._auth);

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(_uid).collection('family_members');

  Stream<List<FamilyMember>> watchMembers() => _col.snapshots().map(
      (snap) => snap.docs.map((d) => FamilyMember.fromMap(d.data())).toList());

  Future<void> addMember(FamilyMember member) => _col.doc(member.id).set(member.toMap());
  Future<void> deleteMember(String id) => _col.doc(id).delete();
}
