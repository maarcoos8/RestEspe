/// Modelo para Categoría de Dieta.
class CategoriaDieta {
  final int idCategoria;
  final String nombreDieta;
  final String colorHex;

  CategoriaDieta({
    required this.idCategoria,
    required this.nombreDieta,
    required this.colorHex,
  });

  /// Convierte un JSON en un objeto CategoriaDieta.
  factory CategoriaDieta.fromJson(Map<String, dynamic> json) {
    return CategoriaDieta(
      idCategoria: json['id_categoria'] as int,
      nombreDieta: json['nombre_dieta'] as String,
      colorHex: json['color_hex'] as String? ?? '#FF6B6B',
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
