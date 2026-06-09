import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/review_model.dart';
import 'image_upload_service.dart';
import '../../core/constants.dart';
import '../../core/auth_token_store.dart';

/// Servicio para obtener reseñas de un establecimiento.
class ReviewService {
  final String baseUrl = AppConstants.apiBaseUrl;

  /// Obtiene reseñas de un establecimiento con paginación.
  /// El backend devuelve ordenadas por fecha descendente.
  Future<List<ReviewModel>> getEstablishmentReviews(
    int idEstablecimiento, {
    int skip = 0,
    int limit = 5,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/resena/establecimiento/$idEstablecimiento?skip=$skip&limit=$limit',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      print('Error obteniendo reseñas: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error en getEstablishmentReviews: $e');
      return [];
    }
  }

  /// Crea una nueva reseña. Si se proporciona `imageFile`, sube la imagen primero
  /// y añade la `url_imagen` en el cuerpo.
  Future<ReviewModel?> createReview({
    required int idEstablecimiento,
    required int idUsuario,
    required double puntuacion,
    String? comentario,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        final imageService = ImageUploadService(baseUrl: baseUrl);
        imageUrl = await imageService.uploadImageUrlOnly(
          imageFile: imageFile,
          useCase: 'resena',
        );
      }

      final uri = Uri.parse('$baseUrl/resena/');
      final body = {
        'id_usuario': idUsuario,
        'id_establecimiento': idEstablecimiento,
        'puntuacion': puntuacion,
        if (comentario != null) 'comentario': comentario,
        if (imageUrl != null) 'url_imagen': imageUrl,
      };

      final resp = await http
          .post(
            uri,
            headers: AuthTokenStore.withAuth({
              'Content-Type': 'application/json',
            }),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final Map<String, dynamic> parsed =
            jsonDecode(resp.body) as Map<String, dynamic>;
        return ReviewModel.fromJson(parsed);
      }

      throw Exception(
        'Error creando reseña (${resp.statusCode}): ${resp.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina una reseña por su id.
  Future<bool> deleteReview(int idResena) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/resena/$idResena'),
            headers: AuthTokenStore.withAuth(const {}),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error eliminando reseña: $e');
      return false;
    }
  }
}
