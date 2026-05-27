import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/photography_model.dart';
import '../../core/constants.dart';

/// Servicio para gestionar fotografías de establecimientos.
class PhotographyService {
  final String baseUrl = AppConstants.apiBaseUrl;

  /// Obtiene todas las fotografías de un establecimiento.
  Future<List<PhotographyModel>> getPhotographiesByEstablishment(
    int idEstablecimiento,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fotografia/establecimiento/$idEstablecimiento'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .cast<Map<String, dynamic>>()
            .map((json) => PhotographyModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error obteniendo fotografías: $e');
      return [];
    }
  }

  /// Obtiene una fotografía por su ID.
  Future<PhotographyModel?> getPhotography(int idFoto) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fotografia/$idFoto'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return PhotographyModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error obteniendo fotografía: $e');
      return null;
    }
  }

  /// Elimina una fotografía por su ID.
  /// Requiere el ID del usuario autenticado para validación de permisos.
  Future<bool> deletePhotography(int idFoto, int idUsuario) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/fotografia/$idFoto?id_usuario=$idUsuario'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para eliminar esta fotografía');
      } else if (response.statusCode == 404) {
        throw Exception('La fotografía no existe');
      } else {
        throw Exception('Error al eliminar la fotografía: ${response.statusCode}');
      }
    } catch (e) {
      print('Error eliminando fotografía: $e');
      rethrow;
    }
  }
}

