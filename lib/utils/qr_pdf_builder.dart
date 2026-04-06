import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

Future<pw.Document> buildQrPdf(
  String destinationName,
  String qrData,
) async {
  final pdf = pw.Document();

  final qrUrl =
      'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$qrData';
  final qrResponse = await http.get(Uri.parse(qrUrl));

  final qrImage = pw.MemoryImage(qrResponse.bodyBytes);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              destinationName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Image(qrImage, width: 300, height: 300),
            pw.SizedBox(height: 20),
            pw.Text(
              'Scan this QR to complete your transport request',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );

  return pdf;
}
