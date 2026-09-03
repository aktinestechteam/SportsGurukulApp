import '../entities/video_submission.dart';
import '../repositories/video_repository.dart';

class GetNotifications {
  const GetNotifications(this._repository);

  final VideoRepository _repository;

  Future<List<VideoNotification>> call() => _repository.getNotifications();
}
