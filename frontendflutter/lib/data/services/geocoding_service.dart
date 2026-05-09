import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Modelo para una sugerencia de ubicación
class LocationSuggestion {
  final int placeId;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? addressType;

  LocationSuggestion({
    required this.placeId,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.addressType,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      placeId: json['place_id'] as int? ?? 0,
      displayName: json['display_name'] as String? ?? '',
      latitude: double.tryParse(json['lat'] as String? ?? '0') ?? 0.0,
      longitude: double.tryParse(json['lon'] as String? ?? '0') ?? 0.0,
      addressType: json['type'] as String?,
    );
  }
}

/// Modelo para información de dirección inversa
class ReverseGeocodeResult {
  final String displayName;
  final String? road;
  final String? houseNumber;
  final String? city;
  final String? postalCode;
  final String? country;

  ReverseGeocodeResult({
    required this.displayName,
    this.road,
    this.houseNumber,
    this.city,
    this.postalCode,
    this.country,
  });

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    return ReverseGeocodeResult(
      displayName: json['display_name'] as String? ?? '',
      road: address['road'] as String?,
      houseNumber: address['house_number'] as String?,
      city: address['city'] as String? ?? address['town'] as String?,
      postalCode: address['postcode'] as String?,
      country: address['country'] as String?,
    );
  }

  String get formattedAddress {
    final parts = <String>[];
    if (road != null && houseNumber != null) {
      parts.add('$road $houseNumber');
    } else if (road != null) {
      parts.add(road!);
    }
    if (city != null) parts.add(city!);
    if (postalCode != null) parts.add(postalCode!);
    return parts.join(', ');
  }
}

/// Servicio para geocodificación usando Nominatim (OpenStreetMap)
class GeocodingService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'RestEspeApp/1.0';

  /// Busca ubicaciones basadas en un texto de búsqueda
  static Future<List<LocationSuggestion>> searchLocations(
    String query, {
    double? latitude,
    double? longitude,
    double searchRadius = 50000, // metros
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, String>{
        'q': query,
        'format': 'json',
        'limit': '5',
      };

      // Si tenemos ubicación actual, hacer búsqueda cercana
      if (latitude != null && longitude != null) {
        params['lat'] = latitude.toString();
        params['lon'] = longitude.toString();
      }

      final uri = Uri.parse('$_nominatimBaseUrl/search').replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        return jsonList
            .map((json) => LocationSuggestion.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error en geocodificación de búsqueda: $e');
      return [];
    }
  }

  /// Obtiene información de dirección a partir de coordenadas (reverse geocode)
  static Future<ReverseGeocodeResult?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final params = <String, String>{
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'zoom': '18',
        'addressdetails': '1',
      };

      final uri = Uri.parse('$_nominatimBaseUrl/reverse').replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ReverseGeocodeResult.fromJson(json);
      }

      return null;
    } catch (e) {
      print('Error en geocodificación inversa: $e');
      return null;
    }
  }
}
