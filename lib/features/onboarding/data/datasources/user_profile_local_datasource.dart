import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/user_profile.dart';
import '../../../loans/data/datasources/loan_local_datasource.dart';

class UserProfileLocalDataSource {
  final LoanLocalDataSource _loanDs = LoanLocalDataSource();

  Future<Database> get db async => _loanDs.db;

  Future<UserProfile?> getUserProfile(String userId) async {
    final database = await db;
    final maps = await database.query('user_profile', where: 'userId = ?', whereArgs: [userId]);
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<void> upsertUserProfile(UserProfile profile) async {
    final database = await db;
    await database.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
