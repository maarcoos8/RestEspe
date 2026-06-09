import 'package:flutter/material.dart';
import '../data/models/restaurant_detail_model.dart';
import '../data/services/restaurant_detail_service.dart';

/// Provider que cachea los detalles de los restaurantes para evitar llamadas redundantes.
/// 
/// Este provider es responsable de:
/// - Cachear los detalles del restaurante
/// - Evitar múltiples llamadas API al mismo endpoint
/// - Deduplicar solicitudes simultáneas del mismo restaurante
class RestaurantDetailProvider extends ChangeNotifier {
  final RestaurantDetailService _service = RestaurantDetailService();

  // Caché de resultados completados
  final Map<int, RestaurantDetail> _cache = {};
  
  // Solicitudes en curso para deduplicación
  final Map<int, Future<RestaurantDetail?>> _pendingRequests = {};

  /// Carga los detalles del restaurante.
  /// 
  /// Si ya están en caché para el mismo establecimiento, retorna el resultado cacheado.
  /// Si hay una solicitud en curso, retorna ese Future (deduplicación).
  /// De otra forma, hace una nueva solicitud y la cachea.
  /// Carga los detalles del restaurante.
  ///
  /// Si ya están en caché para el mismo establecimiento, retorna el resultado cacheado.
  /// Si `forceRefresh` es true, fuerza una llamada al servidor aún si está en caché.
  Future<RestaurantDetail?> loadRestaurantDetail(int idEstablecimiento, {bool forceRefresh = false}) {
    // Si está en caché y no se forza refresco, retornar valor cacheado inmediatamente
    if (!forceRefresh && _cache.containsKey(idEstablecimiento)) {
      return Future.value(_cache[idEstablecimiento]);
    }

    // Si hay una solicitud en curso y no se forza refresco, retornar ese Future (evita duplicados)
    if (!forceRefresh && _pendingRequests.containsKey(idEstablecimiento)) {
      return _pendingRequests[idEstablecimiento]!;
    }

    // Si se forza refresco, limpiar caché y pending para forzar nueva petición
    if (forceRefresh) {
      _cache.remove(idEstablecimiento);
      _pendingRequests.remove(idEstablecimiento);
    }

    // Crear nueva solicitud y almacenarla en pendingRequests
    final future = _service
        .getRestaurantDetail(idEstablecimiento)
        .then((detail) {
          // Guardar en caché si se obtuvo resultado
          if (detail != null) {
            _cache[idEstablecimiento] = detail;
          }
          return detail;
        })
        .whenComplete(() {
          // Limpiar de pendingRequests tanto en éxito como en error
          _pendingRequests.remove(idEstablecimiento);
        });

    // Registrar la solicitud en pendingRequests
    _pendingRequests[idEstablecimiento] = future;
    return future;
  }

  /// Retorna el detalle cacheado si existe, o null.
  RestaurantDetail? getCachedDetail(int idEstablecimiento) => _cache[idEstablecimiento];

  /// Limpia el caché de restaurante.
  void clearCache() {
    _cache.clear();
    _pendingRequests.clear();
  }

  /// Limpia el caché de un restaurante específico (usado cuando se edita).
  void clearRestaurantCache(int idEstablecimiento) {
    _cache.remove(idEstablecimiento);
    _pendingRequests.remove(idEstablecimiento);
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
