import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'features/ads/interstitial_ad_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await initializeDateFormatting('es_DO', null);
  } catch (e) {
    debugPrint('Error inicializando formato de fecha: $e');
  }
  
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
    // Continuar aunque Firebase falle para que el usuario vea el error
  }
  
  try {
    await MobileAds.instance.initialize();
    debugPrint('AdMob inicializado correctamente');
  } catch (e) {
    debugPrint('Error inicializando AdMob: $e');
    // Continuar aunque AdMob falle
  }
  
  // Preload de anuncios en segundo plano, no bloquear inicio
  InterstitialAdManager.instance.preload().catchError((error) {
    debugPrint('Error precargando anuncio intersticial: $error');
  });
  
  runApp(
    const ProviderScope(
      child: MiComprobanteApp(),
    ),
  );
}
