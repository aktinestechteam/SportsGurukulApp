import '../entities/video_comment.dart';
import '../repositories/video_repository.dart';

class AddComment {
  const AddComment(this._repository);

  final VideoRepository _repository;

  Future<VideoComment> call(String videoId, AddCommentInput input) =>
      _repository.addComment(videoId, input);
}
