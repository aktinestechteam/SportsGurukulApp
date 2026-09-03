import '../../../../core/network/api_client.dart';
import '../../domain/entities/video_comment.dart';
import '../../domain/entities/video_submission.dart';
import '../../domain/repositories/video_repository.dart';
import '../models/video_requests.dart';
import '../models/video_responses.dart';

class VideoRemoteDataSource {
  VideoRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<PresignedUpload> generatePresignedUrl(
    GeneratePresignedUrlRequest request,
  ) async {
    final data = await _api.post('/videos/presigned-url', body: request.toJson());
    return VideoResponseParser.presignedUpload(
      (data as Map).cast<String, dynamic>(),
    );
  }

  Future<VideoDetail> createVideo(CreateVideoRequest request) async {
    final data = await _api.post('/videos', body: request.toJson());
    return VideoResponseParser.videoDetail(
      (data as Map).cast<String, dynamic>(),
    );
  }

  Future<List<VideoSubmission>> getMyVideos() async {
    final data = await _api.get('/videos/mine');
    return VideoResponseParser.videoList(data);
  }

  Future<List<VideoSubmission>> getFeed({
    String? sportId,
    String? athleteId,
  }) async {
    final data = await _api.get('/videos/feed', query: {
      if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
      if (athleteId != null && athleteId.isNotEmpty) 'athleteId': athleteId,
    });
    return VideoResponseParser.videoList(data);
  }

  Future<VideoDetail> getVideo(String videoId) async {
    final data = await _api.get('/videos/$videoId');
    return VideoResponseParser.videoDetail(
      (data as Map).cast<String, dynamic>(),
    );
  }

  Future<void> deleteVideo(String videoId) async {
    await _api.delete('/videos/$videoId');
  }

  Future<int> getUnreadCount() async {
    final data = await _api.get('/videos/unread-count');
    if (data is Map) {
      final count = data['count'];
      return count is int ? count : 0;
    }
    return data is int ? data : 0;
  }

  Future<List<VideoNotification>> getNotifications() async {
    final data = await _api.get('/videos/notifications');
    return VideoResponseParser.notificationList(data);
  }

  Future<VideoComment> addComment(
    String videoId,
    AddCommentRequest request,
  ) async {
    final data = await _api.post('/videos/$videoId/comments', body: request.toJson());
    return VideoResponseParser.comment((data as Map).cast<String, dynamic>());
  }

  Future<VideoComment> editComment(
    String videoId,
    String commentId,
    String message,
  ) async {
    final data = await _api.put(
      '/videos/$videoId/comments/$commentId',
      body: UpdateCommentRequest(message: message).toJson(),
    );
    return VideoResponseParser.comment((data as Map).cast<String, dynamic>());
  }

  Future<void> deleteComment(String videoId, String commentId) async {
    await _api.delete('/videos/$videoId/comments/$commentId');
  }

  Future<List<CoachVideoOverview>> getAdminCoachesOverview(
    String academyId,
  ) async {
    final data = await _api.get('/academies/$academyId/videos/coaches');
    return VideoResponseParser.coachOverviewList(data);
  }

  Future<List<VideoSubmission>> getAdminCoachVideoFeed(
    String academyId,
    String coachId, {
    String? sportId,
    String? athleteId,
  }) async {
    final data = await _api.get(
      '/academies/$academyId/videos/coaches/$coachId',
      query: {
        if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
        if (athleteId != null && athleteId.isNotEmpty) 'athleteId': athleteId,
      },
    );
    return VideoResponseParser.videoList(data);
  }
}
