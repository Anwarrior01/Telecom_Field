import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/operation.dart';

class PDFService {
  Future<String> generateOperationPDF(Operation operation) async {
    try {
      print('Starting PDF generation...');
      
      // Request permissions first
      await _requestPermissions();
      
      final pdf = pw.Document();

      // Load images as bytes for PDF
      final List<Uint8List> imageBytes = [];
      print('Loading images: ${operation.photos.length} photos');
      
      for (int i = 0; i < operation.photos.length; i++) {
        try {
          final photo = operation.photos[i];
          print('Loading photo ${i + 1}: ${photo.imageFile.path}');
          
          if (await photo.imageFile.exists()) {
            final bytes = await photo.imageFile.readAsBytes();
            imageBytes.add(bytes);
            print('Photo ${i + 1} loaded successfully: ${bytes.length} bytes');
          } else {
            print('Photo ${i + 1} file not found: ${photo.imageFile.path}');
          }
        } catch (e) {
          print('Error loading photo ${i + 1}: $e');
          // Continue with other images
        }
      }

      // Add pages with proper error handling
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(operation),
              pw.SizedBox(height: 20),
              _buildIntervenantsInfo(operation),
              pw.SizedBox(height: 20),
              _buildClientInfo(operation),
              pw.SizedBox(height: 20),
              _buildEquipmentSection(),
              pw.SizedBox(height: 20),
              _buildPhotosSection(operation, imageBytes),
              pw.SizedBox(height: 20),
              _buildFooter(operation),
            ];
          },
        ),
      );

      // Get directory and save PDF
      final directory = await _getDownloadDirectory();
      final fileName = 'Rapport_${operation.clientInfo.sip}_${_formatFileDate(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      
      print('Save directory: ${directory.path}');
      print('File name: $fileName');
      
      // Ensure directory exists
      await directory.create(recursive: true);
      
      final pdfBytes = await pdf.save();
      print('PDF bytes generated: ${pdfBytes.length} bytes');
      
      await file.writeAsBytes(pdfBytes);

      // Verify file was created
      if (await file.exists()) {
        final fileSize = await file.length();
        print('PDF successfully created: ${file.path}');  
        print('Final file size: $fileSize bytes');
        return file.path;
      } else {
        throw Exception('PDF file was not created');
      }
    } catch (e) {
      print('Error generating PDF: $e');
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final permissions = <Permission>[
        Permission.camera,
        Permission.storage,
        Permission.manageExternalStorage,
      ];
      
      await permissions.request();
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Try Downloads folder first
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download/TelecomField');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      } catch (e) {
        print('Cannot access Downloads folder: $e');
      }
      
      // Try external storage as fallback
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final telecomDir = Directory('${externalDir.path}/TelecomField');
          if (!await telecomDir.exists()) {
            await telecomDir.create(recursive: true);
          }
          return telecomDir;
        }
      } catch (e) {
        print('Cannot access external storage: $e');
      }
    }
    
    // Fallback to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final telecomDir = Directory('${appDir.path}/TelecomField');
    if (!await telecomDir.exists()) {
      await telecomDir.create(recursive: true);
    }
    return telecomDir;
  }

  pw.Widget _buildHeader(Operation operation) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS SUR L\'INTERVENTION',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Date de la demande', isHeader: true),
                  _buildTableCell('Priorité', isHeader: true),
                  _buildTableCell('Type d\'intervention', isHeader: true),
                  _buildTableCell('Date prévue de l\'intervention', isHeader: true),
                  _buildTableCell('Prestataire', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell(_formatDate(operation.createdAt)),
                  _buildTableCell('Planifiée'),
                  _buildTableCell('Intégration'),
                  _buildTableCell(_formatDate(operation.createdAt)),
                  _buildTableCell('ESCOT'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIntervenantsInfo(Operation operation) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INTERVENANTS PRESTATAIRE/CLIENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Prestataire', isHeader: true),
                  _buildTableCell('Nom de l\'intervenant', isHeader: true),
                  _buildTableCell('Téléphone', isHeader: true),
                  _buildTableCell('Client/Mandataire', isHeader: true),
                  _buildTableCell('Téléphone', isHeader: true),
                  _buildTableCell('Date de l\'intervention', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('ESCOT'),
                  _buildTableCell(operation.technicianName),
                  _buildTableCell('0770 000204'),
                  _buildTableCell(operation.clientInfo.contactName),
                  _buildTableCell(operation.clientInfo.phoneNumber),
                  _buildTableCell(_formatDate(operation.createdAt)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClientInfo(Operation operation) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DONNÉES CLIENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('SIP', isHeader: true),
                  _buildTableCell('Work Order', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell(operation.clientInfo.sip),
                  _buildTableCell(operation.clientInfo.workOrder),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Nom du contact', isHeader: true),
                  _buildTableCell('N° de téléphone', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell(operation.clientInfo.contactName),
                  _buildTableCell(operation.clientInfo.phoneNumber),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('ID', isHeader: true),
                  _buildTableCell('', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell(operation.clientInfo.id),
                  _buildTableCell(''),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEquipmentSection() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ÉQUIPEMENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('', isHeader: true),
                  _buildTableCell('Ancien', isHeader: true),
                  _buildTableCell('Qté', isHeader: true),
                  _buildTableCell('Nouveau', isHeader: true),
                  _buildTableCell('Référence', isHeader: true),
                  _buildTableCell('S/N', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('ROUTEUR'),
                  _buildTableCell(''),
                  _buildTableCell('1'),
                  _buildTableCell('✓'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('TEL'),
                  _buildTableCell(''),
                  _buildTableCell('0'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('GPON'),
                  _buildTableCell(''),
                  _buildTableCell('1'),
                  _buildTableCell('✓'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPhotosSection(Operation operation, List<Uint8List> imageBytes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Orange watermark header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'REPORTAGE PHOTOS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Orange',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          
          // Photos section with fixed titles
          ...List.generate(operation.photos.length, (index) {
            final photo = operation.photos[index];
            return _buildPhotoItem(photo, index + 1, index < imageBytes.length ? imageBytes[index] : null);
          }),
        ],
      ),
    );
  }

  pw.Widget _buildPhotoItem(operationPhoto, int photoNumber, Uint8List? imageBytes) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${operationPhoto.description}:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Prise le ${_formatDateTime(operationPhoto.timestamp)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          
          // Image display with Orange watermark
          pw.Container(
            width: double.infinity,
            height: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Stack(
              children: [
                // Main image
                imageBytes != null 
                  ? pw.Image(
                      pw.MemoryImage(imageBytes),
                      fit: pw.BoxFit.contain,
                      width: double.infinity,
                      height: 200,
                    )
                  : _buildPlaceholderBox('Image: ${operationPhoto.imageFile.path.split('/').last}'),
                
                // Orange watermark in corner
                pw.Positioned(
                  bottom: 10,
                  right: 10,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Orange',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
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

  pw.Widget _buildPlaceholderBox(String text) {
    return pw.Container(
      width: double.infinity,
      height: 200,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Stack(
        children: [
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '[IMAGE]',
                  style: pw.TextStyle(
                    color: PdfColors.grey500,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  text,
                  style: const pw.TextStyle(
                    color: PdfColors.grey400,
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          // Orange watermark even for placeholder
          pw.Positioned(
            bottom: 10,
            right: 10,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'Orange',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Operation operation) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RÉCEPTION DE SERVICE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text('PV et Fiche d\'installation:', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 8),
          pw.Text('Internet et voix sont OK', style: const pw.TextStyle(fontSize: 11)),
          pw.Text('Emplacement du matériel choisi par le client.: OK', style: const pw.TextStyle(fontSize: 11)),
          pw.Text('Password d\'accès à distance:', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 20),
          pw.Text(
            'Date: ${_formatDate(operation.createdAt)}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 30),
          pw.Text('Approbateur Orange', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 30),
          pw.Text('Signature: ________________', style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}_${date.month.toString().padLeft(2, '0')}_${date.year}_${date.hour.toString().padLeft(2, '0')}_${date.minute.toString().padLeft(2, '0')}';
  }
}