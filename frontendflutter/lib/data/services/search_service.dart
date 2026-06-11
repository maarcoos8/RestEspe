import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/constants.dart';
import '../models/search_models.dart';

class SearchService {
  SearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<SearchLocationResult>> searchLocations(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) {
      return const [];
    }

    final uri =
        Uri.https('nominatim.openstreetmap.org', '/search', <String, String>{
          'format': 'jsonv2',
          'addressdetails': '1',
          'limit': '6',
          'accept-language': 'es',
          'countrycodes': 'es',
          'q': normalizedQuery,
        });

    final response = await _client.get(
      uri,
      headers: const <String, String>{
        'Accept': 'application/json',
        'User-Agent': 'PinFood/1.0',
      },
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final lat = double.tryParse(entry['lat']?.toString() ?? '');
          final lon = double.tryParse(entry['lon']?.toString() ?? '');
          final displayName = entry['display_name']?.toString() ?? '';

          if (lat == null || lon == null || displayName.isEmpty) {
            return null;
          }

          return SearchLocationResult(
            displayName: displayName,
            coordinates: LatLng(lat, lon),
          );
        })
        .whereType<SearchLocationResult>()
        .toList(growable: false);
  }

  Future<List<SearchRestaurantResult>> searchRestaurants({
    required String query,
    RestaurantMapFilters filters = const RestaurantMapFilters(),
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) {
      return const [];
    }

    final uri = _buildFilteredUri(nombre: normalizedQuery, filters: filters);

    final response = await _client.get(
      uri,
      headers: const <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final id = entry['id_establecimiento'];
          final nombre = entry['nombre']?.toString() ?? '';
          final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');

          if (parsedId == null || nombre.isEmpty) {
            return null;
          }

          return SearchRestaurantResult(
            idEstablecimiento: parsedId,
            nombre: nombre,
            direccionTexto: entry['direccion_texto']?.toString(),
            latitud: double.tryParse(entry['latitud']?.toString() ?? ''),
            longitud: double.tryParse(entry['longitud']?.toString() ?? ''),
            estadoVerificado: entry['estado_verificado'] as bool?,
            ultimaVerificacion: DateTime.tryParse(
              entry['ultima_verificacion']?.toString() ?? '',
            ),
            verificadorId: int.tryParse(
              entry['verificador_id']?.toString() ?? '',
            ),
            categoriasDieta: (entry['categorias_dieta'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(DietCategory.fromJson)
                .toList(growable: false),
          );
        })
        .whereType<SearchRestaurantResult>()
        .toList(growable: false);
  }

  Future<List<SearchRestaurantResult>> searchRestaurantsInViewport({
    required LatLng center,
    required double radiusMeters,
    RestaurantMapFilters filters = const RestaurantMapFilters(),
  }) async {
    final uri = _buildFilteredUri(
      latitud: center.latitude,
      longitud: center.longitude,
      distanciaMetros: radiusMeters,
      filters: filters,
    );

    final response = await _client.get(
      uri,
      headers: const <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final id = entry['id_establecimiento'];
          final nombre = entry['nombre']?.toString() ?? '';
          final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');

          if (parsedId == null || nombre.isEmpty) {
            return null;
          }

          return SearchRestaurantResult(
            idEstablecimiento: parsedId,
            nombre: nombre,
            direccionTexto: entry['direccion_texto']?.toString(),
            latitud: double.tryParse(entry['latitud']?.toString() ?? ''),
            longitud: double.tryParse(entry['longitud']?.toString() ?? ''),
            estadoVerificado: entry['estado_verificado'] as bool?,
            ultimaVerificacion: DateTime.tryParse(
              entry['ultima_verificacion']?.toString() ?? '',
            ),
            verificadorId: int.tryParse(
              entry['verificador_id']?.toString() ?? '',
            ),
            categoriasDieta: (entry['categorias_dieta'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(DietCategory.fromJson)
                .toList(growable: false),
          );
        })
        .whereType<SearchRestaurantResult>()
        .toList(growable: false);
  }

  void dispose() {
    _client.close();
  }

  Uri _buildFilteredUri({
    String? nombre,
    double? latitud,
    double? longitud,
    double? distanciaMetros,
    RestaurantMapFilters filters = const RestaurantMapFilters(),
  }) {
    final queryParametersAll = <String, List<String>>{};

    if (nombre != null && nombre.trim().isNotEmpty) {
      queryParametersAll['nombre'] = <String>[nombre.trim()];
    }

    if (latitud != null) {
      queryParametersAll['latitud'] = <String>[latitud.toString()];
    }

    if (longitud != null) {
      queryParametersAll['longitud'] = <String>[longitud.toString()];
    }

    if (distanciaMetros != null) {
      queryParametersAll['distancia_metros'] = <String>[
        distanciaMetros.toStringAsFixed(0),
      ];
    }

    if (filters.selectedDietIds.isNotEmpty) {
      queryParametersAll['categoria_dieta_ids'] = filters.selectedDietIds
          .map((id) => id.toString())
          .toList();
    }

    if (filters.selectedTypeIds.isNotEmpty) {
      queryParametersAll['tipo_establecimiento_ids'] = filters.selectedTypeIds
          .map((id) => id.toString())
          .toList();
    }

    if (filters.onlyVerified) {
      queryParametersAll['solo_verificados'] = <String>['true'];
    }

    if (filters.minimumRating != null) {
      queryParametersAll['puntuacion_media_minima'] = <String>[
        filters.minimumRating!.toString(),
      ];
    }

    return Uri.parse(
      '${AppConstants.apiBaseUrl}/establecimiento/filtrar',
    ).replace(query: _encodeRepeatedQueryParameters(queryParametersAll));
  }

  String _encodeRepeatedQueryParameters(Map<String, List<String>> parameters) {
    final parts = <String>[];

    for (final entry in parameters.entries) {
      for (final value in entry.value) {
        parts.add('${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value)}');
      }
    }

    return parts.join('&');
  }
}
