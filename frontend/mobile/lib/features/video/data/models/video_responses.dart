import '../../domain/entities/video_comment.dart';
import '../../domain/entities/video_submission.dart';
import '../../domain/repositories/video_repository.dart';

/// Parsing helpers for the `{ "data": ... }` API envelope returned by the
/// backend, mapping raw payloads into their domain response types.
class VideoResponseParser {
  VideoResponseParser._();

  static PresignedUpload presignedUpload(Map<String, dynamic> json) =>
      PresignedUpload.fromJson(json);

  static VideoDetail videoDetail(Map<String, dynamic> json) =>
      VideoDetail.fromJson(json);

  static List<VideoSubmission> videoList(Object? data) {
    if (data is! List) {
      return const [];
    }
    return data
        .map((e) => VideoSubmission.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static VideoComment comment(Map<String, dynamic> json) =>
      VideoComment.fromJson(json);

  static List<VideoComment> commentList(Object? data) {
    if (data is! List) {
      return const [];
    }
    return data
        .map((e) => VideoComment.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static List<VideoNotification> notificationList(Object? data) {
    if (data is! List) {
      return const [];
    }
    return data
        .map((e) => VideoNotification.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static List<CoachVideoOverview> coachOverviewList(Object? data) {
    if (data is! List) {
      return const [];
    }
    return data
        .map((e) => CoachVideoOverview.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
