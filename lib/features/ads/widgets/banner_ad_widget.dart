import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../auth/services/connectivity_service.dart';
import '../ad_helper.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectivityAndLoad();
    });
  }

  Future<void> _checkConnectivityAndLoad() async {
    if (!mounted) return;
    
    final connectivityService = ref.read(connectivityServiceProvider);
    final hasInternet = await connectivityService.hasInternetConnection();

    if (hasInternet) {
      _loadBannerAd();
    } else {
      // Intentar cargar de todos modos, AdMob puede tener anuncios en caché
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    final banner = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
          // Silenciar errores de red (es esperado cuando no hay conexión)
          final errorMessage = error.message.toLowerCase();
          final isNetworkError = errorMessage.contains('network') ||
              errorMessage.contains('connection') ||
              errorMessage.contains('hostname') ||
              errorMessage.contains('internet') ||
              errorMessage.contains('unable to resolve host');

          if (!isNetworkError && errorMessage.isNotEmpty) {
            debugPrint('Error al cargar banner ad: $error');
          }
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si el anuncio no está cargado, mostrar un contenedor con altura mínima
    // para reservar el espacio y evitar que el layout cambie cuando se cargue
    if (!_isLoaded || _bannerAd == null) {
      return Container(
        height: 50,
        width: double.infinity,
        alignment: Alignment.center,
        child: const SizedBox.shrink(),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
