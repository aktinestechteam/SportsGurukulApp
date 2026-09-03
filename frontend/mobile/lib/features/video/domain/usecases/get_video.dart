import '../entities/video_submission.dart';
import '../repositories/video_repository.dart';

class GetVideo {
  const GetVideo(this._repository);

  final VideoRepository _repository;

  Future<VideoDetail> call(String videoId) => _repository.getVideo(videoId);
}
