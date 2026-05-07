import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/services/image_upload_service.dart';

/// Widget de ejemplo que captura una imagen con image_picker y la sube al backend.
class ImageUploaderWidget extends StatefulWidget {
  const ImageUploaderWidget({super.key, required this.apiBaseUrl, required this.idEstablecimiento, required this.idUsuario});

  final String apiBaseUrl;
  final int idEstablecimiento;
  final int idUsuario;

  @override
  State<ImageUploaderWidget> createState() => _ImageUploaderWidgetState();
}

class _ImageUploaderWidgetState extends State<ImageUploaderWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _uploadedUrl;
  bool _isUploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _isUploading = true;
        _error = null;
      });

      final service = ImageUploadService(baseUrl: widget.apiBaseUrl);
      final url = await service.uploadImage(
        imageFile: _selectedImage!,
        idEstablecimiento: widget.idEstablecimiento,
        idUsuario: widget.idUsuario,
      );

      setState(() {
        _uploadedUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _pickAndUpload,
          icon: const Icon(Icons.camera_alt),
          label: Text(_isUploading ? 'Subiendo...' : 'Tomar foto y subir'),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          Image.file(_selectedImage!, height: 160),
        ],
        if (_uploadedUrl != null) ...[
          const SizedBox(height: 8),
          Text('Imagen subida:'),
          SelectableText(_uploadedUrl!),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text('Error: $_error', style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}
