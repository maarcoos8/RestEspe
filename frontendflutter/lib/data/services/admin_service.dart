import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_establishment_model.dart';
import '../models/admin_user_model.dart';
import '../models/categoria_dieta_model.dart';
import '../models/rol_model.dart';
import '../models/tipo_establecimiento_model.dart';
import '../../core/constants.dart';
import '../../core/auth_token_store.dart';

/// Servicio para obtener datos de administración de la aplicación.
class AdminService {
  static Map<String, String> _authHeaders({bool json = false}) {
    final base = <String, String>{};
    if (json) {
      base['Content-Type'] = 'application/json';
    }
    return AuthTokenStore.withAuth(base);
  }

  static String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      // Ignore parse errors and fall back to the provided message.
    }
    return fallback;
  }

  /// Obtiene la lista de usuarios.
  static Future<List<AdminUserModel>> getUsuarios() async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/usuario/');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map(
              (json) => AdminUserModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  /// Busca usuarios por nombre o email.
  /// Si se proporciona `roleId`, sólo devuelve usuarios con ese rol.
  static Future<List<AdminUserModel>> searchUsuarios(String query, {int? roleId}) async {
    if (query.isEmpty) return [];
    try {
      final usuarios = await getUsuarios();
      final lowerQuery = query.toLowerCase();
      return usuarios
          .where((u) {
            final matchesQuery = (u.nombreCompleto?.toLowerCase().contains(lowerQuery) ?? false) ||
                (u.email.toLowerCase().contains(lowerQuery));
            if (!matchesQuery) return false;
            if (roleId != null) return u.idRol == roleId;
            return true;
          })
          .toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }

  /// Obtiene la lista de roles.
  static Future<List<RolModel>> getRoles() async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/rol/');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => RolModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Error al obtener roles: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error al obtener roles: $e');
    }
  }

  /// Actualiza el rol de un usuario.
  static Future<void> updateUsuarioRol(int idUsuario, int idRol) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/usuario/$idUsuario');
    final response = await http.put(
      uri,
      headers: _authHeaders(json: true),
      body: jsonEncode({'id_rol': idRol}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Error al actualizar usuario: $idUsuario (status: ${response.statusCode})',
      );
    }
  }

  /// Elimina un usuario.
  static Future<void> deleteUsuario(int idUsuario) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/usuario/$idUsuario');
    final response = await http.delete(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw Exception(
        'Error al eliminar usuario: $idUsuario (status: ${response.statusCode})',
      );
    }
  }

  /// Obtiene la lista de categorías de dieta.
  static Future<List<CategoriaDieta>> getCategoriasDieta() async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/categoria_dieta/');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map(
              (json) => CategoriaDieta.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Error al obtener categorías de dieta: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al obtener categorías de dieta: $e');
    }
  }

  /// Obtiene la lista de tipos de establecimiento.
  static Future<List<TipoEstablecimiento>> getTiposEstablecimiento() async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/tipo_establecimiento/');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map(
              (json) =>
                  TipoEstablecimiento.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Error al obtener tipos de establecimiento: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error al obtener tipos de establecimiento: $e');
    }
  }

  /// Obtiene una página de establecimientos para la pantalla de administración.
  static Future<List<AdminEstablishmentModel>> getEstablecimientos({
    int skip = 0,
    int limit = 10,
    String? nombre,
    int? responsableId,
    List<int>? categoriaDietaIds,
    List<int>? tipoEstablecimientoIds,
    bool? soloVerificados,
    double? puntuacionMediaMinima,
  }) async {
    try {
      final queryParametersAll = <String, List<String>>{
        'skip': [skip.toString()],
        'limit': [limit.toString()],
      };
      if (nombre != null && nombre.trim().isNotEmpty) {
        queryParametersAll['nombre'] = [nombre.trim()];
      }
      if (responsableId != null) {
        queryParametersAll['responsable_id'] = [responsableId.toString()];
      }
      if (categoriaDietaIds != null && categoriaDietaIds.isNotEmpty) {
        queryParametersAll['categoria_dieta_ids'] = categoriaDietaIds
            .map((id) => id.toString())
            .toList(growable: false);
      }
      if (tipoEstablecimientoIds != null && tipoEstablecimientoIds.isNotEmpty) {
        queryParametersAll['tipo_establecimiento_ids'] = tipoEstablecimientoIds
            .map((id) => id.toString())
            .toList(growable: false);
      }
      if (soloVerificados == true) {
        queryParametersAll['solo_verificados'] = ['true'];
      }
      if (puntuacionMediaMinima != null) {
        queryParametersAll['puntuacion_media_minima'] = [
          puntuacionMediaMinima.toString(),
        ];
      }

      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/establecimiento/filtrar',
      ).replace(query: _encodeRepeatedQueryParameters(queryParametersAll));
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map(
              (json) => AdminEstablishmentModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      }

      throw Exception(
        'Error al obtener establecimientos: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error al obtener establecimientos: $e');
    }
  }

  static String _encodeRepeatedQueryParameters(
    Map<String, List<String>> parameters,
  ) {
    final parts = <String>[];

    for (final entry in parameters.entries) {
      for (final value in entry.value) {
        parts.add(
          '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value)}',
        );
      }
    }

    return parts.join('&');
  }

  /// Crea una nueva categoría de dieta.
  static Future<void> createCategoriaDieta(
    String nombreDieta, {
    String? colorHex,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/categoria_dieta/');
    final body = {'nombre_dieta': nombreDieta};
    if (colorHex != null) {
      body['color_hex'] = colorHex;
    }
    final response = await http.post(
      uri,
      headers: _authHeaders(json: true),
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(response, 'Error al crear categoría de dieta'),
      );
    }
  }

  /// Elimina una categoría de dieta por id.
  static Future<void> deleteCategoriaDieta(int id) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/categoria_dieta/$id');
    final response = await http.delete(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw Exception(
        'Error al eliminar categoría de dieta: $id (status: ${response.statusCode})',
      );
    }
  }

  /// Actualiza una categoría de dieta.
  static Future<void> updateCategoriaDieta(
    int id,
    String nombreDieta, {
    String? colorHex,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/categoria_dieta/$id');
    final body = {'nombre_dieta': nombreDieta};
    if (colorHex != null) {
      body['color_hex'] = colorHex;
    }
    final response = await http.put(
      uri,
      headers: _authHeaders(json: true),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Error al actualizar categoría de dieta',
        ),
      );
    }
  }

  /// Crea un nuevo tipo de establecimiento.
  static Future<void> createTipoEstablecimiento(String nombreCategoria) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/tipo_establecimiento/');
    final response = await http.post(
      uri,
      headers: _authHeaders(json: true),
      body: jsonEncode({'nombre_categoria': nombreCategoria}),
    );
    if (response.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Error al crear tipo de establecimiento',
        ),
      );
    }
  }

  /// Elimina un tipo de establecimiento por id.
  static Future<void> deleteTipoEstablecimiento(int id) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/tipo_establecimiento/$id',
    );
    final response = await http.delete(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw Exception(
        'Error al eliminar tipo de establecimiento: $id (status: ${response.statusCode})',
      );
    }
  }

  /// Actualiza un tipo de establecimiento.
  static Future<void> updateTipoEstablecimiento(
    int id,
    String nombreCategoria,
  ) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/tipo_establecimiento/$id',
    );
    final response = await http.put(
      uri,
      headers: _authHeaders(json: true),
      body: jsonEncode({'nombre_categoria': nombreCategoria}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Error al actualizar tipo de establecimiento',
        ),
      );
    }
  }

  /// Crea un nuevo establecimiento.
  static Future<int> createEstablishment(dynamic formData) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/establecimiento/');

    // formData debe tener método toJson() que devuelva Map<String, dynamic>
    final body = formData is Map<String, dynamic>
        ? formData
        : (formData.toJson() as Map<String, dynamic>);

    final response = await http.post(
      uri,
      headers: _authHeaders(json: true),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      try {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final idEstablecimiento = jsonResponse['id_establecimiento'] as int;

        // Si hay tipos de establecimiento, crearlos
        if (formData.tiposEstablecimientoIds?.isNotEmpty ?? false) {
          for (final tipoId in formData.tiposEstablecimientoIds) {
            await createEstablecimientoTipo(idEstablecimiento, tipoId);
          }
        }

        return idEstablecimiento;
      } catch (e) {
        throw Exception('Error al parsear respuesta: $e');
      }
    } else {
      throw Exception(
        _extractErrorMessage(
          response,
          'Error al crear establecimiento (${response.statusCode})',
        ),
      );
    }
  }

  /// Elimina un establecimiento por id.
  static Future<void> deleteEstablecimiento(int idEstablecimiento) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/establecimiento/$idEstablecimiento',
    );
    final response = await http.delete(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Error al eliminar establecimiento: $idEstablecimiento (status: ${response.statusCode})',
        ),
      );
    }
  }

  /// Actualiza un establecimiento existente.
  static Future<void> updateEstablishment(
    int idEstablecimiento,
    dynamic formData,
    List<int> tiposEstablecimientoIds,
  ) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/establecimiento/$idEstablecimiento',
    );

    // formData debe tener método toJson() que devuelva Map<String, dynamic>
    final body = formData is Map<String, dynamic>
        ? formData
        : (formData.toJson() as Map<String, dynamic>);
    // Incluir tipos en el body para que el backend haga la actualización atómica
    body['tipos_establecimiento_ids'] = tiposEstablecimientoIds;

    final response = await http.put(
      uri,
      headers: _authHeaders(json: true),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Error al actualizar establecimiento (${response.statusCode})',
        ),
      );
    }
  }

  /// Elimina todos los tipos de un establecimiento.
  static Future<void> deleteAllEstablecimientoTipos(
    int idEstablecimiento,
  ) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/establecimiento_tipo/establecimiento/$idEstablecimiento',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;

        for (final tipoJson in jsonList) {
          final tipo = tipoJson as Map<String, dynamic>;
          final idTipo = tipo['id_tipo_establecimiento'] as int;
          await _deleteEstablecimientoTipo(idEstablecimiento, idTipo);
        }
      }
    } catch (e) {
      // Log silencioso - si hay error al eliminar, continuamos
      print('Error eliminando tipos: $e');
    }
  }

  /// Elimina un tipo específico de establecimiento.
  static Future<void> _deleteEstablecimientoTipo(
    int idEstablecimiento,
    int idTipo,
  ) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/establecimiento_tipo/establecimiento/$idEstablecimiento/tipo/$idTipo',
    );
    final response = await http.delete(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Error al eliminar tipo de establecimiento',
        ),
      );
    }
  }

  /// Crea una relación entre un establecimiento y un tipo.
  static Future<void> createEstablecimientoTipo(
    int idEstablecimiento,
    int idTipo,
  ) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/establecimiento_tipo/');
    final response = await http.post(
      uri,
      headers: _authHeaders(json: true),
      body: jsonEncode({
        'id_establecimiento': idEstablecimiento,
        'id_tipo_establecimiento': idTipo,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Error al asignar tipo de establecimiento',
        ),
      );
    }
  }
}
