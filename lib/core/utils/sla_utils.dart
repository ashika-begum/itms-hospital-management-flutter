/*import 'package:cloud_firestore/cloud_firestore.dart';

class SLAUtils {
  /// Returns remaining minutes before SLA deadline
  static int remainingMinutes(Timestamp deadline) {
    final now = DateTime.now();
    return deadline.toDate().difference(now).inMinutes;
  }

  /// Returns true if SLA deadline is crossed
  static bool isBreached(Timestamp deadline) {
    return DateTime.now().isAfter(deadline.toDate());
  }
}*/
