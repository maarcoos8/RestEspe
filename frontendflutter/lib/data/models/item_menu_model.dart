/// Modelo para un plato del menú.
class ItemMenu {
  final int idItemMenu;
  final String nombreItemMenu;
  final String? descripcion;
  final double precio;
  final int idEstablecimiento;
  final int? idTipoItemMenu;

  ItemMenu({
    required this.idItemMenu,
    required this.nombreItemMenu,
    this.descripcion,
    required this.precio,
    required this.idEstablecimiento,
    this.idTipoItemMenu,
  });

  /// Convierte un JSON en un objeto ItemMenu.
  factory ItemMenu.fromJson(Map<String, dynamic> json) {
    try {
      // Obtener precio de forma robusta
      final precioValue = json['precio'];
      final precio = precioValue is num
          ? precioValue.toDouble()
          : double.parse(precioValue.toString());

      // Obtener descripción de forma segura
      final descripcion = json['descripcion'] as String?;

      // Obtener id_tipo_item_menu de forma segura (puede ser null)
      final idTipoItemMenuValue = json['id_tipo_item_menu'];
      final idTipoItemMenu = idTipoItemMenuValue is int?
          ? idTipoItemMenuValue
          : (idTipoItemMenuValue != null
              ? int.parse(idTipoItemMenuValue.toString())
              : null);

      return ItemMenu(
        idItemMenu: json['id_item_menu'] as int,
        nombreItemMenu: json['nombre_item_menu'] as String,
        descripcion: descripcion,
        precio: precio,
        idEstablecimiento: json['id_establecimiento'] as int,
        idTipoItemMenu: idTipoItemMenu,
      );
    } catch (e) {
      throw Exception(
        'Error al deserializar ItemMenu: $e. JSON: $json',
      );
    }
  }

  /// Convierte el objeto en JSON.
  Map<String, dynamic> toJson() {
    return {
      'id_item_menu': idItemMenu,
      'nombre_item_menu': nombreItemMenu,
      'descripcion': descripcion,
      'precio': precio,
      'id_establecimiento': idEstablecimiento,
      'id_tipo_item_menu': idTipoItemMenu,
    };
  }
}
