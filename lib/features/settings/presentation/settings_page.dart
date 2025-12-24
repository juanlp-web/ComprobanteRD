import 'package:characters/characters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_comprobante_rd/core/theme/app_theme.dart';
import 'package:mi_comprobante_rd/core/theme/theme_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../invoice/controllers/invoice_controller.dart';
import '../services/export_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (!next.hasError) return;
      final message =
          ref.read(authControllerProvider.notifier).mapErrorToMessage(
                next.error!,
              );
      if (message == null || message.isEmpty) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    final themeConfig = ref.watch(themeControllerProvider);
    final themeController = ref.read(themeControllerProvider.notifier);
    final seedOptions = AppTheme.seedPalette;
    final invoicesAsync = ref.watch(invoiceControllerProvider);
    final exportService = ref.watch(exportServiceProvider);
    final user = ref.watch(authStateChangesProvider).maybeWhen(
          data: (user) => user,
          orElse: () => null,
        );
    final authController = ref.read(authControllerProvider.notifier);
    final isSigningOut = ref.watch(authControllerProvider).isLoading;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Configuración y herramientas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color del tema',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personaliza el color principal de la aplicación. '
                    'Tu selección se guardará en este dispositivo.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final color in seedOptions)
                        _ThemeColorOption(
                          color: color,
                          isSelected:
                              themeConfig.seedColor.value == color.value,
                          onSelected: () =>
                              themeController.updateSeedColor(color),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (user != null) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu cuenta',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            _avatarInitialsFor(user),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? user.email ?? 'Tu cuenta',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (user.email != null)
                                Text(
                                  user.email!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isSigningOut
                          ? null
                          : () async {
                              await authController.signOut();
                            },
                      icon: isSigningOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exportar comprobantes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Genera un archivo CSV, Excel o PDF con todos los comprobantes guardados.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: invoicesAsync.hasValue &&
                                (invoicesAsync.value?.isNotEmpty ?? false)
                            ? () => exportService.exportAsCsv(
                                  context,
                                  invoices: invoicesAsync.value,
                                )
                            : null,
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Exportar CSV'),
                      ),
                      OutlinedButton.icon(
                        onPressed: invoicesAsync.hasValue &&
                                (invoicesAsync.value?.isNotEmpty ?? false)
                            ? () => exportService.exportAsExcel(
                                  context,
                                  invoices: invoicesAsync.value,
                                )
                            : null,
                        icon: const Icon(Icons.grid_on_outlined),
                        label: const Text('Exportar Excel'),
                      ),
                      OutlinedButton.icon(
                        onPressed: invoicesAsync.hasValue &&
                                (invoicesAsync.value?.isNotEmpty ?? false)
                            ? () => exportService.exportAsPdf(
                                  context,
                                  invoices: invoicesAsync.value,
                                )
                            : null,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exportar PDF'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acerca de',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ComprobanteRD te ayuda a llevar control de tus comprobantes fiscales electrónicos '
                    'con un enfoque amigable, confiable y preparado para contadores y consumidores finales.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      const privacyPolicyUrl = 'https://juanlp-web.github.io/ComprobanteRD/';
                      
                      final uri = Uri.parse(privacyPolicyUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No se pudo abrir la política de privacidad. '
                                'Por favor, contacta al desarrollador.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.privacy_tip_outlined),
                    label: const Text('Política de Privacidad'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botón de eliminar cuenta al final
          if (user != null)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zona de peligro',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Eliminar tu cuenta es una acción permanente. Se eliminarán todos tus datos, comprobantes y la cuenta de autenticación.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isSigningOut
                          ? null
                          : () => _showDeleteAccountDialog(context, ref),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Eliminar cuenta permanentemente'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _avatarInitialsFor(User user) {
  final source = (user.displayName?.trim().isNotEmpty ?? false)
      ? user.displayName!.trim()
      : (user.email?.trim().isNotEmpty ?? false)
          ? user.email!.trim()
          : 'Tú';
  return source.isNotEmpty ? source.characters.first.toUpperCase() : 'T';
}

void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Eliminar cuenta'),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Estás seguro de que deseas eliminar tu cuenta?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Esta acción es permanente e irreversible. Se eliminará:',
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Tu cuenta de autenticación'),
                Text('• Todos tus comprobantes guardados'),
                Text('• Todos tus datos sincronizados'),
                Text('• Todos los datos locales'),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        _DeleteAccountButton(dialogContext: dialogContext),
      ],
    ),
  );
}

class _DeleteAccountButton extends ConsumerStatefulWidget {
  const _DeleteAccountButton({required this.dialogContext});

  final BuildContext dialogContext;

  @override
  ConsumerState<_DeleteAccountButton> createState() =>
      _DeleteAccountButtonState();
}

class _DeleteAccountButtonState
    extends ConsumerState<_DeleteAccountButton> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      
      if (widget.dialogContext.mounted) {
        Navigator.of(widget.dialogContext).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la cuenta: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _isDeleting ? null : _handleDelete,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      child: _isDeleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Text('Eliminar cuenta'),
    );
  }
}

class _ThemeColorOption extends StatelessWidget {
  const _ThemeColorOption({
    required this.color,
    required this.isSelected,
    required this.onSelected,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    final checkIconColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                  : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  color: checkIconColor,
                )
              : null,
        ),
      ),
    );
  }
}
