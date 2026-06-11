/// Modelo para un establecimiento en la pantalla de administración.
class AdminEstablishmentModel {
  final int idEstablecimiento;
  final String nombre;
  final String? direccionTexto;
  final String? imagenUrl;
  final double? latitud;
  final double? longitud;
  final bool estadoVerificado;
  final DateTime? ultimaVerificacion;
  final int? verificadorId;
  final int? responsableId;
  final double? puntuacionMedia;

  AdminEstablishmentModel({
    required this.idEstablecimiento,
    required this.nombre,
    required this.direccionTexto,
    required this.imagenUrl,
    required this.latitud,
    required this.longitud,
    required this.estadoVerificado,
    required this.ultimaVerificacion,
    required this.verificadorId,
    required this.puntuacionMedia,
    this.responsableId,
  });

  factory AdminEstablishmentModel.fromJson(Map<String, dynamic> json) {
    return AdminEstablishmentModel(
      idEstablecimiento: json['id_establecimiento'] as int,
      nombre: json['nombre'] as String,
      direccionTexto: json['direccion_texto'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      estadoVerificado: json['estado_verificado'] as bool? ?? false,
      ultimaVerificacion: json['ultima_verificacion'] != null
          ? DateTime.tryParse(json['ultima_verificacion'] as String)
          : null,
      verificadorId: json['verificador_id'] as int?,
      responsableId: json['responsable_id'] as int?,
      puntuacionMedia: (json['puntuacion_media'] as num?)?.toDouble(),
    );
  }
}
