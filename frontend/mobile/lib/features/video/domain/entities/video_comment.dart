class VideoComment {
  const VideoComment({
    required this.id,
    required this.authorName,
    this.authorRole,
    this.message,
    this.voiceNoteUrl,
    this.voiceNoteDurationSeconds,
    this.isDeleted = false,
    this.createdAt = '',
    this.isOwnComment = false,
  });

  final String id;
  final String authorName;
  final String? authorRole;
  final String? message;
  final String? voiceNoteUrl;
  final int? voiceNoteDurationSeconds;
  final bool isDeleted;
  final String createdAt;
  final bool isOwnComment;

  bool get hasVoiceNote => voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty;

  factory VideoComment.fromJson(Map<String, dynamic> json) {
    return VideoComment(
      id: json['id'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorRole: json['authorRole'] as String?,
      message: json['message'] as String?,
      voiceNoteUrl: json['voiceNoteUrl'] as String?,
      voiceNoteDurationSeconds: json['voiceNoteDurationSeconds'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      isOwnComment: json['isOwnComment'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'authorRole': authorRole,
    'message': message,
    'voiceNoteUrl': voiceNoteUrl,
    'voiceNoteDurationSeconds': voiceNoteDurationSeconds,
    'isDeleted': isDeleted,
    'createdAt': createdAt,
    'isOwnComment': isOwnComment,
  };

  VideoComment copyWith({
    String? message,
    bool? isDeleted,
  }) {
    return VideoComment(
      id: id,
      authorName: authorName,
      authorRole: authorRole,
      message: message ?? this.message,
      voiceNoteUrl: voiceNoteUrl,
      voiceNoteDurationSeconds: voiceNoteDurationSeconds,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      isOwnComment: isOwnComment,
    );
  }
}
