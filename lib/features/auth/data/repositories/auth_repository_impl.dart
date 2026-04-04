import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  AuthRepositoryImpl(this._remote);

  @override
  Stream<AuthUser?> get authStateChanges => _remote.authStateChanges;

  @override
  AuthUser? get currentUser => _remote.currentUser;

  @override
  Future<AuthUser> signInWithEmail(String email, String password) =>
      _remote.signInWithEmail(email, password);

  @override
  Future<AuthUser> registerWithEmail(
          String email, String password, String name) =>
      _remote.registerWithEmail(email, password, name);

  @override
  Future<AuthUser> signInWithGoogle() => _remote.signInWithGoogle();

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _remote.sendPasswordReset(email);
}
