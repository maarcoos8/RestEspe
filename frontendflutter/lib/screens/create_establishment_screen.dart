import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/role_constants.dart';
import '../data/models/admin_user_model.dart';
import '../data/models/create_establishment_form.dart';
import '../data/models/restaurant_detail_model.dart';
import '../data/models/tipo_establecimiento_model.dart';
import '../data/services/admin_service.dart';
import '../data/services/image_upload_service.dart';
import '../data/services/geocoding_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/scaffold_with_nav.dart';

/// Pantalla para crear o editar un establecimiento.
/// Incluye campos para:
/// - Nombre
/// - Imagen (con Cloudinary)
/// - Dirección (texto + mapa para coordenadas)
/// - Tipos de establecimiento (multi-select)
class CreateEstablishmentScreen extends StatefulWidget {
  const CreateEstablishmentScreen({
    super.key,
    this.restaurantToEdit,
    this.tiposEstablecimientoIds = const [],
  });

  /// Si se proporciona, la pantalla estará en modo edición
  final RestaurantDetail? restaurantToEdit;

  /// Tipos de establecimiento asociados (para modo edición)
  final List<int> tiposEstablecimientoIds;

  @override
  State<CreateEstablishmentScreen> createState() =>
      _CreateEstablishmentScreenState();
}

class _CreateEstablishmentScreenState extends State<CreateEstablishmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nombreController = TextEditingController();
  final _contactoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  final _responsableSearchController = TextEditingController();
  late MapController _mapController;

  late final bool _isEditMode;
  late final RestaurantDetail? _restaurantToEdit;

  final CreateEstablishmentForm _formData = CreateEstablishmentForm(
    nombre: '',
    contacto: '',
    tiposEstablecimientoIds: [],
  );

  File? _selectedImage;
  bool _isUploadingImage = false;
  bool _isLoadingTipos = true;
  bool _isCreating = false;
  bool _isSearchingLocation = false;
  bool _isSearchingResponsables = false;
  Timer? _searchDebounceTimer;
  Timer? _responsableSearchTimer;

  List<TipoEstablecimiento> _tiposDisponibles = [];
  List<LocationSuggestion> _locationSuggestions = [];
  List<AdminUserModel> _usuariosFiltrados = [];
  Set<int> _tiposSeleccionados = {};
  AdminUserModel? _selectedResponsable;
  bool _showResponsableSuggestions = false;
  bool _isResponsableEditable = true; // El responsable es editable por defecto

  LatLng _mapCenter = const LatLng(40.4168, -3.7038); // Madrid por defecto
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _restaurantToEdit = widget.restaurantToEdit;
    _isEditMode = _restaurantToEdit != null;

    _loadTiposEstablecimiento();
    _direccionController.addListener(_onDireccionChanged);
    _responsableSearchController.addListener(_onResponsableSearchChanged);

    // Determinar si el responsable es editable según el rol
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeFormAndCheckPermissions();
    });
  }

  /// Inicializa el formulario y verifica permisos para editar responsable
  Future<void> _initializeFormAndCheckPermissions() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (_isEditMode && _restaurantToEdit != null) {
      // Modo edición: cargar datos del establecimiento
      await _loadEstablishmentDataForEditing();

      // El responsable solo es editable para superadmin
      _isResponsableEditable = user?.idRol == RoleConstants.rolSuperadmin;
    } else {
      // Modo creación: si el usuario es responsable, pre-llenar con él
      if (user != null && user.idRol == RoleConstants.rolResponsable) {
        setState(() {
          _selectedResponsable = AdminUserModel(
            idUsuario: user.idUsuario,
            email: user.email,
            nombreCompleto: user.nombreCompleto,
            fotoPerfil: user.fotoPerfil,
            idRol: user.idRol,
          );
          _responsableSearchController.clear();
          _formData.responsableId = user.idUsuario;
          _showResponsableSuggestions = false;
        });
      }
    }
  }

  /// Carga los datos del establecimiento para modo edición
  Future<void> _loadEstablishmentDataForEditing() async {
    if (_restaurantToEdit == null) return;

    setState(() {
      // Cargar campos básicos
      _nombreController.text = _restaurantToEdit!.nombre;
      _contactoController.text = _restaurantToEdit!.contacto;
      _direccionController.text = _restaurantToEdit!.direccionTexto ?? '';

      if (_restaurantToEdit!.coordinates != null) {
        _mapCenter = _restaurantToEdit!.coordinates!;
        _latitudController.text = _restaurantToEdit!.coordinates!.latitude
            .toStringAsFixed(6);
        _longitudController.text = _restaurantToEdit!.coordinates!.longitude
            .toStringAsFixed(6);
        _formData.latitud = _restaurantToEdit!.coordinates!.latitude;
        _formData.longitud = _restaurantToEdit!.coordinates!.longitude;
      }

      if (_restaurantToEdit!.imagenUrl != null) {
        _formData.imagenUrl = _restaurantToEdit!.imagenUrl;
      }

      // Cargar tipos de establecimiento
      _tiposSeleccionados = Set<int>.from(widget.tiposEstablecimientoIds);
      _formData.tiposEstablecimientoIds = widget.tiposEstablecimientoIds;
    });

    // Cargar responsable con datos reales del backend (async)
    if (_restaurantToEdit!.responsableId != null) {
      try {
        final usuarios = await AdminService.getUsuarios();
        final responsable = usuarios.firstWhere(
          (u) => u.idUsuario == _restaurantToEdit!.responsableId,
          orElse: () => AdminUserModel(
            idUsuario: _restaurantToEdit!.responsableId!,
            email: 'No disponible',
            nombreCompleto: 'Responsable no encontrado',
            fotoPerfil: null,
            idRol: RoleConstants.rolResponsable,
          ),
        );
        setState(() {
            _selectedResponsable = responsable;
            _responsableSearchController.text =
              '${responsable.nombreCompleto ?? responsable.email}';
          _formData.responsableId = _restaurantToEdit!.responsableId;
        });
      } catch (e) {
        print('Error cargando responsable: $e');
        // Si hay error, dejar valores ficticios como fallback
        if (mounted) {
          setState(() {
            _selectedResponsable = AdminUserModel(
              idUsuario: _restaurantToEdit!.responsableId!,
              email: 'No disponible',
              nombreCompleto: 'Error cargando responsable',
              fotoPerfil: null,
              idRol: RoleConstants.rolResponsable,
            );
            _responsableSearchController.text = 'Error cargando responsable';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _responsableSearchTimer?.cancel();
    _scrollController.dispose();
    _nombreController.dispose();
    _contactoController.dispose();
    _direccionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    _responsableSearchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Carga los tipos de establecimiento disponibles.
  Future<void> _loadTiposEstablecimiento() async {
    try {
      final tipos = await AdminService.getTiposEstablecimiento();
      setState(() {
        _tiposDisponibles = tipos;
        _isLoadingTipos = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar tipos: $e';
        _isLoadingTipos = false;
      });
    }
  }

  /// Maneja cambios en el campo de dirección con debounce
  void _onDireccionChanged() {
    _searchDebounceTimer?.cancel();
    final query = _direccionController.text.trim();

    if (query.isEmpty) {
      setState(() => _locationSuggestions.clear());
      return;
    }

    setState(() => _isSearchingLocation = true);

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final suggestions = await GeocodingService.searchLocations(
          query,
          latitude: _formData.latitud,
          longitude: _formData.longitud,
        );

        if (mounted) {
          setState(() {
            _locationSuggestions = suggestions;
            _isSearchingLocation = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearchingLocation = false);
        }
      }
    });
  }

  /// Selecciona una ubicación de las sugerencias
  Future<void> _selectLocationFromSuggestion(
    LocationSuggestion suggestion,
  ) async {
    // Actualizar coordenadas
    setState(() {
      _formData.latitud = suggestion.latitude;
      _formData.longitud = suggestion.longitude;
      _mapCenter = LatLng(suggestion.latitude, suggestion.longitude);
      _latitudController.text = suggestion.latitude.toStringAsFixed(6);
      _longitudController.text = suggestion.longitude.toStringAsFixed(6);
      _locationSuggestions.clear();
    });

    // Centrar mapa
    _mapController.move(_mapCenter, 15.0);

    // Obtener dirección con más detalle
    final reverseResult = await GeocodingService.reverseGeocode(
      suggestion.latitude,
      suggestion.longitude,
    );

    if (mounted && reverseResult != null) {
      setState(() {
        _direccionController.text = reverseResult.formattedAddress;
      });
    }
  }

  /// Actualiza la dirección basado en coordenadas (reverse geocode)
  Future<void> _updateAddressFromCoordinates(double lat, double lon) async {
    try {
      final result = await GeocodingService.reverseGeocode(lat, lon);
      if (mounted && result != null) {
        setState(() {
          _direccionController.text = result.formattedAddress;
        });
      }
    } catch (e) {
      // Silenciosamente fallar si no se puede hacer reverse geocode
    }
  }

  /// Actualiza el mapa cuando cambian las coordenadas manualmente
  void _updateMapFromCoordinates() {
    final lat = double.tryParse(_latitudController.text);
    final lon = double.tryParse(_longitudController.text);

    if (lat != null && lon != null) {
      setState(() {
        _formData.latitud = lat;
        _formData.longitud = lon;
        _mapCenter = LatLng(lat, lon);
      });
      _mapController.move(_mapCenter, 15.0);
      _updateAddressFromCoordinates(lat, lon);
    }
  }

  /// Centra el mapa en la ubicación actual del marcador del formulario.
  void _recenterMapToCurrentLocation() {
    _moveToDeviceCurrentLocation();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _setTopError(String message) {
    setState(() {
      _errorMessage = message;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToTop();
      }
    });
  }

  /// Centra el mapa en la ubicación actual del dispositivo y actualiza campos.
  Future<void> _moveToDeviceCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa la ubicación del dispositivo')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado')),
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      if (!mounted) {
        return;
      }

      setState(() {
        _mapCenter = currentLocation;
        _formData.latitud = currentLocation.latitude;
        _formData.longitud = currentLocation.longitude;
        _latitudController.text = currentLocation.latitude.toStringAsFixed(6);
        _longitudController.text = currentLocation.longitude.toStringAsFixed(6);
      });

      _mapController.move(currentLocation, 15.0);
      _updateAddressFromCoordinates(
        currentLocation.latitude,
        currentLocation.longitude,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación actual')),
      );
    }
  }

  /// Abre el selector de imagen (cámara o galería).
  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: const Text('¿De dónde deseas obtener la imagen?'),
        actions: [
          TextButton(
            onPressed: () async {
              final file = await picker.pickImage(source: ImageSource.gallery);
              if (mounted) Navigator.pop(context, file);
            },
            child: const Text('Galería'),
          ),
          TextButton(
            onPressed: () async {
              final file = await picker.pickImage(source: ImageSource.camera);
              if (mounted) Navigator.pop(context, file);
            },
            child: const Text('Cámara'),
          ),
        ],
      ),
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      // Validar el archivo antes de asignarlo
      final validationError = await ImageUploadService.validateImageFile(
        imageFile,
      );
      if (validationError != null) {
        if (mounted) {
          setState(() {
            _errorMessage = validationError;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationError),
              backgroundColor: const Color(AppColors.errorRed),
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImage = imageFile;
        _errorMessage = null;
      });
    }
  }

  /// Sube la imagen a Cloudinary usando el servicio.
  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
      _errorMessage = null;
    });

    try {
      final imageService = ImageUploadService(baseUrl: AppConstants.apiBaseUrl);
      final imageUrl = await imageService.uploadImageUrlOnly(
        imageFile: _selectedImage!,
        useCase: 'establecimiento',
      );

      setState(() {
        _formData.imagenUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen subida correctamente'),
            backgroundColor: Color(AppColors.successGreen),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        _errorMessage = 'Error al subir imagen: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(AppColors.errorRed),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Elimina la imagen seleccionada o la URL existente.
  /// En modo edición, si elimina la imagen guardada, deberá subir una nueva.
  void _removeImage() {
    setState(() {
      // Si hay una imagen seleccionada pero no subida, solo la eliminamos
      if (_selectedImage != null) {
        _selectedImage = null;
      } else if (_formData.imagenUrl != null) {
        // Si estamos en modo edición y elimina la imagen guardada,
        // la URL se borra pero mostraremos el placeholder de "Seleccionar imagen"
        _formData.imagenUrl = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Imagen eliminada. Selecciona una nueva imagen para continuar.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  /// Maneja cambios en el campo de búsqueda de responsable con debounce
  void _onResponsableSearchChanged() {
    _responsableSearchTimer?.cancel();
    final query = _responsableSearchController.text.trim();

    setState(() {
      _showResponsableSuggestions = query.isNotEmpty;
      if (query.isEmpty) {
        _usuariosFiltrados.clear();
        _selectedResponsable = null;
      }
    });

    if (query.isEmpty) return;

    setState(() => _isSearchingResponsables = true);

    _responsableSearchTimer = Timer(
      const Duration(milliseconds: 500),
      () async {
        try {
          final usuarios = await AdminService.searchUsuarios(query, roleId: RoleConstants.rolResponsable);
          if (mounted) {
            setState(() {
              _usuariosFiltrados = usuarios;
              _isSearchingResponsables = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isSearchingResponsables = false);
          }
        }
      },
    );
  }

  /// Selecciona un usuario como responsable
  void _selectResponsable(AdminUserModel usuario) {
    setState(() {
      _selectedResponsable = usuario;
      _responsableSearchController.text =
          usuario.nombreCompleto ?? usuario.email;
      _showResponsableSuggestions = false;
      _usuariosFiltrados.clear();
      _formData.responsableId = usuario.idUsuario;
    });
  }

  /// Muestra un diálogo de confirmación antes de salir.
  void _showExitConfirmation() {
    final title = _isEditMode ? '¿Descartar cambios?' : '¿Descartar cambios?';
    final message = _isEditMode
        ? 'Si sales ahora, los cambios que has realizado no se guardarán.'
        : 'Si sales ahora, los datos que has introducido no se guardarán.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continuar editando',
              style: TextStyle(color: Color(AppColors.primaryOrange)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo
              Navigator.pop(
                context,
                false,
              ); // Salir de la pantalla de creación/edición
            },
            child: const Text(
              'Descartar',
              style: TextStyle(color: Color(AppColors.errorRed)),
            ),
          ),
        ],
      ),
    );
  }

  /// Crea o actualiza el establecimiento en el backend.
  Future<void> _createEstablishment() async {
    if (!_formKey.currentState!.validate()) {
      _setTopError('Revisa los campos marcados en rojo');
      return;
    }
    if (_formData.imagenUrl == null) {
      _setTopError('Por favor sube una imagen');
      return;
    }
    if (_formData.latitud == null || _formData.longitud == null) {
      _setTopError('Por favor selecciona coordenadas');
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // Actualizar datos del formulario
      _formData.nombre = _nombreController.text.trim();
      _formData.contacto = _contactoController.text.trim();
      _formData.direccionTexto = _direccionController.text.trim();
      _formData.tiposEstablecimientoIds = _tiposSeleccionados.toList();

      if (_isEditMode && _restaurantToEdit != null) {
        // Modo actualización
        await AdminService.updateEstablishment(
          _restaurantToEdit!.idEstablecimiento,
          _formData,
          _tiposSeleccionados.toList(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Establecimiento actualizado correctamente'),
            ),
          );
          Navigator.pop(context, true); // Señalar que se actualizó algo
        }
      } else {
        // Modo creación
        await AdminService.createEstablishment(_formData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Establecimiento creado correctamente'),
            ),
          );
          Navigator.pop(context, true); // Señalar que se creó algo
        }
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
      });
      _setTopError('Error al crear establecimiento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: ScaffoldWithNav(
        title: _isEditMode ? 'Editar Establecimiento' : 'Crear Establecimiento',
        currentIndex: 3,
        body: _isLoadingTipos
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(AppColors.primaryOrange),
                ),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(
                              AppColors.errorRed,
                            ).withOpacity(0.1),
                            border: const Border(
                              left: BorderSide(
                                color: Color(AppColors.errorRed),
                                width: 3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(AppColors.errorRed),
                            ),
                          ),
                        ),

                      // Sección: Nombre
                      Text(
                        'Nombre del Establecimiento',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Mi Restaurante',
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF9E9E9E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: const Color(AppColors.white),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Información de contacto',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactoController,
                        decoration: InputDecoration(
                          hintText: 'Correo/teléfono de contacto',
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF9E9E9E)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: const Color(AppColors.white),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El contacto es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Sección: Imagen
                      Text(
                        'Imagen del Establecimiento',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Si hay error al decodificar la imagen
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    setState(() {
                                      _errorMessage =
                                          'Error: La imagen está corrupta o no se puede leer. '
                                          'Intenta seleccionar otra imagen.';
                                      _selectedImage = null;
                                    });
                                  });
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: const Color(
                                      AppColors.accentBeige,
                                    ).withOpacity(0.3),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_rounded,
                                            size: 48,
                                            color: Color(AppColors.errorRed),
                                          ),
                                          SizedBox(height: 8),
                                          Text('Imagen dañada'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: FloatingActionButton.small(
                                onPressed: _removeImage,
                                backgroundColor: const Color(
                                  AppColors.errorRed,
                                ),
                                child: const Icon(Icons.close),
                              ),
                            ),
                            if (_formData.imagenUrl != null)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(AppColors.successGreen),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Subida',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      else if (_selectedImage == null &&
                          _formData.imagenUrl != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _formData.imagenUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: const Color(
                                      AppColors.accentBeige,
                                    ).withOpacity(0.3),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_rounded,
                                            size: 48,
                                            color: Color(AppColors.errorRed),
                                          ),
                                          SizedBox(height: 8),
                                          Text('No se pudo cargar la imagen'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: FloatingActionButton.small(
                                onPressed: _removeImage,
                                backgroundColor: const Color(
                                  AppColors.errorRed,
                                ),
                                child: const Icon(Icons.close),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.successGreen),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Guardada',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (_selectedImage == null && _formData.imagenUrl == null)
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(AppColors.primaryOrange),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(
                              AppColors.accentBeige,
                            ).withOpacity(0.3),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image_rounded,
                                  size: 48,
                                  color: Color(AppColors.primaryOrange),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para seleccionar una imagen',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(AppColors.lightText),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectImage,
                              icon: const Icon(
                                Icons.add_photo_alternate_rounded,
                              ),
                              label: const Text('Seleccionar Imagen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  AppColors.primaryOrange,
                                ),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_selectedImage == null || _isUploadingImage)
                                  ? null
                                  : _uploadImage,
                              icon: _isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload_rounded),
                              label: Text(
                                _isUploadingImage ? 'Subiendo...' : 'Subir',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  AppColors.primaryGreen,
                                ),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sección: Ubicación (Dirección + Mapa integrados)
                      Text(
                        'Ubicación',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Campo de búsqueda de dirección con autocompletado
                      Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Campo de entrada con sugerencias
                              TextFormField(
                                controller: _direccionController,
                                decoration: InputDecoration(
                                  hintText: 'Busca una dirección...',
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                  prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  suffixIcon: _isSearchingLocation
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: const Color(AppColors.white),
                                ),
                              ),

                              // Sugerencias de ubicación
                              if (_locationSuggestions.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(AppColors.white),
                                    border: Border.all(
                                      color: const Color(0x1A000000),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _locationSuggestions.length,
                                    itemBuilder: (context, index) {
                                      final suggestion =
                                          _locationSuggestions[index];
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.place_outlined,
                                          size: 18,
                                        ),
                                        title: Text(
                                          suggestion.displayName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        onTap: () =>
                                            _selectLocationFromSuggestion(
                                              suggestion,
                                            ),
                                      );
                                    },
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Coordenadas manuales (2 campos en fila)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latitudController,
                                      decoration: InputDecoration(
                                        labelText: 'Latitud',
                                        hintText: '0.0000',
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color(AppColors.white),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            signed: true,
                                            decimal: true,
                                          ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          _updateMapFromCoordinates();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _longitudController,
                                      decoration: InputDecoration(
                                        labelText: 'Longitud',
                                        hintText: '0.0000',
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color(AppColors.white),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            signed: true,
                                            decimal: true,
                                          ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          _updateMapFromCoordinates();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Mapa interactivo
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      height: 300,
                                      child: FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: _mapCenter,
                                          initialZoom: 15.0,
                                          onTap: (tapPosition, point) {
                                            setState(() {
                                              _formData.latitud =
                                                  point.latitude;
                                              _formData.longitud =
                                                  point.longitude;
                                              _mapCenter = point;
                                              _latitudController.text = point
                                                  .latitude
                                                  .toStringAsFixed(6);
                                              _longitudController.text = point
                                                  .longitude
                                                  .toStringAsFixed(6);
                                            });
                                            _updateAddressFromCoordinates(
                                              point.latitude,
                                              point.longitude,
                                            );
                                          },
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.example.resto_espe',
                                          ),
                                          MarkerLayer(
                                            markers:
                                                _formData.latitud != null &&
                                                    _formData.longitud != null
                                                ? [
                                                    Marker(
                                                      width: 42,
                                                      height: 42,
                                                      point: LatLng(
                                                        _formData.latitud!,
                                                        _formData.longitud!,
                                                      ),
                                                      alignment:
                                                          Alignment.topCenter,
                                                      child: Transform.translate(
                                                        offset: const Offset(
                                                          0,
                                                          6,
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .location_on_rounded,
                                                          color: Color(
                                                            AppColors
                                                                .primaryOrange,
                                                          ),
                                                          size: 40,
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Botón de ubicación actual (esquina inferior derecha)
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: _MapActionButton(
                                      icon: Icons.my_location_rounded,
                                      backgroundColor: const Color(
                                        AppColors.primaryOrange,
                                      ),
                                      iconColor: const Color(AppColors.white),
                                      onTap: _recenterMapToCurrentLocation,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sección: Tipos de Establecimiento
                      Text(
                        'Tipos de Establecimiento',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_tiposDisponibles.isEmpty)
                        Text(
                          'No hay tipos disponibles',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(AppColors.lightText),
                              ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tiposDisponibles.map((tipo) {
                            final isSelected = _tiposSeleccionados.contains(
                              tipo.idTipoEstablecimiento,
                            );
                            return FilterChip(
                              label: Text(tipo.nombreCategoria),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _tiposSeleccionados.add(
                                      tipo.idTipoEstablecimiento,
                                    );
                                  } else {
                                    _tiposSeleccionados.remove(
                                      tipo.idTipoEstablecimiento,
                                    );
                                  }
                                });
                              },
                              selectedColor: const Color(
                                AppColors.primaryOrange,
                              ).withOpacity(0.2),
                              showCheckmark: true,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // Sección: Responsable
                      Builder(
                        builder: (context) {
                          final authProvider = context.read<AuthProvider>();
                          final isSuperadmin = RoleConstants.isSuperadmin(
                            authProvider.currentUser?.idRol,
                          );
                          final isOwner =
                              authProvider.currentUser?.idRol ==
                              RoleConstants.rolResponsable;

                            // En modo edición, solo superadmin puede editar el responsable
                            final canEditResponsable =
                              !_isEditMode || isSuperadmin;
                            final isReadOnly = !canEditResponsable || isOwner;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Responsable del establecimiento${isOwner || !canEditResponsable ? '' : ' (Opcional)'}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (isReadOnly &&
                                  _selectedResponsable != null &&
                                  !_isEditMode)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0x1A000000),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(AppColors.white),
                                  ),
                                  child: Text(
                                    'Tú eres el responsable (No editable)',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: const Color(
                                            AppColors.primaryOrange,
                                          ),
                                        ),
                                  ),
                                )
                              else if (!isReadOnly &&
                                  _selectedResponsable != null &&
                                  isOwner &&
                                  !_isEditMode)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0x1A000000),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(AppColors.white),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tú eres el responsable (No editable)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: const Color(
                                                AppColors.primaryOrange,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedResponsable!.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              AppColors.primaryOrange,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'Es el responsable (No editable)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(
                                                AppColors.primaryOrange,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (!isReadOnly &&
                                  _selectedResponsable != null &&
                                  !isOwner &&
                                  canEditResponsable &&
                                  !_isEditMode)
                                // Mostrar responsable actual para superadmin que puede editarlo
                                Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0x1A000000),
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        color: const Color(AppColors.white),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Responsable actual:',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF9E9E9E,
                                                  ),
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _selectedResponsable!
                                                    .nombreCompleto ??
                                              _selectedResponsable!.email,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedResponsable!.email,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF9E9E9E,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                        controller: _responsableSearchController,
                                        enabled: canEditResponsable && !isOwner,
                                      decoration: InputDecoration(
                                        hintText:
                                          'Busca un nuevo responsable para cambiar...',
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color(AppColors.white),
                                      ),
                                    ),
                                  ],
                                )
                              else if (!isReadOnly &&
                                  _selectedResponsable != null &&
                                  !isOwner &&
                                  !canEditResponsable &&
                                  !_isEditMode)
                                // Mostrar responsable sin poder editar (responsable normal viendo su establecimiento)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0x1A000000),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(AppColors.white),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedResponsable!.nombreCompleto ??
                                          _selectedResponsable!.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedResponsable!.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: const Color(0xFF9E9E9E),
                                            ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              AppColors.primaryBlue,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'No editable',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(
                                                AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                TextFormField(
                                  controller: _responsableSearchController,
                                  enabled: canEditResponsable && !isOwner,
                                  decoration: InputDecoration(
                                    hintText: canEditResponsable
                                        ? 'Busca por nombre o email...'
                                        : 'No editable',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF9E9E9E),
                                        ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: const Color(AppColors.white),
                                    suffixIcon:
                                        _selectedResponsable != null &&
                                            canEditResponsable &&
                                            !isOwner
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _selectedResponsable = null;
                                                _responsableSearchController
                                                    .clear();
                                                _formData.responsableId = null;
                                                _usuariosFiltrados.clear();
                                                _showResponsableSuggestions =
                                                    false;
                                              });
                                            },
                                          )
                                        : (_isSearchingResponsables
                                              ? const SizedBox(
                                                  width: 40,
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      8.0,
                                                    ),
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                )
                                              : null),
                                  ),
                                ),
                              // Sugerencias de usuarios
                                if (_showResponsableSuggestions &&
                                  _usuariosFiltrados.isNotEmpty &&
                                  canEditResponsable &&
                                  !isOwner)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(AppColors.white),
                                    border: Border.all(
                                      color: const Color(0x1A000000),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _usuariosFiltrados.length,
                                    itemBuilder: (context, index) {
                                      final usuario = _usuariosFiltrados[index];
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.person_outlined,
                                          size: 18,
                                        ),
                                        title: Text(
                                          usuario.nombreCompleto ??
                                              usuario.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                        subtitle: Text(
                                          usuario.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF757575),
                                                fontSize: 11,
                                              ),
                                        ),
                                        onTap: () =>
                                            _selectResponsable(usuario),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Nota importante
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            AppColors.warningYellow,
                          ).withOpacity(0.1),
                          border: const Border(
                            left: BorderSide(
                              color: Color(AppColors.warningYellow),
                              width: 3,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Los diferentes elementos del menú se añadirán desde la edición del establecimiento.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(AppColors.darkText),
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botones: Cancelar y Guardar
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isCreating
                                  ? null
                                  : _showExitConfirmation,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(AppColors.primaryOrange),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Color(AppColors.primaryOrange),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isCreating
                                  ? null
                                  : _createEstablishment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  AppColors.primaryOrange,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: _isCreating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      _isEditMode
                                          ? 'Guardar cambios'
                                          : 'Guardar',
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Botón de acción flotante para el mapa (ubicación actual, zoom, etc.)
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
      shadowColor: Colors.black.withOpacity(0.14),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}
