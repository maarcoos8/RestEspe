import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageUploadService {
  final String baseUrl;

  ImageUploadService({required this.baseUrl});

  /// Sube una imagen al backend. Devuelve la URL de la imagen en caso de éxito.
  ///
  /// Este método crea directamente un registro en tabla `fotografia`.
  Future<String> uploadImage({
    required File imageFile,
    required int idEstablecimiento,
    required int idUsuario,
  }) async {
    final uri = Uri.parse('$baseUrl/fotografia/upload');

    final request = http.MultipartRequest('POST', uri);
    request.fields['id_establecimiento'] = idEstablecimiento.toString();
    request.fields['id_usuario'] = idUsuario.toString();

    final multipartFile = await http.MultipartFile.fromPath('file', imageFile.path);
    request.files.add(multipartFile);

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 201) {
      // Respuesta esperada: objeto FotografiaOut en JSON, contiene `url_imagen`
      final body = resp.body;
      // Extraer url_imagen de forma simple (sin dep parser para POC)
      // Se recomienda usar jsonDecode y modelar la respuesta en producción.
      try {
        final Map<String, dynamic> parsed = jsonDecode(body) as Map<String, dynamic>;
        return parsed['url_imagen'] as String;
      } catch (e) {
        throw Exception('Error parseando respuesta del servidor: $e');
      }
    }

    // Manejo básico de errores
    throw Exception('Error subiendo imagen: ${resp.statusCode} - ${resp.body}');
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
    final uri = Uri.parse('$baseUrl/media/upload-image?use_case=$useCase');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 201) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(resp.body) as Map<String, dynamic>;
        return parsed['image_url'] as String;
      } catch (e) {
        throw Exception('Error parseando respuesta del servidor: $e');
      }
    }

    throw Exception('Error subiendo imagen: ${resp.statusCode} - ${resp.body}');
  }

}
