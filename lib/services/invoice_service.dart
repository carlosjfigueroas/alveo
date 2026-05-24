import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/company.dart';
import '../models/payment.dart';

class InvoiceService {
  static Future<void> generateAndPrintInvoice({
    required Company company,
    required Payment payment,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Configurar logo si lo tenemos, si no un placeholder de Alveo
    // final netImage = await networkImage('https://...'); 

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header: Logo y Datos de Alveo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ALVEO', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        pw.Text('Real Estate SaaS Platform', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('San Juan, Puerto Rico', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('contacto@alveo.com', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('RECIBO DE PAGO', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                        pw.Text('Nro: ${payment.id.substring(0, 8).toUpperCase()}', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('Fecha: ${dateFormat.format(payment.createdAt)}', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 20),

                // Datos del Cliente (Agencia)
                pw.Text('FACTURADO A:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 8),
                pw.Text(company.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(company.contactEmail ?? '', style: const pw.TextStyle(fontSize: 11)),
                pw.Text(company.contactPhone ?? '', style: const pw.TextStyle(fontSize: 11)),
                
                pw.SizedBox(height: 40),

                // Detalle del Pago (Tabla)
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    // Header Tabla
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        _cell('Descripción', flex: 3, isHeader: true),
                        _cell('Referencia', flex: 2, isHeader: true),
                        _cell('Ciclo', flex: 1, isHeader: true),
                        _cell('Monto', flex: 1, isHeader: true, alignRight: true),
                      ],
                    ),
                    // Fila de datos
                    pw.TableRow(
                      children: [
                        _cell('Suscripción Alveo Real Estate - Plan Activo'),
                        _cell(payment.reference ?? ''),
                        _cell(payment.billingCycle == 'annual' ? 'Anual' : 'Mensual'),
                        _cell('\$${payment.amount.toStringAsFixed(2)}', alignRight: true),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 150,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 12)),
                              pw.Text('\$${payment.amount.toStringAsFixed(2)}'),
                            ],
                          ),
                          pw.Divider(thickness: 0.5),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('TOTAL PAGADO:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              pw.Text('\$${payment.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Gracias por confiar en Alveo.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                    pw.Text('Documento generado electrónicamente.', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Abrir el preview de impresión / guardar
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'recibo_alveo_${payment.id.substring(0,6)}.pdf',
    );
  }

  static pw.Widget _cell(String text, {int flex = 1, bool isHeader = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Align(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
