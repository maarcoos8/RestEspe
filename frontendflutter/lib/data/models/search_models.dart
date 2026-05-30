import 'package:latlong2/latlong.dart';

class SearchLocationResult {
  const SearchLocationResult({
    required this.displayName,
    required this.coordinates,
  });

  final String displayName;
  final LatLng coordinates;
}

class SearchRestaurantResult {
  const SearchRestaurantResult({
    required this.idEstablecimiento,
    required this.nombre,
    required this.direccionTexto,
    required this.latitud,
    required this.longitud,
    required this.estadoVerificado,
    required this.ultimaVerificacion,
    required this.verificadorId,
  });

  final int idEstablecimiento;
  final String nombre;
  final String? direccionTexto;
  final double? latitud;
  final double? longitud;
  final bool? estadoVerificado;
  final DateTime? ultimaVerificacion;
  final int? verificadorId;

  LatLng? get coordinates {
    if (latitud == null || longitud == null) {
      return null;
    }
    return LatLng(latitud!, longitud!);
  }
}

class RestaurantMapFilters {
  const RestaurantMapFilters({
    this.selectedDietIds = const [],
    this.selectedTypeIds = const [],
    this.onlyVerified = false,
    this.minimumRating,
  });

  final List<int> selectedDietIds;
  final List<int> selectedTypeIds;
  final bool onlyVerified;
  final double? minimumRating;

  bool get hasActiveFilters =>
      selectedDietIds.isNotEmpty ||
      selectedTypeIds.isNotEmpty ||
      onlyVerified ||
      minimumRating != null;

  RestaurantMapFilters copyWith({
    List<int>? selectedDietIds,
    List<int>? selectedTypeIds,
    bool? onlyVerified,
    double? minimumRating,
  }) {
    return RestaurantMapFilters(
      selectedDietIds: selectedDietIds ?? this.selectedDietIds,
      selectedTypeIds: selectedTypeIds ?? this.selectedTypeIds,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      minimumRating: minimumRating ?? this.minimumRating,
    );
  }
}

class DietCategory {
  const DietCategory({required this.idCategoria, required this.nombreDieta});

  final int idCategoria;
  final String nombreDieta;
}

class MapFocusRequest {
  const MapFocusRequest({
    required this.coordinates,
    required this.zoom,
    required this.token,
    this.establishmentId,
  });

  final LatLng coordinates;
  final double zoom;
  final int? establishmentId;
  final int token;
}
