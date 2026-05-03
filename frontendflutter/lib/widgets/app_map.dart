import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';

import '../core/constants.dart';
import '../data/models/search_models.dart';
import '../data/services/restaurant_detail_service.dart';
import '../providers/search_provider.dart';
import 'restaurant_card_widget.dart';

/// Widget de mapa que muestra OpenStreetMap.
/// Se centra en Madrid por defecto, pero intenta usar la ubicación del dispositivo si está disponible.
class AppMap extends StatefulWidget {
  const AppMap({super.key, this.focusRequest});

  final MapFocusRequest? focusRequest;

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  late MapController mapController;
  SearchProvider? _searchProvider;
  late RestaurantDetailService _restaurantService;
  LatLng? _currentLocation;
  LatLng _mapCenter = const LatLng(40.4168, -3.7038);
  double _currentZoom = 13.0;
  bool isLoadingLocation = true;
  bool _isMapReady = false;
  int _lastHandledFocusToken = -1;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _restaurantService = RestaurantDetailService();
    _initializeMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchProvider ??= context.read<SearchProvider>();
  }

  void _updateReferencePoint(LatLng point) {
    if (!mounted) {
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchProvider?.updateReferencePoint(point);
      }
    });
  }

  void _updateViewportBounds(LatLngBounds bounds) {
    if (!mounted) {
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchProvider?.updateViewportBounds(bounds);
      }
    });
  }

  /// Intenta obtener la ubicación actual del dispositivo antes de pintar el mapa.
  /// Si no es posible, se queda centrado en Madrid, pero sin mostrar antes un salto visual.
  Future<void> _initializeMap() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!serviceEnabled || permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentLocation = null;
            _mapCenter = const LatLng(40.4168, -3.7038);
            isLoadingLocation = false;
          });
          _updateReferencePoint(_mapCenter);
        }
        return;
      }

      if (serviceEnabled &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always)) {
        // Obtener posición actual
        try {
          final Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 8));

          if (mounted) {
            final currentLocation = LatLng(position.latitude, position.longitude);
            setState(() {
              _currentLocation = currentLocation;
              _mapCenter = currentLocation;
              isLoadingLocation = false;
            });
            _updateReferencePoint(currentLocation);
            _applyFocusRequest(widget.focusRequest);
            return;
          }
        } catch (_) {
          // Si no se consigue una posición inmediata, prueba con la última conocida.
          final Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
          if (lastKnownPosition != null && mounted) {
            final lastKnownLocation = LatLng(
              lastKnownPosition.latitude,
              lastKnownPosition.longitude,
            );

            setState(() {
              _currentLocation = lastKnownLocation;
              _mapCenter = lastKnownLocation;
              isLoadingLocation = false;
            });
            _updateReferencePoint(lastKnownLocation);
            return;
          }
        }
      }

      // Permiso denegado o sin posición disponible, mantener Madrid como ubicación por defecto
      if (mounted) {
        setState(() {
          _currentLocation = null;
          _mapCenter = const LatLng(40.4168, -3.7038);
          isLoadingLocation = false;
        });
        _updateReferencePoint(_mapCenter);
      }
    } catch (e) {
      // Error al obtener ubicación, mantener Madrid como ubicación por defecto
      debugPrint('Error al obtener ubicación: $e');
      if (mounted) {
        setState(() {
          _currentLocation = null;
          _mapCenter = const LatLng(40.4168, -3.7038);
          isLoadingLocation = false;
        });
        _updateReferencePoint(_mapCenter);
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusRequest?.token != oldWidget.focusRequest?.token) {
      _applyFocusRequest(widget.focusRequest);
    }
  }

  void _applyFocusRequest(MapFocusRequest? request) {
    if (request == null || request.token == _lastHandledFocusToken) {
      return;
    }

    _lastHandledFocusToken = request.token;
    // Aplicar el focus con 2 niveles de zoom menos, asegurando límites
    final double minZoom = 5.0;
    final double maxZoom = 18.0;
    final double adjustedZoom = (request.zoom - 2).clamp(minZoom, maxZoom).toDouble();
    _moveMap(request.coordinates, adjustedZoom);
  }

  void _moveMap(LatLng center, double zoom) {
    _mapCenter = center;
    _currentZoom = zoom;
    if (_isMapReady) {
      mapController.move(center, zoom);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _zoomBy(double delta) {
    final nextZoom = (_currentZoom + delta).clamp(5.0, 18.0).toDouble();
    _moveMap(_mapCenter, nextZoom);
  }

  void _recenterMap() {
    final currentLocation = _currentLocation;
    if (currentLocation == null) {
      return;
    }

    _moveMap(currentLocation, _currentZoom < 15.0 ? 15.0 : _currentZoom);
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingLocation) {
      return Container(
        color: const Color(AppColors.background),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(AppColors.primaryOrange),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _mapCenter,
        initialZoom: 13.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onMapReady: () {
          _isMapReady = true;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (_isMapReady && mounted) {
              mapController.move(_mapCenter, _currentZoom);
              _updateViewportBounds(mapController.camera.visibleBounds);
            }
          });
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.doubleTapZoom | InteractiveFlag.pinchZoom | InteractiveFlag.scrollWheelZoom,
        ),
        onPositionChanged: (camera, hasGesture) {
          if (!mounted) {
            return;
          }
          _mapCenter = camera.center;
          _currentZoom = camera.zoom;
          _updateReferencePoint(camera.center);
          _updateViewportBounds(camera.visibleBounds);
        },
      ),
      children: [
        // Capa de tiles de OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.resto_espe',
          maxNativeZoom: 19,
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: _searchProvider?.visibleRestaurants
                  .where((restaurant) => restaurant.coordinates != null)
                  .map(
                    (restaurant) => Marker(
                      point: restaurant.coordinates!,
                      width: 42,
                      height: 42,
                      // Ajuste de alineación: usar topCenter para corregir la orientación
                      alignment: Alignment.topCenter,
                      child: Transform.translate(
                        offset: const Offset(0, 6), // bajar el icono 6px para compensar margen
                        child: GestureDetector(
                          onTap: () => _showRestaurantDetails(context, restaurant.idEstablecimiento),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(AppColors.primaryOrange),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false) ??
              const [],
        ),
        // Punto azul de ubicación actual
        if (_currentLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _currentLocation!,
                radius: 8,
                useRadiusInMeter: false,
                color: const Color(0xFF2196F3),
                borderColor: Colors.white,
                borderStrokeWidth: 3,
              ),
            ],
          ),
        Positioned(
          right: 14,
          bottom: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapActionButton(
                icon: Icons.my_location_rounded,
                backgroundColor: const Color(AppColors.primaryOrange),
                iconColor: const Color(AppColors.white),
                onTap: _recenterMap,
              ),
              const SizedBox(height: 10),
              _MapActionButton(
                icon: Icons.add,
                backgroundColor: const Color(AppColors.white),
                iconColor: const Color(AppColors.primaryOrange),
                borderColor: const Color(AppColors.primaryOrange),
                onTap: () => _zoomBy(1),
              ),
              const SizedBox(height: 8),
              _MapActionButton(
                icon: Icons.remove,
                backgroundColor: const Color(AppColors.white),
                iconColor: const Color(AppColors.primaryOrange),
                borderColor: const Color(AppColors.primaryOrange),
                onTap: () => _zoomBy(-1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Carga los detalles del restaurante y muestra un bottom sheet.
  Future<void> _showRestaurantDetails(BuildContext context, int idEstablecimiento) async {
    // Mostrar un loading indicator mientras se cargan los datos
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder(
        future: _restaurantService.getRestaurantDetail(idEstablecimiento),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Color(AppColors.primaryOrange),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Container(
              height: 200,
              alignment: Alignment.center,
              child: Text(
                'Error al cargar los detalles',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          final restaurant = snapshot.data!;
          return RestaurantCardWidget(
            restaurant: restaurant,
            currentLocation: _currentLocation != null
                ? Position(
                    latitude: _currentLocation!.latitude,
                    longitude: _currentLocation!.longitude,
                    timestamp: DateTime.now(),
                    accuracy: 0,
                    altitude: 0,
                    altitudeAccuracy: 0,
                    heading: 0,
                    headingAccuracy: 0,
                    speed: 0,
                    speedAccuracy: 0,
                  )
                : null,
            onViewDetailsPressed: () {
              // TODO: Navegar a la vista de detalles del establecimiento
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Ver detalles: ${restaurant.nombre}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
            },
          );
        },
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
    this.borderColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: borderColor == null ? 0 : 1.5,
        ),
      ),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
