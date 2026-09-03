import '../repositories/video_repository.dart';

class DeleteVideo {
  const DeleteVideo(this._repository);

  final VideoRepository _repository;

  Future<void> call(String videoId) => _repository.deleteVideo(videoId);
}
