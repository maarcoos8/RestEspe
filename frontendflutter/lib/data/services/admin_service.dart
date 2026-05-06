import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/categoria_dieta_model.dart';
import '../models/tipo_establecimiento_model.dart';
import '../../core/constants.dart';

/// Servicio para obtener datos de administración de la aplicación.
class AdminService {
  /// Obtiene la lista de categorías de dieta.
  static Future<List<CategoriaDieta>> getCategoriasDieta() async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/categoria_dieta/');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList.map((json) => CategoriaDieta.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Error al obtener categorías de dieta: ${response.statusCode}');
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
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList.map((json) => TipoEstablecimiento.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Error al obtener tipos de establecimiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener tipos de establecimiento: $e');
    }
  }

  /// Crea una nueva categoría de dieta.
  static Future<void> createCategoriaDieta(String nombreDieta) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/categoria_dieta/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre_dieta': nombreDieta}),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear categoría de dieta: ${response.statusCode}');
    }
  }

  /// Elimina una categoría de dieta por id.
  static Future<void> deleteCategoriaDieta(int id) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/categoria_dieta/$id');
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar categoría de dieta: $id (status: ${response.statusCode})');
    }
  }

  /// Actualiza una categoría de dieta.
  static Future<void> updateCategoriaDieta(int id, String nombreDieta) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/categoria_dieta/$id');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre_dieta': nombreDieta}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar categoría de dieta: $id (status: ${response.statusCode})');
    }
  }

  /// Crea un nuevo tipo de establecimiento.
  static Future<void> createTipoEstablecimiento(String nombreCategoria) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/tipo_establecimiento/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre_categoria': nombreCategoria}),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear tipo de establecimiento: ${response.statusCode}');
    }
  }

  /// Elimina un tipo de establecimiento por id.
  static Future<void> deleteTipoEstablecimiento(int id) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/tipo_establecimiento/$id');
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar tipo de establecimiento: $id (status: ${response.statusCode})');
    }
  }

  /// Actualiza un tipo de establecimiento.
  static Future<void> updateTipoEstablecimiento(int id, String nombreCategoria) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/tipo_establecimiento/$id');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre_categoria': nombreCategoria}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar tipo de establecimiento: $id (status: ${response.statusCode})');
    }
  }
}
