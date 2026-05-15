import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';
import '../data/models/restaurant_detail_model.dart';
import '../widgets/favorite_button.dart';
import '../widgets/scaffold_with_nav.dart';

/// Pantalla de detalle básico de un restaurante.
///
/// Muestra imagen, nombre, dirección, tipos de establecimiento,
/// opciones dietéticas, puntuación y botón de favorito.
class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
    this.currentLocation,
  });

  final RestaurantDetail restaurant;
  final Position? currentLocation;

  double? _calculateDistance() {
    if (currentLocation == null || restaurant.coordinates == null) {
      return null;
    }

    final lat1 = currentLocation!.latitude;
    final lon1 = currentLocation!.longitude;
    final lat2 = restaurant.coordinates!.latitude;
    final lon2 = restaurant.coordinates!.longitude;

    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: 'Detalle del establecimiento',
      currentIndex: 1,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(restaurant: restaurant),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(AppColors.white),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0x1A000000),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.nombre,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(AppColors.darkText),
                                    ),
                              ),
                            ),
                            if (restaurant.puntuacionMedia != null)
                              _RatingBadge(
                                rating: restaurant.puntuacionMedia!,
                                reviews: restaurant.numeroResenas,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Color(AppColors.lightText),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (restaurant.direccionTexto == null ||
                                            restaurant.direccionTexto!
                                                .trim()
                                                .isEmpty)
                                        ? 'Dirección no disponible'
                                        : restaurant.direccionTexto!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(
                                            AppColors.lightText,
                                          ),
                                          height: 1.35,
                                        ),
                                  ),
                                  if (_calculateDistance() != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _calculateDistance()! < 1
                                          ? '${(_calculateDistance()! * 1000).toStringAsFixed(0)} m de distancia'
                                          : '${_calculateDistance()!.toStringAsFixed(1)} km de distancia',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(
                                              AppColors.primaryOrange,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0x1F000000),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Tipos de establecimiento',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        if (restaurant.tiposEstablecimiento.isEmpty)
                          Text(
                            'Sin tipos registrados',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(AppColors.lightText),
                                ),
                          )
                        else
                          Text(
                            restaurant.tiposEstablecimiento
                                .map((tipo) => tipo.nombreCategoria)
                                .join(' · '),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        const SizedBox(height: 18),
                        Text(
                          'Opciones dietéticas',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        if (restaurant.categoriasDieta.isEmpty)
                          Text(
                            'Sin opciones dietéticas registradas',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(AppColors.lightText),
                                ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: restaurant.categoriasDieta
                                .map(
                                  (cat) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        AppColors.primaryOrange,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      cat.nombreDieta,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: const Color(
                                              AppColors.primaryOrange,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: -20,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(AppColors.white),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: FavoriteButton(
                        establishmentId: restaurant.idEstablecimiento,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.restaurant});

  final RestaurantDetail restaurant;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      color: const Color(AppColors.accentBeige).withValues(alpha: 0.35),
      child: restaurant.imagenUrl != null && restaurant.imagenUrl!.isNotEmpty
          ? Image.network(
              restaurant.imagenUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallback();
              },
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return const Center(
      child: Icon(
        Icons.restaurant_menu_rounded,
        size: 72,
        color: Color(AppColors.primaryOrange),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.reviews});

  final double rating;
  final int reviews;

  @override
  Widget build(BuildContext context) {
    final foreground = _ratingForegroundColor(rating);

    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _ratingBackgroundColor(rating),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        '${rating.toStringAsFixed(1)} ($reviews)',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _ratingForegroundColor(double value) {
    if (value >= 4) {
      return Colors.green.shade800;
    }
    if (value >= 2) {
      return Colors.amber.shade800;
    }
    return Colors.red.shade800;
  }

  Color _ratingBackgroundColor(double value) {
    if (value >= 4) {
      return Colors.green.shade50;
    }
    if (value >= 2) {
      return Colors.amber.shade50;
    }
    return Colors.red.shade50;
  }
}

class Math {
  static double cos(double radians) => math.cos(radians);
  static double sin(double radians) => math.sin(radians);
  static double sqrt(double x) => math.sqrt(x);
  static double asin(double x) => math.asin(x);
}
