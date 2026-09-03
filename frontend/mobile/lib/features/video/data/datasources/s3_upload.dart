import 'package:http/http.dart' as http;

/// Uploads raw [bytes] to a presigned S3 upload URL.
///
/// S3 presigned PUT URLs require the exact object content type, so [mimeType]
/// must match the one used when the presigned URL was generated.
///
/// Uses `package:http` body bytes so it works on both mobile (`dart:io`) and
/// Flutter Web (`XHR`), unlike `dart:io`'s `File` which does not exist on web.
Future<bool> uploadToPresignedUrl({
  required String presignedUrl,
  required List<int> bytes,
  required String mimeType,
}) async {
  if (presignedUrl.isEmpty) {
    return false;
  }

  final request = http.Request('PUT', Uri.parse(presignedUrl))
    ..headers['Content-Type'] = mimeType
    ..bodyBytes = bytes;

  final streamed = await request.send();
  await streamed.stream.drain<void>();
  return streamed.statusCode >= 200 && streamed.statusCode < 300;
}
