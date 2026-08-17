# FEATURE — ACADEMY ATHLETE MANAGEMENT

## OBJECTIVE

Implement ONLY the "Manage Athlete" functionality for an Academy.

The Academy already exists and is displayed in the existing Academy Grid/Card.

Each Academy card must provide:

[Manage Athlete]

The workflow must be:

Academy Grid
↓
Academy Card
↓
[Manage Athlete]
↓
Academy Athlete Management Page
├── View All Athletes
└── [Add Athlete]
↓
Add New Athlete
↓
Create Athlete
↓
Athlete appears in Athlete Grid/List

IMPORTANT:

Do NOT implement:

- Athlete Dashboard
- Coach-Athlete assignment
- Training Programs
- Training Sessions
- Attendance
- Assessments
- Progress Tracking
- Diet
- Training Videos
- Feedback
- Chat
- Booking
- Tournament
- Marketplace

This feature is ONLY for Academy Athlete creation, listing and removal.

---

# 1. MASTER REQUIREMENTS

Before implementation, read:

docs/SPORTS_GURUKUL_PRODUCT_MASTER_REQUIREMENTS.md

Also read:

docs/SPORTS_GURUKUL_ACADEMY_SETUP_REQUIREMENTS.md

Follow the existing project architecture and conventions.

Do NOT create a parallel architecture.

---

# 2. ACADEMY CARD

Locate the existing Academy Grid/Card.

Do NOT redesign the existing Academy card.

Add:

[Manage Athlete]

Use the same visual style as:

- Manage Academy
- Manage Coach
- Existing Academy actions

Example:

Pune Sports Excellence Academy

[Manage Academy] [Manage Coach] [Manage Athlete]

The selected Academy ID must be passed to the Athlete Management page.

DO NOT hardcode Academy ID.

The Academy must come from the selected Academy card.

---

# 3. ATHLETE MANAGEMENT PAGE

Clicking:

[Manage Athlete]

must open a dedicated Athlete Management page for that Academy.

Example:

< Back

Pune Sports Excellence Academy

Athlete Management

Manage athletes associated with this academy.

                                      [+ Add Athlete]

The page must contain:

- Academy context
- View All Athletes
- Add Athlete
- Athlete Grid/List

---

# 4. VIEW ALL ATHLETES

Load all Athletes associated with the selected Academy from the backend.

DO NOT use mock data.

DO NOT hardcode athletes.

Display appropriate real information.

Example:

┌────────────────────────────────┐
│ Athlete Photo │
│ │
│ Rahul Patil │
│ User ID: SG-ATH-000123 │
│ Cricket │
│ U16 │
│ PSEA Baner │
│ │
│ Status: Active │
│ │
│ [View] [Delete] │
└────────────────────────────────┘

Potential fields:

- Profile Photo
- Athlete Name
- User ID
- Email
- Mobile
- Primary Sport
- Age Group
- Branch
- Status
- Account Status

Only display fields supported by the actual backend.

---

# 5. EMPTY STATE

If the Academy has no Athletes:

No Athletes Added

No athletes have been added to this Academy yet.

[+ Add Athlete]

Use the existing application empty-state component/style.

Do not display fake records.

---

# 6. ADD ATHLETE

Clicking:

[+ Add Athlete]

must open a NEW dedicated Add Athlete page.

The Academy must already be known from the selected Academy context.

Do not ask the user to select an unrelated Academy again.

Example:

Add Athlete

Academy:
Pune Sports Excellence Academy

## Basic Information

First Name _
Last Name _
Email _
Mobile Number _
Date of Birth \*
Gender

## Sports

Primary Sport \*
Secondary Sport

## Academy Assignment

Branch \*
Status

## Additional Information

Address
Emergency Contact
Profile Photo

                    [Cancel] [Create Athlete]

The exact fields must follow the actual backend domain model.

---

# 7. USER ACCOUNT CREATION

A newly created Academy Athlete must receive a Sports Gurukul User account.

DO NOT create a separate authentication system.

The flow must be:

Academy Admin
↓
Add Athlete
↓
Create User Account
↓
Create Athlete Profile
↓
Assign ACADEMY_ATHLETE
↓
Associate Academy
↓
Associate Branch
↓
Associate Sports
↓
Generate Credentials
↓
Send Email

The Athlete must later use the existing Sports Gurukul Login.

---

# 8. USER ID GENERATION

The backend must automatically generate a unique User ID.

Example:

SG-ATH-000123

or another consistent format based on existing application conventions.

Requirements:

- Backend generates the User ID.
- User ID must be unique.
- Database must enforce uniqueness.
- Flutter must NOT be responsible for final uniqueness.
- If a generated User ID already exists, generate another unique ID.

Do NOT manually type User ID unless the existing architecture explicitly requires it.

---

# 9. RANDOM TEMPORARY PASSWORD

The backend must generate a secure random temporary password.

Requirements:

- Cryptographically secure random generation where supported.
- Sufficient complexity.
- Never hardcode the password.
- Never store plain-text password in PostgreSQL.
- Store only password hash.
- Temporary password exists only for the approved credential-delivery workflow.
- Never log the password.
- Do not return the password unnecessarily through the API.

The Athlete receives the temporary password through email.

---

# 10. ATHLETE ROLE

The newly created account MUST receive:

ACADEMY_ATHLETE

Do NOT assign:

- ACADEMY_COACH
- ACADEMY_ADMIN
- ADMIN
- Other unrelated roles

Use the existing role architecture.

If the role does not exist:

Add it properly to the role model/database.

Do NOT hardcode role strings throughout Flutter.

Backend authorization must recognize:

ACADEMY_ATHLETE

---

# 11. ACADEMY ASSOCIATION

The Athlete must be associated with the Academy from which:

[Manage Athlete]

was opened.

Example:

Pune Sports Excellence Academy
↓
Manage Athlete
↓
Add Athlete
↓
Rahul Patil
↓
ACADEMY_ATHLETE
↓
Pune Sports Excellence Academy

The Academy relationship must be persisted in PostgreSQL/backend.

Do NOT store the relationship only in Flutter.

Backend authorization must verify that the Academy Admin is authorized to add
the Athlete to that Academy.

---

# 12. BRANCH ASSOCIATION

Academy Setup already contains Branches.

DO NOT create a new Branch.

Load existing branches for the selected Academy.

Example:

PSEA Baner
PSEA Wakad

The Athlete should be associated with the appropriate Branch according to
the existing business model.

Do not invent multiple-branch behavior if the backend does not support it.

---

# 13. SPORTS ASSOCIATION

Academy Setup already contains Sports.

DO NOT create duplicate Sports.

Load existing Sports configured for the selected Academy.

Example:

- Cricket
- Football
- Tennis
- Badminton

The Athlete must be associated with valid Academy Sports.

Example:

Athlete:
Rahul Patil

Primary Sport:
Cricket

Secondary Sport:
Football

Do not allow a Sport that is not configured for the selected Academy.

---

# 14. ATHLETE PROFILE

Capture Athlete-specific information supported by the backend.

Potential information:

### Personal

- First Name
- Last Name
- Date of Birth
- Gender
- Profile Photo
- Email
- Mobile

### Sports

- Primary Sport
- Secondary Sport
- Skill Level
- Playing Position where applicable
- Age Group

### Academy

- Branch
- Joining Date
- Status

### Contact

- Address
- Emergency Contact

IMPORTANT:

Do not make sensitive or optional fields mandatory unless the existing
requirements/backend require them.

Do not invent additional business fields.

---

# 15. AGE GROUP

If the existing Academy/Sport model supports age groups, allow the Athlete
to be associated with an appropriate age group.

Example:

U10
U12
U14
U16
U18
Adult

The age group must be derived/validated appropriately from the Athlete's
date of birth where applicable.

Do not allow invalid age-group assignments.

---

# 16. DUPLICATE USER CHECK

Before creating the Athlete:

Check existing:

- User ID
- Email
- Mobile number

If email/mobile already belongs to a User:

DO NOT silently create another account.

Return a clear business error.

Example:

"This email is already registered with Sports Gurukul."

Do not implement User-to-Athlete conversion in this feature unless it already
exists in the backend.

---

# 17. FORM VALIDATION

Implement frontend AND backend validation.

Required fields should include at minimum:

- First Name
- Last Name
- Email or Mobile according to authentication rules
- Date of Birth where required
- Primary Sport
- Branch where required

Validate:

- Email format
- Mobile format
- Date of Birth
- Age
- Required fields
- Valid Sport
- Valid Branch
- Valid Academy

Backend validation remains authoritative.

---

# 18. TRANSACTIONAL CREATION

Athlete creation consists of:

1. Create User
2. Assign ACADEMY_ATHLETE role
3. Create Athlete Profile
4. Create Academy-Athlete association
5. Associate Branch
6. Associate Sport
7. Generate temporary credentials
8. Send email

Use the existing backend transaction pattern.

If a critical operation fails:

DO NOT leave partially created business data.

Example:

If Athlete Profile creation fails after User creation:

Handle rollback according to the existing transaction architecture.

Do not leave an orphaned User.

Email failure must also be handled according to the existing email
architecture.

Do not report:

"Athlete created and email sent"

unless the email operation was successfully initiated.

---

# 19. EMAIL TO ATHLETE

After successful account creation, send an email to the Athlete.

Subject:

Welcome to Sports Gurukul — Your Athlete Account

Email should contain:

- Welcome message
- Academy name
- User ID
- Temporary password
- Login URL
- Login instructions
- Password change instructions if required

Example:

Welcome to Sports Gurukul.

You have been added as an Athlete to:

Pune Sports Excellence Academy

Your login details:

User ID:
SG-ATH-000123

Temporary Password:
<generated temporary password>

Login:
<Application Login URL>

Please change your password after your first login.

IMPORTANT:

- Do not log the temporary password.
- Do not store the plain-text password.
- Do not expose the password through API responses.
- Use the existing email service.

If an email service does not exist, implement a reusable email service
according to the existing backend architecture.

Do NOT put SMTP logic inside the Athlete controller.

---

# 20. FIRST LOGIN

The Athlete Dashboard is NOT part of this feature.

However, the created account must authenticate through the existing
Sports Gurukul Login.

Expected future flow:

Athlete receives email
↓
Login
↓
User authenticated
↓
Role = ACADEMY_ATHLETE
↓
Future Athlete Dashboard

For this feature, only verify that authentication recognizes:

ACADEMY_ATHLETE

Do NOT build the Athlete Dashboard.

---

# 21. SUCCESS FLOW

After successful creation:

Show:

"Athlete added successfully."

Display safe information:

- Athlete Name
- Academy
- User ID
- Email
- Account status

Do NOT show the temporary password in the UI.

Preferred message:

"Login credentials have been sent to the registered email address."

Then:

[View Athletes]

Return to Athlete Management page and refresh the list.

The newly created Athlete must immediately appear.

---

# 22. FAILURE FLOW

If creation fails:

- Do not show success.
- Display a meaningful error.
- Preserve form data where safe.
- Allow retry.
- Prevent duplicate submission.
- Do not expose stack traces.

Handle:

- Duplicate email
- Duplicate mobile
- Database failure
- Invalid Academy
- Invalid Branch
- Invalid Sport
- Invalid age group
- Unauthorized Academy Admin
- Email service failure
- Validation errors

---

# 23. DELETE / REMOVE ATHLETE

Each Athlete card should provide:

[Delete]

Before removal:

Delete Athlete?

Are you sure you want to remove Rahul Patil
from this Academy?

[Cancel] [Delete]

IMPORTANT:

Removing an Athlete from an Academy should NOT automatically delete the
underlying Sports Gurukul User account unless explicitly required by the
existing business rules.

Prefer:

Academy
↓
Athlete Association
↓
Remove/Deactivate Athlete

rather than destroying the User identity.

Historical records must be preserved where required.

Use the backend's business rules to determine whether the operation is:

- Remove from Academy
- Deactivate Athlete
- Delete Athlete Profile

Do not physically delete records blindly.

---

# 24. DELETE AUTHORIZATION

Only an authorized Academy Owner/Admin can remove an Athlete from that
Academy.

Backend MUST verify:

- Current authenticated user
- Academy authorization
- Athlete belongs to selected Academy

Do not rely only on Flutter visibility.

---

# 25. AFTER ADD ATHLETE

After successful creation:

1. Show success message.
2. Navigate back to Athlete Management.
3. Refresh Athlete list.
4. Show newly created Athlete.

No application restart should be required.

---

# 26. AFTER DELETE

After successful removal:

Show:

"Athlete removed successfully."

Refresh the Athlete list.

The removed Athlete must no longer appear in the selected Academy's list.

Do not remove the Athlete from unrelated Academy associations if the domain
supports multiple Academy memberships.

---

# 27. ACADEMY DASHBOARD / CARD

Do NOT redesign the existing Academy card.

Only add:

[Manage Athlete]

Use the same style and placement approach already used for:

[Manage Coach]

The existing Academy Register/Setup functionality must continue to work.

---

# 28. NAVIGATION

Required flow:

Academy Grid
↓
Academy Card
↓
Manage Athlete
↓
Athlete Management
├── View All Athletes
└── Add Athlete
↓
Add Athlete Form
↓
Create
↓
Athlete List

Back navigation must return correctly to the Academy Grid.

---

# 29. API REQUIREMENT

Before creating APIs:

Inspect:

- Existing Swagger
- Academy APIs
- User APIs
- Role APIs
- Coach implementation
- Authentication APIs
- Email service
- Existing Athlete APIs if any

REUSE existing APIs where appropriate.

If required APIs do not exist, build them following existing architecture.

Required capabilities:

- Get Academy Athletes
- Create Academy Athlete
- Remove Academy Athlete

Plus supporting capabilities for:

- User creation
- Role assignment
- Branch selection
- Sport selection
- Email/invitation

Do not create duplicate APIs.

Update Swagger/OpenAPI.

---

# 30. DATABASE REQUIREMENT

Inspect existing PostgreSQL entities/tables:

- Users
- Roles
- UserRoles
- Academies
- Branches
- Sports
- Coach/Athlete profiles
- Academy memberships/associations

Reuse existing domain structures where possible.

If Athlete Profile or Academy-Athlete association does not exist:

Create the minimum required model.

Use:

- Foreign keys
- Unique constraints
- Indexes
- Audit fields
- Proper relationships
- Transactions

Do not create duplicate Academy, Branch or Sport records.

---

# 31. API RESPONSE

Never return the plain-text password.

Safe response can contain:

- Athlete ID
- User ID
- Athlete name
- Email
- Academy
- Branch
- Sport
- Role
- Status
- Invitation/email status

Temporary password must not be returned in normal API response.

---

# 32. UI / UX

Follow the existing Sports Gurukul UI theme.

The Athlete Management page must look consistent with:

- Academy Grid
- Academy Card
- Coach Management
- Add Coach
- Authentication

Reuse:

- Existing theme
- Existing components
- Existing buttons
- Existing typography
- Existing spacing
- Existing dialogs
- Existing snackbar/toast
- Existing loading states

Do NOT introduce another design system.

---

# 33. RESPONSIVE DESIGN

Verify:

- Desktop
- Tablet
- Mobile

Desktop:

Academy Name [+ Add Athlete]

┌──────────┐ ┌──────────┐ ┌──────────┐
│ Athlete1 │ │ Athlete2 │ │ Athlete3 │
└──────────┘ └──────────┘ └──────────┘

Mobile:

Academy Name

[+ Add Athlete]

┌──────────────────┐
│ Athlete 1 │
└──────────────────┘

┌──────────────────┐
│ Athlete 2 │
└──────────────────┘

Use responsive layout rather than forcing desktop UI onto mobile.

---

# 34. LOADING STATE

Implement loading states for:

- Athlete page loading
- Athlete list loading
- Add Athlete submission
- Delete operation
- API refresh

Prevent multiple submissions.

---

# 35. SECURITY

Verify:

- Only authorized Academy Admin/Owner can manage Athletes.
- User cannot add Athlete to another Academy by changing Academy ID.
- User cannot delete Athlete from another Academy.
- User cannot assign unrelated Academy Sports.
- User cannot assign unrelated Academy Branches.
- Password is securely hashed.
- Temporary password is not logged.
- Tokens are not logged.
- Sensitive information is protected.

Backend authorization is authoritative.

---

# 36. TESTING

Backend tests:

## Create Athlete

- Valid request
- User creation
- Athlete profile creation
- Academy association
- Role = ACADEMY_ATHLETE
- Branch association
- Sport association

## Duplicate

- Duplicate email rejected
- Duplicate mobile rejected
- Duplicate User ID handled

## Security

- Unauthorized user rejected
- Wrong Academy rejected
- Cross-Academy access rejected

## Password

- Random password generated
- Password hashed
- Plain password not persisted
- Password not logged
- Password not returned in API response

## Email

- Email triggered
- Correct User ID included
- Academy name included
- Login information included

## Transaction

- Partial creation does not leave invalid business state

---

# 37. FLUTTER TESTING

Verify:

- Academy Card displays Manage Athlete
- Correct Academy ID passed
- Athlete Management opens
- All Athletes load
- Add Athlete opens
- Form validation works
- Submit loading works
- Success works
- Error works
- Delete confirmation works
- Delete works
- Back navigation works
- Responsive UI works

---

# 38. END-TO-END VERIFICATION

Perform this exact workflow:

1. Login as Academy Owner/Admin.
2. Open Academy Grid.
3. Locate an existing Academy.
4. Click Manage Athlete.
5. Verify correct Academy context.
6. Verify existing Athletes.
7. Click Add Athlete.
8. Enter valid Athlete information.
9. Select existing Academy Branch.
10. Select existing Academy Sport.
11. Submit.
12. Verify User is created.
13. Verify unique User ID.
14. Verify random temporary password generation.
15. Verify password is hashed in PostgreSQL.
16. Verify role = ACADEMY_ATHLETE.
17. Verify Athlete Profile.
18. Verify Academy association.
19. Verify Branch association.
20. Verify Sport association.
21. Verify credential email is triggered.
22. Verify Athlete appears in the grid.
23. Verify Athlete can authenticate using normal Sports Gurukul Login.
24. Verify authenticated role = ACADEMY_ATHLETE.
25. Delete/remove the Athlete from the Academy.
26. Verify Athlete disappears from Academy list.
27. Verify the User account is not accidentally destroyed unless explicitly
    required by business rules.

DO NOT implement or test Athlete Dashboard UI in this feature.

---

# 39. ACCEPTANCE CRITERIA

The feature is complete only when:

- [ ] Academy Card contains Manage Athlete.
- [ ] Manage Athlete opens the correct Academy.
- [ ] Athlete Management page exists.
- [ ] All Academy Athletes are displayed.
- [ ] Add Athlete is visible at the top.
- [ ] Add Athlete opens a dedicated page.
- [ ] Athlete User account is created.
- [ ] Unique User ID is generated by backend.
- [ ] Secure random temporary password is generated.
- [ ] Password is securely hashed.
- [ ] Role = ACADEMY_ATHLETE.
- [ ] Athlete Profile is created.
- [ ] Athlete is associated with correct Academy.
- [ ] Existing Academy Branch is reused.
- [ ] Existing Academy Sport is reused.
- [ ] Duplicate users are prevented.
- [ ] Credentials/invitation email is triggered.
- [ ] Plain-text password is never persisted.
- [ ] Plain-text password is never logged.
- [ ] Newly created Athlete appears immediately in the grid.
- [ ] Delete/Remove Athlete works with confirmation.
- [ ] Removing Athlete does not blindly delete the User account.
- [ ] Empty state works.
- [ ] Loading state works.
- [ ] Error handling works.
- [ ] Backend authorization works.
- [ ] Responsive UI works.
- [ ] Existing Academy and Coach functionality is not broken.
- [ ] Backend tests pass.
- [ ] Flutter tests pass.
- [ ] flutter analyze passes.
- [ ] End-to-end verification passes.

---

# 40. DO NOT IMPLEMENT

This feature must STOP after Academy Athlete Management is complete.

Do NOT implement:

- Athlete Dashboard
- Coach-Athlete relationship
- Training Programs
- Training Plans
- Batches
- Sessions
- Attendance
- Assessments
- Progress
- Diet Plans
- Training Videos
- Feedback
- Chat
- Booking
- Tournament
- Marketplace
- Independent Athlete functionality

These will be implemented as separate features.

---

# 41. FINAL REPORT

After implementation provide:

## Backend Changes

- APIs reused
- APIs created
- Database changes
- Athlete entity/profile
- Academy-Athlete relationship
- Role changes
- Authorization
- Email implementation

## Frontend Changes

- Academy Card changes
- Athlete Management page
- Athlete Grid/List
- Add Athlete page
- Delete/Remove functionality
- Navigation
- API integration
- Validation

## Account Creation

Confirm:

User ID generated:
YES/NO

Random password generated:
YES/NO

Password hashed:
YES/NO

Role:
ACADEMY_ATHLETE

Email sent:
YES/NO

Academy association:
YES/NO

Branch association:
YES/NO

Sport association:
YES/NO

## Verification

Report:

- Backend build
- Backend tests
- Flutter analyze
- Flutter tests
- Add Athlete E2E
- Delete Athlete E2E
- Authorization verification
- Email verification
- Authentication verification

## Known Issues

List only genuine remaining issues.

---

# 42. STOP CONDITION

After completing and verifying this feature:

STOP.

Do not start Athlete Dashboard or any other business feature.

Wait for the next feature instruction.
