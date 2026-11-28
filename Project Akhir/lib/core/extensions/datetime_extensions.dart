import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  static const _locale = 'id_ID';

  /// 26 November 2026, 10:13
  String get displayDate =>
      DateFormat('d MMMM y, HH:mm', _locale).format(toLocal());

  /// Senin, 30 November
  String get dayAndMonth =>
      DateFormat('EEEE, d MMMM', _locale).format(toLocal());
}