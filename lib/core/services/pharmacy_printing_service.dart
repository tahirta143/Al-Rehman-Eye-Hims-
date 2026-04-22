import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PharmacyPrintingService {
  static Future<void> printReceipt({
    required Map<String, dynamic> header,
    required List<dynamic> items,
    required Map<String, dynamic> summary,
    Map<String, dynamic>? companyInfo,
  }) async {
    final doc = pw.Document();

    final String hospitalName = companyInfo?['company_name'] ?? 'HEALTH CARE HOSPITAL';
    final DateTime now = DateTime.now();
    final String dateStr = DateFormat('dd/MMM/yy').format(now);
    final String timeStr = DateFormat('hh:mm a').format(now);

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(72 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(hospitalName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('Pharmacy Sales Receipt', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(thickness: 1),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Rcpt: ${header['receipt_no'] ?? '-'}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('$dateStr $timeStr', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer: ${header['customer_name'] ?? 'WALKING CUSTOMER'}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(header['card_sale'] == true ? 'CARD' : 'CASH', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              
              pw.Divider(thickness: 1),
              
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(15),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(25),
                  3: const pw.FixedColumnWidth(35),
                  4: const pw.FixedColumnWidth(40),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    children: [
                      pw.Text('#', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rate', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...items.asMap().entries.map((e) {
                    final i = e.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text('${e.key + 1}', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(i['item_name'] ?? '', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text('${i['qty']}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text('${double.tryParse(i['price']?.toString() ?? '0')?.toStringAsFixed(0)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text('${double.tryParse(i['total']?.toString() ?? '0')?.toStringAsFixed(0)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                      ],
                    );
                  }).toList(),
                ],
              ),
              
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('PKR ${double.tryParse(summary['total_price']?.toString() ?? '0')?.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if ((double.tryParse(summary['discount_amount']?.toString() ?? '0') ?? 0) > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('- ${double.tryParse(summary['discount_amount']?.toString() ?? '0')?.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('PKR ${double.tryParse(summary['payable']?.toString() ?? '0')?.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              if ((double.tryParse(summary['amount_given']?.toString() ?? '0') ?? 0) > 0) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Paid', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('PKR ${double.tryParse(summary['amount_given']?.toString() ?? '0')?.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Return', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('PKR ${double.tryParse(summary['return_amount']?.toString() ?? '0')?.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
              
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),
              pw.Text('Thank you for visiting!', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Powered by HIMS', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }
}
