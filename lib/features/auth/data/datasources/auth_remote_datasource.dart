import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/auth_user.dart';
import '../../../../core/errors/failures.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource(this._auth, this._googleSignIn);

  Stream<AuthUser?> get authStateChanges =>
      _auth.userChanges().map(_mapUser);

  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapUser(cred.user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.code));
    }
  }

  Future<AuthUser> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();
      return _mapUser(_auth.currentUser)!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.code));
    }
  }

  Future<AuthUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthFailure('Google sign-in cancelled');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return _mapUser(cred.user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.code));
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.code));
    }
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  String _mapAuthError(String code) => switch (code) {
    'user-not-found'                           => 'No account found with this email.',
    'wrong-password'                           => 'Incorrect password.',
    'invalid-credential'                       => 'Invalid credentials. Please try again.',
    'email-already-in-use'                     => 'An account already exists with this email.',
    'weak-password'                            => 'Password must be at least 6 characters.',
    'invalid-email'                            => 'Please enter a valid email address.',
    'user-disabled'                            => 'This account has been disabled.',
    'operation-not-allowed'                    => 'This sign-in method is not enabled.',
    'requires-recent-login'                    => 'Please sign in again to continue.',
    'account-exists-with-different-credential' => 'An account exists with a different sign-in method.',
    'too-many-requests'                        => 'Too many attempts. Please try again later.',
    'network-request-failed'                   => 'No internet connection.',
    _                                          => 'Error: $code',
  };
}
