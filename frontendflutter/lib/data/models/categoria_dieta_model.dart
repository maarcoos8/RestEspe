/// Modelo para Categoría de Dieta.
class CategoriaDieta {
  final int idCategoria;
  final String nombreDieta;
  final String colorHex;
  final int? cantidadPlatos;
  final int? totalPlatos;

  CategoriaDieta({
    required this.idCategoria,
    required this.nombreDieta,
    required this.colorHex,
    this.cantidadPlatos,
    this.totalPlatos,
  });

  /// Etiqueta lista para UI: "vegano 4/5" si hay conteos disponibles.
  String get etiquetaConConteo {
    if (cantidadPlatos != null && totalPlatos != null) {
      return '$nombreDieta $cantidadPlatos/$totalPlatos';
    }
    return nombreDieta;
  }

  /// Convierte un JSON en un objeto CategoriaDieta.
  factory CategoriaDieta.fromJson(Map<String, dynamic> json) {
    return CategoriaDieta(
      idCategoria: json['id_categoria'] as int,
      nombreDieta: json['nombre_dieta'] as String,
      colorHex: json['color_hex'] as String? ?? '#FF6B6B',
      cantidadPlatos: (json['cantidad_platos'] as num?)?.toInt(),
      totalPlatos: (json['total_platos'] as num?)?.toInt(),
    );
  }

  /// Convierte el objeto en JSON.
  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nombre_dieta': nombreDieta,
      'color_hex': colorHex,
    };
  }
}
