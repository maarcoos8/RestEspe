import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/auth_token_store.dart';

class ImageUploadService {
  final String baseUrl;

  ImageUploadService({required this.baseUrl});

  /// Valida que el archivo de imagen sea válido.
  /// Comprueba que existe y que tiene un tamaño razonable.
  static Future<String?> validateImageFile(File imageFile) async {
    try {
      // Verificar que el archivo existe
      if (!await imageFile.exists()) {
        return 'El archivo de imagen no existe o fue eliminado.';
      }

      // Verificar tamaño (máximo 10 MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return 'La imagen es demasiado grande (máximo 10 MB).';
      }

      // Verificar que es un formato válido (por extensión)
      final path = imageFile.path.toLowerCase();
      if (!path.endsWith('.jpg') &&
          !path.endsWith('.jpeg') &&
          !path.endsWith('.png') &&
          !path.endsWith('.gif') &&
          !path.endsWith('.webp')) {
        return 'Formato de imagen no válido. Usa JPG, PNG, GIF o WebP.';
      }

      return null; // Sin errores
    } catch (e) {
      return 'Error validando imagen: $e';
    }
  }

  /// Sube una imagen al backend. Devuelve la URL de la imagen en caso de éxito.
  ///
  /// Este método crea directamente un registro en tabla `fotografia`.
  Future<String> uploadImage({
    required File imageFile,
    required int idEstablecimiento,
    required int idUsuario,
  }) async {
    // Validar el archivo
    final validationError = await validateImageFile(imageFile);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final uri = Uri.parse('$baseUrl/fotografia/upload');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthTokenStore.withAuth(const {}));
      request.fields['id_establecimiento'] = idEstablecimiento.toString();
      request.fields['id_usuario'] = idUsuario.toString();

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 201) {
        // Respuesta esperada: objeto FotografiaOut en JSON, contiene `url_imagen`
        final body = resp.body;
        try {
          final Map<String, dynamic> parsed =
              jsonDecode(body) as Map<String, dynamic>;
          return parsed['url_imagen'] as String;
        } catch (e) {
          throw Exception('Error procesando respuesta del servidor: $e');
        }
      }

      // Manejo básico de errores
      throw Exception(
        'Error subiendo imagen (${resp.statusCode}): ${_extractErrorMessage(resp.body)}',
      );
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Sube una imagen al endpoint genérico de media y devuelve la URL.
  ///
  /// Útil para usar Cloudinary con:
  /// - `Establecimiento.imagen_url`
  /// - `Resena.url_imagen`
  /// - `Fotografia.url_imagen` (si se quiere flujo de 2 pasos)
  Future<String> uploadImageUrlOnly({
    required File imageFile,
    required String useCase,
  }) async {
    // Validar el archivo
    final validationError = await validateImageFile(imageFile);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final uri = Uri.parse('$baseUrl/media/upload-image?use_case=$useCase');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(AuthTokenStore.withAuth(const {}));
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 201) {
        try {
          final Map<String, dynamic> parsed =
              jsonDecode(resp.body) as Map<String, dynamic>;
          return parsed['image_url'] as String;
        } catch (e) {
          throw Exception('Error procesando respuesta del servidor: $e');
        }
      }

      throw Exception(
        'Error subiendo imagen (${resp.statusCode}): ${_extractErrorMessage(resp.body)}',
      );
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Extrae el mensaje de error de una respuesta JSON si es posible.
  static String _extractErrorMessage(String? responseBody) {
    if (responseBody == null || responseBody.isEmpty) {
      return 'Respuesta vacía del servidor';
    }
    try {
      final Map<String, dynamic> parsed =
          jsonDecode(responseBody) as Map<String, dynamic>;
      if (parsed['detail'] != null) {
        return parsed['detail'].toString();
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
