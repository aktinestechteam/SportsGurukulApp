import 'video_comment.dart';

class VideoSubmission {
  const VideoSubmission({
    required this.id,
    required this.title,
    this.sportName,
    this.athleteId,
    required this.athleteName,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.commentCount = 0,
    this.isViewed = false,
    this.isNew = false,
    this.createdAt = '',
  });

  final String id;
  final String title;
  final String? sportName;
  final String? athleteId;
  final String athleteName;
  final String? thumbnailUrl;
  final int durationSeconds;
  final int commentCount;
  final bool isViewed;
  final bool isNew;
  final String createdAt;

  factory VideoSubmission.fromJson(Map<String, dynamic> json) {
    return VideoSubmission(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sportName: json['sportName'] as String?,
      athleteId: json['athleteId'] as String?,
      athleteName: json['athleteName'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isViewed: json['isViewed'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sportName': sportName,
    'athleteId': athleteId,
    'athleteName': athleteName,
    'thumbnailUrl': thumbnailUrl,
    'durationSeconds': durationSeconds,
    'commentCount': commentCount,
    'isViewed': isViewed,
    'isNew': isNew,
    'createdAt': createdAt,
  };
}

class VideoDetail {
  const VideoDetail({
    required this.id,
    required this.title,
    this.sportName,
    this.athleteId,
    required this.athleteName,
    this.thumbnailUrl,
    this.message,
    this.videoUrl = '',
    this.durationSeconds = 0,
    this.commentCount = 0,
    this.isViewed = false,
    this.isNew = false,
    this.createdAt = '',
    this.comments = const [],
  });

  final String id;
  final String title;
  final String? sportName;
  final String? athleteId;
  final String athleteName;
  final String? thumbnailUrl;
  final String? message;
  final String videoUrl;
  final int durationSeconds;
  final int commentCount;
  final bool isViewed;
  final bool isNew;
  final String createdAt;
  final List<VideoComment> comments;

  factory VideoDetail.fromJson(Map<String, dynamic> json) {
    return VideoDetail(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sportName: json['sportName'] as String?,
      athleteId: json['athleteId'] as String?,
      athleteName: json['athleteName'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      message: json['message'] as String?,
      videoUrl: json['videoUrl'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isViewed: json['isViewed'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      comments: (json['comments'] as List? ?? const [])
          .map((e) => VideoComment.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'sportName': sportName,
    'athleteId': athleteId,
    'athleteName': athleteName,
    'thumbnailUrl': thumbnailUrl,
    'message': message,
    'videoUrl': videoUrl,
    'durationSeconds': durationSeconds,
    'commentCount': commentCount,
    'isViewed': isViewed,
    'isNew': isNew,
    'createdAt': createdAt,
    'comments': comments.map((e) => e.toJson()).toList(),
  };

  VideoSubmission toSubmission() {
    return VideoSubmission(
      id: id,
      title: title,
      sportName: sportName,
      athleteId: athleteId,
      athleteName: athleteName,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      commentCount: commentCount,
      isViewed: isViewed,
      isNew: isNew,
      createdAt: createdAt,
    );
  }

  VideoDetail copyWith({
    List<VideoComment>? comments,
    int? commentCount,
    bool? isViewed,
    bool? isNew,
  }) {
    return VideoDetail(
      id: id,
      title: title,
      sportName: sportName,
      athleteId: athleteId,
      athleteName: athleteName,
      thumbnailUrl: thumbnailUrl,
      message: message,
      videoUrl: videoUrl,
      durationSeconds: durationSeconds,
      commentCount: commentCount ?? this.commentCount,
      isViewed: isViewed ?? this.isViewed,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt,
      comments: comments ?? this.comments,
    );
  }
}

class CoachVideoOverview {
  const CoachVideoOverview({
    required this.coachId,
    required this.firstName,
    required this.lastName,
    this.sports = const [],
    this.athleteCount = 0,
    this.totalVideoCount = 0,
    this.unreviewedVideoCount = 0,
  });

  final String coachId;
  final String firstName;
  final String lastName;
  final List<String> sports;
  final int athleteCount;
  final int totalVideoCount;
  final int unreviewedVideoCount;

  String get fullName => '$firstName $lastName'.trim();

  factory CoachVideoOverview.fromJson(Map<String, dynamic> json) {
    return CoachVideoOverview(
      coachId: json['coachId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      sports: (json['sports'] as List? ?? const []).cast<String>(),
      athleteCount: json['athleteCount'] as int? ?? 0,
      totalVideoCount: json['totalVideoCount'] as int? ?? 0,
      unreviewedVideoCount: json['unreviewedVideoCount'] as int? ?? 0,
    );
  }
}

class VideoNotification {
  const VideoNotification({
    required this.type,
    required this.videoId,
    required this.videoTitle,
    required this.actorName,
    this.athleteId,
    this.createdAt = '',
  });

  final String type;
  final String videoId;
  final String videoTitle;
  final String actorName;
  final String? athleteId;
  final String createdAt;

  factory VideoNotification.fromJson(Map<String, dynamic> json) {
    return VideoNotification(
      type: json['type'] as String? ?? '',
      videoId: json['videoId'] as String? ?? '',
      videoTitle: json['videoTitle'] as String? ?? '',
      actorName: json['actorName'] as String? ?? '',
      athleteId: json['athleteId'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
