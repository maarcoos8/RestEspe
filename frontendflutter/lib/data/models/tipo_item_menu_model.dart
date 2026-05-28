/// Modelo para una sección (tipo) del menú.
class TipoItemMenu {
  final int idTipoItem;
  final int idEstablecimiento;
  final String nombreTipo;

  TipoItemMenu({
    required this.idTipoItem,
    required this.idEstablecimiento,
    required this.nombreTipo,
  });

  /// Convierte un JSON en un objeto TipoItemMenu.
  factory TipoItemMenu.fromJson(Map<String, dynamic> json) {
    try {
      return TipoItemMenu(
        idTipoItem: json['id_tipo_item'] as int,
        idEstablecimiento: json['id_establecimiento'] as int,
        nombreTipo: json['nombre_tipo'] as String,
      );
    } catch (e) {
      throw Exception(
        'Error al deserializar TipoItemMenu: $e. JSON: $json',
      );
    }
  }

  /// Convierte el objeto en JSON.
  Map<String, dynamic> toJson() {
    return {
      'id_tipo_item': idTipoItem,
      'id_establecimiento': idEstablecimiento,
      'nombre_tipo': nombreTipo,
    };
  }
}
