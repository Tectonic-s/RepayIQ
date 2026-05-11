import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/family_remote_datasource.dart';
import '../../domain/entities/family_member.dart';

final _familyDsProvider = Provider((ref) => FamilyRemoteDataSource(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    ));

final familyStreamProvider = StreamProvider<List<FamilyMember>>((ref) {
  return ref.watch(_familyDsProvider).watchMembers();
});

class FamilyNotifier extends StateNotifier<AsyncValue<void>> {
  final FamilyRemoteDataSource _ds;
  FamilyNotifier(this._ds) : super(const AsyncValue.data(null));

  Future<void> addMember({
    required String name,
    required String relationship,
    required double monthlyIncome,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ds.addMember(FamilyMember(
      id: const Uuid().v4(),
      name: name,
      relationship: relationship,
      monthlyIncome: monthlyIncome,
    )));
  }

  Future<void> deleteMember(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ds.deleteMember(id));
  }
}

final familyNotifierProvider = StateNotifierProvider<FamilyNotifier, AsyncValue<void>>(
  (ref) => FamilyNotifier(ref.watch(_familyDsProvider)),
);
