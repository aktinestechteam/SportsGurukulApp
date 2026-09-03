import '../repositories/video_repository.dart';

class GetUnreadCount {
  const GetUnreadCount(this._repository);

  final VideoRepository _repository;

  Future<int> call() => _repository.getUnreadCount();
}
