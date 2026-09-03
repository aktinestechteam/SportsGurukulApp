import '../entities/video_submission.dart';
import '../repositories/video_repository.dart';

class GetMyVideos {
  const GetMyVideos(this._repository);

  final VideoRepository _repository;

  Future<List<VideoSubmission>> call() => _repository.getMyVideos();
}
