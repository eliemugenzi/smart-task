import 'package:intl/intl.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

 String formatDueDate(DateTime date) {
    bool isToday = DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;
    if (isToday) {
      return 'Today, ${DateFormat('hh:mm a').format(date)}';
    }
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }