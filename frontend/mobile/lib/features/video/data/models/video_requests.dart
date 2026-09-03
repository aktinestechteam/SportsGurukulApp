class GeneratePresignedUrlRequest {
  const GeneratePresignedUrlRequest({
    required this.fileName,
    required this.contentType,
    required this.fileSizeBytes,
  });

  final String fileName;
  final String contentType;
  final int fileSizeBytes;

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'contentType': contentType,
    'fileSizeBytes': fileSizeBytes,
  };
}

class CreateVideoRequest {
  const CreateVideoRequest({
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

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    's3Key': s3Key,
    'thumbnailS3Key': thumbnailS3Key,
    'durationSeconds': durationSeconds,
    'fileSizeBytes': fileSizeBytes,
    'sportId': sportId,
  };
}

class AddCommentRequest {
  const AddCommentRequest({
    this.message,
    this.voiceNoteS3Key,
    this.voiceNoteDurationSeconds,
    this.voiceNoteSizeBytes,
  });

  final String? message;
  final String? voiceNoteS3Key;
  final int? voiceNoteDurationSeconds;
  final int? voiceNoteSizeBytes;

  Map<String, dynamic> toJson() => {
    'message': message,
    'voiceNoteS3Key': voiceNoteS3Key,
    'voiceNoteDurationSeconds': voiceNoteDurationSeconds,
    'voiceNoteSizeBytes': voiceNoteSizeBytes,
  };
}

class UpdateCommentRequest {
  const UpdateCommentRequest({required this.message});

  final String message;

  Map<String, dynamic> toJson() => {'message': message};
}
