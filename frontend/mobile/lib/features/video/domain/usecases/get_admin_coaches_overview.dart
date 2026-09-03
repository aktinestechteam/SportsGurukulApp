import '../entities/video_submission.dart';
import '../repositories/video_repository.dart';

class GetAdminCoachesOverview {
  const GetAdminCoachesOverview(this._repository);

  final VideoRepository _repository;

  Future<List<CoachVideoOverview>> call(String academyId) =>
      _repository.getAdminCoachesOverview(academyId);
}
