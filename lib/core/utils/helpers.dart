import 'package:intl/intl.dart';

class Helpers {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'BOOKED':
        return 'Booked';
      case 'ACCEPTED':
        return 'Accepted';
      case 'PLANNED':
        return 'Planned';
      case 'ACTIVE':
        return 'Active';
      case 'COMPLETED':
        return 'Completed';
      case 'POD_PENDING':
        return 'POD Pending';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static String getTripTypeLabel(String tripType) {
    switch (tripType.toUpperCase()) {
      case 'IMPORT':
        return 'Import';
      case 'EXPORT':
        return 'Export';
      default:
        return tripType;
    }
  }
}
