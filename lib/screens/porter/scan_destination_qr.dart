import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanDestinationQR extends StatefulWidget {
  final String requestId;
  final String expectedItemId;

  const ScanDestinationQR({
    super.key,
    required this.requestId,
    required this.expectedItemId,
  });

  @override
  State<ScanDestinationQR> createState() => _ScanDestinationQRState();
}

class _ScanDestinationQRState extends State<ScanDestinationQR> {
  bool _handled = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSuccess() async {
    final requestDoc = await FirebaseFirestore.instance
        .collection("requests")
        .doc(widget.requestId)
        .get();

    final data = requestDoc.data() ?? {};

    // ✅ Get From & To directly from map
    final from = data["from"]?["itemName"] ?? "Unknown";
    final to = data["to"]?["itemName"] ?? "Unknown";

    // ✅ Fetch nurse name using nurseId
    String requestedBy = "Unknown";
    final nurseId = data["nurseId"];

    if (nurseId != null) {
      final nurseDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(nurseId)
          .get();

      requestedBy = nurseDoc.data()?["name"] ?? "Unknown";
    }

    // ✅ Calculate Time Taken
    DateTime? acceptedAt;
    if (data["timeline"]?["acceptedAt"] != null) {
      acceptedAt = (data["timeline"]["acceptedAt"] as Timestamp).toDate();
    }

    final now = DateTime.now();
    String timeTaken = "";

    if (acceptedAt != null) {
      final diff = now.difference(acceptedAt);
      timeTaken = "${diff.inMinutes} min ${diff.inSeconds % 60} sec";
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Text(
                "Request Completed 🎉",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _infoRow("From", from),
              _infoRow("To", to),
              _infoRow("Requested By", requestedBy),
              if (timeTaken.isNotEmpty) _infoRow("Time Taken", timeTaken),
              const SizedBox(height: 24),
              const Text(
                "Congratulations! Great job 👏",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Done"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Destination QR")),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) async {
          if (_handled) return;
          _handled = true;

          final code = capture.barcodes.first.rawValue;
          if (code == null) {
            _handled = false;
            return;
          }

          final scannedItemId = code.replaceFirst("DEST:", "").trim();

          if (scannedItemId != widget.expectedItemId) {
            _handled = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ Wrong destination QR")),
            );
            return;
          }

          await _controller.stop();

          await FirebaseFirestore.instance
              .collection("requests")
              .doc(widget.requestId)
              .update({
            "status": "completed",
            "flags.awaitingDestinationVerification": false,
            "timeline.arrivedDestinationConfirmedAt":
                FieldValue.serverTimestamp(),
            "timeline.completedAt": FieldValue.serverTimestamp(),
            "lastUpdatedAt": FieldValue.serverTimestamp(),
          });

          await _handleSuccess();
        },
      ),
    );
  }
}
