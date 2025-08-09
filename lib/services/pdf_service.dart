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
      // Request permissions first
      await _requestPermissions();
      
      final pdf = pw.Document();

      // Add page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(operation),
              pw.SizedBox(height: 20),
              _buildTechnicianInfo(operation),
              pw.SizedBox(height: 20),
              _buildClientInfo(operation),
              pw.SizedBox(height: 20),
              _buildEquipmentSection(),
              pw.SizedBox(height: 20),
              _buildPhotosSection(operation),
              pw.SizedBox(height: 20),
              _buildFooter(operation),
            ];
          },
        ),
      );

      // Get directory and save PDF
      final directory = await _getDownloadDirectory();
      final fileName = 'Rapport_${operation.clientInfo.sip}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      print('PDF saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error generating PDF: $e');
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.camera,
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Try Downloads folder first
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        return downloadsDir;
      }
      
      // Try external storage
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final telecomDir = Directory('${externalDir.path}/TelecomField');
        if (!await telecomDir.exists()) {
          await telecomDir.create(recursive: true);
        }
        return telecomDir;
      }
    }
    
    // Fallback to app documents directory
    return await getApplicationDocumentsDirectory();
  }

  pw.Widget _buildHeader(Operation operation) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.teal200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RAPPORT D\'INTERVENTION TÉLÉCOM',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Date: ${_formatDate(operation.createdAt)}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Text(
            'ID Opération: ${operation.id}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTechnicianInfo(Operation operation) {
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
                  _buildTableCell('Date d\'intervention', isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildTableCell('ESCOT'),
                  _buildTableCell(operation.technicianName),
                  _buildTableCell('0770 000204'),
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

  pw.Widget _buildPhotosSection(Operation operation) {
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
            'REPORTAGE PHOTOS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          ...operation.photos.asMap().entries.map((entry) {
            final index = entry.key;
            final photo = entry.value;
            return _buildPhotoItem(photo, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  pw.Widget _buildPhotoItem(operationPhoto, int photoNumber) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Photo $photoNumber: ${operationPhoto.description}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Prise le ${_formatDateTime(operationPhoto.timestamp)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          // Image placeholder - en attendant l'implémentation complète des images
          pw.Container(
            width: double.infinity,
            height: 200,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '[PHOTO ATTACHÉE]',
                    style: pw.TextStyle(
                      color: PdfColors.grey500,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    operationPhoto.imageFile.path.split('/').last,
                    style: const pw.TextStyle(
                      color: PdfColors.grey400,
                      fontSize: 10,
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

  pw.Widget _buildFooter(Operation operation) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
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
          pw.Text('PV et Fiche d\'installation: ✓'),
          pw.SizedBox(height: 8),
          pw.Text('Internet et voix sont OK'),
          pw.Text('Emplacement du matériel choisi par le client: OK'),
          pw.Text('Password d\'accès à distance: '),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Réalisé par: ${operation.technicianName}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Technicien ${operation.technicianDomain}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Date: ${_formatDate(operation.createdAt)}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Approbateur Orange'),
                  pw.SizedBox(height: 30),
                  pw.Text('Signature: ________________'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
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
}