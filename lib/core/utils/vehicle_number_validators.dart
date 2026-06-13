/// Indian registration: 2 letters + 2 digits + 2 letters + 4 digits (10 chars), e.g. MH12AB3434.
class VehicleNumberValidators {
  static String normalize(String? value) {
    if (value == null || value.isEmpty) return '';
    return value.replaceAll(RegExp(r'\s+'), '').trim().toUpperCase();
  }

  static String? validateIndianRegistration(String? value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) {
      return 'Enter vehicle number';
    }
    if (normalized.length != 10) {
      return 'Vehicle number must be exactly 10 characters (e.g. MH12AB3434)';
    }
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{2}[0-9]{4}$').hasMatch(normalized)) {
      return 'Use format: state (2 letters), district (2 digits), series (2 letters), number (4 digits)';
    }
    return null;
  }
}
