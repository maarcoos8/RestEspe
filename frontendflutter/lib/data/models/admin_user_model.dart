/// Modelo para un usuario en administración.
class AdminUserModel {
  final int idUsuario;
  final String email;
  final String? nombreCompleto;
  final String? fotoPerfil;
  final int? idRol;

  AdminUserModel({
    required this.idUsuario,
    required this.email,
    this.nombreCompleto,
    this.fotoPerfil,
    this.idRol,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      idUsuario: json['id_usuario'] as int,
      email: json['email'] as String,
      nombreCompleto: json['nombre_completo'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
      idRol: json['id_rol'] as int?,
    );
  }
}
