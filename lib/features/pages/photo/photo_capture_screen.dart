import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecom_app/models/client_info.dart';
import 'package:telecom_app/models/operation_photo.dart';
import 'package:telecom_app/models/operation.dart';
import 'package:telecom_app/core/utils/app_theme.dart';
import 'package:telecom_app/services/pdf_service.dart';

class PhotoCaptureScreen extends StatefulWidget {
  final ClientInfo clientInfo;
  final String technicianName;
  final String technicianDomain;

  const PhotoCaptureScreen({
    super.key,
    required this.clientInfo,
    required this.technicianName,
    required this.technicianDomain,
  });

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen>
    with TickerProviderStateMixin {
  final List<OperationPhoto> _photos = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();
  late AnimationController _listAnimationController;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _requestPermissions();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
    await Permission.storage.request();
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        _showDescriptionDialog(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la capture: $e')),
      );
    }
  }

  void _showDescriptionDialog(File imageFile) {
    _descriptionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text(
          'Description de l\'image',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(imageFile),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez ce qui est visible sur l\'image...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _addPhoto(imageFile, _descriptionController.text);
              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _addPhoto(File imageFile, String description) {
    setState(() {
      _photos.add(OperationPhoto(
        imageFile: imageFile,
        description: description.isEmpty ? 'Aucune description' : description,
        timestamp: DateTime.now(),
      ));
    });
    _listAnimationController.forward();
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _generatePDF() async {
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Create operation
      final operation = Operation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientInfo: widget.clientInfo,
        photos: _photos,
        createdAt: DateTime.now(),
        technicianName: widget.technicianName,
        technicianDomain: widget.technicianDomain,
      );

      // Generate PDF
      final pdfService = PDFService();
      final pdfPath = await pdfService.generateOperationPDF(operation);

      // Save operation to history
      await _saveOperation(operation);

      setState(() {
        _isGeneratingPdf = false;
      });

      if (mounted) {
        _showSuccessDialog(pdfPath);
      }
    } catch (e) {
      setState(() {
        _isGeneratingPdf = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la génération PDF: $e')),
        );
      }
    }
  }

  Future<void> _saveOperation(Operation operation) async {
    final prefs = await SharedPreferences.getInstance();
    final operations = prefs.getStringList('operations') ?? [];
    operations.add(jsonEncode(operation.toJson()));
    await prefs.setStringList('operations', operations);
  }

  void _showSuccessDialog(String pdfPath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PDF généré avec succès!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Le fichier a été sauvegardé dans vos téléchargements',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Retour à l\'accueil'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Photos'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_photos.length}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Client Info Summary
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clientInfo.contactName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SIP: ${widget.clientInfo.sip} | WO: ${widget.clientInfo.workOrder}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Photos List
          Expanded(
            child: _photos.isEmpty
                ? _buildEmptyState()
                : AnimatedList(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    initialItemCount: _photos.length,
                    itemBuilder: (context, index, animation) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ),
                        ),
                        child: _buildPhotoCard(index),
                      );
                    },
                  ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Prendre Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _generatePDF,
                    icon: _isGeneratingPdf
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _isGeneratingPdf ? 'Génération...' : 'Générer PDF',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.secondaryDark,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 60,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune photo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commencez par prendre des photos\nde votre intervention',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index) {
    final photo = _photos[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(photo.imageFile),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(photo.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removePhoto(index),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
