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
  State<CreateEstablishmentScreen> createState() => _CreateEstablishmentScreenState();
}

class _CreateEstablishmentScreenState extends State<CreateEstablishmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  final _propietarioSearchController = TextEditingController();
  late MapController _mapController;

  late final bool _isEditMode;
  late final RestaurantDetail? _restaurantToEdit;

  final CreateEstablishmentForm _formData = CreateEstablishmentForm(
    nombre: '',
    tiposEstablecimientoIds: [],
  );

  File? _selectedImage;
  bool _isUploadingImage = false;
  bool _isLoadingTipos = true;
  bool _isCreating = false;
  bool _isSearchingLocation = false;
  bool _isSearchingPropietarios = false;
  Timer? _searchDebounceTimer;
  Timer? _propietarioSearchTimer;

  List<TipoEstablecimiento> _tiposDisponibles = [];
  List<LocationSuggestion> _locationSuggestions = [];
  List<AdminUserModel> _usuariosFiltrados = [];
  Set<int> _tiposSeleccionados = {};
  AdminUserModel? _selectedPropietario;
  bool _showPropietarioSuggestions = false;
  bool _isPropietarioEditable = true; // El propietario es editable por defecto

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
    _propietarioSearchController.addListener(_onPropietarioSearchChanged);
    
    // Determinar si el propietario es editable según el rol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormAndCheckPermissions();
    });
  }

  /// Inicializa el formulario y verifica permisos para editar propietario
  void _initializeFormAndCheckPermissions() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (_isEditMode && _restaurantToEdit != null) {
      // Modo edición: cargar datos del establecimiento
      _loadEstablishmentDataForEditing();
      
      // El propietario solo es editable para superadmin
      _isPropietarioEditable = user?.idRol == RoleConstants.rolSuperadmin;
    } else {
      // Modo creación: si el usuario es propietario, pre-llenar con él
      if (user != null && user.idRol == RoleConstants.rolPropietario) {
        setState(() {
          _selectedPropietario = AdminUserModel(
            idUsuario: user.idUsuario,
            email: user.email,
            nombreCompleto: user.nombreCompleto,
            fotoPerfil: user.fotoPerfil,
            idRol: user.idRol,
          );
          _propietarioSearchController.text = '${user.nombreCompleto ?? user.email} (Tú)';
          _formData.propietarioId = user.idUsuario;
          _showPropietarioSuggestions = false;
        });
      }
    }
  }

  /// Carga los datos del establecimiento para modo edición
  void _loadEstablishmentDataForEditing() {
    if (_restaurantToEdit == null) return;

    setState(() {
      // Cargar campos básicos
      _nombreController.text = _restaurantToEdit!.nombre;
      _direccionController.text = _restaurantToEdit!.direccionTexto ?? '';
      
      if (_restaurantToEdit!.coordinates != null) {
        _mapCenter = _restaurantToEdit!.coordinates!;
        _latitudController.text = _restaurantToEdit!.coordinates!.latitude.toStringAsFixed(6);
        _longitudController.text = _restaurantToEdit!.coordinates!.longitude.toStringAsFixed(6);
        _formData.latitud = _restaurantToEdit!.coordinates!.latitude;
        _formData.longitud = _restaurantToEdit!.coordinates!.longitude;
      }
      
      if (_restaurantToEdit!.imagenUrl != null) {
        _formData.imagenUrl = _restaurantToEdit!.imagenUrl;
      }
      
      // Cargar tipos de establecimiento
      _tiposSeleccionados = Set<int>.from(widget.tiposEstablecimientoIds);
      _formData.tiposEstablecimientoIds = widget.tiposEstablecimientoIds;
      
      // Cargar propietario
      if (_restaurantToEdit!.propietarioId != null) {
        _selectedPropietario = AdminUserModel(
          idUsuario: _restaurantToEdit!.propietarioId!,
          email: 'propietario@example.com',
          nombreCompleto: 'Propietario del establecimiento',
          fotoPerfil: null,
          idRol: RoleConstants.rolPropietario,
        );
        _propietarioSearchController.text = 'Propietario del establecimiento';
        _formData.propietarioId = _restaurantToEdit!.propietarioId;
      }
      
      _formData.nombre = _nombreController.text;
      _formData.direccionTexto = _direccionController.text;
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _propietarioSearchTimer?.cancel();
    _scrollController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    _propietarioSearchController.dispose();
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
  Future<void> _selectLocationFromSuggestion(LocationSuggestion suggestion) async {
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
      _updateAddressFromCoordinates(currentLocation.latitude, currentLocation.longitude);
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
      final validationError = await ImageUploadService.validateImageFile(imageFile);
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

  /// Elimina la imagen seleccionada.
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _formData.imagenUrl = null;
    });
  }

  /// Maneja cambios en el campo de búsqueda de propietario con debounce
  void _onPropietarioSearchChanged() {
    _propietarioSearchTimer?.cancel();
    final query = _propietarioSearchController.text.trim();

    setState(() {
      _showPropietarioSuggestions = query.isNotEmpty;
      if (query.isEmpty) {
        _usuariosFiltrados.clear();
        _selectedPropietario = null;
      }
    });

    if (query.isEmpty) return;

    setState(() => _isSearchingPropietarios = true);

    _propietarioSearchTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final usuarios = await AdminService.searchUsuarios(query);
        if (mounted) {
          setState(() {
            _usuariosFiltrados = usuarios;
            _isSearchingPropietarios = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearchingPropietarios = false);
        }
      }
    });
  }

  /// Selecciona un usuario como propietario
  void _selectPropietario(AdminUserModel usuario) {
    setState(() {
      _selectedPropietario = usuario;
      _propietarioSearchController.text = usuario.nombreCompleto ?? usuario.email;
      _showPropietarioSuggestions = false;
      _usuariosFiltrados.clear();
      _formData.propietarioId = usuario.idUsuario;
    });
  }

  /// Muestra un diálogo de confirmación antes de salir.
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text('Si sales ahora, los datos que has introducido no se guardarán.'),
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
              Navigator.pop(context, false); // Salir de la pantalla de creación
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
            const SnackBar(content: Text('Establecimiento actualizado correctamente')),
          );
          Navigator.pop(context, true); // Señalar que se actualizó algo
        }
      } else {
        // Modo creación
        await AdminService.createEstablishment(_formData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Establecimiento creado correctamente')),
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
                child: CircularProgressIndicator(color: Color(AppColors.primaryOrange)),
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
                            color: const Color(AppColors.errorRed).withOpacity(0.1),
                            border: const Border(
                              left: BorderSide(color: Color(AppColors.errorRed), width: 3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(AppColors.errorRed)),
                          ),
                        ),

                      // Sección: Nombre
                    Text(
                      'Nombre del Establecimiento',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Mi Restaurante',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF9E9E9E),
                            ),
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
                    const SizedBox(height: 24),

                    // Sección: Imagen
                    Text(
                      'Imagen del Establecimiento',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setState(() {
                                    _errorMessage = 'Error: La imagen está corrupta o no se puede leer. '
                                        'Intenta seleccionar otra imagen.';
                                    _selectedImage = null;
                                  });
                                });
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: const Color(AppColors.accentBeige).withOpacity(0.3),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                              backgroundColor: const Color(AppColors.errorRed),
                              child: const Icon(Icons.close),
                            ),
                          ),
                          if (_formData.imagenUrl != null)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(AppColors.successGreen),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Subida',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
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
                          color: const Color(AppColors.accentBeige).withOpacity(0.3),
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
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            icon: const Icon(Icons.add_photo_alternate_rounded),
                            label: const Text('Seleccionar Imagen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(AppColors.primaryOrange),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_selectedImage == null || _isUploadingImage) ? null : _uploadImage,
                            icon: _isUploadingImage
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_rounded),
                            label: Text(_isUploadingImage ? 'Subiendo...' : 'Subir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(AppColors.primaryGreen),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sección: Ubicación (Dirección + Mapa integrados)
                    Text(
                      'Ubicación',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF9E9E9E),
                                ),
                                prefixIcon: const Icon(Icons.location_on_outlined),
                                suffixIcon: _isSearchingLocation
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(strokeWidth: 2),
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
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _locationSuggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion = _locationSuggestions[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.place_outlined, size: 18),
                                      title: Text(
                                        suggestion.displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      onTap: () => _selectLocationFromSuggestion(suggestion),
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
                                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: const Color(AppColors.white),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
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
                                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: const Color(AppColors.white),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
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
                                            _formData.latitud = point.latitude;
                                            _formData.longitud = point.longitude;
                                            _mapCenter = point;
                                            _latitudController.text = point.latitude.toStringAsFixed(6);
                                            _longitudController.text = point.longitude.toStringAsFixed(6);
                                          });
                                          _updateAddressFromCoordinates(point.latitude, point.longitude);
                                        },
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: 'com.example.resto_espe',
                                        ),
                                        MarkerLayer(
                                          markers: _formData.latitud != null && _formData.longitud != null
                                              ? [
                                                  Marker(
                                                    width: 42,
                                                    height: 42,
                                                    point: LatLng(_formData.latitud!, _formData.longitud!),
                                                    alignment: Alignment.topCenter,
                                                    child: Transform.translate(
                                                      offset: const Offset(0, 6),
                                                      child: const Icon(
                                                        Icons.location_on_rounded,
                                                        color: Color(AppColors.primaryOrange),
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
                                    backgroundColor: const Color(AppColors.primaryOrange),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (_tiposDisponibles.isEmpty)
                      Text(
                        'No hay tipos disponibles',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(AppColors.lightText),
                            ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tiposDisponibles.map((tipo) {
                          final isSelected = _tiposSeleccionados.contains(tipo.idTipoEstablecimiento);
                          return FilterChip(
                            label: Text(tipo.nombreCategoria),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _tiposSeleccionados.add(tipo.idTipoEstablecimiento);
                                } else {
                                  _tiposSeleccionados.remove(tipo.idTipoEstablecimiento);
                                }
                              });
                            },
                            selectedColor: const Color(AppColors.primaryOrange).withOpacity(0.2),
                            showCheckmark: true,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),

                    // Sección: Propietario
                    Builder(
                      builder: (context) {
                        final authProvider = context.read<AuthProvider>();
                        final isSuperadmin = RoleConstants.isSuperadmin(authProvider.currentUser?.idRol);
                        final isOwner = authProvider.currentUser?.idRol == RoleConstants.rolPropietario;
                        
                        // En modo edición, solo superadmin puede editar el propietario
                        final canEditPropietario = !_isEditMode || isSuperadmin;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Propietario del Establecimiento${isOwner || !canEditPropietario ? '' : ' (Opcional)'}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _propietarioSearchController,
                              enabled: canEditPropietario && !isOwner, // No editable si es propietario o no hay permisos
                              decoration: InputDecoration(
                                hintText: canEditPropietario ? 'Busca por nombre o email...' : 'No editable',
                                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: const Color(AppColors.white),
                                suffixIcon: _selectedPropietario != null && canEditPropietario && !isOwner
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _selectedPropietario = null;
                                            _propietarioSearchController.clear();
                                            _formData.propietarioId = null;
                                            _usuariosFiltrados.clear();
                                            _showPropietarioSuggestions = false;
                                          });
                                        },
                                      )
                                    : (_isSearchingPropietarios
                                        ? const SizedBox(
                                            width: 40,
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : null),
                              ),
                            ),
                            // Sugerencias de usuarios
                            if (_showPropietarioSuggestions && _usuariosFiltrados.isNotEmpty && canEditPropietario && !isOwner)
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
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _usuariosFiltrados.length,
                                  itemBuilder: (context, index) {
                                    final usuario = _usuariosFiltrados[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.person_outlined, size: 18),
                                      title: Text(
                                        usuario.nombreCompleto ?? usuario.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      subtitle: Text(
                                        usuario.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFF757575),
                                              fontSize: 11,
                                            ),
                                      ),
                                      onTap: () => _selectPropietario(usuario),
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
                        color: const Color(AppColors.warningYellow).withOpacity(0.1),
                        border: const Border(
                          left: BorderSide(color: Color(AppColors.warningYellow), width: 3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Los diferentes elementos del menú se añadirán desde la edición del establecimiento.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            onPressed: _isCreating ? null : _showExitConfirmation,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(AppColors.primaryOrange)),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Color(AppColors.primaryOrange)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createEstablishment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(AppColors.primaryOrange),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isCreating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(_isEditMode ? 'Guardar cambios' : 'Guardar'),
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
