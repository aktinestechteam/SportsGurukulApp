final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
final RegExp _mobileRegExp = RegExp(r'^\+?\d{7,15}$');
final RegExp _passwordUpper = RegExp(r'[A-Z]');
final RegExp _passwordLower = RegExp(r'[a-z]');
final RegExp _passwordDigit = RegExp(r'\d');
final RegExp _passwordSpecial = RegExp(r'[^A-Za-z0-9]');

String? validateRequired(String? value, {String field = 'This field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$field is required.';
  }
  return null;
}

String? validateEmail(String? value) {
  final required = validateRequired(value, field: 'Email');
  if (required != null) {
    return required;
  }
  if (!_emailRegExp.hasMatch(value!.trim())) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? validateMobile(String? value) {
  final required = validateRequired(value, field: 'Mobile number');
  if (required != null) {
    return required;
  }
  if (!_mobileRegExp.hasMatch(value!.trim())) {
    return 'Enter a valid mobile number.';
  }
  return null;
}

String? validatePassword(String? value) {
  final required = validateRequired(value, field: 'Password');
  if (required != null) {
    return required;
  }
  final password = value!;
  if (password.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  if (!_passwordUpper.hasMatch(password) ||
      !_passwordLower.hasMatch(password) ||
      !_passwordDigit.hasMatch(password) ||
      !_passwordSpecial.hasMatch(password)) {
    return 'Password needs uppercase, lowercase, number and special character.';
  }
  return null;
}

String? Function(String?) confirmWith(
  String Function() getValue, {
  required String field,
}) {
  return (value) {
    final required = validateRequired(value, field: field);
    if (required != null) {
      return required;
    }
    if (value != getValue()) {
      return 'Passwords do not match.';
    }
    return null;
  };
}
