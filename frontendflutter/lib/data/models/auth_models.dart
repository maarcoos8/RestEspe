class GoogleUserProfile {
  final int idUsuario;
  final String email;
  final String? nombreCompleto;
  final String? fotoPerfil;
  final int? idRol;
  final String? idToken;

  const GoogleUserProfile({
    required this.idUsuario,
    required this.email,
    this.nombreCompleto,
    this.fotoPerfil,
    this.idRol,
    this.idToken,
  });

  factory GoogleUserProfile.fromJson(Map<String, dynamic> json) {
    return GoogleUserProfile(
      idUsuario: json['id_usuario'] as int,
      email: json['email'] as String,
      nombreCompleto: json['nombre_completo'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
      idRol: json['id_rol'] as int?,
      idToken: json['id_token'] as String?,
    );
  }

  GoogleUserProfile copyWith({
    int? idUsuario,
    String? email,
    String? nombreCompleto,
    String? fotoPerfil,
    int? idRol,
    String? idToken,
  }) {
    return GoogleUserProfile(
      idUsuario: idUsuario ?? this.idUsuario,
      email: email ?? this.email,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      idRol: idRol ?? this.idRol,
      idToken: idToken ?? this.idToken,
    );
  }
}
