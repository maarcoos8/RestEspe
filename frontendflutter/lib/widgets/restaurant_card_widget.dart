import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../data/models/restaurant_detail_model.dart';

/// Widget que muestra los detalles de un restaurante en una tarjeta.
/// Se puede usar en diferentes contextos (sheet modal, vista, etc).
class RestaurantCardWidget extends StatefulWidget {
  const RestaurantCardWidget({
    super.key,
    required this.restaurant,
    this.currentLocation,
    this.onViewDetailsPressed,
  });

  final RestaurantDetail restaurant;
  final Position? currentLocation;
  final VoidCallback? onViewDetailsPressed;

  @override
  State<RestaurantCardWidget> createState() => _RestaurantCardWidgetState();
}

class _RestaurantCardWidgetState extends State<RestaurantCardWidget> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = false;
  }

  /// Calcula la distancia entre dos puntos (en km).
  double? _calculateDistance() {
    if (widget.currentLocation == null || widget.restaurant.coordinates == null) {
      return null;
    }

    final lat1 = widget.currentLocation!.latitude;
    final lon1 = widget.currentLocation!.longitude;
    final lat2 = widget.restaurant.coordinates!.latitude;
    final lon2 = widget.restaurant.coordinates!.longitude;

    // Fórmula de Haversine simplificada
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        Math.cos((lat2 - lat1) * p) / 2 +
        Math.cos(lat1 * p) * Math.cos(lat2 * p) * (1 - Math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R=6371 km
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final rating = widget.restaurant.puntuacionMedia;

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(AppColors.white),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle para cerrar (opcional)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nombre y botón favorito
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.restaurant.nombre,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: const Color(AppColors.primaryOrange),
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tipos de establecimiento
              if (widget.restaurant.tiposEstablecimiento.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.restaurant.tiposEstablecimiento
                        .map((tipo) => tipo.nombreCategoria)
                        .join(' • '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Categorías de dieta con fondo y color
              if (widget.restaurant.categoriasDieta.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.restaurant.categoriasDieta
                        .map(
                          (cat) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(AppColors.primaryOrange).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              cat.nombreDieta,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(AppColors.primaryOrange),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Distancia y puntuación en fila
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Distancia
                  if (distance != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance < 1
                              ? '${(distance * 1000).toStringAsFixed(0)} m'
                              : '${distance.toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),

                  // Puntuación
                  if (rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _ratingBackgroundColor(rating),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _ratingForegroundColor(rating).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${rating.toStringAsFixed(1)} (${widget.restaurant.numeroResenas})',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: _ratingForegroundColor(rating),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Botón "Ver detalles"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColors.primaryOrange),
                    foregroundColor: const Color(AppColors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: widget.onViewDetailsPressed,
                  child: Text(
                    'Ver detalles',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(AppColors.white),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _ratingForegroundColor(double rating) {
    if (rating >= 4) {
      return Colors.green.shade800;
    }
    if (rating >= 2) {
      return Colors.amber.shade800;
    }
    return Colors.red.shade800;
  }

  Color _ratingBackgroundColor(double rating) {
    if (rating >= 4) {
      return Colors.green.shade50;
    }
    if (rating >= 2) {
      return Colors.amber.shade50;
    }
    return Colors.red.shade50;
  }
}

// Helper class para operaciones matemáticas
class Math {
  static double cos(double radians) => math.cos(radians);
  static double sin(double radians) => math.sin(radians);
  static double sqrt(double x) => math.sqrt(x);
  static double asin(double x) => math.asin(x);
}
