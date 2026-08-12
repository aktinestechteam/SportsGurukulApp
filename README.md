# SPORTSGURUKUL

SPORTSGURUKUL is a sports training and learning platform delivered as a mobile application backed by a REST API.

## Repository Structure

```text
SPORTSGURUKUL/
├── docs/
│   └── features/          Feature specifications and design documents
├── frontend/
│   └── mobile/            Flutter mobile application
├── backend/
│   └── api/               .NET solution and Web API project
└── README.md
```

## Backend (backend/api)

- Solution: `SPORTSGURUKUL.sln`
- Project: `SPORTSGURUKUL.Api` (ASP.NET Core Web API, net9.0)

```bash
cd backend/api
dotnet build SPORTSGURUKUL.sln
dotnet run --project SPORTSGURUKUL.Api
```

## Frontend (frontend/mobile)

Flutter application (`sports_gurukul`) targeting Android and iOS.

```bash
cd frontend/mobile
flutter pub get
flutter run
```

## Documentation

Feature specifications live under `docs/features/`.
