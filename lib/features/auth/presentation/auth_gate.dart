import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/home_shell.dart';
import '../controllers/auth_controller.dart';
import '../data/auth_repository.dart';
import 'sign_in_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final currentUser = ref.watch(authRepositoryProvider).currentUser;

    return authState.when(
      data: (user) {
        if (user == null) {
          return const SignInPage();
        }
        // Verificar que el correo esté verificado (excepto para Google Sign-In que ya está verificado)
        if (!user.emailVerified &&
            user.providerData.any((info) => info.providerId == 'password')) {
          return _EmailVerificationRequired(user: user);
        }
        return const HomeShell();
      },
      loading: () {
        // Si hay un usuario actual, mostrar la app mientras carga el estado
        if (currentUser != null) {
          return const HomeShell();
        }
        // Timeout: después de 5 segundos, mostrar página de inicio de sesión
        return _LoadingWithTimeout(
          onTimeout: () {
            ref.invalidate(authStateChangesProvider);
          },
        );
      },
      error: (error, stackTrace) {
        // Log del error para debugging
        debugPrint('Error en AuthGate: $error');
        debugPrint('Stack trace: $stackTrace');
        
        // Si hay un usuario actual verificado, intentar mostrar la app
        if (currentUser != null && currentUser.emailVerified) {
          return const HomeShell();
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No pudimos verificar tu sesión.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      ref.invalidate(authStateChangesProvider);
                    },
                    child: const Text('Reintentar'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // Forzar mostrar página de inicio de sesión
                      ref.invalidate(authStateChangesProvider);
                    },
                    child: const Text('Ir a inicio de sesión'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmailVerificationRequired extends ConsumerStatefulWidget {
  const _EmailVerificationRequired({required this.user});

  final User user;

  @override
  ConsumerState<_EmailVerificationRequired> createState() =>
      _EmailVerificationRequiredState();
}

class _EmailVerificationRequiredState
    extends ConsumerState<_EmailVerificationRequired> {
  bool _isResending = false;

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authControllerProvider.notifier).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Correo de verificación reenviado. Revisa tu bandeja de entrada.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reenviar correo: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _checkVerification() async {
    await ref.read(authControllerProvider.notifier).reloadUser();
    ref.invalidate(authStateChangesProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_unread,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verifica tu correo electrónico',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hemos enviado un correo de verificación a:',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Por favor, revisa tu bandeja de entrada y haz clic en el enlace de verificación para activar tu cuenta.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isResending ? null : _resendVerification,
                  icon: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.email),
                  label:
                      Text(_isResending ? 'Reenviando...' : 'Reenviar correo'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _checkVerification,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ya verifiqué mi correo'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                  },
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingWithTimeout extends StatefulWidget {
  const _LoadingWithTimeout({required this.onTimeout});

  final VoidCallback onTimeout;

  @override
  State<_LoadingWithTimeout> createState() => _LoadingWithTimeoutState();
}

class _LoadingWithTimeoutState extends State<_LoadingWithTimeout> {
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Timeout de 5 segundos: si después de 5 segundos sigue cargando,
    // forzar mostrar la página de inicio de sesión
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint('Timeout en AuthGate: forzando invalidación del provider');
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
