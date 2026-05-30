import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../data/services/restaurant_detail_service.dart';
import '../screens/restaurant_detail_screen.dart';

/// Gestiona deep links de la app para abrir detalles de establecimiento.
class DeepLinkHandler {
  DeepLinkHandler({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;
  final AppLinks _appLinks = AppLinks();
  final RestaurantDetailService _restaurantDetailService =
      RestaurantDetailService();

  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledUri;
  DateTime? _lastHandledAt;

  Future<void> init() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      await _handleUri(initialUri);
    } catch (_) {
      // Ignorar errores de enlace inicial.
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        await _handleUri(uri);
      },
      onError: (_) {
        // Ignorar errores de stream de deep links.
      },
    );
  }

  Future<void> _handleUri(Uri? uri) async {
    if (uri == null) return;

    // Evita dobles aperturas por el mismo evento del sistema, pero permite
    // volver a abrir el mismo enlace si el usuario lo dispara más tarde.
    final now = DateTime.now();
    if (_lastHandledUri == uri.toString() &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 1)) {
      return;
    }

    final establishmentId = _extractEstablishmentId(uri);
    if (establishmentId == null) return;

    _lastHandledUri = uri.toString();
    _lastHandledAt = now;

    final detail = await _restaurantDetailService.getRestaurantDetail(
      establishmentId,
    );

    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) return;

    if (detail == null) {
      ScaffoldMessenger.maybeOf(navigatorState.context)?.showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el establecimiento compartido'),
        ),
      );
      return;
    }

    await navigatorState.push(
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(
          restaurant: detail,
        ),
      ),
    );
  }

  int? _extractEstablishmentId(Uri uri) {
    if (uri.scheme != 'pinfood') return null;

    if (uri.host != 'establecimiento') return null;

    if (uri.pathSegments.isEmpty) return null;

    return int.tryParse(uri.pathSegments.first);
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
  }
}
