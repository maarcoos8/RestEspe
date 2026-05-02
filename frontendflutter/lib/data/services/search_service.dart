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

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', <String, String>{
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
        'User-Agent': 'RestEspe/1.0',
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
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) {
      return const [];
    }

    final uri = Uri.parse('${AppConstants.apiBaseUrl}/establecimiento/filtrar')
        .replace(queryParameters: <String, String>{
      'nombre': normalizedQuery,
    });

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
            ultimaVerificacion: DateTime.tryParse(entry['ultima_verificacion']?.toString() ?? ''),
            verificadorId: int.tryParse(entry['verificador_id']?.toString() ?? ''),
          );
        })
        .whereType<SearchRestaurantResult>()
        .toList(growable: false);
  }

  void dispose() {
    _client.close();
  }
}