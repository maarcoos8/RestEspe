import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/role_constants.dart';
import '../data/models/restaurant_detail_model.dart';
import '../data/models/review_model.dart';
import '../data/services/restaurant_detail_service.dart';
import '../data/services/review_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/establishment_actions_buttons.dart';
import '../widgets/favorite_button.dart';
import '../widgets/scaffold_with_nav.dart';
import 'review_creation_dialog.dart';

/// Pantalla de detalle básico de un restaurante.
///
/// Muestra imagen, nombre, dirección, tipos de establecimiento,
/// opciones dietéticas, puntuación y botón de favorito.
class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
    this.currentLocation,
  });

  final RestaurantDetail restaurant;
  final Position? currentLocation;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  late RestaurantDetail _currentRestaurant;
  final RestaurantDetailService _restaurantDetailService =
      RestaurantDetailService();
  final ReviewService _reviewService = ReviewService();
  bool _isReloading = false;
  bool _wasEdited = false; // Bandera para rastrear si se editó
  String _selectedTab = 'menu'; // 'menu', 'resenas', 'imagenes'
  List<ReviewModel> _reviews = [];
  int _reviewSkip = 0;
  bool _isLoadingReviews = false;
  bool _hasMoreReviews = true;
  final ScrollController _reviewScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentRestaurant = widget.restaurant;
    _reviewScrollController.addListener(_onReviewScroll);
  }

  @override
  void dispose() {
    _reviewScrollController.dispose();
    super.dispose();
  }

  /// Carga más reseñas al hacer scroll
  void _onReviewScroll() {
    if (_reviewScrollController.position.pixels >=
            _reviewScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingReviews &&
        _hasMoreReviews) {
      _loadMoreReviews();
    }
  }

  /// Carga reseñas iniciales
  Future<void> _loadInitialReviews() async {
    if (_isLoadingReviews) return;

    setState(() {
      _isLoadingReviews = true;
      _reviewSkip = 0;
      _reviews = [];
      _hasMoreReviews = true;
    });

    try {
      final newReviews = await _reviewService.getEstablishmentReviews(
        _currentRestaurant.idEstablecimiento,
        skip: 0,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _reviews = newReviews;
          _reviewSkip = 5;
          _hasMoreReviews = newReviews.length == 5;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  /// Carga más reseñas (infinite scroll)
  Future<void> _loadMoreReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final newReviews = await _reviewService.getEstablishmentReviews(
        _currentRestaurant.idEstablecimiento,
        skip: _reviewSkip,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _reviews.addAll(newReviews);
          _reviewSkip += 5;
          _hasMoreReviews = newReviews.length == 5;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  /// Recarga los datos del restaurante desde el servidor
  Future<void> _reloadRestaurantData() async {
    if (_isReloading) return;

    setState(() {
      _isReloading = true;
    });

    try {
      final updatedRestaurant = await _restaurantDetailService
          .getRestaurantDetail(widget.restaurant.idEstablecimiento);

      if (mounted && updatedRestaurant != null) {
        setState(() {
          _currentRestaurant = updatedRestaurant;
          _wasEdited = true; // Marcar que se editó exitosamente
        });
      }
    } catch (e) {
      // Error silent - revisar logs si es necesario
    } finally {
      if (mounted) {
        setState(() {
          _isReloading = false;
        });
      }
    }
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

  String _getVerificationTimeText(DateTime verificationDate) {
    final now = DateTime.now();
    final difference = now.difference(verificationDate);

    final days = difference.inDays;
    final months = (days / 30).floor();

    if (days < 30) {
      if (days == 0) {
        return 'hoy';
      } else if (days == 1) {
        return 'hace 1 día';
      } else {
        return 'hace $days días';
      }
    } else {
      if (months == 1) {
        return 'hace 1 mes';
      } else {
        return 'hace $months meses';
      }
    }
  }

  double? _calculateDistance() {
    if (widget.currentLocation == null ||
        _currentRestaurant.coordinates == null) {
      return null;
    }

    final lat1 = widget.currentLocation!.latitude;
    final lon1 = widget.currentLocation!.longitude;
    final lat2 = _currentRestaurant.coordinates!.latitude;
    final lon2 = _currentRestaurant.coordinates!.longitude;

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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // Si ya se removió, no hacer nada

        // Si se volvió de editar (result == true), recargar los datos
        if (result == true) {
          _reloadRestaurantData();
          return; // No salir, permitir continuar viendo los datos actualizados
        }

        // Si se está intentando salir y se editó, propagar el resultado
        if (_wasEdited) {
          Navigator.of(context).pop(true);
        }
      },
      child: ScaffoldWithNav(
        title: 'Detalle del establecimiento',
        currentIndex: 1,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroImage(restaurant: _currentRestaurant),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _currentRestaurant.nombre,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(AppColors.darkText),
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_currentRestaurant.puntuacionMedia != null)
                                _RatingBadge(
                                  rating: _currentRestaurant.puntuacionMedia!,
                                  reviews: _currentRestaurant.numeroResenas,
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
                                      (_currentRestaurant.direccionTexto ==
                                                  null ||
                                              _currentRestaurant.direccionTexto!
                                                  .trim()
                                                  .isEmpty)
                                          ? 'Dirección no disponible'
                                          : _currentRestaurant.direccionTexto!,
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
                          if (_currentRestaurant.tiposEstablecimiento.isEmpty)
                            Text(
                              'Sin tipos registrados',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(AppColors.lightText),
                                  ),
                            )
                          else
                            Text(
                              _currentRestaurant.tiposEstablecimiento
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
                          if (_currentRestaurant.categoriasDieta.isEmpty)
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
                              children: _currentRestaurant.categoriasDieta
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
                          const SizedBox(height: 18),
                          if (_currentRestaurant.estadoVerificado == true &&
                              _currentRestaurant.ultimaVerificacion != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 20,
                                  color: Color(AppColors.primaryGreen),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Verificado por ${_currentRestaurant.verificadorId == _currentRestaurant.propietarioId ? 'el propietario' : 'un administrador global'} ${_getVerificationTimeText(_currentRestaurant.ultimaVerificacion!)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(
                                            AppColors.primaryGreen,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                const Icon(
                                  Icons.priority_high,
                                  size: 20,
                                  color: Color(AppColors.errorRed),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'No verificado',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(AppColors.errorRed),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: -20,
                    child: EstablishmentActionsButtons(
                      restaurant: _currentRestaurant,
                      onDeleted: () {
                        Navigator.of(context).pop();
                      },
                      onEdit: _reloadRestaurantData,
                      onVerify: _reloadRestaurantData,
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
                          establishmentId: _currentRestaurant.idEstablecimiento,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Menú de secciones: Menú, Reseñas, Imágenes
              Container(
                color: const Color(AppColors.white),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('Menú', 'menu')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTabButton('Reseñas', 'resenas')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTabButton('Imágenes', 'imagenes')),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0x1F000000)),
              // Contenido de la sección seleccionada
              Container(
                color: const Color(AppColors.background),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabValue) {
    final isSelected = _selectedTab == tabValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabValue;
        });
        // Cargar reseñas si se selecciona la pestaña de reseñas
        if (tabValue == 'resenas' && _reviews.isEmpty) {
          _loadInitialReviews();
        }
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(AppColors.primaryOrange)
                : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(AppColors.white)
                  : const Color(AppColors.darkText),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'resenas':
        return _buildReviewsSection();
      case 'imagenes':
        return Text(
          'sección imágenes',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case 'menu':
      default:
        return Text(
          'sección menú',
          style: Theme.of(context).textTheme.bodyMedium,
        );
    }
  }

  Widget _buildReviewsSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isOwner = currentUser?.idUsuario == _currentRestaurant.propietarioId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón "Crear nueva reseña" solo si no es propietario
        if (!isOwner)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ReviewCreationDialog(
                      idEstablecimiento: widget.restaurant.idEstablecimiento,
                      onReviewCreated: (review) {
                        setState(() {
                          _reviews.insert(0, review);
                          // Actualizar puntuación media y contador localmente
                          final oldAvg =
                              _currentRestaurant.puntuacionMedia ?? 0.0;
                          final oldCount = _currentRestaurant.numeroResenas;
                          final newCount = oldCount + 1;
                          final newAvg =
                              ((oldAvg * oldCount) + review.puntuacion) /
                              newCount;
                          _currentRestaurant = RestaurantDetail(
                            idEstablecimiento:
                                _currentRestaurant.idEstablecimiento,
                            nombre: _currentRestaurant.nombre,
                            direccionTexto: _currentRestaurant.direccionTexto,
                            coordinates: _currentRestaurant.coordinates,
                            estadoVerificado:
                                _currentRestaurant.estadoVerificado,
                            ultimaVerificacion:
                                _currentRestaurant.ultimaVerificacion,
                            verificadorId: _currentRestaurant.verificadorId,
                            categoriasDieta: _currentRestaurant.categoriasDieta,
                            tiposEstablecimiento:
                                _currentRestaurant.tiposEstablecimiento,
                            puntuacionMedia: newAvg,
                            numeroResenas: newCount,
                            imagenUrl: _currentRestaurant.imagenUrl,
                            propietarioId: _currentRestaurant.propietarioId,
                          );
                        });
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear nueva reseña'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.primaryOrange),
                  foregroundColor: const Color(AppColors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        // Lista de reseñas con infinite scroll
        if (_reviews.isEmpty && !_isLoadingReviews)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Sin reseñas aún',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(AppColors.lightText),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 400, // Altura fija para la lista de reseñas
            child: ListView.separated(
              controller: _reviewScrollController,
              itemCount: _reviews.length + (_isLoadingReviews ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == _reviews.length) {
                  // Loading indicator
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildReviewCard(_reviews[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final timeAgo = _getTimeAgoText(review.fechaPublicacion);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSuperadmin = RoleConstants.isSuperadmin(
      authProvider.currentUser?.idRol,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        border: Border.all(color: const Color(0x1F000000)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila: Avatar + Nombre || Estrellas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + Nombre
              Expanded(
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: review.fotoPerfil != null
                          ? NetworkImage(review.fotoPerfil!)
                          : null,
                      child: review.fotoPerfil == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    // Nombre
                    Expanded(
                      child: Text(
                        review.nombreUsuario ?? 'Usuario anónimo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Estrellas
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.puntuacion.toInt()
                        ? Icons.star
                        : (index < review.puntuacion
                              ? Icons.star_half
                              : Icons.star_outline),
                    size: 16,
                    color: const Color(AppColors.primaryOrange),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Comentario
          if (review.comentario != null && review.comentario!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                review.comentario!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          // Imagen (si existe)
          if (review.urlImagen != null && review.urlImagen!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Image.network(
                              review.urlImagen!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  height: 240,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                                (progress.expectedTotalBytes ??
                                                    1)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 240,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    review.urlImagen!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
            ),
          // Acciones inferiores y fecha
          Row(
            children: [
              if (isSuperadmin)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: const Color(
                      AppColors.errorRed,
                    ).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(
                        AppColors.errorRed,
                      ).withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(AppColors.errorRed),
                    ),
                    onPressed: () => _confirmDeleteReview(review),
                  ),
                ),
              const Spacer(),
              Text(
                timeAgo,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(AppColors.lightText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteReview(ReviewModel review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar reseña'),
          content: const Text(
            '¿Seguro que quieres eliminar esta reseña? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(AppColors.errorRed),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final deleted = await _reviewService.deleteReview(review.idResena);
    if (!mounted) return;

    if (deleted) {
      setState(() {
        _reviews.removeWhere((item) => item.idResena == review.idResena);

        final oldCount = _currentRestaurant.numeroResenas;
        if (oldCount <= 1) {
          _currentRestaurant = RestaurantDetail(
            idEstablecimiento: _currentRestaurant.idEstablecimiento,
            nombre: _currentRestaurant.nombre,
            direccionTexto: _currentRestaurant.direccionTexto,
            coordinates: _currentRestaurant.coordinates,
            estadoVerificado: _currentRestaurant.estadoVerificado,
            ultimaVerificacion: _currentRestaurant.ultimaVerificacion,
            verificadorId: _currentRestaurant.verificadorId,
            categoriasDieta: _currentRestaurant.categoriasDieta,
            tiposEstablecimiento: _currentRestaurant.tiposEstablecimiento,
            puntuacionMedia: null,
            numeroResenas: 0,
            imagenUrl: _currentRestaurant.imagenUrl,
            propietarioId: _currentRestaurant.propietarioId,
          );
        } else {
          final oldAvg = _currentRestaurant.puntuacionMedia ?? 0.0;
          final newCount = oldCount - 1;
          final newAvg = ((oldAvg * oldCount) - review.puntuacion) / newCount;
          _currentRestaurant = RestaurantDetail(
            idEstablecimiento: _currentRestaurant.idEstablecimiento,
            nombre: _currentRestaurant.nombre,
            direccionTexto: _currentRestaurant.direccionTexto,
            coordinates: _currentRestaurant.coordinates,
            estadoVerificado: _currentRestaurant.estadoVerificado,
            ultimaVerificacion: _currentRestaurant.ultimaVerificacion,
            verificadorId: _currentRestaurant.verificadorId,
            categoriasDieta: _currentRestaurant.categoriasDieta,
            tiposEstablecimiento: _currentRestaurant.tiposEstablecimiento,
            puntuacionMedia: newAvg,
            numeroResenas: newCount,
            imagenUrl: _currentRestaurant.imagenUrl,
            propietarioId: _currentRestaurant.propietarioId,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reseña eliminada'),
          backgroundColor: Color(AppColors.successGreen),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la reseña'),
          backgroundColor: Color(AppColors.errorRed),
        ),
      );
    }
  }

  String _getTimeAgoText(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'hace unos segundos';
    } else if (difference.inHours < 1) {
      final mins = difference.inMinutes;
      return 'hace $mins ${mins == 1 ? "minuto" : "minutos"}';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return 'hace $hours ${hours == 1 ? "hora" : "horas"}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'hace $days ${days == 1 ? "día" : "días"}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'hace $weeks ${weeks == 1 ? "semana" : "semanas"}';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'hace $months ${months == 1 ? "mes" : "meses"}';
    }
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.star, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            '($reviews)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
