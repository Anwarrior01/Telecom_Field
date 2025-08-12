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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  bool _isGeneratingPdf = false;
  bool _isAddingPhoto = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _requestPermissions();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final permissions = [Permission.camera, Permission.storage];
    await permissions.request();
  }

  Future<void> _takePicture() async {
    if (_isAddingPhoto) return;

    setState(() {
      _isAddingPhoto = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        await _showDescriptionDialog(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la capture: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingPhoto = false;
        });
      }
    }
  }

  Future<void> _showDescriptionDialog(File imageFile) async {
    _descriptionController.clear();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Description de l\'image',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(imageFile),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez ce qui est visible sur l\'image...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final description = _descriptionController.text.trim();
              Navigator.pop(context, description.isEmpty ? 'Photo d\'intervention' : description);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      _addPhoto(imageFile, result);
    }
  }

  void _addPhoto(File imageFile, String description) {
    final photo = OperationPhoto(
      imageFile: imageFile,
      description: description,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _photos.add(photo);
    });
    
    // Animate the addition
    _listKey.currentState?.insertItem(_photos.length - 1);
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo ajoutée: $description'),
        backgroundColor: AppTheme.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removePhoto(int index) {
    if (index >= _photos.length) return;

    final removedPhoto = _photos[index];
    setState(() {
      _photos.removeAt(index);
    });
    
    // Animate the removal
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
        ),
        child: FadeTransition(
          opacity: animation,
          child: _buildPhotoCard(removedPhoto, index, animation: animation),
        ),
      ),
    );
  }

  Future<void> _generatePDF() async {
    if (_photos.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter au moins une photo');
      return;
    }

    if (_isGeneratingPdf) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    _fabAnimationController.forward();

    try {
      // Create operation
      final operation = Operation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientInfo: widget.clientInfo,
        photos: List.from(_photos), // Create a copy to avoid modification during generation
        createdAt: DateTime.now(),
        technicianName: widget.technicianName,
        technicianDomain: widget.technicianDomain,
      );

      // Generate PDF
      final pdfService = PDFService();
      final pdfPath = await pdfService.generateOperationPDF(operation);

      // Save operation to history
      await _saveOperation(operation);

      if (mounted) {
        _showSuccessDialog(pdfPath);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la génération PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
        _fabAnimationController.reverse();
      }
    }
  }

  Future<void> _saveOperation(Operation operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operations = prefs.getStringList('operations') ?? [];
      operations.add(jsonEncode(operation.toJson()));
      await prefs.setStringList('operations', operations);
    } catch (e) {
      print('Error saving operation: $e');
    }
  }

  void _showSuccessDialog(String pdfPath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              'Fichier sauvegardé:\n${pdfPath.split('/').last}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Emplacement: ${pdfPath.contains('Download') ? 'Téléchargements' : 'Documents App'}',
              style: const TextStyle(
                fontSize: 12,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
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
                    key: _listKey,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    initialItemCount: _photos.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= _photos.length) return Container();
                      return _buildPhotoCard(_photos[index], index, animation: animation);
                    },
                  ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryDark.withOpacity(0.5),
              border: Border(
                top: BorderSide(color: AppTheme.accent.withOpacity(0.2)),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAddingPhoto ? null : _takePicture,
                          icon: _isAddingPhoto 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt),
                          label: Text(_isAddingPhoto ? 'Capture...' : 'Prendre Photo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ScaleTransition(
                      scale: _fabScaleAnimation,
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
                          _isGeneratingPdf ? 'Génération en cours...' : 'Générer PDF',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildPhotoCard(OperationPhoto photo, int index, {Animation<double>? animation}) {
    Widget card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(photo.imageFile),
                    fit: BoxFit.cover,
                  ),
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
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Supprimer la photo',
            ),
          ],
        ),
      ),
    );

    if (animation != null) {
      return SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
        ),
        child: FadeTransition(opacity: animation, child: card),
      );
    }

    return card;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}