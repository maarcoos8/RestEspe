import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item_menu_model.dart';
import '../models/tipo_item_menu_model.dart';
import '../../core/constants.dart';

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
        try {
          final List<dynamic> jsonList =
              jsonDecode(response.body) as List<dynamic>;
          return jsonList
              .map((json) =>
                  TipoItemMenu.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (parseError) {
          throw Exception(
            'Error al parsear secciones: $parseError. Respuesta: ${response.body}',
          );
        }
      } else {
        throw Exception(
          'Error al obtener secciones del menú: ${response.statusCode} - ${response.body}',
        );
      }
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
        try {
          final List<dynamic> jsonList =
              jsonDecode(response.body) as List<dynamic>;
          return jsonList
              .map((json) =>
                  ItemMenu.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (parseError) {
          throw Exception(
            'Error al parsear platos: $parseError. Respuesta: ${response.body}',
          );
        }
      } else {
        throw Exception(
          'Error al obtener platos: ${response.statusCode} - ${response.body}',
        );
      }
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_establecimiento': idEstablecimiento,
          'nombre_tipo': nombreTipo,
        }),
      );

      if (response.statusCode == 201) {
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          return TipoItemMenu.fromJson(jsonData);
        } catch (e) {
          throw Exception('Error al parsear respuesta del servidor: $e. Respuesta: ${response.body}');
        }
      } else {
        throw Exception('Error al crear sección: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al crear sección: $e');
    }
  }

  /// Crea un nuevo plato.
  static Future<ItemMenu> crearPlato(
    int idEstablecimiento,
    String nombreItemMenu,
    double precio,
    int? idTipoItemMenu, {
    String? descripcion,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/item_menu/');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_establecimiento': idEstablecimiento,
          'nombre_item_menu': nombreItemMenu,
          'descripcion': descripcion,
          'precio': precio,
          'id_tipo_item_menu': idTipoItemMenu,
        }),
      );

      if (response.statusCode == 201) {
        try {
          final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
          return ItemMenu.fromJson(jsonData);
        } catch (e) {
          throw Exception('Error al parsear respuesta del servidor: $e. Respuesta: ${response.body}');
        }
      } else {
        throw Exception('Error al crear plato: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al crear plato: $e');
    }
  }
}
