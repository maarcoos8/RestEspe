/// Modelo DTO para el formulario de creación de establecimiento.
class CreateEstablishmentForm {
  String nombre;
  String? direccionTexto;
  String? imagenUrl;
  double? latitud;
  double? longitud;
  List<int> tiposEstablecimientoIds;

  CreateEstablishmentForm({
    required this.nombre,
    this.direccionTexto,
    this.imagenUrl,
    this.latitud,
    this.longitud,
    this.tiposEstablecimientoIds = const [],
  });

  /// Convierte a JSON para enviar al backend.
  /// Estado verificado siempre es false por defecto.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'direccion_texto': direccionTexto,
      'imagen_url': imagenUrl,
      'latitud': latitud,
      'longitud': longitud,
      'estado_verificado': false,
    };
  }

  /// Verifica si el formulario es válido (campos requeridos llenos).
  bool isValid() {
    return nombre.isNotEmpty && imagenUrl != null && latitud != null && longitud != null;
  }
}
