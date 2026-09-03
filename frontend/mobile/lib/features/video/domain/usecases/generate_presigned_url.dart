import '../repositories/video_repository.dart';

class GeneratePresignedUrl {
  const GeneratePresignedUrl(this._repository);

  final VideoRepository _repository;

  Future<PresignedUpload> call(GeneratePresignedUrlInput input) =>
      _repository.generatePresignedUrl(input);
}
