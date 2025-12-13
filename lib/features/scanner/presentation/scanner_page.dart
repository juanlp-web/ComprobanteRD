import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:intl/intl.dart';

import '../../ads/interstitial_ad_manager.dart';
import '../../ads/widgets/banner_ad_widget.dart';
import '../../auth/services/connectivity_service.dart';
import '../../invoice/controllers/invoice_controller.dart';
import '../../invoice/domain/invoice.dart';
import '../invoice_parser.dart';
import '../../dgii/dgii_validation_service.dart';

/// Scanner de códigos QR usando APIs nativas de la cámara
/// 
/// Esta implementación utiliza:
/// - camera: API nativa de la cámara del dispositivo
/// - google_mlkit_barcode_scanning: Google ML Kit nativo para Android
/// - Apple Vision nativo para iOS

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key, this.isVisible = true});

  final bool isVisible;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  BarcodeScanner? _barcodeScanner;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isStreaming = false;
  String? _lastRawValue;
  DateTime? _lastDetectionAt;
  DateTime? _lastFrameProcessed;
  int _successfulScanCount = 0;
  bool _isPageVisible = true;
  
  // Throttling: procesar frames cada 200ms para mejor rendimiento y precisión
  static const _frameProcessingInterval = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _isPageVisible = widget.isVisible;
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _deactivateCamera();
    } else if (state == AppLifecycleState.resumed && _isPageVisible) {
      _reactivateCamera();
    }
  }

  @override
  void didUpdateWidget(ScannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detectar cuando cambia la visibilidad de la página
    if (oldWidget.isVisible != widget.isVisible) {
      _isPageVisible = widget.isVisible;
      if (!_isPageVisible) {
        _deactivateCamera();
      } else if (_isPageVisible && _cameraController != null && _cameraController!.value.isInitialized) {
        _reactivateCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró ninguna cámara disponible'),
            ),
          );
        }
        return;
      }

      // Usar la cámara trasera por defecto
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Usar resolución muy alta para mejor precisión en detección de QR
      _cameraController = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Inicializar el escáner de códigos de barras nativo
      _barcodeScanner = BarcodeScanner(
        formats: [BarcodeFormat.qrCode],
      );

      if (mounted) {
        setState(() => _isInitialized = true);
        _startScanning();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error inicializando cámara: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar la cámara: $e'),
          ),
        );
      }
    }
  }

  Future<void> _startScanning() async {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized || 
        _isStreaming ||
        !mounted) {
      return;
    }

    try {
      _isStreaming = true;
      await _cameraController!.startImageStream(_processImage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Scanner] Error iniciando stream: $e');
      }
      if (mounted) {
        _isStreaming = false;
      }
    }
  }

  Future<void> _stopScanning() async {
    if (!_isStreaming || _cameraController == null) return;
    
    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      _isStreaming = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Scanner] Error deteniendo stream: $e');
      }
      _isStreaming = false;
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || _barcodeScanner == null) return;

    // Throttling: procesar solo cada cierto intervalo para mejor rendimiento
    final now = DateTime.now();
    if (_lastFrameProcessed != null &&
        now.difference(_lastFrameProcessed!) < _frameProcessingInterval) {
      return;
    }
    _lastFrameProcessed = now;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final barcodes = await _barcodeScanner!.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        final rawValue = barcode.displayValue ?? barcode.rawValue;

        if (rawValue != null && rawValue.isNotEmpty && rawValue.length >= 10) {
          // Evitar procesar el mismo código múltiples veces
          if (_lastRawValue == rawValue &&
              _lastDetectionAt != null &&
              DateTime.now().difference(_lastDetectionAt!) <
                  const Duration(seconds: 3)) {
            return;
          }

          if (kDebugMode) {
            debugPrint('[Scanner] QR detectado: $rawValue');
          }

          _lastRawValue = rawValue;
          _lastDetectionAt = DateTime.now();
          
          // Detener el escaneo mientras procesamos
          await _stopScanning();
          setState(() => _isProcessing = true);

          await _processQRCode(rawValue);

          // Reanudar el escaneo
          if (mounted && _cameraController != null && _cameraController!.value.isInitialized) {
            await _startScanning();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Scanner] Error procesando imagen: $e');
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    try {
      // Calcular la rotación correcta según la orientación de la cámara
      final camera = _cameraController?.description;
      InputImageRotation rotation = InputImageRotation.rotation0deg;
      
      if (camera != null) {
        // Ajustar rotación según la orientación del sensor de la cámara
        switch (camera.sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation90deg;
            break;
          case 180:
            rotation = InputImageRotation.rotation180deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }
      }

      // Determinar el formato de imagen según la plataforma
      // Android usa NV21, iOS usa bgra8888
      final format = image.format.group == ImageFormatGroup.yuv420
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error convirtiendo imagen: $e');
      }
      return null;
    }
  }

  Future<void> _processQRCode(String rawValue) async {
    if (!mounted) return;

    try {
      final controller = ref.read(invoiceControllerProvider.notifier);
      final dgiiService = ref.read(dgiiValidationServiceProvider);
      final connectivityService = ref.read(connectivityServiceProvider);
      var invoice = InvoiceParser.parse(rawValue);
      DgiiValidationResult? validationResult;
      var validationMessage = '';

      // Verificar conectividad antes de intentar validar (con timeout)
      bool hasInternet = false;
      try {
        hasInternet = await connectivityService
            .hasInternetConnection()
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
      } catch (e) {
        hasInternet = false;
        if (kDebugMode) {
          debugPrint('[Scanner] Error al verificar conectividad: $e');
        }
      }

      if (hasInternet) {
        try {
          validationResult = await dgiiService.validate(invoice);
          if (validationResult.status == DgiiValidationStatus.missingData) {
            validationMessage =
                'Faltan datos para validar este comprobante en la DGII.';
          } else if (validationResult.status == DgiiValidationStatus.error) {
            validationMessage =
                'La DGII no respondió: ${validationResult.message}';
          } else if (validationResult.status == DgiiValidationStatus.notFound) {
            validationMessage = 'La DGII no encontró registros para este e-CF.';
            invoice = invoice.copyWith(
              validationStatus: 'Sin registros en la DGII',
              validatedAt: DateTime.now(),
            );
          } else {
            final String estado =
                validationResult.estado ?? validationResult.message;
            invoice = invoice.copyWith(
              issuerName: (invoice.issuerName.isEmpty ||
                      invoice.issuerName == 'Proveedor desconocido')
                  ? validationResult.valueFor('Razón social emisor') ??
                      invoice.issuerName
                  : invoice.issuerName,
              buyerName: validationResult.valueFor('Razón social comprador') ??
                  invoice.buyerName,
              buyerRnc: validationResult.valueFor('RNC Comprador') ??
                  invoice.buyerRnc,
              totalItbis: _parseDouble(
                    validationResult.valueFor('Total de ITBIS'),
                  ) ??
                  invoice.totalItbis,
              validationStatus: estado,
              validatedAt: DateTime.now(),
              status: estado,
            );
            validationMessage = 'Validación DGII: $estado';
          }
        } catch (error) {
          validationMessage =
              'No se pudo validar con la DGII: $error. Puedes intentarlo luego.';
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              '[Scanner] Sin conexión a internet, saltando validación DGII');
        }
      }

      if (!mounted) {
        return;
      }

      final shouldSave = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return _InvoicePreviewSheet(
            invoice: invoice,
            validationResult: validationResult,
            validationMessage:
                validationMessage.isEmpty ? null : validationMessage,
          );
        },
      );

      if (shouldSave != true || !mounted) {
        return;
      }

      final (savedInvoice, isNew) = await controller.upsertInvoice(invoice);
      var feedbackMessage = isNew
          ? 'Comprobante guardado correctamente.'
          : 'Comprobante actualizado (ya existía en tu historial).';
      if (validationMessage.isNotEmpty) {
        feedbackMessage = '$feedbackMessage $validationMessage';
      }

      _showSnackBar(context, feedbackMessage);

      _successfulScanCount++;
      if (_successfulScanCount % 5 == 0) {
        await InterstitialAdManager.instance.show();
      }

      if (mounted) {
        setState(() {
          _lastRawValue = savedInvoice.rawData;
        });
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrió un error al procesar el QR: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deactivateCamera() async {
    // Detener el stream
    await _stopScanning();
    
    // Apagar el flash si está encendido
    if (_cameraController != null && 
        _cameraController!.value.isInitialized &&
        _cameraController!.value.flashMode == FlashMode.torch) {
      try {
        await _cameraController!.setFlashMode(FlashMode.off);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Scanner] Error apagando flash: $e');
        }
      }
    }
  }

  Future<void> _reactivateCamera() async {
    if (_cameraController != null && 
        _cameraController!.value.isInitialized &&
        !_isStreaming &&
        mounted) {
      await _startScanning();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Detener el stream primero
    _stopScanning();
    
    // Apagar el flash antes de dispose
    if (_cameraController != null && 
        _cameraController!.value.isInitialized &&
        _cameraController!.value.flashMode == FlashMode.torch) {
      _cameraController!.setFlashMode(FlashMode.off).catchError((_) {});
    }
    
    // Cerrar el escáner de códigos
    _barcodeScanner?.close();
    _barcodeScanner = null;
    
    // Dispose del controller de la cámara
    _cameraController?.dispose();
    _cameraController = null;
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Cámara expandida ocupando la mayor parte de la pantalla
          Expanded(
            flex: 10,
            child: Stack(
              children: [
                // Vista de la cámara sin bordes redondeados para ocupar todo el espacio
                if (_isInitialized && _cameraController != null)
                  Positioned.fill(
                    child: _buildCameraPreview(),
                  )
                else
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                // Overlay con marco de escaneo
                Positioned.fill(
                  child: _buildScannerOverlay(),
                ),
                // Botones flotantes en la parte superior
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón de flash
                      FloatingActionButton(
                        heroTag: 'flash',
                        mini: true,
                        backgroundColor: Colors.black54,
                        onPressed: _toggleFlash,
                        child: Icon(
                          _cameraController?.value.flashMode == FlashMode.torch
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón de cambio de cámara
                      FloatingActionButton(
                        heroTag: 'switch',
                        mini: true,
                        backgroundColor: Colors.black54,
                        onPressed: _switchCamera,
                        child: const Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Área de información más compacta
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Escanea un e-CF',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          // Banner ad con espacio reservado
          Container(
            height: 50,
            alignment: Alignment.center,
            child: const BannerAdWidget(),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.setFlashMode(
        _cameraController!.value.flashMode == FlashMode.torch
            ? FlashMode.off
            : FlashMode.torch,
      );
      // Actualizar el estado para que el botón muestre el icono correcto
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar flash: $e'),
          ),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameraController == null || !mounted) return;

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solo hay una cámara disponible'),
            ),
          );
        }
        return;
      }

      final currentCamera = _cameraController!.description;
      final newCamera = cameras.firstWhere(
        (c) => c.lensDirection != currentCamera.lensDirection,
        orElse: () => cameras.first,
      );

      // Detener el stream primero
      await _stopScanning();
      
      // Guardar referencia temporal y establecer a null antes de dispose
      final oldController = _cameraController;
      _cameraController = null;
      
      // Actualizar el estado para que el widget no intente usar el controller disposed
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }

      // Dispose del controller anterior
      await oldController?.dispose();

      if (!mounted) return;

      // Crear nuevo controller
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        await _startScanning();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Scanner] Error al cambiar cámara: $e');
      }
      if (mounted) {
        // Si hay error, intentar restaurar el estado
        setState(() {
          _isInitialized = _cameraController != null && 
                          _cameraController!.value.isInitialized;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar cámara: $e'),
          ),
        );
      }
    }
  }

  Widget _buildCameraPreview() {
    // Verificar que el controller existe, está inicializado y no está disposed
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized ||
        !mounted) {
      return Container(color: Colors.black);
    }

    try {
      // Usar LayoutBuilder para obtener el espacio disponible y calcular correctamente
      return LayoutBuilder(
        builder: (context, constraints) {
          // Verificar nuevamente que el controller sigue siendo válido
          if (_cameraController == null || 
              !_cameraController!.value.isInitialized ||
              !mounted) {
            return Container(color: Colors.black);
          }

          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          
          // Usar todo el ancho y altura disponible
          return Center(
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: CameraPreview(_cameraController!),
            ),
          );
        },
      );
    } catch (e) {
      // Si hay un error (por ejemplo, controller disposed), mostrar contenedor negro
      if (kDebugMode) {
        debugPrint('[Scanner] Error en _buildCameraPreview: $e');
      }
      return Container(color: Colors.black);
    }
  }

  Widget _buildScannerOverlay() {
    return CustomPaint(
      painter: _ScannerOverlayPainter(),
      child: Container(),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    final cleaned = normalized.contains(',')
        ? normalized.replaceAll('.', '').replaceAll(',', '.')
        : normalized;
    return double.tryParse(cleaned);
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo más oscuro para mejor contraste
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Área de escaneo expandida verticalmente
    // Ancho: 80% del ancho disponible
    // Alto: 60% de la altura disponible (más alto que ancho)
    final scanAreaWidth = size.width * 0.80;
    final scanAreaHeight = size.height * 0.60;
    final scanAreaLeft = (size.width - scanAreaWidth) / 2;
    final scanAreaTop = (size.height - scanAreaHeight) / 2;
    final scanArea = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaWidth,
      scanAreaHeight,
    );

    // Dibujar fondo oscuro con recorte en el centro
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(scanArea, const Radius.circular(20)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Marco de escaneo más visible y grueso
    final cornerLength = 35.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Esquinas superiores
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      Offset(scanAreaLeft, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - cornerLength, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Esquinas inferiores
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight - cornerLength),
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - cornerLength, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight - cornerLength),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InvoicePreviewSheet extends StatelessWidget {
  const _InvoicePreviewSheet({
    required this.invoice,
    this.validationResult,
    this.validationMessage,
  });

  final Invoice invoice;
  final DgiiValidationResult? validationResult;
  final String? validationMessage;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700; // Pantallas pequeñas
    
    // Ajustar altura máxima según el tamaño de la pantalla
    // Usar altura razonable pero asegurar que los botones sean visibles
    final maxHeight = isSmallScreen 
        ? screenHeight * 0.85  // 85% en pantallas pequeñas
        : screenHeight * 0.80; // 80% en pantallas normales
    
    // Ajustar padding inferior según el tamaño de la pantalla
    // Padding suficiente para que los botones sean visibles
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 20;
    
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: bottomPadding,
          top: 8,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle del bottom sheet
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            // Contenido scrollable - usar Expanded con flex limitado
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nuevo comprobante',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revisa la información y confirma para guardar en tu historial.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    _InvoiceDataRow(
                      label: 'Proveedor',
                      value: invoice.issuerName,
                    ),
                    _InvoiceDataRow(
                      label: 'RNC',
                      value: invoice.rnc,
                    ),
                    _InvoiceDataRow(
                      label: 'No. e-CF',
                      value: invoice.ecfNumber,
                    ),
                    _InvoiceDataRow(
                      label: 'Monto',
                      value: invoice.formattedAmount,
                    ),
                    _InvoiceDataRow(
                      label: 'Fecha',
                      value: InvoiceParser.extractRawValue(
                            invoice.rawData,
                            const ['FechaEmision', 'fechaemision', 'fecha'],
                          ) ??
                          invoice.formattedDate,
                    ),
                    _InvoiceDataRow(
                      label: 'Tipo',
                      value: invoice.type,
                    ),
                    if (invoice.status != null)
                      _InvoiceDataRow(
                        label: 'Estatus',
                        value: invoice.status!,
                      ),
                    if (validationMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            validationResult?.status == DgiiValidationStatus.accepted
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              validationMessage!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (invoice.buyerName != null)
                      _InvoiceDataRow(
                        label: 'Comprador',
                        value: invoice.buyerName!,
                      ),
                    if (invoice.buyerRnc != null)
                      _InvoiceDataRow(
                        label: 'RNC comprador',
                        value: invoice.buyerRnc!,
                      ),
                    if (invoice.totalItbis != null)
                      _InvoiceDataRow(
                        label: 'ITBIS',
                        value: NumberFormat.currency(
                          locale: 'en_US',
                          symbol: 'RD\$',
                        ).format(invoice.totalItbis),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            // Botones siempre visibles en la parte inferior - contenedor fijo
            // Padding adaptativo según el tamaño de pantalla
            Container(
              padding: EdgeInsets.only(
                bottom: isSmallScreen 
                    ? screenHeight * 0.12  // 12% de la altura en pantallas pequeñas
                    : screenHeight * 0.10,  // 10% de la altura en pantallas normales
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar comprobante'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceDataRow extends StatelessWidget {
  const _InvoiceDataRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
