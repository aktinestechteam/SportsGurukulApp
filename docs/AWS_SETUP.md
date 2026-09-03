# AWS S3 Setup Guide

This document explains how to configure AWS S3 for storing and serving the
videos, thumbnails, and voice notes in SPORTSGURUKUL.

## Overview

- **Bucket:** private S3 bucket (e.g. `sportsgurukul-media`)
- **Access:** presigned URLs only (never make the bucket public)
- **Keys:** generated automatically by the backend — no manual folder creation needed
- **Formats:** only `MP4` (H.264/AAC) videos are accepted, since those play on
  Android (ExoPlayer), iOS (AVPlayer), and web (browser)

## 1. IAM user (where the keys come from)

Create a programmatic IAM user and give it S3 access **only on your bucket**:

1. AWS Console → **IAM → Users → Create user** (name e.g. `sportsgurukul-backend`).
2. Do **not** grant console access (this is a programmatic/API user).
3. Attach this inline policy (least privilege):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::sportsgurukul-media/*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::sportsgurukul-media"
    }
  ]
}
```

4. **Create access key** → AWS shows an **Access key ID** and a **Secret access key**.
   Save both. These are the credentials the backend uses.

## 2. Create the bucket

1. AWS S3 Console → **Create bucket**.
2. Name it exactly as you want it referenced (recommended: `sportsgurukul-media`).
3. Choose the region (e.g. `ap-south-1`). Remember it — it must match config.
4. **Block all public access = ON** (bucket stays private).
5. After creation, in **Permissions → Cross-origin resource sharing (CORS)** add:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["PUT", "GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

No bucket folders are needed — the backend writes files under `videos/...` and
`voice-notes/...` keys automatically on upload.

## 3. Where to put your credentials in the project

### Option A — appsettings.json

File: `backend/api/SPORTSGURUKUL.Api/appsettings.json`

```json
"Aws": {
  "AccessKey": "YOUR_AWS_ACCESS_KEY",
  "SecretKey": "YOUR_AWS_SECRET_KEY",
  "BucketName": "sportsgurukul-media",
  "Region": "ap-south-1",
  "UrlExpirationMinutes": 10
}
```

> Note: the `"Aws"` block may already exist with placeholders. Fill in the values.
> Do **not** commit real secrets if this repo is shared — prefer Option B.

### Option B — environment variables (recommended)

The code reads these automatically and they override the file values:

| Variable | Value |
|----------|-------|
| `AWS_ACCESS_KEY_ID` | your Access key ID |
| `AWS_SECRET_ACCESS_KEY` | your Secret access key |
| `AWS_REGION` | e.g. `ap-south-1` |

PowerShell example:

```powershell
$env:AWS_ACCESS_KEY_ID = "YOUR_ACCESS_KEY"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_KEY"
$env:AWS_REGION = "ap-south-1"
```

If you use env vars, you can leave the AccessKey/SecretKey in the file as placeholders.

## 4. Restart the API server

After changing credentials or config, **stop and restart** the API so the new
values load:

```powershell
cd backend\api
dotnet run
```

## 5. Verify

- Upload an MP4 video from the app. It should appear in the S3 bucket under
  `videos/<athleteUserId>/<random>.mp4`.
- Playback uses a 10-minute presigned URL (`UrlExpirationMinutes`, default 10).
- Deleting a video/comment removes the related S3 objects too.

## Troubleshooting

- **`InvalidAccessKeyId` / `SignatureDoesNotMatch`** — keys are wrong, or region
  in config doesn't match the bucket region.
- **Browser upload fails with CORS error** — the CORS rule in Section 2 is missing.
- **Playback blank/black screen** — file is not H.264/AAC MP4 (only MP4 is accepted).

## Related code locations

| Concern | Path |
|---------|------|
| S3 service interface | `backend/api/SPORTSGURUKUL.Application/Common/Interfaces/IS3Service.cs` |
| S3 implementation | `backend/api/SPORTSGURUKUL.Infrastructure/Storage/S3Service.cs` |
| S3 options + DI | `backend/api/SPORTSGURUKUL.Application/Common/Options/AwsOptions.cs`, `backend/api/SPORTSGURUKUL.Infrastructure/DependencyInjection.cs` |
| S3 config | `backend/api/SPORTSGURUKUL.Api/appsettings.json` |
| Presigned URL endpoint + key building | `backend/api/SPORTSGURUKUL.Api/Controllers/VideosController.cs` |
| Read (download) URLs | `backend/api/SPORTSGURUKUL.Application/Videos/Common/VideoResponseMapper.cs` |
| S3 delete cleanup | `backend/api/SPORTSGURUKUL.Application/Videos/Commands/DeleteVideoCommand.cs`, `DeleteCommentCommand.cs` |
| Client upload helper | `frontend/mobile/lib/features/video/data/datasources/s3_upload.dart` |
