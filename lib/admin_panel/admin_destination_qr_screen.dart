import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';
import '../utils/download_qr_pdf.dart';

class AdminDestinationQRScreen extends StatelessWidget {
  final String destinationId;
  final String destinationName;

  const AdminDestinationQRScreen({
    super.key,
    required this.destinationId,
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = "DEST:$destinationId";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔵 BLUE HEADER WITH BACK BUTTON
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // 🔙 BACK BUTTON
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Destination QR",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // 🔵 QR CARD
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      destinationName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: qrData,
                      size: 260,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.print),
                      label: const Text("Download & Print QR"),
                      onPressed: () {
                        downloadQrPdf(destinationName, qrData);
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      qrData,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
