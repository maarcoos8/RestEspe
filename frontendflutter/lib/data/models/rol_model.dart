/// Modelo para un rol.
class RolModel {
  final int idRol;
  final String nombreRol;

  RolModel({
    required this.idRol,
    required this.nombreRol,
  });

  factory RolModel.fromJson(Map<String, dynamic> json) {
    return RolModel(
      idRol: json['id_rol'] as int,
      nombreRol: json['nombre_rol'] as String,
    );
  }
}
