import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/auth_token_store.dart';
import '../../core/constants.dart';
import '../models/search_models.dart';

/// Servicio para gestionar establecimientos favoritos del usuario.
class FavoriteService {
  FavoriteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<SearchRestaurantResult>> getFavoritesByUser(int userId) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/usuario_establecimiento_favorito/usuario/$userId',
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
            categoriasDieta: const [],
          );
        })
        .whereType<SearchRestaurantResult>()
        .toList(growable: false);
  }

  Future<void> addFavorite({
    required int userId,
    required int establishmentId,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/usuario_establecimiento_favorito/',
    );
    final response = await _client.post(
      uri,
      headers: AuthTokenStore.withAuth(const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }),
      body: jsonEncode(<String, int>{
        'id_usuario': userId,
        'id_establecimiento': establishmentId,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('No se pudo añadir el favorito');
    }
  }

  Future<void> removeFavorite({
    required int userId,
    required int establishmentId,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/usuario_establecimiento_favorito/usuario/$userId/establecimiento/$establishmentId',
    );

    final response = await _client.delete(
      uri,
      headers: AuthTokenStore.withAuth(const <String, String>{
        'Accept': 'application/json',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo eliminar el favorito');
    }
  }

  void dispose() {
    _client.close();
  }
}
