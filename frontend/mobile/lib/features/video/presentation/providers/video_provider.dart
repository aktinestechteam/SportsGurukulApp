import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/datasources/video_signalr_service.dart';
import '../../domain/entities/video_comment.dart';
import '../../domain/entities/video_submission.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/create_video.dart';
import '../../domain/usecases/delete_comment.dart';
import '../../domain/usecases/delete_video.dart';
import '../../domain/usecases/edit_comment.dart';
import '../../domain/usecases/generate_presigned_url.dart';
import '../../domain/usecases/get_admin_coach_video_feed.dart';
import '../../domain/usecases/get_admin_coaches_overview.dart';
import '../../domain/usecases/get_my_videos.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/get_unread_count.dart';
import '../../domain/usecases/get_video.dart';
import '../../domain/usecases/get_video_feed.dart';

enum VideoStatus { initial, loading, loaded, error }

enum VideoDetailStatus { initial, loading, loaded, error }

class VideoProvider extends ChangeNotifier {
  VideoProvider({
    required GetMyVideos getMyVideos,
    required GetVideoFeed getVideoFeed,
    required GetVideo getVideo,
    required CreateVideo createVideo,
    required AddComment addComment,
    required EditComment editComment,
    required DeleteComment deleteComment,
    required DeleteVideo deleteVideo,
    required GetUnreadCount getUnreadCount,
    required GetNotifications getNotifications,
    required GetAdminCoachesOverview getAdminCoachesOverview,
    required GetAdminCoachVideoFeed getAdminCoachVideoFeed,
    required GeneratePresignedUrl generatePresignedUrl,
    required VideoSignalRService signalR,
  }) : _getMyVideos = getMyVideos,
       _getVideoFeed = getVideoFeed,
       _getVideo = getVideo,
       _createVideo = createVideo,
       _addComment = addComment,
       _editComment = editComment,
       _deleteComment = deleteComment,
       _deleteVideo = deleteVideo,
       _getUnreadCount = getUnreadCount,
       _getNotifications = getNotifications,
       _getAdminCoachesOverview = getAdminCoachesOverview,
       _getAdminCoachVideoFeed = getAdminCoachVideoFeed,
       _generatePresignedUrl = generatePresignedUrl,
       _signalR = signalR {
    _newCommentSub = _signalR.onNewComment.listen(_handleNewComment);
    _commentUpdatedSub = _signalR.onCommentUpdated.listen(_handleCommentUpdated);
    _commentDeletedSub =
        _signalR.onCommentDeleted.listen(_handleCommentDeleted);
    _videoDeletedSub = _signalR.onVideoDeleted.listen(_handleVideoDeleted);
    _newVideoSub = _signalR.onNewVideo.listen(_handleNewVideo);
    _coachRemovedSub = _signalR.onCoachRemoved.listen(_handleCoachRemoved);
  }

  final GetMyVideos _getMyVideos;
  final GetVideoFeed _getVideoFeed;
  final GetVideo _getVideo;
  final CreateVideo _createVideo;
  final AddComment _addComment;
  final EditComment _editComment;
  final DeleteComment _deleteComment;
  final DeleteVideo _deleteVideo;
  final GetUnreadCount _getUnreadCount;
  final GetNotifications _getNotifications;
  final GetAdminCoachesOverview _getAdminCoachesOverview;
  final GetAdminCoachVideoFeed _getAdminCoachVideoFeed;
  final GeneratePresignedUrl _generatePresignedUrl;
  final VideoSignalRService _signalR;

  late final StreamSubscription<VideoCommentEvent> _newCommentSub;
  late final StreamSubscription<VideoCommentEvent> _commentUpdatedSub;
  late final StreamSubscription<VideoCommentDeleteEvent> _commentDeletedSub;
  late final StreamSubscription<String> _videoDeletedSub;
  late final StreamSubscription<VideoSubmission> _newVideoSub;
  late final StreamSubscription<String> _coachRemovedSub;

  VideoStatus _myVideosStatus = VideoStatus.initial;
  List<VideoSubmission> _myVideos = [];
  String? _myVideosError;

  VideoStatus _feedStatus = VideoStatus.initial;
  List<VideoSubmission> _feed = [];
  String? _feedError;

  VideoDetailStatus _detailStatus = VideoDetailStatus.initial;
  VideoDetail? _currentVideo;
  String? _detailError;

  String? _openVideoId;

  bool _isCreating = false;
  bool _isSendingComment = false;
  bool _isEditingComment = false;
  bool _isDeletingComment = false;
  bool _isDeletingVideo = false;
  String? _actionError;

  int _unreadCount = 0;
  bool _notificationsLoaded = false;
  List<VideoNotification> _notifications = [];

  VideoStatus _adminOverviewStatus = VideoStatus.initial;
  List<CoachVideoOverview> _adminOverview = [];
  String? _adminOverviewError;

  VideoStatus _adminFeedStatus = VideoStatus.initial;
  List<VideoSubmission> _adminFeed = [];
  String? _adminFeedError;

  // Getters
  VideoStatus get myVideosStatus => _myVideosStatus;
  List<VideoSubmission> get myVideos => _myVideos;
  String? get myVideosError => _myVideosError;

  VideoStatus get feedStatus => _feedStatus;
  List<VideoSubmission> get feed => _feed;
  String? get feedError => _feedError;

  VideoStatus get adminOverviewStatus => _adminOverviewStatus;
  List<CoachVideoOverview> get adminOverview => _adminOverview;
  String? get adminOverviewError => _adminOverviewError;

  VideoStatus get adminFeedStatus => _adminFeedStatus;
  List<VideoSubmission> get adminFeed => _adminFeed;
  String? get adminFeedError => _adminFeedError;

  VideoDetailStatus get detailStatus => _detailStatus;
  VideoDetail? get currentVideo => _currentVideo;
  List<VideoComment> get comments => _currentVideo?.comments ?? const [];
  String? get detailError => _detailError;

  String? get openVideoId => _openVideoId;
  bool get isCreating => _isCreating;
  bool get isSendingComment => _isSendingComment;
  bool get isEditingComment => _isEditingComment;
  bool get isDeletingComment => _isDeletingComment;
  bool get isDeletingVideo => _isDeletingVideo;
  String? get actionError => _actionError;

  int get unreadCount => _unreadCount;
  bool get notificationsLoaded => _notificationsLoaded;
  List<VideoNotification> get notifications => _notifications;

  bool get isLoadingMyVideos =>
      _myVideosStatus == VideoStatus.initial ||
      _myVideosStatus == VideoStatus.loading;
  bool get isLoadingFeed =>
      _feedStatus == VideoStatus.initial || _feedStatus == VideoStatus.loading;
  bool get isLoadingAdminOverview =>
      _adminOverviewStatus == VideoStatus.initial ||
      _adminOverviewStatus == VideoStatus.loading;
  bool get isLoadingAdminFeed =>
      _adminFeedStatus == VideoStatus.initial ||
      _adminFeedStatus == VideoStatus.loading;
  bool get isLoadingDetail => _detailStatus == VideoDetailStatus.initial ||
      _detailStatus == VideoDetailStatus.loading;

  // -------------------------------------------------------------------------
  // Feed / list loading
  // -------------------------------------------------------------------------

  Future<void> loadMyVideos({bool refresh = false}) async {
    if (!refresh) {
      _myVideosStatus = VideoStatus.loading;
    }
    _myVideosError = null;
    notifyListeners();

    try {
      _myVideos = await _getMyVideos();
      _myVideosStatus = VideoStatus.loaded;
    } on ApiException catch (e) {
      if (!refresh) {
        _myVideosStatus = VideoStatus.error;
      }
      _myVideosError = e.friendlyMessage;
    } catch (_) {
      if (!refresh) {
        _myVideosStatus = VideoStatus.error;
      }
      _myVideosError = 'Unable to load your videos. Please try again.';
    }
    notifyListeners();
  }

  Future<void> loadFeed({
    String? sportId,
    String? athleteId,
    bool refresh = false,
  }) async {
    if (!refresh) {
      _feedStatus = VideoStatus.loading;
    }
    _feedError = null;
    notifyListeners();

    try {
      _feed = await _getVideoFeed(
        sportId: sportId,
        athleteId: athleteId,
      );
      _feedStatus = VideoStatus.loaded;
    } on ApiException catch (e) {
      if (!refresh) {
        _feedStatus = VideoStatus.error;
      }
      _feedError = e.friendlyMessage;
    } catch (_) {
      if (!refresh) {
        _feedStatus = VideoStatus.error;
      }
      _feedError = 'Unable to load the video feed. Please try again.';
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Admin overview / coach feed
  // -------------------------------------------------------------------------

  Future<void> loadAdminCoachesOverview(
    String academyId, {
    bool refresh = false,
  }) async {
    if (!refresh) {
      _adminOverviewStatus = VideoStatus.loading;
    }
    _adminOverviewError = null;
    notifyListeners();

    try {
      _adminOverview = await _getAdminCoachesOverview(academyId);
      _adminOverviewStatus = VideoStatus.loaded;
    } on ApiException catch (e) {
      if (!refresh) {
        _adminOverviewStatus = VideoStatus.error;
      }
      _adminOverviewError = e.friendlyMessage;
    } catch (_) {
      if (!refresh) {
        _adminOverviewStatus = VideoStatus.error;
      }
      _adminOverviewError =
          'Unable to load the coach video overview. Please try again.';
    }
    notifyListeners();
  }

  Future<void> loadAdminCoachFeed(
    String academyId,
    String coachId, {
    String? sportId,
    String? athleteId,
    bool refresh = false,
  }) async {
    if (!refresh) {
      _adminFeedStatus = VideoStatus.loading;
    }
    _adminFeedError = null;
    notifyListeners();

    try {
      _adminFeed = await _getAdminCoachVideoFeed(
        academyId,
        coachId,
        sportId: sportId,
        athleteId: athleteId,
      );
      _adminFeedStatus = VideoStatus.loaded;
    } on ApiException catch (e) {
      if (!refresh) {
        _adminFeedStatus = VideoStatus.error;
      }
      _adminFeedError = e.friendlyMessage;
    } catch (_) {
      if (!refresh) {
        _adminFeedStatus = VideoStatus.error;
      }
      _adminFeedError =
          'Unable to load this coach\'s videos. Please try again.';
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Detail
  // -------------------------------------------------------------------------

  /// Opens a video, joining the SignalR group for it and loading details.
  Future<VideoDetail?> openVideo(String videoId) async {
    _openVideoId = videoId;
    _detailStatus = VideoDetailStatus.loading;
    _detailError = null;
    notifyListeners();

    await _signalR.joinVideo(videoId);

    try {
      final video = await _getVideo(videoId);
      _currentVideo = video;
      _detailStatus = VideoDetailStatus.loaded;
      notifyListeners();
      return video;
    } on ApiException catch (e) {
      _detailStatus = VideoDetailStatus.error;
      _detailError = e.friendlyMessage;
      notifyListeners();
      return null;
    } catch (_) {
      _detailStatus = VideoDetailStatus.error;
      _detailError = 'Unable to load this video. Please try again.';
      notifyListeners();
      return null;
    }
  }

  /// Leaves the SignalR group for the currently open video.
  Future<void> closeVideo() async {
    final videoId = _openVideoId;
    _openVideoId = null;
    _currentVideo = null;
    if (videoId != null) {
      await _signalR.leaveVideo(videoId);
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Create video
  // -------------------------------------------------------------------------

  Future<bool> createVideo(CreateVideoInput input) async {
    _isCreating = true;
    _actionError = null;
    notifyListeners();
    try {
      final video = await _createVideo(input);
      _myVideos = [video.toSubmission(), ..._myVideos];
      _isCreating = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isCreating = false;
      _actionError = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _isCreating = false;
      _actionError = 'Unable to upload the video. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Comments
  // -------------------------------------------------------------------------

  Future<VideoComment?> addComment(
    String videoId,
    AddCommentInput input,
  ) async {
    _isSendingComment = true;
    _actionError = null;
    notifyListeners();
    try {
      final comment = await _addComment(videoId, input);
      _applyComment(comment);
      _isSendingComment = false;
      notifyListeners();
      return comment;
    } on ApiException catch (e) {
      _isSendingComment = false;
      _actionError = e.friendlyMessage;
      notifyListeners();
      return null;
    } catch (_) {
      _isSendingComment = false;
      _actionError = 'Unable to send your message. Please try again.';
      notifyListeners();
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Edit / delete comment
  // -------------------------------------------------------------------------

  /// Edits the current user's own comment and updates it locally.
  Future<VideoComment?> editComment(
    String videoId,
    String commentId,
    String message,
  ) async {
    final text = message.trim();
    if (text.isEmpty) {
      return null;
    }
    _isEditingComment = true;
    _actionError = null;
    notifyListeners();
    try {
      final comment = await _editComment(videoId, commentId, text);
      _applyComment(comment);
      _isEditingComment = false;
      notifyListeners();
      return comment;
    } on ApiException catch (e) {
      _isEditingComment = false;
      _actionError = e.friendlyMessage;
      notifyListeners();
      return null;
    } catch (_) {
      _isEditingComment = false;
      _actionError = 'Unable to update your comment. Please try again.';
      notifyListeners();
      return null;
    }
  }

  /// Deletes the current user's own comment, marking it deleted locally.
  Future<bool> deleteComment(String videoId, String commentId) async {
    _isDeletingComment = true;
    _actionError = null;
    notifyListeners();
    try {
      await _deleteComment(videoId, commentId);
      final updated = _replaceComment(
        commentId,
        (comment) => comment.copyWith(isDeleted: true),
      );
      if (_currentVideo != null && updated != null) {
        _currentVideo = _currentVideo!.copyWith(comments: updated);
      }
      _isDeletingComment = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isDeletingComment = false;
      _actionError = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _isDeletingComment = false;
      _actionError = 'Unable to delete your comment. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Delete video
  // -------------------------------------------------------------------------

  /// Deletes the athlete's own video along with all of its comments.
  /// Returns true on success.
  Future<bool> deleteVideo(String videoId) async {
    _isDeletingVideo = true;
    _actionError = null;
    notifyListeners();
    try {
      await _deleteVideo(videoId);
      _myVideos = _myVideos.where((v) => v.id != videoId).toList();
      _feed = _feed.where((v) => v.id != videoId).toList();
      _adminFeed = _adminFeed.where((v) => v.id != videoId).toList();
      if (_openVideoId == videoId) {
        _openVideoId = null;
        _currentVideo = null;
        _detailStatus = VideoDetailStatus.initial;
      }
      _isDeletingVideo = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isDeletingVideo = false;
      _actionError = e.friendlyMessage;
      notifyListeners();
      return false;
    } catch (_) {
      _isDeletingVideo = false;
      _actionError = 'Unable to delete the video. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Unread count / notifications
  // -------------------------------------------------------------------------

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _getUnreadCount();
      notifyListeners();
    } catch (_) {
      // Non-fatal; leave the previous count.
    }
  }

  Future<void> loadNotifications() async {
    try {
      _notifications = await _getNotifications();
      _notificationsLoaded = true;
      notifyListeners();
    } catch (_) {
      // Non-fatal; leave previously loaded notifications.
    }
  }

  // -------------------------------------------------------------------------
  // Presigned URL
  // -------------------------------------------------------------------------

  Future<PresignedUpload?> generatePresignedUrl(
    GeneratePresignedUrlInput input,
  ) async {
    try {
      return await _generatePresignedUrl(input);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActionError() {
    _actionError = null;
    return Future.value();
  }

  // -------------------------------------------------------------------------
  // SignalR handlers
  // -------------------------------------------------------------------------

  void _handleNewComment(VideoCommentEvent event) {
    if (event.videoId == _openVideoId) {
      _applyComment(event.comment);
      notifyListeners();
    }
  }

  void _handleCommentUpdated(VideoCommentEvent event) {
    if (event.videoId == _openVideoId) {
      _applyComment(event.comment);
      notifyListeners();
    }
  }

  void _handleCommentDeleted(VideoCommentDeleteEvent event) {
    if (event.videoId != _openVideoId) {
      return;
    }
    final updated = _replaceComment(
      event.commentId,
      (comment) => VideoComment(
        id: comment.id,
        authorName: comment.authorName,
        authorRole: comment.authorRole,
        message: comment.message,
        voiceNoteUrl: comment.voiceNoteUrl,
        voiceNoteDurationSeconds: comment.voiceNoteDurationSeconds,
        isDeleted: true,
        createdAt: comment.createdAt,
        isOwnComment: comment.isOwnComment,
      ),
    );
    if (_currentVideo != null && updated != null) {
      _currentVideo = _currentVideo!.copyWith(comments: updated);
      notifyListeners();
    }
  }

  void _handleVideoDeleted(String videoId) {
    final myBefore = _myVideos.length;
    final feedBefore = _feed.length;
    final adminBefore = _adminFeed.length;
    _myVideos = _myVideos.where((v) => v.id != videoId).toList();
    _feed = _feed.where((v) => v.id != videoId).toList();
    _adminFeed = _adminFeed.where((v) => v.id != videoId).toList();
    if (_myVideos.length != myBefore ||
        _feed.length != feedBefore ||
        _adminFeed.length != adminBefore) {
      notifyListeners();
    }
  }

  void _handleNewVideo(VideoSubmission video) {
    _feed = [video, ..._feed];
    notifyListeners();
  }

  void _handleCoachRemoved(String athleteId) {
    final before = _feed.length;
    final adminBefore = _adminFeed.length;
    _feed = _feed.where((v) => v.athleteId != athleteId).toList();
    _adminFeed = _adminFeed.where((v) => v.athleteId != athleteId).toList();
    if (_feed.length != before || _adminFeed.length != adminBefore) {
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _applyComment(VideoComment comment) {
    if (_currentVideo == null) {
      return;
    }

    final index = _currentVideo!.comments.indexWhere((c) => c.id == comment.id);
    final updated = [
      for (var i = 0; i < _currentVideo!.comments.length; i++)
        if (i == index) comment else _currentVideo!.comments[i],
      if (index == -1) comment,
    ];

    _currentVideo = _currentVideo!.copyWith(
      comments: updated,
      commentCount: index == -1
          ? (_currentVideo!.commentCount + 1)
          : _currentVideo!.commentCount,
    );
  }

  List<VideoComment>? _replaceComment(
    String commentId,
    VideoComment Function(VideoComment) transform,
  ) {
    if (_currentVideo == null) {
      return null;
    }
    for (var i = 0; i < _currentVideo!.comments.length; i++) {
      if (_currentVideo!.comments[i].id == commentId) {
        final updated = [
          for (var j = 0; j < _currentVideo!.comments.length; j++)
            if (j == i)
              transform(_currentVideo!.comments[i])
            else
              _currentVideo!.comments[j],
        ];
        return updated;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _newCommentSub.cancel();
    _commentUpdatedSub.cancel();
    _commentDeletedSub.cancel();
    _videoDeletedSub.cancel();
    _newVideoSub.cancel();
    _coachRemovedSub.cancel();
    final videoId = _openVideoId;
    _openVideoId = null;
    if (videoId != null) {
      _signalR.leaveVideo(videoId);
    }
    super.dispose();
  }
}
