import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_helper.dart';

class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  Completer<void>? _loadingCompleter;
  final Connectivity _connectivity = Connectivity();

  Future<bool> _hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<void> preload() async {
    if (_interstitialAd != null || _isLoading) {
      return _loadingCompleter?.future ?? Future.value();
    }

    // Verificar conectividad antes de intentar cargar
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      return Future.value();
    }

    _isLoading = true;
    _loadingCompleter = Completer<void>();

    final adUnitId = AdHelper.interstitialAdUnitId;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          _loadingCompleter?.complete();
        },
        onAdFailedToLoad: (error) {
          _interstitialAd?.dispose();
          _interstitialAd = null;
          _isLoading = false;

          // Siempre completar sin error para no bloquear la app
          // Los errores de anuncios no deberían impedir el uso de la aplicación
          _loadingCompleter?.complete();
        },
      ),
    );

    return _loadingCompleter!.future;
  }

  Future<bool> show() async {
    if (_interstitialAd == null) {
      try {
        await preload();
      } catch (_) {
        return false;
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      return false;
    }

    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        preload();
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        preload();
        completer.complete(false);
      },
    );

    ad.show();
    _interstitialAd = null;
    return completer.future;
  }
}
