import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/operation.dart';

class PDFService {
  Future<String> generateOperationPDF(Operation operation) async {
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
            _buildClientInfo(operation),
            pw.SizedBox(height: 20),
            _buildPhotosSection(operation),
            pw.SizedBox(height: 20),
            _buildFooter(operation),
          ];
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'operation_${operation.id}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  pw.Widget _buildHeader(Operation operation) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RAPPORT D\'INTERVENTION TÉLÉCOM',
            style: pw.TextStyle(
              fontSize: 18,
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
          _buildInfoRow('SIP:', operation.clientInfo.sip),
          _buildInfoRow('Work Order:', operation.clientInfo.workOrder),
          _buildInfoRow('Nom du contact:', operation.clientInfo.contactName),
          _buildInfoRow('Téléphone:', operation.clientInfo.phoneNumber),
          _buildInfoRow('ID:', operation.clientInfo.id),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  pw.Widget _buildPhotosSection(Operation operation) {
    return pw.Column(
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
        ...operation.photos.map((photo) => _buildPhotoItem(photo)).toList(),
      ],
    );
  }

  pw.Widget _buildPhotoItem(operation_photo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Photo prise le ${_formatDateTime(operation_photo.timestamp)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            operation_photo.description,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          // Note: Image loading from file would need additional implementation
          pw.Container(
            width: double.infinity,
            height: 200,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(
                '[Photo: ${operation_photo.imageFile.path.split('/').last}]',
                style: const pw.TextStyle(color: PdfColors.grey500),
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
          pw.Text('Internet et voix sont OK'),
          pw.Text('Emplacement du matériel choisi par le client: OK'),
          pw.SizedBox(height: 16),
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
                  pw.Text('Technicien de ${operation.technicianDomain}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Date: ${_formatDate(operation.createdAt)}'),
                  pw.SizedBox(height: 20),
                  pw.Text('Signature: ________________'),
                ],
              ),
            ],
          ),
        ],
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