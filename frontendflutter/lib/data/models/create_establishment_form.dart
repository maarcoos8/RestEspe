/// Modelo DTO para el formulario de creación de establecimiento.
class CreateEstablishmentForm {
  String nombre;
  String contacto;
  String? direccionTexto;
  String? imagenUrl;
  double? latitud;
  double? longitud;
  List<int> tiposEstablecimientoIds;
  int? responsableId;

  CreateEstablishmentForm({
    required this.nombre,
    required this.contacto,
    this.direccionTexto,
    this.imagenUrl,
    this.latitud,
    this.longitud,
    this.tiposEstablecimientoIds = const [],
    this.responsableId,
  });

  /// Convierte a JSON para enviar al backend.
  /// Estado verificado siempre es false por defecto.
  Map<String, dynamic> toJson() {
    final json = {
      'nombre': nombre,
      'contacto': contacto,
      'direccion_texto': direccionTexto,
      'imagen_url': imagenUrl,
      'latitud': latitud,
      'longitud': longitud,
      'estado_verificado': false,
    };
    if (responsableId != null) {
      json['responsable_id'] = responsableId;
    }
    return json;
  }

  /// Verifica si el formulario es válido (campos requeridos llenos).
  bool isValid() {
    return nombre.isNotEmpty &&
        contacto.isNotEmpty &&
        imagenUrl != null &&
        latitud != null &&
        longitud != null;
  }
}
