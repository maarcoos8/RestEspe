import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/auth_token_store.dart';
import '../../core/constants.dart';
import '../models/categoria_dieta_model.dart';
import '../models/item_menu_model.dart';
import '../models/tipo_item_menu_model.dart';

/// Servicio para obtener datos del menú del establecimiento.
class MenuService {
  /// Obtiene todas las secciones del menú de un establecimiento.
  static Future<List<TipoItemMenu>> getSecciones(int idEstablecimiento) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/tipo_item_menu/establecimiento/$idEstablecimiento',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => TipoItemMenu.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
        'Error al obtener secciones del menú: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al obtener secciones del menú: $e');
    }
  }

  /// Obtiene todos los platos de un establecimiento.
  static Future<List<ItemMenu>> getPlatos(int idEstablecimiento) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/item_menu/establecimiento/$idEstablecimiento',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => ItemMenu.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
        'Error al obtener platos: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al obtener platos: $e');
    }
  }

  /// Obtiene los platos de una sección específica.
  static Future<List<ItemMenu>> getPlatosPorSeccion(int idTipoItem) async {
    try {
      final platos = await getPlatos(1); // Placeholder, se obtienen todos
      return platos.where((p) => p.idTipoItemMenu == idTipoItem).toList();
    } catch (e) {
      throw Exception('Error al obtener platos de la sección: $e');
    }
  }

  /// Crea una nueva sección del menú.
  static Future<TipoItemMenu> crearSeccion(
    int idEstablecimiento,
    String nombreTipo,
  ) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/tipo_item_menu/');
      final response = await http.post(
        uri,
        headers: AuthTokenStore.withAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'id_establecimiento': idEstablecimiento,
          'nombre_tipo': nombreTipo,
        }),
      );

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TipoItemMenu.fromJson(jsonData);
      }

      throw Exception(
        'Error al crear sección: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al crear sección: $e');
    }
  }

  /// Actualiza una sección existente.
  static Future<TipoItemMenu> actualizarSeccion(
    int idTipoItem,
    String nombreTipo,
  ) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/tipo_item_menu/$idTipoItem',
      );
      final response = await http.put(
        uri,
        headers: AuthTokenStore.withAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({'nombre_tipo': nombreTipo}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TipoItemMenu.fromJson(jsonData);
      }

      throw Exception(
        'Error al actualizar sección: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al actualizar sección: $e');
    }
  }

  /// Elimina una sección.
  static Future<void> eliminarSeccion(int idTipoItem) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/tipo_item_menu/$idTipoItem',
      );
      final response = await http.delete(
        uri,
        headers: AuthTokenStore.withAuth(const {}),
      );
      if (response.statusCode == 200) return;

      throw Exception(
        'Error al eliminar sección: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al eliminar sección: $e');
    }
  }

  /// Elimina un plato por id.
  static Future<void> eliminarPlato(int idItem) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/item_menu/$idItem');
      final response = await http.delete(
        uri,
        headers: AuthTokenStore.withAuth(const {}),
      );
      if (response.statusCode == 200) return;

      throw Exception(
        'Error al eliminar plato: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al eliminar plato: $e');
    }
  }

  /// Actualiza un plato (partial update).
  static Future<ItemMenu> actualizarPlato(
    int idItem,
    Map<String, dynamic> data,
  ) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/item_menu/$idItem');
      final response = await http.put(
        uri,
        headers: AuthTokenStore.withAuth({'Content-Type': 'application/json'}),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ItemMenu.fromJson(jsonData);
      }

      throw Exception(
        'Error al actualizar plato: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al actualizar plato: $e');
    }
  }

  /// Crea un nuevo plato.
  static Future<ItemMenu> crearPlato(
    int idEstablecimiento,
    String nombreItemMenu,
    double precio,
    int? idTipoItemMenu, {
    String? descripcion,
    List<int>? idCategorias,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/item_menu/');
      final response = await http.post(
        uri,
        headers: AuthTokenStore.withAuth({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'id_establecimiento': idEstablecimiento,
          'nombre_item_menu': nombreItemMenu,
          'descripcion': descripcion,
          'precio': precio,
          'id_tipo_item_menu': idTipoItemMenu,
          'id_categorias': idCategorias,
        }),
      );

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ItemMenu.fromJson(jsonData);
      }

      throw Exception(
        'Error al crear plato: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al crear plato: $e');
    }
  }

  /// Obtiene todas las categorias de dieta existentes.
  static Future<List<CategoriaDieta>> getCategorias() async {
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
      }

      throw Exception(
        'Error al obtener categorias: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error al obtener categorias: $e');
    }
  }
}
