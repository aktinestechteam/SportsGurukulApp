# SPORTSGURUKUL -- Authentication Feature Requirements

## 1. Document Information

  Item       Value
  ---------- -------------------------
  Project    SPORTSGURUKUL
  Feature    Authentication
  Version    1.0
  Status     Development Requirement
  Frontend   Flutter
  Backend    .NET 9 Web API
  Database   PostgreSQL
  ORM        Entity Framework Core
  Scope      Authentication only

## 2. Objective

Implement a complete, secure, production-ready Authentication feature
for SPORTSGURUKUL. This is the first functional module and must provide
the foundation for future modules.

Scope includes application startup/session validation, registration,
sign in/out, forgot/reset/change password, refresh token, current user,
account status, default role, secure password/token handling, API
validation, PostgreSQL persistence, and Flutter UI/state management.

Out of scope: Academy, Coach, Athlete, Training, Attendance, Diet,
Video, Payment, Marketplace, Notifications, AI, Analytics and other
business features.

## 3. Technology

### Frontend

-   Flutter / Dart
-   Material 3
-   Feature-based architecture
-   Centralized API client
-   Secure token storage
-   Centralized authentication state
-   Route guards

### Backend

-   .NET 9 / ASP.NET Core Web API / C#
-   Entity Framework Core
-   PostgreSQL provider
-   JWT Bearer Authentication
-   Refresh Tokens
-   FluentValidation or equivalent
-   Swagger/OpenAPI
-   Structured logging

## 4. Authentication User Journey

``` text
Application Start → Splash → Check Session
                              ├─ No Session → Sign In
                              └─ Session → Validate/Refresh → /auth/me → Home

Sign Up → Validate → Create User → Assign AppUser → Sign In

Forgot Password → Email → Secure Reset Token → Reset Password → Sign In
```

## 5. Default Role

Every normal registration receives `AppUser`. The backend owns role
assignment.

Initial roles: - SystemAdmin - AcademyAdmin - AcademyCoach -
AcademyAthlete - Coach - Athlete - AppUser

Only `AppUser` is assigned by this module. The model must support
multiple roles later.

## 6. Splash / Session Initialization

1.  Show splash.
2.  Read access/refresh tokens from secure storage.
3.  No session → Sign In.
4.  Existing session → validate access token.
5.  Expired access token + valid refresh token → refresh.
6.  Call `GET /api/auth/me`.
7.  Store authenticated user state.
8.  Navigate to Home.
9.  Failed refresh/validation → clear session → Sign In.

Do not flash the Sign In page when a valid session exists.

## 7. Sign Up

### Fields

-   First Name
-   Last Name
-   Email
-   Mobile Number
-   Password
-   Confirm Password
-   Accept Terms & Conditions

### Validation

-   Required fields
-   Valid email
-   Valid mobile number
-   Password policy
-   Password confirmation
-   Terms acceptance

Frontend validation is for UX; backend validation is authoritative.

### API

`POST /api/auth/register`

Request:

``` json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "mobileNumber": "+919999999999",
  "password": "Password@123",
  "confirmPassword": "Password@123",
  "acceptTerms": true
}
```

Registration rules: - Case-insensitive unique email. - Secure password
hash only; never plaintext. - Account status Active unless email
verification is enabled. - Assign AppUser automatically. - Transactional
creation. - No sensitive data in response.

## 8. Sign In

### Screen

Email, Password, Sign In, Forgot Password, Create Account, password
visibility, loading and validation/error states.

### API

`POST /api/auth/login`

Request:

``` json
{
  "email": "john@example.com",
  "password": "Password@123"
}
```

Successful response contains access token, refresh token, expiry and
user identity/roles.

Rules: - Validate credentials. - Enforce account status. - Update
LastLoginAt. - Generate access and refresh tokens. - Return current user
information. - Never expose password information.

## 9. JWT Access Token

Use JWT Bearer authentication. Claims should be limited to required
identity/authorization data such as User ID, Email, Roles, token ID,
issued time and expiry. Do not put sensitive personal data into JWT.
Keep access tokens short-lived. Store signing secrets only in secure
server configuration/environment variables.

## 10. Refresh Token

### API

`POST /api/auth/refresh`

Request:

``` json
{ "refreshToken": "..." }
```

Validate existence, hash, expiry, revocation and user status. Issue a
new access token and rotate the refresh token. Revoke the old refresh
token and persist the new token.

## 11. Logout

### API

`POST /api/auth/logout`

Request:

``` json
{ "refreshToken": "..." }
```

Revoke refresh token, clear Flutter tokens/state and navigate to Sign
In. Logout should be safe to repeat.

## 12. Current User

### API

`GET /api/auth/me`

Requires authentication.

Example response:

``` json
{
  "success": true,
  "message": "User retrieved successfully.",
  "data": {
    "userId": "...",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "mobileNumber": "+919999999999",
    "roles": ["AppUser"],
    "defaultRole": "AppUser",
    "accountStatus": "Active"
  }
}
```

## 13. Forgot Password

### API

`POST /api/auth/forgot-password`

Request:

``` json
{ "email": "john@example.com" }
```

Always return a generic response so the API cannot reveal whether an
account exists.

Example: \> If an account exists for this email, password reset
instructions have been sent.

Generate a cryptographically secure, expiring, single-use token. Store
only its hash.

## 14. Reset Password

### API

`POST /api/auth/reset-password`

Request:

``` json
{
  "token": "...",
  "newPassword": "NewPassword@123",
  "confirmPassword": "NewPassword@123"
}
```

Validate token existence, expiry and unused state. Hash the new
password, mark token used, and revoke existing refresh sessions after
successful reset.

Handle invalid, expired and already-used reset links.

## 15. Change Password

### API

`POST /api/auth/change-password`

Request:

``` json
{
  "currentPassword": "OldPassword@123",
  "newPassword": "NewPassword@123",
  "confirmPassword": "NewPassword@123"
}
```

Require current password, validate new password and confirmation,
securely update password, and handle existing refresh sessions according
to the security policy.

## 16. Account Status

Supported states: - Active - Suspended - Deactivated - Locked

Only Active users can sign in. Enforcement must be server-side.

## 17. Email Verification

Architecture must support email verification. If enabled in the first
release:

`POST /api/auth/verify-email`

`POST /api/auth/resend-verification`

Tokens must be secure, hashed, expiring and single-use. If deferred,
keep the model ready without unnecessary UI/API implementation.

## 18. Password Policy

Recommended default: - Minimum 8 characters - One uppercase - One
lowercase - One number - One special character

Keep policy centralized/configurable. Backend is authoritative.

## 19. PostgreSQL Tables

### Users

``` text
Users
--------------------------------
Id
FirstName
LastName
Email
NormalizedEmail
MobileNumber
NormalizedMobileNumber
PasswordHash
AccountStatus
IsEmailVerified
CreatedAt
UpdatedAt
LastLoginAt
```

Recommended: UUID primary key, unique NormalizedEmail, indexes,
timestamptz UTC timestamps.

### Roles

``` text
Roles
--------------------------------
Id
Name
Description
IsSystemRole
CreatedAt
```

Seed: SystemAdmin, AcademyAdmin, AcademyCoach, AcademyAthlete, Coach,
Athlete, AppUser.

### UserRoles

``` text
UserRoles
--------------------------------
UserId
RoleId
AssignedAt
AssignedBy
IsActive
```

Foreign keys to Users/Roles and unique UserId + RoleId.

### RefreshTokens

``` text
RefreshTokens
--------------------------------
Id
UserId
TokenHash
ExpiresAt
CreatedAt
RevokedAt
ReplacedByTokenId
CreatedByIp
RevokedByIp
```

Store only token hash. Index TokenHash and UserId. Support rotation and
revocation.

### PasswordResetTokens

``` text
PasswordResetTokens
--------------------------------
Id
UserId
TokenHash
ExpiresAt
CreatedAt
UsedAt
```

Store only hash, require expiry and single use.

### EmailVerificationTokens (if enabled)

``` text
EmailVerificationTokens
--------------------------------
Id
UserId
TokenHash
ExpiresAt
CreatedAt
UsedAt
```

## 20. Entity Relationships

``` text
User
 |
 +----< UserRoles >---- Role
 |
 +----< RefreshTokens
 |
 +----< PasswordResetTokens
 |
 +----< EmailVerificationTokens
```

Define delete behavior explicitly; do not allow uncontrolled cascading
deletion of security/audit records.

## 21. EF Core

Implement: - DbContext - Entity configurations - Relationships -
Indexes - Unique constraints - PostgreSQL UUID support - UTC timestamp
handling - EF Core migration

The migration must create the authentication schema. Do not maintain
duplicate manual SQL table definitions.

## 22. Backend API Endpoints

``` text
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
GET  /api/auth/me
POST /api/auth/forgot-password
POST /api/auth/reset-password
POST /api/auth/change-password
POST /api/auth/verify-email
POST /api/auth/resend-verification
```

Email verification endpoints may be omitted if explicitly deferred.

## 23. API Response Standard

Success:

``` json
{
  "success": true,
  "message": "Operation completed successfully.",
  "data": {}
}
```

Validation:

``` json
{
  "success": false,
  "message": "Validation failed.",
  "errors": {
    "email": ["Invalid email address."]
  }
}
```

Do not expose stack traces or internal exception details.

## 24. Flutter Structure

Use the existing feature boundary:

``` text
frontend/mobile/lib/features/authentication/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── widgets/
    └── providers/
```

## 25. Flutter Pages

Implement: - splash_page.dart - sign_in_page.dart - sign_up_page.dart -
forgot_password_page.dart - reset_password_page.dart -
change_password_page.dart

Home is only a basic authenticated destination for this feature.

## 26. Flutter Authentication State

Support: - Initial - CheckingSession - Unauthenticated -
Authenticating - Authenticated - Refreshing - LoggingOut -
SessionExpired - Error

Authentication state must be centralized and not stored inside
individual screens.

## 27. Flutter Secure Storage

Store access and refresh tokens using secure device storage. Do not use
plain SharedPreferences for sensitive tokens.

## 28. Flutter API Client

Centralized API client must handle base URL, headers, access token, HTTP
status handling, refresh flow, timeout, serialization and authentication
failure handling. Widgets must not make raw HTTP calls.

## 29. Flutter Routing

``` text
/ → Splash → Session Check
                 ├─ No → /sign-in
                 └─ Valid → /home
```

Authentication routes: - /sign-in - /sign-up - /forgot-password -
/reset-password - /change-password

Protect authenticated routes.

## 30. Home After Login

For this feature only:

``` text
Welcome, {First Name}
Role: App User

[Change Password]
[Logout]
```

No business features yet.

## 31. Error Handling

Handle invalid email/password, duplicate email, invalid registration,
suspended/deactivated/locked accounts, expired/invalid reset links,
network/API failures, session expiry and refresh failure. Never display
raw exceptions.

## 32. Security Requirements

Mandatory: - Secure password hashing - Secure reset tokens - Secure
refresh tokens - JWT validation - Refresh token rotation - Refresh token
revocation - Account status enforcement - Rate limiting on sensitive
authentication endpoints - Generic Forgot Password response -
HTTPS-ready API - Secure Flutter token storage - Server-side
authorization - Input validation - Database constraints - No secrets in
source control

Never store plaintext passwords/tokens, trust client-supplied roles,
store JWT secrets in Flutter, or expose internal exceptions.

## 33. Configuration

Use environment/secret configuration for:

``` text
ConnectionStrings__DefaultConnection
Jwt__Secret
Jwt__Issuer
Jwt__Audience
Jwt__AccessTokenMinutes
Jwt__RefreshTokenDays
Email__Host
Email__Port
Email__Username
Email__Password
```

Never commit real values.

## 34. Logging

Log authentication events without secrets: - Registration
attempt/result - Login success/failure - Logout - Token refresh -
Password reset requested/completed - Password changed - Account
blocked/suspended

Never log passwords, access tokens, refresh tokens, reset tokens or
verification tokens.

## 35. Acceptance Criteria

### Registration

-   [ ] Registration works.
-   [ ] Required fields validated.
-   [ ] Duplicate email prevented.
-   [ ] Password securely hashed.
-   [ ] AppUser assigned automatically.
-   [ ] Account created successfully.

### Sign In

-   [ ] Valid user can sign in.
-   [ ] Invalid credentials rejected.
-   [ ] Account status enforced.
-   [ ] Access and refresh tokens generated.
-   [ ] User information returned.

### Session

-   [ ] Tokens stored securely.
-   [ ] Splash checks session.
-   [ ] Access token refresh works.
-   [ ] Refresh token rotation works.
-   [ ] Invalid session redirects to Sign In.

### Password Recovery

-   [ ] Forgot Password works.
-   [ ] Generic response prevents account enumeration.
-   [ ] Reset token expires.
-   [ ] Reset token is single-use.
-   [ ] Password can be reset.
-   [ ] Existing refresh sessions handled after reset.

### Change Password

-   [ ] Current password validated.
-   [ ] New password validated.
-   [ ] Password updated securely.
-   [ ] Existing sessions handled according to policy.

### Logout

-   [ ] Refresh token revoked.
-   [ ] Local tokens cleared.
-   [ ] User state cleared.
-   [ ] User returns to Sign In.

### Current User

-   [ ] `/api/auth/me` works.
-   [ ] AppUser is returned as default role.
-   [ ] Roles come from backend.
-   [ ] Unauthorized requests rejected.

### Database

-   [ ] Tables created through EF migration.
-   [ ] Foreign keys exist.
-   [ ] Unique email constraint exists.
-   [ ] Required indexes exist.
-   [ ] Roles seeded.

### Frontend

-   [ ] Authentication screens work.
-   [ ] Validation works.
-   [ ] Loading states work.
-   [ ] API errors handled.
-   [ ] Route protection works.
-   [ ] Session restoration works.
-   [ ] Successful login opens Home.

## 36. Implementation Sequence

### Phase 1 -- Database

1.  Define authentication entities.
2.  Configure PostgreSQL.
3.  Configure EF Core.
4.  Create migration.
5.  Create authentication tables.
6.  Seed roles.

### Phase 2 -- Backend

1.  Configuration.
2.  Password hashing.
3.  JWT service.
4.  Refresh token service.
5.  Registration API.
6.  Login API.
7.  Current User API.
8.  Refresh API.
9.  Logout API.
10. Forgot Password API.
11. Reset Password API.
12. Change Password API.
13. Email verification if enabled.
14. Error handling.
15. Validation.
16. Swagger.

### Phase 3 -- Flutter

1.  Authentication models.
2.  API client.
3.  Secure storage.
4.  Repository.
5.  Authentication state.
6.  Routing.
7.  Splash.
8.  Sign In.
9.  Sign Up.
10. Forgot Password.
11. Reset Password.
12. Change Password.
13. Home.
14. Logout.
15. Session restoration.

### Phase 4 -- Integration

Verify:

``` text
Sign Up → Sign In → Home → Refresh Session → Logout
```

and:

``` text
Forgot Password → Reset Password → Sign In
```

## 37. OpenCode Implementation Rule

When this requirement is supplied to OpenCode:

1.  Read the complete requirement first.
2.  Inspect the existing SPORTSGURUKUL structure.
3.  Implement only Authentication.
4.  Develop PostgreSQL, .NET API and Flutter in parallel.
5.  Create database schema through EF Core migration.
6.  Keep API contracts consistent with Flutter models.
7.  Do not hardcode secrets.
8.  Do not introduce unnecessary dependencies.
9.  Maintain separation between UI, domain, API and persistence.
10. Do not start another business feature until Authentication is
    complete.
