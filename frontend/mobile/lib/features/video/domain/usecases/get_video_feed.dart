import '../entities/video_submission.dart';
import '../repositories/video_repository.dart';

class GetVideoFeed {
  const GetVideoFeed(this._repository);

  final VideoRepository _repository;

  Future<List<VideoSubmission>> call({
    String? sportId,
    String? athleteId,
  }) =>
      _repository.getFeed(sportId: sportId, athleteId: athleteId);
}
