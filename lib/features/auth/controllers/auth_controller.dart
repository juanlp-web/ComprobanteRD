import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod/riverpod.dart';

import '../data/auth_repository.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signInWithEmail(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.registerWithEmail(
        email: email,
        password: password,
        displayName: name,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.signInWithGoogle);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.signOut);
  }

  Future<void> sendEmailVerification() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.sendEmailVerification);
  }

  Future<void> reloadUser() async {
    await _repository.reloadUser();
  }

  void reset() {
    state = const AsyncData(null);
  }

  String? mapErrorToMessage(Object error) {
    if (error is FirebaseAuthException) {
      if (error.code == 'email-not-verified') {
        return error.message;
      }
      if (error.code == 'email-verification-failed') {
        return error.message;
      }
      if (error.code == 'network-request-failed') {
        return 'Sin conexión a internet. Verifica tu conexión e intenta nuevamente.';
      }
      if (error.code == 'too-many-requests') {
        return 'Demasiados intentos. Por favor, espera un momento.';
      }
      if (error.code == 'user-disabled') {
        return 'Esta cuenta ha sido deshabilitada.';
      }
      if (error.code == 'user-not-found') {
        return 'No se encontró una cuenta con este correo.';
      }
      if (error.code == 'wrong-password') {
        return 'Contraseña incorrecta.';
      }
      if (error.code == 'email-already-in-use') {
        return 'Este correo ya está registrado.';
      }
      if (error.code == 'weak-password') {
        return 'La contraseña es muy débil.';
      }
      if (error.code == 'invalid-email') {
        return 'Correo electrónico inválido.';
      }
      if (error.code == 'account-exists-with-different-credential') {
        return 'Ya existe una cuenta con este correo usando otro método de inicio de sesión.';
      }
      if (error.code == 'invalid-credential') {
        return 'Credenciales inválidas. Por favor, intenta nuevamente.';
      }
      if (error.code == 'operation-not-allowed') {
        return 'El inicio de sesión con Google no está habilitado. Contacta al soporte.';
      }
      return error.message ?? 'Error de autenticación: ${error.code}';
    }
    if (error is GoogleSignInAbortedException) {
      return 'Inicio de sesión cancelado.';
    }
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('internet') ||
        errorString.contains('socket')) {
      return 'Sin conexión a internet. Verifica tu conexión e intenta nuevamente.';
    }
    if (errorString.contains('sign_in_failed') ||
        errorString.contains('signin') ||
        errorString.contains('google')) {
      return 'Error al iniciar sesión con Google. Verifica tu configuración o intenta nuevamente.';
    }
    return error.toString();
  }
}
