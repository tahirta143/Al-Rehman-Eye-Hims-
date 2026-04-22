import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ThermalReceiptHelper {
  static Future<Uint8List> generateReceipt({
    required String hospitalName,
    required String receiptId,
    required String mrNumber,
    required String patientName,
    required String age,
    required String gender,
    required String date,
    required String time,
    required List<Map<String, dynamic>> items,
    required double total,
    required double discount,
    required double payable,
    required String cashier,
    Map<String, dynamic>? tokens,
    String? qrData,
  }) async {
    final pdf = pw.Document();
    final mono = pw.Font.courier();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          72 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          final base = pw.TextStyle(font: mono, fontSize: 10);
          final small = base.copyWith(fontSize: 9);
          final bold = base.copyWith(fontWeight: pw.FontWeight.bold);
          final amountInWords = numberToWordsPKR(payable.toInt());

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header (aligned like React thermal template)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 24, height: 24),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          hospitalName.toUpperCase(),
                          style: base.copyWith(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text('OPD Receipt', style: small.copyWith(fontSize: 10)),
                      ],
                    ),
                  )
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.black),

              // MR and Receipt ID
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(text: 'MR: ', style: small),
                        pw.TextSpan(text: mrNumber.isEmpty ? '-' : mrNumber, style: small.copyWith(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.Text(receiptId, style: small.copyWith(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 2),

              // Patient name
              pw.Text(
                patientName.isEmpty ? '-' : patientName,
                style: base.copyWith(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),

              // Age/Gender and Date/Time (same order as React)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${age.isEmpty ? '-' : age}y · ${gender.isEmpty ? '-' : gender}',
                    style: small,
                  ),
                  pw.Text('$date $time', style: small),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.black),

              // Services (React uses name + line total only)
              ...items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${item['name'] ?? ''}', style: base),
                            if (tokens != null &&
                                tokens.containsKey(item['id']?.toString())) ...[
                              pw.SizedBox(height: 2),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.black,
                                  borderRadius: pw.BorderRadius.all(
                                      pw.Radius.circular(2)),
                                ),
                                child: pw.Text(
                                  'Token # ${tokens[item['id'].toString()]}',
                                  style: bold.copyWith(
                                      fontSize: 8, color: PdfColors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            _money(((item['rate'] ?? 0) as num).toDouble() *
                                ((item['qty'] ?? 1) as num).toDouble()),
                            textAlign: pw.TextAlign.right,
                            style: bold,
                          ),
                        ),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.black),

              // Totals
              if (discount > 0) ...[
                _buildTotalRow('Subtotal', total, baseStyle: base, valuePrefix: 'PKR '),
                _buildTotalRow('Discount', discount, baseStyle: base, isNegative: true),
              ],
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
                padding: const pw.EdgeInsets.only(top: 2),
                child: _buildTotalRow(
                  'Total',
                  payable,
                  baseStyle: base.copyWith(fontSize: 13),
                  valuePrefix: 'PKR ',
                  isBold: true,
                ),
              ),

              pw.SizedBox(height: 3),
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                ),
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  '$amountInWords Rupees Only',
                  style: small.copyWith(fontStyle: pw.FontStyle.italic),
                ),
              ),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.Text(
                'Cashier: ${cashier.isEmpty ? 'STAFF' : cashier}',
                style: small.copyWith(fontWeight: pw.FontWeight.bold),
              ),

              if (qrData != null) ...[
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: 90,
                        height: 90,
                        child: pw.BarcodeWidget( // ignore: deprecated_member_use
                          barcode: pw.Barcode.qrCode(),
                          data: qrData,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Scan to view receipt', style: small.copyWith(fontSize: 8)),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Thank you for visiting',
                  style: small.copyWith(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 6),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTotalRow(
    String label,
    double value, {
    required pw.TextStyle baseStyle,
    String valuePrefix = '',
    bool isBold = false,
    bool isNegative = false,
  }) {
    final style = isBold
        ? baseStyle.copyWith(fontWeight: pw.FontWeight.bold)
        : baseStyle;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(
            '${isNegative ? "- " : ""}$valuePrefix${_money(value)}',
            style: style,
          ),
        ],
      ),
    );
  }

  static String _money(double value) {
    final s = value.round().toString();
    final chars = s.split('').reversed.toList();
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) out.add(',');
      out.add(chars[i]);
    }
    return out.reversed.join();
  }

  static String numberToWordsPKR(int n) {
    if (n == 0) return 'Zero';
    
    final units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    
    String convert(int n) {
      if (n < 20) return units[n];
      if (n < 100) return '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${units[n % 10]}' : ''}';
      if (n < 1000) return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${convert(n % 100)}' : ''}';
      if (n < 100000) return '${convert(n ~/ 1000)} Thousand${n % 1000 != 0 ? ' ${convert(n % 1000)}' : ''}';
      if (n < 10000000) return '${convert(n ~/ 100000)} Lakh${n % 100000 != 0 ? ' ${convert(n % 100000)}' : ''}';
      return '${convert(n ~/ 10000000)} Crore${n % 10000000 != 0 ? ' ${convert(n % 10000000)}' : ''}';
    }
    
    return convert(n);
  }
}
