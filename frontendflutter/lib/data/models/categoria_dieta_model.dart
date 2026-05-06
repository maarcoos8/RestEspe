/// Modelo para Categoría de Dieta.
class CategoriaDieta {
  final int idCategoria;
  final String nombreDieta;

  CategoriaDieta({
    required this.idCategoria,
    required this.nombreDieta,
  });

  /// Convierte un JSON en un objeto CategoriaDieta.
  factory CategoriaDieta.fromJson(Map<String, dynamic> json) {
    return CategoriaDieta(
      idCategoria: json['id_categoria'] as int,
      nombreDieta: json['nombre_dieta'] as String,
    );
  }

  /// Convierte el objeto en JSON.
  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nombre_dieta': nombreDieta,
    };
  }
}
