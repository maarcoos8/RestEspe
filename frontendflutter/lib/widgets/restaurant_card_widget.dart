import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../data/models/restaurant_detail_model.dart';
import 'favorite_button.dart';

/// Widget que muestra los detalles de un restaurante en una tarjeta.
/// Se puede usar en diferentes contextos (sheet modal, vista, etc).
class RestaurantCardWidget extends StatefulWidget {
  const RestaurantCardWidget({
    super.key,
    required this.restaurant,
    this.currentLocation,
    this.compact = false,
    this.showViewDetailsButton = false,
    this.onCardTap,
    this.onViewDetailsPressed,
  });

  final RestaurantDetail restaurant;
  final Position? currentLocation;
  final bool compact;
  final bool showViewDetailsButton;
  final VoidCallback? onCardTap;
  final VoidCallback? onViewDetailsPressed;

  @override
  State<RestaurantCardWidget> createState() => _RestaurantCardWidgetState();
}

class _RestaurantCardWidgetState extends State<RestaurantCardWidget> {
  /// Calcula la distancia entre dos puntos (en km).
  double? _calculateDistance() {
    if (widget.currentLocation == null ||
        widget.restaurant.coordinates == null) {
      return null;
    }

    final lat1 = widget.currentLocation!.latitude;
    final lon1 = widget.currentLocation!.longitude;
    final lat2 = widget.restaurant.coordinates!.latitude;
    final lon2 = widget.restaurant.coordinates!.longitude;

    // Fórmula de Haversine simplificada
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        Math.cos((lat2 - lat1) * p) / 2 +
        Math.cos(lat1 * p) *
            Math.cos(lat2 * p) *
            (1 - Math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R=6371 km
  }

  Color _hexToColor(String hexString) {
    String hex = hexString.replaceFirst('#', '');
    // Si tiene 6 caracteres, agregar FF al inicio para opacidad completa
    if (hex.length == 6) {
      return Color(int.parse('ff$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    // Color por defecto si el formato es inválido
    return Color(int.parse('ffFF6B6B', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final rating = widget.restaurant.puntuacionMedia;
    final isCompact = widget.compact;

    return GestureDetector(
      onTap: widget.onCardTap,
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(AppColors.white),
            border: Border.fromBorderSide(
              BorderSide(color: Color(0x1A000000), width: 1),
            ),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del establecimiento o icono genérico
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: const Color(AppColors.accentBeige).withOpacity(0.3),
                  child:
                      widget.restaurant.imagenUrl != null &&
                          widget.restaurant.imagenUrl!.isNotEmpty
                      ? Image.network(
                          widget.restaurant.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildGenericImage();
                          },
                        )
                      : _buildGenericImage(),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, isCompact ? 12 : 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: isCompact ? 4 : 8),

                    // Nombre y botón favorito
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.restaurant.nombre,
                            style:
                                (isCompact
                                        ? Theme.of(context).textTheme.titleLarge
                                        : Theme.of(
                                            context,
                                          ).textTheme.headlineSmall)
                                    ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FavoriteButton(
                          establishmentId: widget.restaurant.idEstablecimiento,
                          size: isCompact ? 24 : 28,
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 6 : 8),

                    // Tipos de establecimiento
                    if (widget.restaurant.tiposEstablecimiento.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: isCompact ? 8 : 12),
                        child: Text(
                          widget.restaurant.tiposEstablecimiento
                              .map((tipo) => tipo.nombreCategoria)
                              .join(' • '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Categorías de dieta con fondo y color
                    if (widget.restaurant.categoriasDieta.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: isCompact ? 0 : 0),
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
                                    color: _hexToColor(
                                      cat.colorHex,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    cat.nombreDieta,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _hexToColor(cat.colorHex),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                    SizedBox(height: isCompact ? 8 : 10),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0x1F000000),
                    ),
                    SizedBox(height: isCompact ? 8 : 10),

                    // Distancia y puntuación en fila
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Distancia y estado de verificación
                        Row(
                          children: [
                            if (distance != null) ...[
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _verificationBackgroundColor(
                                  widget.restaurant.estadoVerificado,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _verificationForegroundColor(
                                    widget.restaurant.estadoVerificado,
                                  ).withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.restaurant.estadoVerificado == true
                                    ? 'Verificado'
                                    : 'No verificado',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: _verificationForegroundColor(
                                        widget.restaurant.estadoVerificado,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                color: _ratingForegroundColor(
                                  rating,
                                ).withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: _ratingForegroundColor(rating),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: _ratingForegroundColor(rating),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${widget.restaurant.numeroResenas})',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: _ratingForegroundColor(rating),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: isCompact ? 8 : 16),

                    // Botón "Ver detalles"
                    if (widget.showViewDetailsButton &&
                        widget.onViewDetailsPressed != null)
                      SizedBox(
                        width: double.infinity,
                        height: isCompact ? 44 : 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              AppColors.primaryOrange,
                            ),
                            foregroundColor: const Color(AppColors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: widget.onViewDetailsPressed,
                          child: Text(
                            'Ver detalles',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: const Color(AppColors.white),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget genérico con icono cuando no hay imagen del establecimiento.
  Widget _buildGenericImage() {
    return Container(
      color: const Color(AppColors.accentBeige).withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: const Color(AppColors.primaryOrange).withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Sin imagen',
              style: TextStyle(
                color: const Color(AppColors.primaryOrange).withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
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

  Color _verificationForegroundColor(bool? verified) {
    return verified == true ? Colors.green.shade800 : Colors.red.shade800;
  }

  Color _verificationBackgroundColor(bool? verified) {
    return verified == true ? Colors.green.shade50 : Colors.red.shade50;
  }
}

// Helper class para operaciones matemáticas
class Math {
  static double cos(double radians) => math.cos(radians);
  static double sin(double radians) => math.sin(radians);
  static double sqrt(double x) => math.sqrt(x);
  static double asin(double x) => math.asin(x);
}
