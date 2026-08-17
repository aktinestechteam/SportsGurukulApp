# Coach ↔ Athlete Mapping

Update the existing **Academy Coach Addition and Edit workflow** and the **Academy Athlete Addition and Edit workflow** to support Coach ↔ Athlete mapping.

## Requirements

### Coach → Athlete

While **adding or editing a Coach**:

- Show all available Athletes belonging to the selected Academy.
- Allow the Academy Admin to select/map one or multiple Athletes to the Coach.
- An Athlete can be mapped to multiple Coaches.
- The same Athlete must NOT be duplicated for the same Coach.
- If the Academy currently has no Athletes, show a proper empty state and allow the Coach to be created without mapping.
- During Edit Coach, show currently mapped Athletes and allow Add/Remove mappings.
- Do not create duplicate mapping records.

### Athlete → Coach

While **adding or editing an Athlete**:

- Show all available Coaches belonging to the selected Academy.
- Allow the Academy Admin to select/map one or multiple Coaches.
- A Coach can be mapped to multiple Athletes.
- The same Coach must NOT be duplicated for the same Athlete.
- If no Coaches are available, show a proper empty state and allow the Athlete to be created without mapping.
- During Edit Athlete, show currently mapped Coaches and allow Add/Remove mappings.
- Both sides must remain synchronized.

## Backend

Implement/extend the Coach-Athlete relationship using a proper many-to-many association:

```text
Coach ─────< CoachAthlete >───── Athlete
```
