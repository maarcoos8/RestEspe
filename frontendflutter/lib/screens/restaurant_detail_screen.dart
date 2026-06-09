import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../core/role_constants.dart';
import '../data/models/restaurant_detail_model.dart';
import '../data/models/review_model.dart';
import '../data/models/item_menu_model.dart';
import '../data/models/tipo_item_menu_model.dart';
import '../data/services/restaurant_detail_service.dart';
import '../data/services/review_service.dart';
import '../data/services/menu_service.dart';
import '../providers/restaurant_detail_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/establishment_actions_buttons.dart';
import '../widgets/favorite_button.dart';
import '../widgets/scaffold_with_nav.dart';
import '../widgets/establishment_gallery_widget.dart';
import 'review_creation_dialog.dart';

/// Pantalla de detalle b+ísico de un restaurante.
///
/// Muestra imagen, nombre, direcci+¦n, tipos de establecimiento,
/// opciones diet+®ticas, puntuaci+¦n y bot+¦n de favorito.
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
  bool _wasEdited = false; // Bandera para rastrear si se edit+¦
  String _selectedTab = 'menu'; // 'menu', 'resenas', 'imagenes'
  List<ReviewModel> _reviews = [];
  int _reviewSkip = 0;
  bool _isLoadingReviews = false;
  bool _hasMoreReviews = true;
  final ScrollController _reviewScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  late Widget _galleryWidget;
  
  // Variables para el men+¦
  List<TipoItemMenu> _secciones = [];
  List<ItemMenu> _platos = [];
  bool _isLoadingMenu = false;
  String? _errorMenu;
  final Set<int> _expandedSections = {};

  Future<void> _shareEstablishment() async {
    final link = AppConstants.establishmentShareUrl(
      _currentRestaurant.idEstablecimiento,
    );

    await Clipboard.setData(ClipboardData(text: link));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enlace copiado'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    await Share.share(
      'Mira este establecimiento en PinFood: $link',
      subject: 'Compartido desde PinFood',
    );
  }

  @override
  void initState() {
    super.initState();
    _currentRestaurant = widget.restaurant;
    _galleryWidget = EstablishmentGallery(
      key: const ValueKey('establishment_gallery'),
      idEstablecimiento: widget.restaurant.idEstablecimiento,
    );
    _reviewScrollController.addListener(_onReviewScroll);
    _loadMenu();
  }

  @override
  void didUpdateWidget(RestaurantDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.idEstablecimiento != widget.restaurant.idEstablecimiento) {
      _galleryWidget = EstablishmentGallery(
        key: const ValueKey('establishment_gallery'),
        idEstablecimiento: widget.restaurant.idEstablecimiento,
      );
    }
  }

  @override
  void dispose() {
    _reviewScrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  /// Carga m+ís rese+¦as al hacer scroll
  void _onReviewScroll() {
    if (_reviewScrollController.position.pixels >=
      _reviewScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingReviews &&
        _hasMoreReviews) {
      _loadMoreReviews();
    }
  }

  /// Carga rese+¦as iniciales
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

  /// Carga m+ís rese+¦as (infinite scroll)
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
          _wasEdited = true; // Marcar que se edit+¦ exitosamente
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

  /// Recarga el detalle del restaurante y el menú tras una mutación.
  Future<void> _refreshAfterMenuMutation() async {
    await _reloadRestaurantData();
    if (!mounted) return;

    context
        .read<RestaurantDetailProvider>()
        .clearRestaurantCache(_currentRestaurant.idEstablecimiento);

    // También limpiar la caché de restaurantes visibles en el mapa
    // para que la vista del mapa vuelva a cargar los datos actualizados.
    context.read<SearchProvider>().clearVisibleRestaurantsCache();

    await _loadMenu();
  }

  Future<void> _handleMenuVerificationFlow({
    required bool wasVerifiedBefore,
    required String actionLabel,
  }) async {
    if (!wasVerifiedBefore || !mounted) return;

    final unsetSuccess = await _restaurantDetailService.setVerificationState(
      _currentRestaurant.idEstablecimiento,
      verified: false,
      verifierId: null,
    );

    if (!unsetSuccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo marcar el establecimiento como no verificado'),
          backgroundColor: Color(AppColors.errorRed),
        ),
      );
      return;
    }

    final shouldVerifyAgain = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Establecimiento sin verificar'),
          content: Text(
            'Has $actionLabel un plato en un establecimiento verificado. Al guardar, el establecimiento pasará a estar sin verificar. ¿Quieres verificarlo de nuevo ahora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No verificar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(AppColors.primaryGreen),
              ),
              child: const Text('Verificar de nuevo'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldVerifyAgain == null) return;

    bool verifiedAgain = false;
    if (shouldVerifyAgain) {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo volver a verificar el establecimiento'),
            backgroundColor: Color(AppColors.errorRed),
          ),
        );
        return;
      }

      verifiedAgain = await _restaurantDetailService.verifyEstablishment(
        _currentRestaurant.idEstablecimiento,
        currentUser.idUsuario,
      );

      if (!verifiedAgain) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo volver a verificar el establecimiento'),
            backgroundColor: Color(AppColors.errorRed),
          ),
        );
        return;
      }
    }

    await _reloadRestaurantData();
    // Limpiar la caché del provider de detalle para que otras vistas
    // (ej. el card del mapa) obtengan la versión actualizada del restaurante.
    context.read<RestaurantDetailProvider>().clearRestaurantCache(
      _currentRestaurant.idEstablecimiento,
    );
    if (!mounted) return;

    // Asegurar que el mapa recargue los datos tras verificar/no verificar
    context.read<SearchProvider>().clearVisibleRestaurantsCache();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          verifiedAgain
              ? 'Establecimiento verificado de nuevo'
              : 'Establecimiento marcado como no verificado',
        ),
        backgroundColor: const Color(AppColors.successGreen),
      ),
    );
  }

  /// Carga el men+¦ del establecimiento
  Future<void> _loadMenu() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMenu = true;
      _errorMenu = null;
    });

    try {
      final secciones =
          await MenuService.getSecciones(_currentRestaurant.idEstablecimiento);
      final platos =
          await MenuService.getPlatos(_currentRestaurant.idEstablecimiento);

      if (mounted) {
        setState(() {
          _secciones = secciones;
          _platos = platos;
          _isLoadingMenu = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMenu = e.toString().replaceFirst('Exception: ', '');
          _isLoadingMenu = false;
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
    // Color por defecto si el formato es inv+ílido
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
        if (didPop) return; // Si ya se removi+¦, no hacer nada

        // Si se volvi+¦ de editar (result == true), recargar los datos
        if (result == true) {
          _reloadRestaurantData();
          return; // No salir, permitir continuar viendo los datos actualizados
        }

        // Si se est+í intentando salir y se edit+¦, propagar el resultado
        if (_wasEdited) {
          Navigator.of(context).pop(true);
        }
      },
      child: ScaffoldWithNav(
        title: 'Detalle del establecimiento',
        currentIndex: -1, // Ninguna pesta+¦a seleccionada cuando estamos en el detalle
        body: _buildScrollableView(),
      ),
    );
  }

  Widget _buildScrollableView() {
    return SingleChildScrollView(
          controller: _mainScrollController,
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
                                          ? 'Direcci+¦n no disponible'
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
                                  .join(' • '),
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
                    child: Row(
                      children: [
                        Container(
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
                          child: IconButton(
                            onPressed: _shareEstablishment,
                            icon: const Icon(
                              Icons.share,
                              color: Color(AppColors.primaryGreen),
                            ),
                            tooltip: 'Compartir establecimiento',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
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
                              establishmentId:
                                  _currentRestaurant.idEstablecimiento,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Men+¦ de secciones: Men+¦, Rese+¦as, Im+ígenes
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
              // Contenido de la secci+¦n seleccionada
              Container(
                color: const Color(AppColors.background),
                child: _buildTabContentWithIndexedStack(),
              ),
            ],
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
        
        // Cargar rese+¦as si se selecciona la pesta+¦a de rese+¦as
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

  Widget _buildTabContentWithIndexedStack() {
    return IndexedStack(
      index: _getTabIndex(),
      children: [
        // Tab 0: Men+¦
        _buildMenuSection(),
        // Tab 1: Rese+¦as
        _buildReviewsSection(),
        // Tab 2: Im+ígenes
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: _galleryWidget,
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isOwner = currentUser?.idUsuario == _currentRestaurant.propietarioId;
    final isAdmin = RoleConstants.isAdmin(currentUser?.idRol);
    final canCreateMenuItems = isOwner || isAdmin;

    if (_isLoadingMenu) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMenu != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Center(
          child: Text(
            'Error al cargar el menú: $_errorMenu',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(AppColors.errorRed)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botones de crear secci+¦n y crear plato (solo para propietario/admin/superadmin)
          if (canCreateMenuItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await _showCrearSeccionDialog();
                        if (result != null) {
                          await _refreshAfterMenuMutation();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear sección'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(AppColors.primaryOrange),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await _showCrearPlatoDialog();
                        if (result != null) {
                          await _refreshAfterMenuMutation();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear plato'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(AppColors.primaryOrange),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Secciones de menú ordenadas por creación
          if (_secciones.isEmpty && _platos.isEmpty)
            Center(
              child: Text(
                'No hay platos disponibles',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(AppColors.lightText)),
              ),
            )
          else ...[
            // Mostrar secciones con sus platos
            ..._secciones.asMap().entries.map((entry) {
              final seccion = entry.value;
              final platosDeLaSeccion = _platos
                  .where((p) => p.idTipoItemMenu == seccion.idTipoItem)
                  .toList();
              final isExpanded =
                  _expandedSections.contains(seccion.idTipoItem);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSeccionDesplegable(
                  seccion: seccion,
                  platos: platosDeLaSeccion,
                  isExpanded: isExpanded,
                  onToggle: () {
                    setState(() {
                      if (_expandedSections.contains(seccion.idTipoItem)) {
                        _expandedSections.remove(seccion.idTipoItem);
                      } else {
                        _expandedSections.add(seccion.idTipoItem);
                      }
                    });
                  },
                ),
              );
            }).toList(),
            // Sección "Otros" para platos sin sección
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOtrosDesplegable(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionDesplegable({
    required TipoItemMenu seccion,
    required List<ItemMenu> platos,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final canManage = currentUser != null &&
        (RoleConstants.isAdmin(currentUser.idRol) ||
            currentUser.idUsuario == _currentRestaurant.propietarioId);

    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        border: Border.all(color: const Color(0x1F000000), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) => onToggle(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          seccion.nombreTipo,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${platos.length} plato${platos.length != 1 ? 's' : ''}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: const Color(AppColors.lightText)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canManage) ...[
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 18,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(AppColors.primaryBlue),
                ),
                onPressed: () async {
                  final result = await _showCrearSeccionDialog(seccion: seccion);
                  if (result != null) {
                    await _refreshAfterMenuMutation();
                  }
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 18,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(AppColors.errorRed),
                ),
                onPressed: () async {
                  final shouldDeletePlatos = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: Text('Eliminar sección "${seccion.nombreTipo}"'),
                        content: const Text(
                          '¿Deseas eliminar también los platos dentro de esta sección?\n\nSi eliges "Sí", se borrarán los platos. Si eliges "No", los platos pasarán a la sección "Otros".',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(AppColors.errorRed),
                            ),
                            child: const Text('Sí'),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldDeletePlatos == null) return;

                  try {
                    if (shouldDeletePlatos) {
                      for (final plato in platos) {
                        await MenuService.eliminarPlato(plato.idItemMenu);
                      }
                    } else {
                      for (final plato in platos) {
                        await MenuService.actualizarPlato(
                          plato.idItemMenu,
                          {'id_tipo_item_menu': null},
                        );
                      }
                    }

                    await MenuService.eliminarSeccion(seccion.idTipoItem);
                    await _refreshAfterMenuMutation();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            shouldDeletePlatos
                                ? 'Sección y platos eliminados'
                                : 'Sección eliminada',
                          ),
                          backgroundColor: const Color(AppColors.successGreen),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar sección: ${e.toString()}'),
                        backgroundColor: const Color(AppColors.errorRed),
                      ),
                    );
                  }
                },
              ),
            ],
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        children: platos.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sin platos en esta sección',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(AppColors.lightText)),
                  ),
                ),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: platos
                        .map(
                          (plato) =>
                              _buildPlatoCard(plato),
                        )
                        .toList(),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildOtrosDesplegable() {
    // Platos que no pertenecen a ninguna sección (id_tipo_item_menu == null)
    final platosOtros = _platos.where((p) {
      return p.idTipoItemMenu == null;
    }).toList();

    final isExpanded = _expandedSections.contains(-1); // ID especial para "Otros"

    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        border: Border.all(color: const Color(0x1F000000), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) {
          setState(() {
            if (_expandedSections.contains(-1)) {
              _expandedSections.remove(-1);
            } else {
              _expandedSections.add(-1);
            }
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        title: Text(
          'Otros',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${platosOtros.length} plato${platosOtros.length != 1 ? 's' : ''}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: const Color(AppColors.lightText)),
        ),
        children: platosOtros.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sin platos sin clasificar',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(AppColors.lightText)),
                  ),
                ),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: platosOtros
                        .map(
                          (plato) =>
                              _buildPlatoCard(plato),
                        )
                        .toList(),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildPlatoCard(ItemMenu plato) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final canManage = currentUser != null &&
        (RoleConstants.isAdmin(currentUser.idRol) ||
            currentUser.idUsuario == _currentRestaurant.propietarioId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        decoration: BoxDecoration(
          color: const Color(AppColors.white),
          border: Border.all(color: const Color(0x0F000000), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre (grande) + Precio (a la derecha)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    plato.nombreItemMenu,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${plato.precio.toStringAsFixed(2)}€',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(AppColors.primaryOrange),
                      ),
                ),
              ],
            ),
            // Descripción (pequeña)
            if (plato.descripcion != null && plato.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                plato.descripcion!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(AppColors.lightText)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (plato.categorias.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: plato.categorias
                    .map(
                      (categoria) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _hexToColor(categoria.colorHex)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          categoria.nombreDieta,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _hexToColor(categoria.colorHex),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (canManage) ...[
              const SizedBox(height: 0),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 22, minHeight: 22),
                      splashRadius: 12,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: Color(AppColors.primaryBlue),
                      ),
                      onPressed: () async {
                        final updatedPlato = await _showCrearPlatoDialog(
                          plato: plato,
                        );
                        if (updatedPlato != null) {
                          await _refreshAfterMenuMutation();
                        }
                      },
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 22, minHeight: 22),
                      splashRadius: 12,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 15,
                        color: Color(AppColors.errorRed),
                      ),
                      onPressed: () async {
                        final wasVerifiedBefore =
                            _currentRestaurant.estadoVerificado == true;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text('Eliminar plato'),
                              content: Text(
                                '¿Seguro que quieres eliminar "${plato.nombreItemMenu}"? Esta acción no se puede deshacer.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        const Color(AppColors.errorRed),
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm != true) return;

                        try {
                          await MenuService.eliminarPlato(plato.idItemMenu);
                          await _refreshAfterMenuMutation();
                          await _handleMenuVerificationFlow(
                            wasVerifiedBefore: wasVerifiedBefore,
                            actionLabel: 'eliminado',
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Plato eliminado'),
                                backgroundColor: Color(AppColors.successGreen),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error al eliminar plato: ${e.toString().replaceFirst('Exception: ', '')}',
                                ),
                                backgroundColor:
                                    const Color(AppColors.errorRed),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getTabIndex() {
    switch (_selectedTab) {
      case 'resenas':
        return 1;
      case 'imagenes':
        return 2;
      case 'menu':
      default:
        return 0;
    }
  }

  Widget _buildReviewsSection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isOwner = currentUser?.idUsuario == _currentRestaurant.propietarioId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
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
                          // Actualizar puntuaci+¦n media y contador localmente
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
        // Lista de rese+¦as con infinite scroll
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
            height: 400, // Altura fija para la lista de rese+¦as
            child: ListView.separated(
              controller: _reviewScrollController,
              itemCount: _reviews.length + (_isLoadingReviews ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final timeAgo = _getTimeAgoText(review.fechaPublicacion);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final canDelete = currentUser != null &&
        (review.idUsuario == currentUser.idUsuario ||
            RoleConstants.isSuperadmin(currentUser.idRol));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(AppColors.white),
        border: Border.all(color: const Color(0x1F000000)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Column(
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
                        errorBuilder: (_, _, _) => Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                ),
              // Fecha
              Text(
                timeAgo,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(AppColors.lightText),
                ),
              ),
            ],
          ),
          // Bot+¦n eliminar en esquina inferior derecha
          if (canDelete)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _confirmDeleteReview(review),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(AppColors.errorRed),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(AppColors.white),
                    size: 18,
                  ),
                ),
              ),
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

  /// Diálogo para crear o editar una sección
  Future<String?> _showCrearSeccionDialog({TipoItemMenu? seccion}) async {
    final TextEditingController nombreController = TextEditingController(
      text: seccion?.nombreTipo ?? '',
    );
    bool isLoading = false;
    final bool isEditing = seccion != null;

    return showDialog<String?>(
      context: this.context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(AppColors.white),
              title: Text(
                isEditing ? 'Editar sección' : 'Crear sección',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(AppColors.darkText),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      hintText: 'Nombre de la sección',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Cancelar',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(AppColors.lightText),
                        ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading || nombreController.text.trim().isEmpty
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final nombreSeccion = nombreController.text.trim();
                            final currentSeccion = seccion;
                            if (currentSeccion != null) {
                              await MenuService.actualizarSeccion(
                                currentSeccion.idTipoItem,
                                nombreSeccion,
                              );
                            } else {
                              await MenuService.crearSeccion(
                                _currentRestaurant.idEstablecimiento,
                                nombreSeccion,
                              );
                            }

                            if (this.mounted) {
                              // Mostrar SnackBar ANTES de cerrar el dialog
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                      ? '"$nombreSeccion" ha sido actualizado'
                                      : '"$nombreSeccion" ha sido creado',
                                  ),
                                  backgroundColor:
                                      const Color(AppColors.successGreen),
                                ),
                              );
                              // Cerrar el dialog despu+®s
                              Navigator.of(ctx).pop(nombreSeccion);
                            }
                          } catch (e) {
                            if (this.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                      ? 'Error al actualizar sección: ${e.toString().replaceFirst('Exception: ', '')}'
                                      : 'Error al crear sección: ${e.toString().replaceFirst('Exception: ', '')}',
                                  ),
                                  backgroundColor: const Color(AppColors.errorRed),
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColors.primaryOrange),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Diálogo para crear o editar un plato
  Future<ItemMenu?> _showCrearPlatoDialog({ItemMenu? plato}) async {
    final categoriasDisponibles = await MenuService.getCategorias();
    final TextEditingController nombreController = TextEditingController(
      text: plato?.nombreItemMenu ?? '',
    );
    final TextEditingController descripcionController = TextEditingController(
      text: plato?.descripcion ?? '',
    );
    final TextEditingController precioController = TextEditingController(
      text: plato != null ? plato.precio.toStringAsFixed(2) : '',
    );
    int? seccionSeleccionada = plato?.idTipoItemMenu;
    bool isLoading = false;
    bool hasUnsavedChanges = false;
    final bool isEditing = plato != null;
    final Set<int> categoriasSeleccionadas = {
      ...?plato?.categorias.map((categoria) => categoria.idCategoria),
    };
    final Set<int> categoriasIniciales = Set<int>.from(categoriasSeleccionadas);
    final String precioInicial = plato != null ? plato.precio.toStringAsFixed(2) : '';
    final String nombreInicial = plato?.nombreItemMenu ?? '';
    final String descripcionInicial = plato?.descripcion ?? '';
    final int? seccionInicial = plato?.idTipoItemMenu;
    final bool wasVerifiedBefore = _currentRestaurant.estadoVerificado == true;

    return showDialog<ItemMenu?>(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateUnsavedChanges() {
              setState(() {
                hasUnsavedChanges = nombreController.text.trim() != nombreInicial ||
                    descripcionController.text.trim() != descripcionInicial ||
                    precioController.text.trim() != precioInicial ||
                    seccionSeleccionada != seccionInicial ||
                    categoriasSeleccionadas.length != categoriasIniciales.length ||
                    !categoriasSeleccionadas.containsAll(categoriasIniciales);
              });
            }

            Future<void> handleCancel() async {
              if (hasUnsavedChanges) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: const Color(AppColors.white),
                    title: const Text('¿Descartar cambios?'),
                    content: const Text(
                      'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(false),
                        child: const Text('Seguir editando'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(true),
                        child: const Text('Descartar'),
                      ),
                    ],
                  ),
                );
                if (confirm ?? false) {
                    Navigator.of(context).pop();
                }
              } else {
                  Navigator.of(context).pop();
              }
            }

            return AlertDialog(
                backgroundColor: const Color(AppColors.white),
                title: Text(
                  isEditing ? 'Editar plato' : 'Crear plato',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(AppColors.darkText),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nombre
                      TextField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del plato *',
                          hintText: 'Ej: Pizza Margherita',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => updateUnsavedChanges(),
                      ),
                      const SizedBox(height: 12),
                      // Descripción
                      TextField(
                        controller: descripcionController,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Ej: Con mozzarella y albahaca',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        maxLines: 3,
                        onChanged: (_) => updateUnsavedChanges(),
                      ),
                      const SizedBox(height: 12),
                      // Precio
                      TextField(
                        controller: precioController,
                        decoration: InputDecoration(
                          labelText: 'Precio (€) *',
                          hintText: '9.99',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixText: '€',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => updateUnsavedChanges(),
                      ),
                      const SizedBox(height: 12),
                      // Sección (desplegable)
                      DropdownButtonFormField<int?>(
                        initialValue: seccionSeleccionada,
                        decoration: InputDecoration(
                          labelText: 'Sección *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          // Opción "Otros" (sin sección)
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Otros (sin sección)'),
                          ),
                          // Secciones existentes
                          ..._secciones.map((seccion) {
                            return DropdownMenuItem<int?>(
                              value: seccion.idTipoItem,
                              child: Text(seccion.nombreTipo),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            seccionSeleccionada = value;
                          });
                          updateUnsavedChanges();
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Opciones dietéticas',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(AppColors.darkText),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (categoriasDisponibles.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No hay categorías dietéticas disponibles',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(AppColors.lightText),
                                ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categoriasDisponibles
                              .map(
                                (categoria) => FilterChip(
                                  selected: categoriasSeleccionadas
                                      .contains(categoria.idCategoria),
                                  label: Text(categoria.nombreDieta),
                                  showCheckmark: false,
                                  selectedColor: _hexToColor(categoria.colorHex)
                                      .withValues(alpha: 0.18),
                                  backgroundColor: const Color(AppColors.white),
                                  side: BorderSide(
                                    color: categoriasSeleccionadas
                                            .contains(categoria.idCategoria)
                                        ? _hexToColor(categoria.colorHex)
                                        : const Color(0x1F000000),
                                  ),
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: categoriasSeleccionadas
                                                .contains(categoria.idCategoria)
                                            ? _hexToColor(categoria.colorHex)
                                            : const Color(AppColors.darkText),
                                        fontWeight: FontWeight.w600,
                                      ),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        categoriasSeleccionadas.add(
                                          categoria.idCategoria,
                                        );
                                      } else {
                                        categoriasSeleccionadas.remove(
                                          categoria.idCategoria,
                                        );
                                      }
                                    });
                                    updateUnsavedChanges();
                                  },
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : handleCancel,
                    child: Text(
                      'Cancelar',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(AppColors.lightText),
                          ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ||
                            nombreController.text.trim().isEmpty ||
                            precioController.text.trim().isEmpty
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final precio =
                                  double.parse(precioController.text.trim());
                              final nombrePlato = nombreController.text.trim();
                              final descripcion = descripcionController.text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : descripcionController.text.trim();
                                final currentPlato = plato;

                                final nuevoPlato = isEditing && currentPlato != null
                                  ? await MenuService.actualizarPlato(
                                    currentPlato.idItemMenu,
                                    {
                                    'nombre_item_menu': nombrePlato,
                                    'descripcion': descripcion,
                                    'precio': precio,
                                    'id_establecimiento': _currentRestaurant
                                      .idEstablecimiento,
                                    'id_tipo_item_menu':
                                      seccionSeleccionada,
                                    'id_categorias':
                                      categoriasSeleccionadas.toList(),
                                    },
                                  )
                                  : await MenuService.crearPlato(
                                    _currentRestaurant.idEstablecimiento,
                                    nombrePlato,
                                    precio,
                                    seccionSeleccionada,
                                    descripcion: descripcion,
                                    idCategorias: categoriasSeleccionadas
                                      .toList(),
                                  );

                              if (this.mounted) {
                                // Mostrar SnackBar ANTES de cerrar el dialog
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? '"$nombrePlato" ha sido actualizado'
                                          : '"$nombrePlato" ha sido creado',
                                    ),
                                    backgroundColor:
                                        const Color(AppColors.successGreen),
                                  ),
                                );
                                // Cerrar el dialog despu+®s
                                Navigator.of(ctx).pop(nuevoPlato);
                              }
                              await _refreshAfterMenuMutation();
                              await _handleMenuVerificationFlow(
                                wasVerifiedBefore: wasVerifiedBefore,
                                actionLabel: isEditing ? 'editado' : 'creado',
                              );
                            } catch (e) {
                              if (this.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Error al actualizar plato: ${e.toString().replaceFirst('Exception: ', '')}'
                                          : 'Error al crear plato: ${e.toString().replaceFirst('Exception: ', '')}',
                                    ),
                                    backgroundColor:
                                        const Color(AppColors.errorRed),
                                  ),
                                );
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.primaryOrange),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              );
          },
        );
      },
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

