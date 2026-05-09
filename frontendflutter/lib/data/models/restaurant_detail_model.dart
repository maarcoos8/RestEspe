import 'package:latlong2/latlong.dart';

/// Modelo para los detalles completos de un restaurante.
class RestaurantDetail {
  const RestaurantDetail({
    required this.idEstablecimiento,
    required this.nombre,
    required this.direccionTexto,
    required this.coordinates,
    required this.estadoVerificado,
    required this.ultimaVerificacion,
    required this.verificadorId,
    required this.categoriasDieta,
    required this.tiposEstablecimiento,
    required this.puntuacionMedia,
    required this.numeroResenas,
    this.imagenUrl,
  });

  final int idEstablecimiento;
  final String nombre;
  final String? direccionTexto;
  final LatLng? coordinates;
  final bool? estadoVerificado;
  final DateTime? ultimaVerificacion;
  final int? verificadorId;
  final List<DietaCategory> categoriasDieta;
  final List<RestaurantType> tiposEstablecimiento;
  final double? puntuacionMedia;
  final int numeroResenas;
  final String? imagenUrl;
}

/// Categoría de dieta de un restaurante.
class DietaCategory {
  const DietaCategory({
    required this.idCategoria,
    required this.nombreDieta,
  });

  final int idCategoria;
  final String nombreDieta;

  factory DietaCategory.fromJson(Map<String, dynamic> json) {
    return DietaCategory(
      idCategoria: json['id_categoria'] as int,
      nombreDieta: json['nombre_dieta'] as String,
    );
  }
}

/// Tipo de establecimiento (ej: hamburguesería, pizzería, etc).
class RestaurantType {
  const RestaurantType({
    required this.idTipo,
    required this.nombreCategoria,
  });

  final int idTipo;
  final String nombreCategoria;

  factory RestaurantType.fromJson(Map<String, dynamic> json) {
    return RestaurantType(
      idTipo: json['id_tipo_establecimiento'] as int,
      nombreCategoria: json['nombre_categoria'] as String,
    );
  }
}
