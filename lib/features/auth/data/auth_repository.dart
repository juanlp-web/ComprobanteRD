import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod/riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    GoogleSignIn(
      scopes: const [
        'email',
      ],
      // Usar el serverClientId del web client para autenticación con Firebase
      serverClientId: '40406620278-44bn3stj2ocnsvuosgduduv7em30j8k3.apps.googleusercontent.com',
    ),
  );
});

class AuthRepository {
  AuthRepository(this._auth, this._googleSignIn);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Verificar que el correo esté verificado
    if (credential.user != null && !credential.user!.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message:
            'Por favor, verifica tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada.',
      );
    }

    return credential;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No hay un usuario para verificar.',
      );
    }

    if (user.emailVerified) {
      throw FirebaseAuthException(
        code: 'already-verified',
        message: 'Tu correo ya está verificado.',
      );
    }

    try {
      await user.sendEmailVerification();
    } catch (e) {
      final errorMessage =
          e is FirebaseAuthException ? e.message : e.toString();
      throw FirebaseAuthException(
        code: 'email-verification-failed',
        message:
            'No se pudo enviar el correo de verificación: $errorMessage. Verifica tu conexión e intenta nuevamente.',
      );
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      // Actualizar displayName si se proporciona
      if (displayName != null && displayName.isNotEmpty) {
        try {
          await credential.user!.updateDisplayName(displayName);
          await credential.user!.reload();
        } catch (e) {
          // Si falla actualizar el displayName, continuar sin error
        }
      }

      // Enviar correo de verificación
      try {
        await credential.user!.sendEmailVerification();
      } catch (e) {
        // Si falla enviar el correo, lanzar excepción con más detalles
        final errorMessage =
            e is FirebaseAuthException ? e.message : e.toString();
        throw FirebaseAuthException(
          code: 'email-verification-failed',
          message:
              'No se pudo enviar el correo de verificación: $errorMessage. Verifica tu conexión e intenta nuevamente.',
        );
      }
    }

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const GoogleSignInAbortedException();
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}

class GoogleSignInAbortedException implements Exception {
  const GoogleSignInAbortedException();
}
