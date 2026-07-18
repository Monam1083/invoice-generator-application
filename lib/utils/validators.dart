/// Shared form-field validators used across invoice and settings screens.
class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value, {bool optional = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return optional ? null : 'Email is required';
    }
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? phone(String? value, {bool optional = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return optional ? null : 'Phone number is required';
    }
    final regex = RegExp(r'^[\d\+\-\s\(\)]{6,}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'Value'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$field is required';
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid $field';
    }
    return null;
  }

  static String? nonNegativeNumber(String? value, {String field = 'Value'}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      return 'Enter a valid $field';
    }
    return null;
  }
}
