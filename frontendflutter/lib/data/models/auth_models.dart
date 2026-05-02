class GoogleUserProfile {
  final int idUsuario;
  final String email;
  final String? nombreCompleto;
  final String? fotoPerfil;
  final int? idRol;

  const GoogleUserProfile({
    required this.idUsuario,
    required this.email,
    this.nombreCompleto,
    this.fotoPerfil,
    this.idRol,
  });

  factory GoogleUserProfile.fromJson(Map<String, dynamic> json) {
    return GoogleUserProfile(
      idUsuario: json['id_usuario'] as int,
      email: json['email'] as String,
      nombreCompleto: json['nombre_completo'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
      idRol: json['id_rol'] as int?,
    );
  }
}