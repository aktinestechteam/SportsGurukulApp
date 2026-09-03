import '../entities/video_comment.dart';
import '../repositories/video_repository.dart';

class EditComment {
  const EditComment(this._repository);

  final VideoRepository _repository;

  Future<VideoComment> call(
    String videoId,
    String commentId,
    String message,
  ) =>
      _repository.editComment(videoId, commentId, message);
}
