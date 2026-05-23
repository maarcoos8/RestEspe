/// Modelo para una reseña de un establecimiento.
class ReviewModel {
  const ReviewModel({
    required this.idResena,
    required this.idUsuario,
    required this.idEstablecimiento,
    required this.puntuacion,
    required this.comentario,
    required this.urlImagen,
    required this.fechaPublicacion,
    this.nombreUsuario,
    this.fotoPerfil,
  });

  final int idResena;
  final int idUsuario;
  final int idEstablecimiento;
  final double puntuacion;
  final String? comentario;
  final String? urlImagen;
  final DateTime fechaPublicacion;
  final String? nombreUsuario;
  final String? fotoPerfil;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      idResena: json['id_resena'] as int,
      idUsuario: json['id_usuario'] as int,
      idEstablecimiento: json['id_establecimiento'] as int,
      puntuacion: (json['puntuacion'] as num).toDouble(),
      comentario: json['comentario'] as String?,
      urlImagen: json['url_imagen'] as String?,
      fechaPublicacion: DateTime.parse(json['fecha_publicacion'] as String),
      nombreUsuario: json['nombre_usuario'] as String?,
      fotoPerfil: json['foto_perfil'] as String?,
    );
  }

  /// Copia el modelo con valores opcionales nuevos.
  ReviewModel copyWith({
    int? idResena,
    int? idUsuario,
    int? idEstablecimiento,
    double? puntuacion,
    String? comentario,
    String? urlImagen,
    DateTime? fechaPublicacion,
    String? nombreUsuario,
    String? fotoPerfil,
  }) {
    return ReviewModel(
      idResena: idResena ?? this.idResena,
      idUsuario: idUsuario ?? this.idUsuario,
      idEstablecimiento: idEstablecimiento ?? this.idEstablecimiento,
      puntuacion: puntuacion ?? this.puntuacion,
      comentario: comentario ?? this.comentario,
      urlImagen: urlImagen ?? this.urlImagen,
      fechaPublicacion: fechaPublicacion ?? this.fechaPublicacion,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
    );
  }
}
