import '../entities/video_submission.dart';
import '../repositories/video_repository.dart';

class GetAdminCoachVideoFeed {
  const GetAdminCoachVideoFeed(this._repository);

  final VideoRepository _repository;

  Future<List<VideoSubmission>> call(
    String academyId,
    String coachId, {
    String? sportId,
    String? athleteId,
  }) =>
      _repository.getAdminCoachVideoFeed(
        academyId,
        coachId,
        sportId: sportId,
        athleteId: athleteId,
      );
}
