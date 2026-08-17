Academy Coach creation

# 1. USER ID GENERATION

The system must automatically create a User ID for newly created 'Academy Coach' based on the information received.
Generate a unique User ID according to a consistent application rule.
Assign Role as 'Academy Coach' for newly created coach from Academy.

IMPORTANT:

- User ID must be unique.
- Backend must enforce uniqueness.
- Do not generate the User ID only on Flutter.
- The backend must be authoritative.

If the generated User ID already exists, generate another unique identifier.

---

# 2. RANDOM PASSWORD

The backend must generate a secure random temporary password.

Requirements:

- Cryptographically secure random generation where supported.
- Sufficient complexity.
- Never hardcode a password.
- Never store the plain-text password in the database.
- Store only the secure password hash.
- Plain-text temporary password may exist only long enough to deliver it through
  the approved email workflow.
- Do not log the password.
- Do not return the password unnecessarily through the API response.

The Coach should receive the temporary password by email.

---

# 3. COACH ROLE

The newly created account MUST receive:

ACADEMY_COACH AS Role

Do NOT assign Any Other Role:

as the primary Coach role for this workflow.

Use the application's existing role architecture.

If the system currently has only USER, extend the role system correctly.

Do not create hardcoded role checks scattered across the Flutter code.

Backend authorization must recognize:

ACADEMY_COACH

---

# 4. ACADEMY ASSOCIATION

The newly created Coach must be associated with the Academy from which
the Add Coach action was initiated.

Example:

Pune Sports Excellence Academy
↓
Add Coach
↓
Rahul Sharma
↓
ACADEMY_COACH
↓
Pune Sports Excellence Academy

The association must be persisted in the backend.

Do not store the Academy relationship only in Flutter.

The backend must enforce that the authenticated Academy owner/admin is
authorized to add a Coach to that Academy.

---

# 5. BRANCH ASSOCIATION

Academy Setup already contains Branch information.

Do NOT create a new Branch during Coach creation.

Load existing branches for the selected Academy.

Example:

Academy:
Pune Sports Excellence Academy

Branches:

- PSEA Baner
- PSEA Wakad

The Coach can be assigned to the appropriate Branch according to the
existing business rules.

If multiple Branch assignment is supported by the current domain model,
follow it.

Do not invent multiple-branch behavior if the backend does not support it.

---

# 6. SPORTS ASSOCIATION

Academy Setup already contains Sports.

Do NOT create duplicate Sports.

Load the existing Sports configured for the selected Academy.

Example:

Academy Sports:

- Cricket
- Football
- Tennis
- Badminton

Coach can be associated with one or more supported sports according to the
existing business rules.

Example:

Coach:
Rahul Sharma

Sport:
Cricket

Specialization:
Batting / Fielding

Do not allow invalid/unrelated sports to be assigned to the Academy Coach.

---

# 7. DUPLICATE USER CHECK

Before creating a new User:

Check for existing:

- User ID
- Email
- Mobile number

If the email/mobile already belongs to an existing User:

Do NOT silently create a duplicate account.

The backend must return a clear business response.

Example:

"This email is already registered with Sports Gurukul."

If the product later supports converting an existing User into a Coach,
that will be a separate feature.

DO NOT implement that conversion in this task unless it is already
supported by the existing backend.

---

# 8. FORM VALIDATION

Implement client-side validation.

Required fields:

- First Name
- Last Name
- Email
- Mobile Number
- Primary Sport
- Academy Branch where required

Validate:

- Email format
- Mobile format
- Minimum/maximum lengths
- Required fields
- Valid Sport
- Valid Branch

Backend validation is mandatory as well.

Do not rely only on Flutter validation.

---

# 9. TRANSACTIONAL CREATION

Coach creation consists of multiple operations:

1. Create User
2. Assign ACADEMY_COACH role
3. Create Coach Profile
4. Create Academy-Coach association
5. Associate Branch
6. Associate Sport
7. Generate temporary credentials
8. Send email

The backend must ensure that the business data does not remain partially
created if a critical operation fails.

Use the existing transaction pattern.

For example:

If Coach Profile creation fails after User creation:

Do not leave an orphaned User unless the existing architecture explicitly
supports that lifecycle.

Handle rollback/transaction appropriately.

Email failure should be handled according to the application's email
architecture and business rules.

Do not falsely report "Coach created and email sent" if email delivery was
not successfully initiated.

---

# 10. EMAIL TO COACH

After successful account creation, send an email to the Coach.

The email should contain:

Subject:

Welcome to Sports Gurukul — Your Coach Account

Content should include:

- Welcome message
- Academy name
- User ID
- Temporary password
- Login URL
- Instructions to log in
- Password change instructions if required

Example:

Welcome to Sports Gurukul.

You have been added as a Coach to:

Pune Sports Excellence Academy

Your login details:

User ID:
SG-COACH-000123

Temporary Password:

---

Login:
[Application Login URL]

Please change your password after your first login.

IMPORTANT:

Do not expose the temporary password in application logs.

Do not store the email content with the plain-text password in logs.

Use the existing email service if one already exists.

If an email service does not exist:

Implement the minimum reusable email service required by the project's
backend architecture.

Do not create a hardcoded SMTP implementation inside the Coach controller.

---

# 11. FIRST LOGIN

The Coach Dashboard is NOT part of this feature.

However, the account created by this feature must be capable of authenticating
through the existing Login workflow.

The expected future flow is:

Coach receives email
↓
Login
↓
User authenticated
↓
Role = ACADEMY_COACH
↓
Future Coach Dashboard

For this feature, only verify that the authentication system correctly
recognizes the newly created account and role.

Do NOT build the Coach Dashboard now.

---

# 12. SUCCESS FLOW

After successful creation:

Show:

"Coach added successfully."

Also indicate:

- Coach name
- Academy
- User ID
- Email
- Account/invitation status

Do NOT show the temporary password in the UI after creation unless the
existing security design explicitly requires it.

Preferred:

"Login credentials have been sent to the registered email address."

Then:

[View Coaches]

or return to the Coach List according to the application's navigation pattern.

---

# 13. FAILURE FLOW

If creation fails:

- Do not show success.
- Display a meaningful error.
- Preserve form data where safe.
- Allow retry.
- Do not create duplicate accounts on retry.
- Do not expose stack traces.

Handle:

- Duplicate email
- Duplicate mobile
- Database failure
- Invalid Academy
- Invalid Branch
- Invalid Sport
- Unauthorized Academy Admin
- Email service failure
- Validation errors

---

# 14. AUTHORIZATION

Only the authorized Academy owner/admin should be able to click Add Coach
and successfully create a Coach.

Frontend:

- Show Add Coach only where appropriate.

Backend:

- MUST enforce authorization.

The API must verify:

Authenticated User
↓
Has Academy Owner permission
↓
Owns/manages selected Academy
↓
Can create ACADEMY_COACH
