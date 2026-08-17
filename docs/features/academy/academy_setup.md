# Sports Gurukul — Academy Setup Requirements

## Purpose

Academy Setup is the initial configuration workflow completed after an Academy is created.

It establishes the foundational information and resources that the Academy will use later in Academy operations.

Academy Setup is separate from Coach Management, Athlete Management, Training, Attendance, Assessments, Booking, and Tournament Management.

## Academy Setup Scope

```text
Create Academy
      |
      +-- Academy Details
      +-- Branch Details
      +-- Sports
      +-- Facilities
      +-- Memberships
      +-- Working Hours
```

## 1. Academy Details

Capture the basic information required to identify and operate the Academy.

Expected information includes:

- Academy Name
- Academy Profile / Description
- Contact Information
- Location / Address
- Academy Logo / Profile Image where supported
- Public / Private

Note : If Public then only during Join Academy feature development user will be able to view / search this Academy.

The exact fields must follow the backend/API contract when the feature is implemented.

## 2. Branch Details

Configure the branches belonging to the Academy.

Example:

```text
Academy
 |
 +-- Main Branch
 +-- Branch 2
 +-- Branch 3
```

Branch information is part of Academy Setup.

Do not recreate the initial Branch Setup as a separate onboarding workflow.

Later, Academy Admin may have Branch Management for ongoing operational changes.

## 3. Sports

Configure the sports offered by the Academy.

Example:

```text
Academy Sports
 |
 +-- Cricket
 +-- Football
 +-- Tennis
 +-- Badminton
```

Academy Sports will later be relevant to:

- Coach Management
- Athlete Management
- Training Programs
- Training Batches
- Training Sessions
- Performance

Do not create duplicate Sport definitions when building later features.

Reuse the Academy Sport domain established during setup.

## 4. Facilities

Configure the facilities/resources available at the Academy.

Example:

```text
Facilities
 |
 +-- Cricket Ground
 +-- Indoor Nets
 +-- Gym
 +-- Tennis Court
 +-- Training Room
```

Facilities may later be used by:

- Training Sessions
- Bookings
- Calendar
- Academy Operations

Do not recreate Facility Setup in later modules.

Later management screens may allow the Academy Admin to modify existing facilities.

## 5. Memberships

Configure the membership offerings/plans provided by the Academy.

Example:

```text
Memberships
 |
 +-- Monthly
 +-- Quarterly
 +-- Annual
 +-- Sport-specific Plans
```

The exact membership fields and business rules must be based on the backend/API contract.

Do not invent additional membership behavior during implementation.

Membership Management later refers to the ongoing management of the membership configuration created during setup.

## 6. Working Hours

Configure the Academy's operating hours.

Example:

```text
Monday       06:00 - 21:00
Tuesday      06:00 - 21:00
Wednesday    06:00 - 21:00
Thursday     06:00 - 21:00
Friday       06:00 - 21:00
Saturday     06:00 - 21:00
Sunday       07:00 - 18:00
```

The exact schedule depends on the Academy configuration.

Working hours can later be used when implementing:

- Training Sessions
- Coach Availability
- Bookings
- Facility Scheduling

## What Academy Setup Does NOT Include

The following are Academy Operations features and are NOT part of the initial Academy Setup:

- Coach Management
- Athlete Management
- Training Programs
- Training Batches
- Coach Assignment
- Athlete Enrollment
- Training Sessions
- Attendance
- Assessments
- Performance
- Progress
- Booking Management
- Tournament Management

These should be implemented later as separate features.

## Academy Lifecycle

```text
Register Academy
       |
       v
Academy Setup
       |
       +-- Academy Details
       +-- Branches
       +-- Sports
       +-- Facilities
       +-- Memberships
       +-- Working Hours
       |
       v
Academy Dashboard
       |
       v
Academy Operations
       |
       +-- Coach Management
       +-- Athlete Management
       +-- Training Programs
       +-- Training Batches
       +-- Training Sessions
       +-- Attendance
       +-- Assessments
       +-- Progress
       +-- Booking
       +-- Tournament
```

## Important Implementation Rules

1. Academy Setup should be completed before Academy operational features are configured.
2. Branches, Sports, Facilities, Memberships, and Working Hours should not be duplicated in later feature implementations.
3. Later features must reuse the existing Academy Setup domain entities and relationships.
4. If a required backend API does not exist, develop the API as part of the feature instead of using fake data.
5. Swagger/OpenAPI must accurately represent the implemented APIs.
6. Do not hardcode Academy, Branch, Sport, Facility, or Membership data.
7. The authenticated Academy Admin must operate against the correct Academy context.
8. Backend authorization is authoritative.
9. Academy Setup is foundational configuration; Academy Operations are implemented separately.

# AFTER Setup

- Newly created Academy should display under Register Academy Section in user home page.
- User can edit / delete the Academy
- User can create as many as Academy's using Register Academy option
- Academy is going to register under created user.
- User add update delete academy

```

```
