import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  Future<UserCredential> signInWithApple() async {
    // Verificar si Apple Sign In está disponible
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-not-available',
        message: 'Apple Sign In no está disponible en este dispositivo.',
      );
    }

    // Solicitar credenciales de Apple
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // Crear OAuth credential para Firebase
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // Iniciar sesión con Firebase
    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Si el usuario es nuevo y tenemos nombre, actualizarlo
    if (userCredential.additionalUserInfo?.isNewUser == true) {
      final displayName = appleCredential.givenName != null ||
              appleCredential.familyName != null
          ? '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim()
          : null;

      if (displayName != null && displayName.isNotEmpty) {
        try {
          await userCredential.user?.updateDisplayName(displayName);
          await userCredential.user?.reload();
        } catch (e) {
          // Si falla actualizar el displayName, continuar sin error
        }
      }
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Elimina la cuenta del usuario y todos sus datos de Firebase
  /// También elimina los datos locales si se proporciona el repositorio
  Future<void> deleteAccount({Future<void> Function(String userId)? deleteLocalData}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No hay un usuario autenticado para eliminar.',
      );
    }

    final userId = user.uid;

    try {
      // 1. Eliminar todos los datos de Firestore del usuario
      final firestore = FirebaseFirestore.instance;
      final userInvoicesRef = firestore.collection('users').doc(userId).collection('invoices');
      
      // Obtener todos los documentos y eliminarlos
      final invoicesSnapshot = await userInvoicesRef.get();
      final batch = firestore.batch();
      
      for (final doc in invoicesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Eliminar el documento del usuario también si existe
      final userDocRef = firestore.collection('users').doc(userId);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        batch.delete(userDocRef);
      }
      
      await batch.commit();

      // 2. Eliminar datos locales si se proporciona la función
      if (deleteLocalData != null) {
        await deleteLocalData(userId);
      }

      // 3. Eliminar la cuenta de Firebase Auth
      await user.delete();
    } catch (e) {
      // Si falla, intentar al menos cerrar sesión
      await signOut();
      throw FirebaseAuthException(
        code: 'account-deletion-failed',
        message: 'Error al eliminar la cuenta: ${e.toString()}',
      );
    }
  }
}

class GoogleSignInAbortedException implements Exception {
  const GoogleSignInAbortedException();
}
