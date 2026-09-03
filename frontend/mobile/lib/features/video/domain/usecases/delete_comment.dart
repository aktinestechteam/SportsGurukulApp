import '../repositories/video_repository.dart';

class DeleteComment {
  const DeleteComment(this._repository);

  final VideoRepository _repository;

  Future<void> call(String videoId, String commentId) =>
      _repository.deleteComment(videoId, commentId);
}
