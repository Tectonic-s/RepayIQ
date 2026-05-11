import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> registerWithEmail(String email, String password, String name);
  Future<AuthUser> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  AuthUser? get currentUser;
}
