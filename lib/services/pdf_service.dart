import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../models/operation.dart';

class PDFService {
  Future<String> generateOperationPDF(Operation operation) async {
    try {
      print('Starting PDF generation...');
      
      // Request permissions first
      await _requestPermissions();
      
      final pdf = pw.Document();

      // Load PDF header image
      pw.ImageProvider? headerImage;
      try {
        final headerData = await rootBundle.load('assets/pdf-header.png');
        final headerBytes = headerData.buffer.asUint8List();
        headerImage = pw.MemoryImage(headerBytes);
        print('Header image loaded successfully');
      } catch (e) {
        print('Could not load header image: $e');
      }

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
        }
      }

      // Add page with header image and exact layout
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          header: headerImage != null 
            ? (pw.Context context) => _buildHeaderFromImage(headerImage!)
            : null,
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 20),
              _buildInterventionInfoTable(operation),
              pw.SizedBox(height: 20),
              _buildClientDataTable(operation),
              pw.SizedBox(height: 20),
              _buildIntervenantTable(operation),
              pw.SizedBox(height: 20),
              _buildEquipmentTable(),
              pw.SizedBox(height: 20),
              _buildPhotosSection(operation, imageBytes),
              pw.SizedBox(height: 20),
              _buildServiceReceptionSection(operation),
            ];
          },
        ),
      );

      // Save PDF
      final directory = await _getDownloadDirectory();
      final fileName = 'Rapport_${operation.clientInfo.sip}_${_formatFileDate(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      
      print('Save directory: ${directory.path}');
      print('File name: $fileName');
      
      await directory.create(recursive: true);
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      if (await file.exists()) {
        print('PDF successfully created: ${file.path}');
        return file.path;
      } else {
        throw Exception('PDF file was not created');
      }
    } catch (e) {
      print('Error generating PDF: $e');
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  // Header from image
  pw.Widget _buildHeaderFromImage(pw.ImageProvider headerImage) {
    return pw.Container(
      width: double.infinity,
      height: 80,
      child: pw.Image(
        headerImage,
        fit: pw.BoxFit.fitWidth,
      ),
    );
  }

  // Informations sur l'intervention - exact layout with merged header
  pw.Widget _buildInterventionInfoTable(Operation operation) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FractionColumnWidth(0.2),
        1: const pw.FractionColumnWidth(0.15),
        2: const pw.FractionColumnWidth(0.2),
        3: const pw.FractionColumnWidth(0.25),
        4: const pw.FractionColumnWidth(0.2),
      },
      children: [
        // Main header - RED spanning all columns
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.red),
              child: pw.Text(
                'Informations sur l\'intervention',
                style: pw.TextStyle(
                  fontSize: 10, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
          ],
        ),
        // Column headers - YELLOW
        pw.TableRow(
          children: [
            _buildYellowCell('Date de la demande'),
            _buildYellowCell('Priorité'),
            _buildYellowCell('Type d\'intervention'),
            _buildYellowCell('Date prévue de l\'intervention'),
            _buildYellowCell('Prestataire'),
          ],
        ),
        // Data row - WHITE
        pw.TableRow(
          children: [
            _buildWhiteCell(''),
            _buildWhiteCell('Planifiée'),
            _buildWhiteCell('Intégration'),
            _buildWhiteCell(''),
            _buildWhiteCell('ESCOT'),
          ],
        ),
      ],
    );
  }

  // Données client - exact layout with merged header and filled data
  pw.Widget _buildClientDataTable(Operation operation) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FractionColumnWidth(0.3),
        1: const pw.FractionColumnWidth(0.3),
        2: const pw.FractionColumnWidth(0.4),
      },
      children: [
        // Header - RED spanning all columns
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.red),
              child: pw.Text(
                'Données client',
                style: pw.TextStyle(
                  fontSize: 10, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
          ],
        ),
        // SIP
        pw.TableRow(
          children: [
            _buildYellowCell('SIP'),
            _buildWhiteCell(operation.clientInfo.sip),
            _buildWhiteCell(''),
          ],
        ),
        // Work Order
        pw.TableRow(
          children: [
            _buildYellowCell('Work Order'),
            _buildWhiteCell(operation.clientInfo.workOrder),
            _buildWhiteCell(''),
          ],
        ),
        // Contact name
        pw.TableRow(
          children: [
            _buildYellowCell('Nom du contact'),
            _buildWhiteCell(operation.clientInfo.contactName),
            _buildWhiteCell(''),
          ],
        ),
        // Phone
        pw.TableRow(
          children: [
            _buildYellowCell('N° de téléphone'),
            _buildWhiteCell(operation.clientInfo.phoneNumber),
            _buildWhiteCell(''),
          ],
        ),
        // ID
        pw.TableRow(
          children: [
            _buildYellowCell('ID'),
            _buildWhiteCell(operation.clientInfo.id),
            _buildWhiteCell(''),
          ],
        ),
      ],
    );
  }

  // Intervenants - exact layout with merged header and filled data
  pw.Widget _buildIntervenantTable(Operation operation) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FractionColumnWidth(0.15),
        1: const pw.FractionColumnWidth(0.2),
        2: const pw.FractionColumnWidth(0.15),
        3: const pw.FractionColumnWidth(0.2),
        4: const pw.FractionColumnWidth(0.15),
        5: const pw.FractionColumnWidth(0.15),
      },
      children: [
        // Header - RED spanning all columns
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.red),
              child: pw.Text(
                'Intervenants Prestataire/Client',
                style: pw.TextStyle(
                  fontSize: 10, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
          ],
        ),
        // Column headers - YELLOW
        pw.TableRow(
          children: [
            _buildYellowCell('Prestataire'),
            _buildYellowCell('Nom de l\'intervenant'),
            _buildYellowCell('Téléphone'),
            _buildYellowCell('Client/Mandataire'),
            _buildYellowCell('Téléphone'),
            _buildYellowCell('Date de l\'intervention'),
          ],
        ),
        // Data row - WHITE with technician data
        pw.TableRow(
          children: [
            _buildWhiteCell('ESCOT'),
            _buildWhiteCell(operation.technicianName),
            _buildWhiteCell('0770000204'),
            _buildWhiteCell(operation.clientInfo.contactName),
            _buildWhiteCell(operation.clientInfo.phoneNumber),
            _buildWhiteCell(_formatDate(operation.createdAt)),
          ],
        ),
      ],
    );
  }

  // Equipment table - exact layout with merged header
  pw.Widget _buildEquipmentTable() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FractionColumnWidth(0.2),
        1: const pw.FractionColumnWidth(0.15),
        2: const pw.FractionColumnWidth(0.1),
        3: const pw.FractionColumnWidth(0.15),
        4: const pw.FractionColumnWidth(0.2),
        5: const pw.FractionColumnWidth(0.2),
      },
      children: [
        // Header - RED spanning all columns
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.red),
              child: pw.Text(
                'Équipements remis au client',
                style: pw.TextStyle(
                  fontSize: 10, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
            pw.Container(decoration: const pw.BoxDecoration(color: PdfColors.red), child: pw.Text('')),
          ],
        ),
        // First sub header row - YELLOW
        pw.TableRow(
          children: [
            _buildYellowCell('Équipement'),
            _buildYellowCell(''),
            _buildYellowCell('Qté'),
            _buildYellowCell('Référence'),
            _buildYellowCell(''),
            _buildYellowCell('S/N'),
          ],
        ),
        // Second sub header row - YELLOW
        pw.TableRow(
          children: [
            _buildYellowCell('Nouveau'),
            _buildYellowCell('Ancien'),
            _buildYellowCell(''),
            _buildYellowCell('Nouveau'),
            _buildYellowCell('Ancien'),
            _buildYellowCell('Nouveau'),
          ],
        ),
        // Third sub header row - YELLOW  
        pw.TableRow(
          children: [
            _buildYellowCell(''),
            _buildYellowCell(''),
            _buildYellowCell(''),
            _buildYellowCell(''),
            _buildYellowCell(''),
            _buildYellowCell('Ancien'),
          ],
        ),
        // Equipment rows - WHITE
        pw.TableRow(
          children: [
            _buildWhiteCell('ROUTEUR'),
            _buildWhiteCell(''),
            _buildWhiteCell('1'),
            _buildWhiteCell(''),
            _buildWhiteCell(''),
            _buildWhiteCell(''),
          ],
        ),
        pw.TableRow(
          children: [
            _buildWhiteCell('TEL'),
            _buildWhiteCell(''),
            _buildWhiteCell('0'),
            _buildWhiteCell(''),
            _buildWhiteCell(''),
            _buildWhiteCell(''),
          ],
        ),
        pw.TableRow(
          children: [
            _buildWhiteCell('GPON'),
            _buildWhiteCell(''),
            _buildWhiteCell('1'),
            _buildWhiteCell(''),
            _buildWhiteCell(''),
            _buildWhiteCell(''),
          ],
        ),
      ],
    );
  }

  // Photos section - simple layout
  pw.Widget _buildPhotosSection(Operation operation, List<Uint8List> imageBytes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with border
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Text(
            'Reportage photos',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        
        // Photos with descriptions
        ...List.generate(operation.photos.length, (index) {
          final photo = operation.photos[index];
          final imageData = index < imageBytes.length ? imageBytes[index] : null;
          
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${photo.description} :',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 5),
              
              // Image
              if (imageData != null)
                pw.Container(
                  width: 200,
                  height: 150,
                  child: pw.Image(
                    pw.MemoryImage(imageData),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              
              pw.SizedBox(height: 15),
            ],
          );
        }),
      ],
    );
  }

  // Service reception section
  pw.Widget _buildServiceReceptionSection(Operation operation) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with border
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Text(
            'Réception de service',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        
        pw.Text('Pv et Fiche D\'installation :', 
          style: pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 10),
        pw.Text('Internet et voix sont OK', 
          style: pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 5),
        pw.Text('Emplacement du matériel choisi par le client. : OK', 
          style: pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 5),
        pw.Text('Password d\'accès à distance :', 
          style: pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 20),
        pw.Text('Date', style: pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 20),
        pw.Text('Approbateur Orange', style: pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 20),
        pw.Text('Signature', style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  // Helper methods for colored cells
  pw.Widget _buildYellowCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: const pw.BoxDecoration(color: PdfColors.yellow),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildWhiteCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  // Rest of helper methods remain the same
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
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download/TelecomField');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      } catch (e) {
        print('Cannot access Downloads folder: $e');
      }
      
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
    
    final appDir = await getApplicationDocumentsDirectory();
    final telecomDir = Directory('${appDir.path}/TelecomField');
    if (!await telecomDir.exists()) {
      await telecomDir.create(recursive: true);
    }
    return telecomDir;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatFileDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}_${date.month.toString().padLeft(2, '0')}_${date.year}_${date.hour.toString().padLeft(2, '0')}_${date.minute.toString().padLeft(2, '0')}';
  }
}