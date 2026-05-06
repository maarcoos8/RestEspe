/// Modelo para Tipo de Establecimiento.
class TipoEstablecimiento {
  final int idTipoEstablecimiento;
  final String nombreCategoria;

  TipoEstablecimiento({
    required this.idTipoEstablecimiento,
    required this.nombreCategoria,
  });

  /// Convierte un JSON en un objeto TipoEstablecimiento.
  factory TipoEstablecimiento.fromJson(Map<String, dynamic> json) {
    return TipoEstablecimiento(
      idTipoEstablecimiento: json['id_tipo_establecimiento'] as int,
      nombreCategoria: json['nombre_categoria'] as String,
    );
  }

  /// Convierte el objeto en JSON.
  Map<String, dynamic> toJson() {
    return {
      'id_tipo_establecimiento': idTipoEstablecimiento,
      'nombre_categoria': nombreCategoria,
    };
  }
}
