import '../repositories/auth_repository.dart';

class CheckSession {
  const CheckSession(this._repository);

  final AuthRepository _repository;

  Future<bool> call() => _repository.hasStoredSession();
}
