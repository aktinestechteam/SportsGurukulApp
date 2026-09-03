import '../entities/video_comment.dart';
import '../entities/video_submission.dart';

abstract class VideoRepository {
  Future<PresignedUpload> generatePresignedUrl(
    GeneratePresignedUrlInput input,
  );

  Future<VideoDetail> createVideo(CreateVideoInput input);

  Future<List<VideoSubmission>> getMyVideos();

  Future<List<VideoSubmission>> getFeed({
    String? sportId,
    String? athleteId,
  });

  Future<VideoDetail> getVideo(String videoId);

  Future<void> deleteVideo(String videoId);

  Future<int> getUnreadCount();

  Future<List<VideoNotification>> getNotifications();

  Future<VideoComment> addComment(String videoId, AddCommentInput input);

  Future<VideoComment> editComment(
    String videoId,
    String commentId,
    String message,
  );

  Future<void> deleteComment(String videoId, String commentId);

  Future<List<CoachVideoOverview>> getAdminCoachesOverview(String academyId);

  Future<List<VideoSubmission>> getAdminCoachVideoFeed(
    String academyId,
    String coachId, {
    String? sportId,
    String? athleteId,
  });
}

class GeneratePresignedUrlInput {
  const GeneratePresignedUrlInput({
    required this.fileName,
    required this.contentType,
    required this.fileSizeBytes,
  });

  final String fileName;
  final String contentType;
  final int fileSizeBytes;
}

class PresignedUpload {
  const PresignedUpload({required this.uploadUrl, required this.s3Key});

  final String uploadUrl;
  final String s3Key;

  factory PresignedUpload.fromJson(Map<String, dynamic> json) {
    return PresignedUpload(
      uploadUrl: json['uploadUrl'] as String? ?? '',
      s3Key: json['s3Key'] as String? ?? '',
    );
  }
}

class CreateVideoInput {
  const CreateVideoInput({
    required this.title,
    this.message,
    required this.s3Key,
    this.thumbnailS3Key,
    this.durationSeconds,
    required this.fileSizeBytes,
    this.sportId,
  });

  final String title;
  final String? message;
  final String s3Key;
  final String? thumbnailS3Key;
  final int? durationSeconds;
  final int fileSizeBytes;
  final String? sportId;
}

class AddCommentInput {
  const AddCommentInput({
    this.message,
    this.voiceNoteS3Key,
    this.voiceNoteDurationSeconds,
    this.voiceNoteSizeBytes,
  });

  final String? message;
  final String? voiceNoteS3Key;
  final int? voiceNoteDurationSeconds;
  final int? voiceNoteSizeBytes;
}
