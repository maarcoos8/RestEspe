import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/models/review_model.dart';
import '../data/services/review_service.dart';
import '../providers/auth_provider.dart';

/// Dialog para crear una nueva reseña
class ReviewCreationDialog extends StatefulWidget {
  const ReviewCreationDialog({
    super.key,
    required this.idEstablecimiento,
    required this.onReviewCreated,
  });

  final int idEstablecimiento;
  final Function(ReviewModel) onReviewCreated;

  @override
  State<ReviewCreationDialog> createState() => _ReviewCreationDialogState();
}

class _ReviewCreationDialogState extends State<ReviewCreationDialog> {
  double _selectedRating = 0.0;
  final TextEditingController _commentController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _hasChanges = true;
    });
  }

  void _onRatingChanged(double newRating) {
    setState(() {
      _selectedRating = newRating;
      _hasChanges = true;
    });
  }

  void _onCommentChanged(String value) {
    setState(() {
      _hasChanges = true;
    });
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text('¿Deseas descartar los cambios en la reseña?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el dialog de confirmación
              Navigator.pop(context); // Cierra el dialog de creación
            },
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  void _handleBackPress() {
    if (_hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.pop(context);
    }
  }

  void _handleCancel() {
    if (_hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.pop(context);
    }
  }

  void _handlePost() {
    // Validación: requiere al menos una estrella
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una puntuación')),
      );
      return;
    }

    _postReview();
  }

  Future<void> _postReview() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      final service = ReviewService();

      final created = await service.createReview(
        idEstablecimiento: widget.idEstablecimiento,
        idUsuario: currentUser.idUsuario,
        puntuacion: _selectedRating,
        comentario: _commentController.text.isNotEmpty
            ? _commentController.text
            : null,
        imageFile: _selectedImage,
      );

      if (created != null) {
        if (!mounted) return;
        // Enriquecer con datos del usuario local si es necesario
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = auth.currentUser;
        var enriched = created;
        if (currentUser != null) {
          enriched = created.copyWith(
            nombreUsuario: currentUser.nombreCompleto ?? currentUser.email,
            fotoPerfil: currentUser.fotoPerfil,
          );
        }
        widget.onReviewCreated(enriched);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reseña publicada'),
            backgroundColor: const Color(AppColors.successGreen),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al publicar reseña: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasChanges) {
          _showUnsavedChangesDialog();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nueva reseña',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _handleBackPress,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rating Stars
                Center(child: _buildRatingSelector()),
                const SizedBox(height: 20),

                // Puntuación actual
                Center(
                  child: Text(
                    _selectedRating == 0
                        ? 'Selecciona una puntuación'
                        : 'Puntuación: $_selectedRating ⭐',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Comment TextField
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: 'Comentario (opcional)',
                    hintText: 'Cuéntanos tu experiencia...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(AppColors.primaryOrange),
                        width: 2,
                      ),
                    ),
                  ),
                  minLines: 3,
                  maxLines: 5,
                  onChanged: _onCommentChanged,
                ),
                const SizedBox(height: 16),

                // Image Uploader
                if (_selectedImage == null)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(AppColors.primaryOrange),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(AppColors.accentBeige),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Color(AppColors.primaryOrange),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Agregar imagen (opcional)',
                              style: TextStyle(
                                color: Color(AppColors.primaryOrange),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleCancel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(AppColors.primaryOrange),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(AppColors.primaryOrange),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _handlePost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primaryOrange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _isUploading ? 'Subiendo...' : 'Postear',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(AppColors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1; // 1..5

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            // Detect tap position within the star to choose half or full
            double width = 40.0; // fixed hit area width per star
            final dx = details.localPosition.dx;
            final isHalf = dx < (width / 2);
            final newRating = isHalf ? (starIndex - 0.5) : starIndex.toDouble();
            _onRatingChanged(newRating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Icon(
                  _getStarIconForIndex(starIndex),
                  size: 32,
                  color: _getStarColorForIndex(starIndex),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  IconData _getStarIconForIndex(int starIndex) {
    if (_selectedRating >= starIndex) {
      return Icons.star;
    } else if (_selectedRating >= (starIndex - 0.5)) {
      return Icons.star_half;
    } else {
      return Icons.star_outline;
    }
  }

  Color _getStarColorForIndex(int starIndex) {
    return _selectedRating >= (starIndex - 0.5)
        ? const Color(AppColors.primaryOrange)
        : Colors.grey[300]!;
  }
}
