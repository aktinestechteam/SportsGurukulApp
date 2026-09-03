import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/video_comment.dart';
import '../../domain/entities/video_submission.dart';

/// Real-time SignalR client for the video feature. Listens to comment and
/// video push events and exposes them as broadcast streams. The presentation
/// layer should call [connect] on login and [disconnect] on logout, and use
/// [joinVideo] / [leaveVideo] when a user enters/leaves a video screen.
class VideoSignalRService {
  VideoSignalRService({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  HubConnection? _connection;

  final _newCommentController =
      StreamController<VideoCommentEvent>.broadcast();
  final _commentUpdatedController =
      StreamController<VideoCommentEvent>.broadcast();
  final _commentDeletedController =
      StreamController<VideoCommentDeleteEvent>.broadcast();
  final _newVideoController = StreamController<VideoSubmission>.broadcast();
  final _videoDeletedController = StreamController<String>.broadcast();
  final _coachRemovedController = StreamController<String>.broadcast();
  final _connectionStateController =
      StreamController<HubConnectionState>.broadcast();

  Stream<VideoCommentEvent> get onNewComment => _newCommentController.stream;
  Stream<VideoCommentEvent> get onCommentUpdated =>
      _commentUpdatedController.stream;
  Stream<VideoCommentDeleteEvent> get onCommentDeleted =>
      _commentDeletedController.stream;
  Stream<VideoSubmission> get onNewVideo => _newVideoController.stream;
  Stream<String> get onVideoDeleted => _videoDeletedController.stream;
  Stream<String> get onCoachRemoved => _coachRemovedController.stream;
  Stream<HubConnectionState> get onConnectionState =>
      _connectionStateController.stream;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  /// Connects to the `/hubs/video` endpoint using the current access token.
  Future<void> connect() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await disconnect();

    final baseUrl = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api$'), '');
    final url = '$baseUrl/hubs/video?access_token=$token';

    final connection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            skipNegotiation: true,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _registerHandlers(connection);

    _connection = connection;

    connection.onreconnecting(({error}) {
      _connectionStateController.add(HubConnectionState.Reconnecting);
    });

    connection.onreconnected(({connectionId}) {
      _connectionStateController.add(HubConnectionState.Connected);
    });

    connection.onclose(({error}) {
      _connectionStateController.add(HubConnectionState.Disconnected);
    });

    await connection.start();
    _connectionStateController.add(HubConnectionState.Connected);
  }

  /// Stops the active connection and releases its handlers.
  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) {
      return;
    }
    try {
      await connection.stop();
    } catch (_) {
      // Best-effort disconnect.
    }
    _connectionStateController.add(HubConnectionState.Disconnected);
  }

  /// Joins the comment group for a given video.
  Future<void> joinVideo(String videoId) async {
    final connection = _connection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      return;
    }
    await connection.send('JoinVideo', args: [videoId]);
  }

  /// Leaves the comment group for a given video.
  Future<void> leaveVideo(String videoId) async {
    final connection = _connection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      return;
    }
    await connection.send('LeaveVideo', args: [videoId]);
  }

  void _registerHandlers(HubConnection connection) {
    connection.on('NewComment', (args) {
      final videoId = _argString(args, 0);
      final comment = _argMap(args, 1);
      if (videoId != null && comment != null) {
        _newCommentController.add(
          VideoCommentEvent(videoId, VideoComment.fromJson(comment)),
        );
      }
    });

    connection.on('CommentUpdated', (args) {
      final videoId = _argString(args, 0);
      final comment = _argMap(args, 1);
      if (videoId != null && comment != null) {
        _commentUpdatedController.add(
          VideoCommentEvent(videoId, VideoComment.fromJson(comment)),
        );
      }
    });

    connection.on('CommentDeleted', (args) {
      final videoId = _argString(args, 0);
      final commentId = _argString(args, 1);
      if (videoId != null && commentId != null) {
        _commentDeletedController.add(
          VideoCommentDeleteEvent(videoId, commentId),
        );
      }
    });

    connection.on('NewVideo', (args) {
      final video = _argMap(args, 0);
      if (video != null) {
        _newVideoController.add(VideoSubmission.fromJson(video));
      }
    });

    connection.on('VideoDeleted', (args) {
      final videoId = _argString(args, 0);
      if (videoId != null) {
        _videoDeletedController.add(videoId);
      }
    });

    connection.on('CoachRemoved', (args) {
      final athleteId = _argString(args, 0);
      if (athleteId != null) {
        _coachRemovedController.add(athleteId);
      }
    });
  }

  String? _argString(List<Object?>? args, int index) {
    if (args == null || index >= args.length) {
      return null;
    }
    return args[index]?.toString();
  }

  Map<String, dynamic>? _argMap(List<Object?>? args, int index) {
    if (args == null || index >= args.length) {
      return null;
    }
    final value = args[index];
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  void dispose() {
    _newCommentController.close();
    _commentUpdatedController.close();
    _commentDeletedController.close();
    _newVideoController.close();
    _videoDeletedController.close();
    _coachRemovedController.close();
    _connectionStateController.close();
  }
}

class VideoCommentEvent {
  const VideoCommentEvent(this.videoId, this.comment);

  final String videoId;
  final VideoComment comment;
}

class VideoCommentDeleteEvent {
  const VideoCommentDeleteEvent(this.videoId, this.commentId);

  final String videoId;
  final String commentId;
}
