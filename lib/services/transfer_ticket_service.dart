import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/energy_transfer.dart';
class TransferTicketService {
  const TransferTicketService();

  Future<void> printOrShare(EnergyTransfer transfer) async {
    final bytes = await buildTicket(transfer);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'energy-transfer-${transfer.id}.pdf',
    );
  }

  Future<Uint8List> buildTicket(EnergyTransfer transfer) async {
    final document = pw.Document();
    final date = transfer.createdAt.toLocal();
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              decoration: const pw.BoxDecoration(color: PdfColor(0.06, 0.17, 0.27)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SMART ENERGY TANZANIA',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'UNIT TRANSFER TICKET',
                    style: const pw.TextStyle(
                      color: PdfColor(0.76, 0.86, 0.95),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              '${transfer.formattedAmount} kWh',
              style: pw.TextStyle(
                color: const PdfColor(0.08, 0.41, 0.77),
                fontSize: 29,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 18),
            _detail('Ticket reference', transfer.id),
            _detail('Date and time', dateLabel),
            _detail(
              'From meter',
              '${transfer.fromMeterName} - ${transfer.fromMeterNumber}',
            ),
            _detail(
              'To meter',
              '${transfer.toMeterName} - ${transfer.toMeterNumber}',
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber700),
              ),
              child: pw.Text(
                'LOCAL DEMO RECORD - This ticket confirms an entry in this device only. '
                'No electricity units were transferred through a utility provider.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 3),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Keep this ticket for your records.',
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
            ),
          ],
        ),
      ),
    );

    return document.save();
  }

  pw.Widget _detail(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 13),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
        ),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}
