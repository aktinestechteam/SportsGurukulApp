import '../../domain/entities/video_comment.dart';
import '../../domain/entities/video_submission.dart';
import '../../domain/repositories/video_repository.dart';
import '../datasources/video_remote_data_source.dart';
import '../models/video_requests.dart';

class VideoRepositoryImpl implements VideoRepository {
  VideoRepositoryImpl({required this.dataSource});

  final VideoRemoteDataSource dataSource;

  @override
  Future<PresignedUpload> generatePresignedUrl(
    GeneratePresignedUrlInput input,
  ) {
    return dataSource.generatePresignedUrl(
      GeneratePresignedUrlRequest(
        fileName: input.fileName,
        contentType: input.contentType,
        fileSizeBytes: input.fileSizeBytes,
      ),
    );
  }

  @override
  Future<VideoDetail> createVideo(CreateVideoInput input) {
    return dataSource.createVideo(_mapCreateRequest(input));
  }

  @override
  Future<List<VideoSubmission>> getMyVideos() => dataSource.getMyVideos();

  @override
  Future<List<VideoSubmission>> getFeed({
    String? sportId,
    String? athleteId,
  }) =>
      dataSource.getFeed(sportId: sportId, athleteId: athleteId);

  @override
  Future<VideoDetail> getVideo(String videoId) => dataSource.getVideo(videoId);

  @override
  Future<void> deleteVideo(String videoId) => dataSource.deleteVideo(videoId);

  @override
  Future<int> getUnreadCount() => dataSource.getUnreadCount();

  @override
  Future<List<VideoNotification>> getNotifications() =>
      dataSource.getNotifications();

  @override
  Future<VideoComment> addComment(String videoId, AddCommentInput input) {
    return dataSource.addComment(videoId, _mapAddCommentRequest(input));
  }

  @override
  Future<VideoComment> editComment(
    String videoId,
    String commentId,
    String message,
  ) =>
      dataSource.editComment(videoId, commentId, message);

  @override
  Future<void> deleteComment(String videoId, String commentId) =>
      dataSource.deleteComment(videoId, commentId);

  @override
  Future<List<CoachVideoOverview>> getAdminCoachesOverview(String academyId) =>
      dataSource.getAdminCoachesOverview(academyId);

  @override
  Future<List<VideoSubmission>> getAdminCoachVideoFeed(
    String academyId,
    String coachId, {
    String? sportId,
    String? athleteId,
  }) =>
      dataSource.getAdminCoachVideoFeed(
        academyId,
        coachId,
        sportId: sportId,
        athleteId: athleteId,
      );

  CreateVideoRequest _mapCreateRequest(CreateVideoInput input) {
    return CreateVideoRequest(
      title: input.title,
      message: input.message,
      s3Key: input.s3Key,
      thumbnailS3Key: input.thumbnailS3Key,
      durationSeconds: input.durationSeconds,
      fileSizeBytes: input.fileSizeBytes,
      sportId: input.sportId,
    );
  }

  AddCommentRequest _mapAddCommentRequest(AddCommentInput input) {
    return AddCommentRequest(
      message: input.message,
      voiceNoteS3Key: input.voiceNoteS3Key,
      voiceNoteDurationSeconds: input.voiceNoteDurationSeconds,
      voiceNoteSizeBytes: input.voiceNoteSizeBytes,
    );
  }
}
