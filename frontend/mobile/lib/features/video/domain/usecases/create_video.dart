import '../entities/video_submission.dart';
import '../repositories/video_repository.dart';

class CreateVideo {
  const CreateVideo(this._repository);

  final VideoRepository _repository;

  Future<VideoDetail> call(CreateVideoInput input) =>
      _repository.createVideo(input);
}
