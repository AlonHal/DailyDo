# DailyDo — Development Plan

Status: planning only — no code written yet. This is the working plan for building DailyDo and for shaping it into a reusable baseline for future apps. Update the checkboxes as phases complete.

## 1. Product Summary

DailyDo is a daily multiple-choice practice app. The user is shown a question (text or image prompt) with several answer options (each also text or image) and must pick the correct one(s). Intended daily uses include practicing vocabulary in a foreign language, testing geography knowledge, and similar recall drills. The habit — doing a short practice session every day — is the point of the app, not any single content domain.

The core non-negotiable requirement: the content database is fully configurable and stays entirely under the user's control — local-only, easily inspected, exported, and edited, with no server dependency.

## 2. Feature Scope (v1)

**Must-have**
- Create/manage "Question Sets" (decks/topics, e.g. "Spanish Vocabulary", "World Capitals")
- Each question: a prompt (text or image) plus multiple answer options (each text or image)
- Support both single-correct and multiple-correct question modes
- Daily practice session: pull N questions, present multiple-choice UI, give immediate feedback, show a score at the end
- Full content management inside the app — add/edit/delete sets, questions, answers — no external tool required
- Local SQLite database, entirely on-device, user has full access
- Import/export of question sets, for backup, bulk authoring, and sharing between the user's own devices
- Basic history: score per session, accuracy per set

**Nice-to-have (later phases, not blocking v1)**
- Daily reminder notification
- Streaks / spaced-repetition scheduling
- Sessions that mix multiple question sets
- Search/filter in the content manager
- Dark mode / theming
- Stats dashboard (accuracy trends over time, per set/category)

**Explicitly out of scope for v1**
- Cloud sync, accounts, multi-device sharing (local-only by design)
- iOS build (Android first; the stack supports iOS later, see setup summary §18)
- Any social/sharing features between different users

## 3. Architecture

Layered, matching the earlier environment-setup summary's recommended structure, adapted for DailyDo and organized so `core/` can be lifted out into a reusable package once a second app exists.

```
lib/
├── main.dart
├── app/                      # App shell: routing, theme, DI wiring
├── core/                     # Written to be REUSABLE ACROSS FUTURE APPS
│   ├── database/              # Drift setup helpers, base DAO patterns
│   ├── import_export/         # Generic JSON/zip import-export framework
│   ├── media/                 # Local file storage helpers for images
│   ├── notifications/         # Local notification scheduling helper
│   ├── settings/               # Key-value app settings storage
│   └── widgets/                # Shared UI components, theme tokens
├── features/
│   ├── practice/               # Daily quiz session: question UI, scoring
│   ├── content_manager/        # CRUD for sets / questions / answers
│   ├── stats/                  # History & progress views
│   └── settings/                # Settings screen
└── data/
    ├── database/                # Drift tables & generated code (app-specific schema)
    └── repositories/            # Repository layer between UI and DB
```

Rule of thumb: nothing needs to physically live under `core/` for v1 — the folder boundary just marks the seam where a second app would later pull code out into a shared package (see §8). Don't build the package before there's a second consumer.

## 4. Data Model (draft — confirm §9 before starting Phase 2)

**Tables**
- `QuestionSets(id, name, description, category, colorOrIcon, source[built_in|user|imported], createdAt, updatedAt)`
- `Questions(id, setId → QuestionSets, promptType[text|image], promptText, promptImagePath, answerMode[single|multiple], notes, createdAt)`
- `AnswerOptions(id, questionId → Questions, contentType[text|image], contentText, contentImagePath, isCorrect, sortOrder)`
- `PracticeSessions(id, date, setIds, totalQuestions, correctCount, startedAt, completedAt)`
- `Attempts(id, sessionId → PracticeSessions, questionId → Questions, selectedOptionIds, isCorrect, answeredAt)`
- `Settings(key, value)` — daily reminder time, daily question count target, theme, etc.

**Media**
User-picked images are copied into the app's own documents directory (`images/{uuid}.ext`); the DB stores only the relative path, never an absolute one — this keeps export/import portable across devices.

## 5. Import / Export — the "user owns the database" requirement

Two portability layers, both should exist by the end of v1:

1. **Raw DB access.** The SQLite file is a normal file in app storage. Document how to pull it (`adb pull`) and open it with `sqlitebrowser` or the `sqlite3` CLI (already covered in the environment setup summary) for anyone who wants to inspect or hand-edit it directly.
2. **Structured export/import.** An "Export Set" / "Import Set" feature using a documented JSON schema (bundled into a zip with images for sets that use pictures). This lets the user author question sets in a text editor outside the app, and move sets between their own devices without any backend.

Build (2) as a generic module in `core/import_export/` from the start — it's also the piece that makes this app an actual baseline, since any future app storing user content will want the same shape.

## 6. Phased Build Plan

**Phase 0 — Environment ready** *(from the earlier setup summary)*
- [ ] Flutter SDK, Android Studio/SDK, VS Code extensions installed; `flutter doctor -v` clean
- [ ] KVM vs. physical-device testing path decided
- [ ] `git init` in this folder, Flutter `.gitignore`, first commit

**Phase 1 — Scaffold**
- [ ] `flutter create`, folder structure from §3, base theme, empty home screen
- [ ] Drift + sqlite3 wired up, empty schema compiles, `build_runner` working

**Phase 2 — Data layer**
- [ ] Tables from §4 implemented as a Drift schema + first migration
- [ ] Repository layer over the DAOs (no UI yet); unit tests for repository logic

**Phase 3 — Content manager (CRUD)**
- [ ] Create/edit/delete Question Sets
- [ ] Create/edit/delete Questions + Answer Options (text and image)
- [ ] Image picker that copies the file into app storage and stores the relative path

**Phase 4 — Import / export**
- [ ] JSON schema defined and documented
- [ ] Export a set → file / share sheet
- [ ] Import a set → validation + merge-or-replace handling

**Phase 5 — Daily practice session (the core loop)**
- [ ] Session generator (pick N questions from the chosen set(s))
- [ ] Quiz UI: single-choice (radio) and multi-choice (checkbox), text and image prompts/options
- [ ] Immediate feedback + end-of-session score screen
- [ ] Persist `PracticeSessions` + `Attempts`

**Phase 6 — Progress & history**
- [ ] Per-set accuracy, session history list
- [ ] Streaks (optional)

**Phase 7 — Reminders**
- [ ] Local daily notification, configurable time, opt-in

**Phase 8 — Polish & release prep**
- [ ] `flutter analyze` / `dart format` / `flutter test` clean, coverage baseline
- [ ] App icon, app name, Play Store packaging basics
- [ ] Manual test pass on a physical device or emulator

**Phase 9 — Extract the baseline** *(deferred until app #2 actually starts)*
- [ ] Move `core/` into a standalone local package (path dependency first)
- [ ] Re-point DailyDo at the package, verify nothing broke
- [ ] Use the package as the starting point for the next app

## 7. Testing Strategy

- **Unit tests**: repository layer, session-generation logic, import/export parsing — pure Dart, fast, and where regressions matter most.
- **Widget tests**: quiz screen renders both question modes correctly; content-manager forms validate input.
- **Manual/device tests**: image picking, notifications, and anything touching platform channels — these aren't meaningfully unit-testable.
- **CI**: not needed until the repo is pushed somewhere remote. Until then, run the validation script from the setup summary locally before each commit:
  ```bash
  dart format --output=none --set-exit-if-changed .
  flutter analyze
  flutter test
  ```

## 8. Making This a Real Baseline

Two things earn the "baseline for future apps" label — not just naming a folder `core/`:

1. Keep the import/export module and local-DB patterns generic (no DailyDo-specific fields leaking into `core/`) so lifting them into a package later is a copy, not a rewrite.
2. Don't extract anything into a shared package until app #2 actually needs it (Phase 9). Building it speculatively now, with only one consumer, risks guessing the wrong abstraction.

## 9. Decisions Needed

These affect the schema and UI directly — confirm before Phase 2 starts:

- [ ] Fixed `answerMode` per question (single vs. multiple correct), or can it vary within a set? (recommended: fixed per question — simpler UI)
- [ ] Can one practice session mix multiple question sets, or is it always one set at a time?
- [ ] Is spaced repetition in scope for v1, or is plain random daily sampling enough to start?
- [ ] Are reminder notifications wanted for v1, or fine to defer to Phase 7 as currently planned?
- [ ] Where do images come from — camera/gallery only, or should the app also ship with bundled sample content?

## 10. Git & Repo Conventions

Carried over from the environment setup summary, applied to this repo specifically:

- Commit `pubspec.lock`; ignore `build/`, `.dart_tool/`, and IDE caches
- No signing keys, secrets, or noisy generated Drift `.g.dart` diffs in review focus
- Snapshot the VM before Flutter/Android SDK upgrades; commit before touching tooling versions
- Suggested branch model: trunk-based (`main` + short-lived feature branches) — fine for a solo project, revisit only if collaborators join

---

**Next step**: confirm/adjust §9, then Phase 0 (environment verification) and Phase 1 (scaffold) can start.
