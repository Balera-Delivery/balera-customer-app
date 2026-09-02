import 'package:intl/intl.dart';

class Formatters {
  static String date(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  static String dateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  static String time(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String currency(num? amount) {
    if (amount == null) return '0.00 ETB';
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '${formatter.format(amount)} ETB';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
