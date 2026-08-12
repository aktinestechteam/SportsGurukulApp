import '../repositories/auth_repository.dart';

class ResetPassword {
  const ResetPassword(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) => _repository.resetPassword(
    token: token,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );
}
