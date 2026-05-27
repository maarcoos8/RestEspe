/// Modelo para una fotografía de un establecimiento.
class PhotographyModel {
  const PhotographyModel({
    required this.idFoto,
    required this.idEstablecimiento,
    required this.idUsuario,
    required this.urlImagen,
    required this.fechaSubida,
    this.nombreUsuario,
    this.fotoPerfil,
  });

  final int idFoto;
  final int idEstablecimiento;
  final int idUsuario;
  final String urlImagen;
  final DateTime fechaSubida;
  final String? nombreUsuario;
  final String? fotoPerfil;

  factory PhotographyModel.fromJson(Map<String, dynamic> json) {
    return PhotographyModel(
      idFoto: json['id_foto'] as int,
      idEstablecimiento: json['id_establecimiento'] as int,
      idUsuario: json['id_usuario'] as int,
      urlImagen: json['url_imagen'] as String,
      fechaSubida: DateTime.parse(json['fecha_subida'] as String),
      nombreUsuario: json['nombre_usuario'] as String?,
      fotoPerfil: json['foto_perfil'] as String?,
    );
  }

  /// Copia el modelo con valores opcionales nuevos.
  PhotographyModel copyWith({
    int? idFoto,
    int? idEstablecimiento,
    int? idUsuario,
    String? urlImagen,
    DateTime? fechaSubida,
    String? nombreUsuario,
    String? fotoPerfil,
  }) {
    return PhotographyModel(
      idFoto: idFoto ?? this.idFoto,
      idEstablecimiento: idEstablecimiento ?? this.idEstablecimiento,
      idUsuario: idUsuario ?? this.idUsuario,
      urlImagen: urlImagen ?? this.urlImagen,
      fechaSubida: fechaSubida ?? this.fechaSubida,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
    );
  }
}
