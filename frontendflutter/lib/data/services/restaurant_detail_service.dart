import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../models/restaurant_detail_model.dart';
import '../../core/constants.dart';

/// Servicio para obtener detalles de restaurantes desde el backend.
class RestaurantDetailService {
  final String baseUrl = AppConstants.apiBaseUrl;

  /// Obtiene los detalles completos de un restaurante.
  /// Realiza 3 llamadas en paralelo: establecimiento, categorías y tipos.
  Future<RestaurantDetail?> getRestaurantDetail(int idEstablecimiento) async {
    try {
      // Realizar todas las llamadas en paralelo
      final results = await Future.wait([
        _getEstablecimientoBasic(idEstablecimiento),
        _getCategoriasDieta(idEstablecimiento),
        _getTiposEstablecimiento(idEstablecimiento),
        _getPuntuacionMedia(idEstablecimiento),
      ], eagerError: true);

      final establecimientoJson = results[0] as Map<String, dynamic>?;
      final categoriasJson = results[1] as List<dynamic>;
      final tiposJson = results[2] as List<dynamic>;
      final puntuacionJson = results[3] as Map<String, dynamic>?;

      if (establecimientoJson == null) {
        return null;
      }

      return RestaurantDetail(
        idEstablecimiento: establecimientoJson['id_establecimiento'] as int,
        nombre: establecimientoJson['nombre'] as String,
        direccionTexto: establecimientoJson['direccion_texto'] as String?,
        coordinates: _parseCoordinates(
          establecimientoJson['latitud'],
          establecimientoJson['longitud'],
        ),
        estadoVerificado: establecimientoJson['estado_verificado'] as bool?,
        ultimaVerificacion: establecimientoJson['ultima_verificacion'] != null
            ? DateTime.parse(establecimientoJson['ultima_verificacion'] as String)
            : null,
        verificadorId: establecimientoJson['verificador_id'] as int?,
        categoriasDieta: categoriasJson
            .whereType<Map<String, dynamic>>()
            .map((cat) => DietaCategory.fromJson(cat))
            .toList(),
        tiposEstablecimiento: tiposJson
            .whereType<Map<String, dynamic>>()
            .map((tipo) => RestaurantType.fromJson(tipo))
            .toList(),
        puntuacionMedia: puntuacionJson?['puntuacion_media'] as double?,
        numeroResenas: (puntuacionJson?['numero_resenas'] as num?)?.toInt() ?? 0,
        imagenUrl: establecimientoJson['imagen_url'] as String?,
        propietarioId: establecimientoJson['propietario_id'] as int?,
      );
    } catch (e) {
      print('Error obteniendo detalles del restaurante: $e');
      return null;
    }
  }

  /// Obtiene los datos básicos del establecimiento.
  Future<Map<String, dynamic>?> _getEstablecimientoBasic(int idEstablecimiento) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/establecimiento/$idEstablecimiento'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error obteniendo establecimiento básico: $e');
      return null;
    }
  }

  /// Obtiene las categorías de dieta de un establecimiento.
  /// El backend ahora devuelve las categorías con el nombre incluido.
  /// Endpoint: GET /establecimiento_categoria/establecimiento/{id}
  Future<List<dynamic>> _getCategoriasDieta(int idEstablecimiento) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/establecimiento_categoria/establecimiento/$idEstablecimiento'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error obteniendo categorías de dieta: $e');
      return [];
    }
  }

  /// Obtiene los tipos de establecimiento de un establecimiento.
  /// El backend ahora devuelve los tipos con el nombre incluido.
  /// Endpoint: GET /establecimiento_tipo/establecimiento/{id}
  Future<List<dynamic>> _getTiposEstablecimiento(int idEstablecimiento) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/establecimiento_tipo/establecimiento/$idEstablecimiento'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error obteniendo tipos de establecimiento: $e');
      return [];
    }
  }

  /// Obtiene la puntuación media del establecimiento.
  Future<Map<String, dynamic>?> _getPuntuacionMedia(int idEstablecimiento) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/establecimiento/$idEstablecimiento/puntuacion-media'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error obteniendo puntuación media: $e');
      return null;
    }
  }

  LatLng? _parseCoordinates(dynamic lat, dynamic lng) {
    if (lat != null && lng != null) {
      try {
        return LatLng(
          (lat is String) ? double.parse(lat) : (lat as num).toDouble(),
          (lng is String) ? double.parse(lng) : (lng as num).toDouble(),
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
