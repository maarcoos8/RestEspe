import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/search_models.dart';
import '../data/services/search_service.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider({SearchService? service})
    : _service = service ?? SearchService();

  final SearchService _service;
  Timer? _debounceTimer;

  String _query = '';
  bool _isLoading = false;
  List<SearchLocationResult> _locations = const [];
  List<SearchRestaurantResult> _restaurants = const [];
  List<SearchRestaurantResult> _visibleRestaurants = const [];
  RestaurantMapFilters _filters = RestaurantMapFilters();
  MapFocusRequest? _focusRequest;
  LatLng? _referencePoint;
  LatLngBounds? _viewportBounds;
  int _focusToken = 0;
  int _searchGeneration = 0;
  int _viewportGeneration = 0;
  final Distance _distance = const Distance();
  Timer? _viewportDebounceTimer;

  String get query => _query;
  bool get isLoading => _isLoading;
  List<SearchLocationResult> get locations => _locations;
  List<SearchRestaurantResult> get restaurants => _restaurants;
  List<SearchRestaurantResult> get visibleRestaurants => _visibleRestaurants;
  RestaurantMapFilters get filters => _filters;
  MapFocusRequest? get focusRequest => _focusRequest;

  bool get hasResults => _locations.isNotEmpty || _restaurants.isNotEmpty;
  bool get hasActiveFilters => _filters.hasActiveFilters;

  void updateReferencePoint(LatLng point) {
    final previous = _referencePoint;
    if (previous != null) {
      final deltaMeters = _distance.as(LengthUnit.Meter, previous, point);
      if (deltaMeters < 50) {
        return;
      }
    }

    _referencePoint = point;
    if (_locations.isEmpty && _restaurants.isEmpty) {
      return;
    }

    _sortResultsByProximity();
    notifyListeners();
  }

  void updateViewportBounds(LatLngBounds bounds) {
    _viewportBounds = bounds;
    _viewportDebounceTimer?.cancel();
    _viewportDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_runViewportFetch(bounds));
    });
  }

  void applyFilters(RestaurantMapFilters filters) {
    _filters = filters;
    _searchGeneration++;
    _viewportGeneration++;
    notifyListeners();
    _refreshFilteredResults();
  }

  void clearFilters() {
    applyFilters(RestaurantMapFilters());
  }

  void onQueryChanged(String value) {
    _query = value;
    _debounceTimer?.cancel();

    if (_query.trim().isEmpty) {
      _clearResults();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_runSearch(_query));
    });
    notifyListeners();
  }

  Future<void> _runSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return;
    }

    final int searchGeneration = ++_searchGeneration;
    _setLoading(true);

    try {
      final locations = await _service.searchLocations(query);
      final restaurants = await _service.searchRestaurants(
        query: query,
        filters: _filters,
      );

      if (searchGeneration != _searchGeneration) {
        return;
      }

      _locations = locations;
      _restaurants = restaurants;
      _sortResultsByProximity();
    } catch (_) {
      if (searchGeneration != _searchGeneration) {
        return;
      }
      _locations = const [];
      _restaurants = const [];
    } finally {
      if (searchGeneration == _searchGeneration) {
        _setLoading(false);
      }
    }
  }

  Future<void> _runViewportFetch(LatLngBounds bounds) async {
    final int viewportGeneration = ++_viewportGeneration;

    final center = bounds.center;
    final radiusMeters = _estimateRadius(bounds, center);

    try {
      final restaurants = await _service.searchRestaurantsInViewport(
        center: center,
        radiusMeters: radiusMeters,
        filters: _filters,
      );

      if (viewportGeneration != _viewportGeneration) {
        return;
      }

      final filtered = restaurants
          .where((restaurant) {
            final coordinates = restaurant.coordinates;
            return coordinates != null && bounds.contains(coordinates);
          })
          .toList(growable: false);

      _visibleRestaurants = filtered;
      _sortVisibleRestaurantsByProximity();
      notifyListeners();
    } catch (_) {
      if (viewportGeneration != _viewportGeneration) {
        return;
      }
      _visibleRestaurants = const [];
      notifyListeners();
    }
  }

  void _sortResultsByProximity() {
    final referencePoint = _referencePoint;
    if (referencePoint == null) {
      return;
    }

    _locations = [..._locations]
      ..sort((a, b) {
        final aDistance = _distance.as(
          LengthUnit.Meter,
          referencePoint,
          a.coordinates,
        );
        final bDistance = _distance.as(
          LengthUnit.Meter,
          referencePoint,
          b.coordinates,
        );
        return aDistance.compareTo(bDistance);
      });

    _restaurants = [..._restaurants]
      ..sort((a, b) {
        final aCoords = a.coordinates;
        final bCoords = b.coordinates;

        if (aCoords == null && bCoords == null) {
          return a.nombre.compareTo(b.nombre);
        }
        if (aCoords == null) {
          return 1;
        }
        if (bCoords == null) {
          return -1;
        }

        final aDistance = _distance.as(
          LengthUnit.Meter,
          referencePoint,
          aCoords,
        );
        final bDistance = _distance.as(
          LengthUnit.Meter,
          referencePoint,
          bCoords,
        );
        return aDistance.compareTo(bDistance);
      });
  }

  void _sortVisibleRestaurantsByProximity() {
    final referencePoint = _referencePoint ?? _viewportBounds?.center;
    if (referencePoint == null) {
      return;
    }

    _visibleRestaurants = [..._visibleRestaurants]
      ..sort((a, b) {
        final aCoords = a.coordinates;
        final bCoords = b.coordinates;

        if (aCoords == null && bCoords == null) {
          return a.nombre.compareTo(b.nombre);
        }
        if (aCoords == null) {
          return 1;
        }
        if (bCoords == null) {
          return -1;
        }

        final aDistance = _distance.as(
          LengthUnit.Meter,
          referencePoint,
          aCoords,
        );
        final bDistance = _distance.as(
          LengthUnit.Meter,
          referencePoint,
          bCoords,
        );
        return aDistance.compareTo(bDistance);
      });
  }

  double _estimateRadius(LatLngBounds bounds, LatLng center) {
    final distances = <double>[
      _distance.as(LengthUnit.Meter, center, bounds.northEast),
      _distance.as(LengthUnit.Meter, center, bounds.northWest),
      _distance.as(LengthUnit.Meter, center, bounds.southEast),
      _distance.as(LengthUnit.Meter, center, bounds.southWest),
    ];

    return distances.reduce((a, b) => a > b ? a : b) + 250;
  }

  void selectLocation(SearchLocationResult location) {
    _focusRequest = MapFocusRequest(
      coordinates: location.coordinates,
      zoom: 15,
      token: ++_focusToken,
    );
    notifyListeners();
  }

  void selectRestaurant(SearchRestaurantResult restaurant) {
    final coordinates = restaurant.coordinates;
    if (coordinates == null) {
      return;
    }

    _focusRequest = MapFocusRequest(
      coordinates: coordinates,
      zoom: 16,
      token: ++_focusToken,
      establishmentId: restaurant.idEstablecimiento,
    );
    notifyListeners();
  }

  void clearSuggestions() {
    _query = '';
    _clearResults();
  }

  void _refreshFilteredResults() {
    final query = _query.trim();
    final viewportBounds = _viewportBounds;

    if (query.isNotEmpty) {
      unawaited(_runSearch(query));
    }

    if (viewportBounds != null) {
      unawaited(_runViewportFetch(viewportBounds));
    }
  }

  void _clearResults() {
    _debounceTimer?.cancel();
    _searchGeneration++;
    _isLoading = false;
    _locations = const [];
    _restaurants = const [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Limpia la caché de restaurantes visibles en el mapa.
  /// Se llama cuando vuelves de editar un establecimiento para forzar
  /// una recarga de datos desde el servidor.
  void clearVisibleRestaurantsCache() {
    _visibleRestaurants = const [];
    _viewportGeneration++; // Incrementar para cancelar fetches pendientes
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _viewportDebounceTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}
