import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  /// 15 Nov 2026, 14:30
  String get displayDate => DateFormat('d MMM yyyy, HH:mm').format(toLocal());
}