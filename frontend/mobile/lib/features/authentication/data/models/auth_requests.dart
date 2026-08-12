class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.password,
    required this.confirmPassword,
    required this.acceptTerms,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String password;
  final String confirmPassword;
  final bool acceptTerms;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'mobileNumber': mobileNumber,
    'password': password,
    'confirmPassword': confirmPassword,
    'acceptTerms': acceptTerms,
  };
}

class RefreshTokenRequest {
  const RefreshTokenRequest(this.refreshToken);

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest(this.email);

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String token;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}
