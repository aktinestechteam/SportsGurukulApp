import '../repositories/auth_repository.dart';

class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) => _repository.register(
    firstName: firstName,
    lastName: lastName,
    email: email,
    mobileNumber: mobileNumber,
    password: password,
    confirmPassword: confirmPassword,
    acceptTerms: acceptTerms,
  );
}
