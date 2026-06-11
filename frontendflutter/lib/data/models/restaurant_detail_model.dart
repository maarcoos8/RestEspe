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
    this.responsableId,
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
  final int? responsableId;
}

/// Categoría de dieta de un restaurante.
class DietaCategory {
  const DietaCategory({
    required this.idCategoria,
    required this.nombreDieta,
    required this.colorHex,
    this.cantidadPlatos,
    this.totalPlatos,
  });

  final int idCategoria;
  final String nombreDieta;
  final String colorHex;
  final int? cantidadPlatos;
  final int? totalPlatos;

  String get etiquetaConConteo {
    if (cantidadPlatos != null && totalPlatos != null) {
      return '$nombreDieta $cantidadPlatos/$totalPlatos';
    }
    return nombreDieta;
  }

  factory DietaCategory.fromJson(Map<String, dynamic> json) {
    final cantidadPlatos = (json['cantidad_platos'] as num?)?.toInt();
    final totalPlatos = (json['total_platos'] as num?)?.toInt();
    final nombreDieta = json['nombre_dieta'] as String;

    return DietaCategory(
      idCategoria: json['id_categoria'] as int,
      nombreDieta: nombreDieta,
      cantidadPlatos: cantidadPlatos,
      totalPlatos: totalPlatos,
      colorHex: json['color_hex'] as String? ?? '#FF6B6B',
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