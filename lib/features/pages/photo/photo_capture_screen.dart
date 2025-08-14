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
  final String technicianNumber; // Changed from technicianDomain to technicianNumber

  const PhotoCaptureScreen({
    super.key,
    required this.clientInfo,
    required this.technicianName,
    required this.technicianNumber, // Updated parameter
  });

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen>
    with TickerProviderStateMixin {
  final Map<String, OperationPhoto?> _photos = {};
  final ImagePicker _picker = ImagePicker();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  bool _isGeneratingPdf = false;
  bool _isAddingPhoto = false;
  
  // العناوين المطلوبة بنفس الترتيب
  final List<String> _photoTitles = [
    'Équipement installé',
    'Test signal (photomètre)',
    'Speed test (Test WIFI)',
    'Etiquetage indoor',
    'PV et Fiche d\'installation',
  ];

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
    
    // تهيئة المفاتيح للصور
    for (String title in _photoTitles) {
      _photos[title] = null;
    }
    
    _requestPermissions();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final permissions = [Permission.camera, Permission.storage];
    await permissions.request();
  }

  Future<void> _takePicture(String photoTitle) async {
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
        final photo = OperationPhoto(
          imageFile: File(image.path),
          description: photoTitle,
          timestamp: DateTime.now(),
        );
        
        setState(() {
          _photos[photoTitle] = photo;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo ajoutée: $photoTitle'),
            backgroundColor: AppTheme.accent,
            duration: const Duration(seconds: 2),
          ),
        );
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

  void _removePhoto(String photoTitle) {
    setState(() {
      _photos[photoTitle] = null;
    });
  }

  Future<void> _generatePDF() async {
    final takenPhotos = _photos.values.where((photo) => photo != null).toList();
    
    if (takenPhotos.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter au moins une photo');
      return;
    }

    if (_isGeneratingPdf) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    _fabAnimationController.forward();

    try {
      // Create operation with taken photos
      final operation = Operation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientInfo: widget.clientInfo,
        photos: List<OperationPhoto>.from(takenPhotos),
        createdAt: DateTime.now(),
        technicianName: widget.technicianName,
        technicianNumber: widget.technicianNumber, // Updated field
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

  int get _takenPhotosCount {
    return _photos.values.where((photo) => photo != null).length;
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
              '$_takenPhotosCount/${_photoTitles.length}',
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _photoTitles.length,
              itemBuilder: (context, index) {
                final photoTitle = _photoTitles[index];
                final photo = _photos[photoTitle];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.accent, AppTheme.accentSecondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                photo != null ? Icons.check_circle : Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    photoTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    photo != null 
                                        ? 'Photo prise à ${_formatTime(photo!.timestamp)}'
                                        : 'Photo non prise',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: photo != null ? AppTheme.accent : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Photo preview or capture button
                        if (photo != null) ...[
                          Row(
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
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _takePicture(photoTitle),
                                        icon: const Icon(Icons.camera_alt, size: 16),
                                        label: const Text('Reprendre'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        onPressed: () => _removePhoto(photoTitle),
                                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                        label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isAddingPhoto ? null : () => _takePicture(photoTitle),
                              icon: _isAddingPhoto 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.camera_alt),
                              label: Text(_isAddingPhoto ? 'Capture en cours...' : 'Prendre Photo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
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
              child: SizedBox(
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
                      _isGeneratingPdf ? 'Génération PDF...' : 'Générer PDF',
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
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}