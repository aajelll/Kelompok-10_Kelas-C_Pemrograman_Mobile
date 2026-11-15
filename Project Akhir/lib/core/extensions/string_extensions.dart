extension StringX on String {
  /// "resilient" -> "Resilient"
  String get capitalized =>
      isEmpty ? this : this[0].toUpperCase() + substring(1).toLowerCase();

  /// Validasi format email sederhana.
  bool get isValidEmail => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trim());
}