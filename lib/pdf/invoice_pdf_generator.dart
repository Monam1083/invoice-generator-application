import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice_model.dart';
import '../models/invoice_status.dart';

/// Builds and exports a PDF representation of an [InvoiceModel].
class InvoicePdfGenerator {
  InvoicePdfGenerator._();

  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');

  static Future<pw.Document> _build(InvoiceModel invoice) async {
    final doc = pw.Document();

    pw.MemoryImage? logoImage;
    final logoPath = invoice.business.logoPath;
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        logoImage = pw.MemoryImage(await file.readAsBytes());
      }
    }

    String money(double v) => '${invoice.currencySymbol}${v.toStringAsFixed(2)}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header: logo + business info + invoice title
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          height: 50,
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Image(logoImage),
                        ),
                      pw.Text(
                        invoice.business.name,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(invoice.business.address,
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(invoice.business.email,
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(invoice.business.phone,
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('No: ${invoice.invoiceNumber}'),
                      pw.Text('Date: ${_dateFmt.format(invoice.invoiceDate)}'),
                      pw.Text('Due: ${_dateFmt.format(invoice.dueDate)}'),
                      pw.Container(
                        margin: const pw.EdgeInsets.only(top: 6),
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          invoice.status.label.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Bill to
              pw.Text('Bill To',
                  style:
                      pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.customer.name,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.customer.address,
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text(invoice.customer.email,
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text(invoice.customer.phone,
                  style: const pw.TextStyle(fontSize: 10)),

              pw.SizedBox(height: 20),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.4),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                    children: [
                      _cell('Item', bold: true, color: PdfColors.white),
                      _cell('Qty', bold: true, color: PdfColors.white),
                      _cell('Unit Price', bold: true, color: PdfColors.white),
                      _cell('Discount', bold: true, color: PdfColors.white),
                      _cell('Amount', bold: true, color: PdfColors.white),
                    ],
                  ),
                  ...invoice.items.map(
                    (item) => pw.TableRow(
                      children: [
                        _cell(item.name),
                        _cell(item.quantity % 1 == 0
                            ? item.quantity.toStringAsFixed(0)
                            : item.quantity.toString()),
                        _cell(money(item.unitPrice)),
                        _cell(item.discountPercent > 0
                            ? '${item.discountPercent.toStringAsFixed(0)}%'
                            : '-'),
                        _cell(money(item.total)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _totalsRow('Subtotal', money(invoice.subtotal)),
                      _totalsRow('Tax (${invoice.taxPercent.toStringAsFixed(1)}%)',
                          money(invoice.taxAmount)),
                      pw.Divider(color: PdfColors.grey400),
                      _totalsRow('Grand Total', money(invoice.grandTotal),
                          bold: true),
                    ],
                  ),
                ),
              ),

              if (invoice.notes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 24),
                pw.Text('Notes / Payment Instructions',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 10)),
              ],

              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc;
  }

  static pw.Widget _cell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _totalsRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: bold ? 13 : 11,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  /// Returns the raw PDF bytes for the invoice - used for preview/print.
  static Future<List<int>> generateBytes(InvoiceModel invoice) async {
    final doc = await _build(invoice);
    return doc.save();
  }

  /// Saves the PDF to the app's documents directory and returns the file.
  static Future<File> saveToDevice(InvoiceModel invoice) async {
    final bytes = await generateBytes(invoice);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Opens the native share sheet (WhatsApp, Email, etc.) with the PDF.
  static Future<void> share(InvoiceModel invoice) async {
    final bytes = await generateBytes(invoice);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }

  /// Opens the platform print dialog / preview for the invoice.
  static Future<void> print(InvoiceModel invoice) async {
    final bytes = await generateBytes(invoice);
    await Printing.layoutPdf(
      onLayout: (format) async => Uint8List.fromList(bytes),
      name: invoice.invoiceNumber,
    );
  }
}
