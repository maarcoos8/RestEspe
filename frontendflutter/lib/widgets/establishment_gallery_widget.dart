import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../data/models/photography_model.dart';
import '../data/services/photography_service.dart';
import '../data/services/image_upload_service.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'photo_viewer_dialog.dart';

/// Galería de fotografías de un establecimiento en grid 3x3.
/// El primer cuadrado contiene un botón "+" para subir nuevas fotos.
class EstablishmentGallery extends StatefulWidget {
  const EstablishmentGallery({
    super.key,
    required this.idEstablecimiento,
  });

  final int idEstablecimiento;

  @override
  State<EstablishmentGallery> createState() => _EstablishmentGalleryState();
}

class _EstablishmentGalleryState extends State<EstablishmentGallery> {
  final PhotographyService _photographyService = PhotographyService();
  late Future<List<PhotographyModel>> _photosFuture;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void didUpdateWidget(EstablishmentGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idEstablecimiento != widget.idEstablecimiento) {
      _loadPhotos();
    }
  }

  void _loadPhotos() {
    _photosFuture =
        _photographyService.getPhotographiesByEstablishment(widget.idEstablecimiento);
  }

  Future<void> _handlePhotoUpload() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes estar autenticado para subir fotos')),
        );
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      if (mounted) {
        // Mostrar loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Subiendo fotografía...'),
                ],
              ),
            ),
          ),
        );

        try {
          final imageUploadService = ImageUploadService(
            baseUrl: AppConstants.apiBaseUrl,
          );

          await imageUploadService.uploadImage(
            imageFile: imageFile,
            idEstablecimiento: widget.idEstablecimiento,
            idUsuario: currentUser.idUsuario,
          );

          if (mounted) {
            Navigator.pop(context); // Cerrar loading

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fotografía subida exitosamente'),
                backgroundColor: Color(AppColors.successGreen),
              ),
            );

            // Recargar fotos automáticamente
            setState(() {
              _loadPhotos();
            });
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Cerrar loading

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error subiendo fotografía: $e'),
                backgroundColor: const Color(AppColors.errorRed),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(AppColors.errorRed),
          ),
        );
      }
    }
  }

  void _openPhotoViewer(List<PhotographyModel> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => PhotoViewerDialog(
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PhotographyModel>>(
      future: _photosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final photos = snapshot.data ?? [];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: photos.length + 1, // +1 para el botón de agregar
          itemBuilder: (context, index) {
            // Primer elemento: botón para agregar foto
            if (index == 0) {
              return _buildAddPhotoButton(context);
            }

            // Resto: fotos
            final photo = photos[index - 1];
            return _buildPhotoTile(context, photo, photos, index - 1);
          },
        );
      },
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return GestureDetector(
      onTap: _handlePhotoUpload,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7F1),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add_a_photo,
            size: 40,
            color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoTile(
    BuildContext context,
    PhotographyModel photo,
    List<PhotographyModel> allPhotos,
    int photoIndex,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    // Verificar si el usuario puede eliminar (es propietario o superadmin)
    final canDelete = currentUser != null && 
        (currentUser.idUsuario == photo.idUsuario || 
         currentUser.idRol == AppConstants.roleSuperAdmin);

    return GestureDetector(
      onTap: () => _openPhotoViewer(allPhotos, photoIndex),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.urlImagen,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF5F5F5),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Color(0xFF999999)),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
            // Botón de eliminar en la esquina inferior izquierda
            if (canDelete)
              Positioned(
                bottom: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => _showDeleteConfirmation(context, photo),
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
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, PhotographyModel photo) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar fotografía'),
        content: const Text('¿Está seguro de que desea eliminar esta fotografía? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo

              try {
                await _photographyService.deletePhotography(
                  photo.idFoto,
                  currentUser.idUsuario,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fotografía eliminada exitosamente'),
                      backgroundColor: Color(AppColors.successGreen),
                    ),
                  );

                  // Recargar fotos
                  setState(() {
                    _loadPhotos();
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error eliminando fotografía: $e'),
                      backgroundColor: const Color(AppColors.errorRed),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(AppColors.errorRed),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
