# GymOS - Architecture Reference Guide

## 1. Backend (.NET 10 Clean Architecture)
The backend strictly follows Clean Architecture and Vertical Slice patterns. The dependency rule points inwards.

- **GymOS.Api (Presentation):**
  - *Role:* Entry point. Maps HTTP requests to MediatR commands/queries.
  - *Rule:* **ZERO business logic.** No DbContext, no complex if-conditions.
  - *Structure:* `/Endpoints`, `Program.cs`, `appsettings.json`.

- **GymOS.Application (Business Logic):**
  - *Role:* The core engine. Contains all MediatR Handlers, DTOs, and Interfaces.
  - *Rule:* Grouped by Feature (Vertical Slices), not by technical layers. Use explicit `[property: JsonPropertyName("...")]` on DTOs when exact JSON contract stability is critical (e.g., `photoUrl`, `gender`).
  - *Structure:* `/Features/{FeatureName}/Commands`, `/Features/{FeatureName}/Queries`, `/DTOs`, `/Interfaces`.

- **GymOS.Domain (Enterprise Logic):**
  - *Role:* Defines the core entities and enums (e.g., `Gender`: `Unspecified = 0`, `Male = 1`, `Female = 2`).
  - *Rule:* Independent of all other layers. No external dependencies (No EF Core, No ASP.NET).
  - *Structure:* `/Entities`, `/Enums`, `/Common`.

- **GymOS.Infrastructure (Data & External Services):**
  - *Role:* Communicates with the database, file storage, and background workers.
  - *Rule:* Implements interfaces defined in the Application layer.
  - *Structure:* `/Data` (`GymDbContext`), `/Migrations`, `/Services` (Cache, Tenant, AutoCheckOut), `/BackgroundJobs` (e.g., `PeriodicTimer`-based hosted services).

- **Backend Operational Rules:**
  - **Multi-Tenancy:** Every tenant-scoped entity must include `TenantId` and be isolated via Global Query Filters in `GymDbContext`. Background jobs processing all tenants must explicitly use `IgnoreQueryFilters()`.
  - **File Storage & Cleanup:** Uploaded media (e.g., member photos) is stored on a persistent volume. When replacing or deleting a photo, always save/update the DB first, then safely delete the old file strictly within the configured uploads root (guard against path traversal; wrap in `try/catch` with warning logs).
  - **Idempotency:** Sync and background operations (such as auto check-out after 180 minutes) must be idempotent and safe against concurrent runs.

---

## 2. Frontend (Flutter Feature-First)
The mobile app follows a Feature-First architecture using Riverpod for State Management, GoRouter for navigation, and Drift for Offline-First persistence.

- **lib/core/:**
  - *Role:* Shared foundational elements.
  - *Rule:* Must NEVER import anything from `/features`.
  - *Structure:* `/network` (Dio, SyncEngine), `/database` (Drift tables, DAOs, migrations), `/theme` (AppTheme, Spacing, Colors), `/widgets` (Reusable Gym-prefixed widgets), `/providers` (Global states like Theme, Locale, Sync).

- **lib/features/:**
  - *Role:* Vertical slices of app functionality.
  - *Rule:* Each feature is independent. State is managed via Riverpod providers/notifiers. No UI logic inside providers.
  - *Structure:* `/auth`, `/home`, `/members`, `/settings`.
  - *Sub-structure per feature:* `/models`, `/providers`, `/services` (API calls), `/ui`.

- **lib/routes/:**
  - *Role:* Centralized GoRouter configuration.

---

## 3. Theme, Colors & Visual System Rules
1. **Zero Hardcoded Colors:** Never hardcode hex colors or Material colors (e.g., `Colors.blue`) in widgets. Always read from `context.gymColors` and `AppSpacing` / radius tokens.
2. **Dynamic Tenant/User Accent:** The accent color is chosen dynamically in Settings and exposed via the theme provider. Never hardcode a fixed accent color.
3. **WCAG 4.5:1 Text Contrast (`accentText`):** Use the computed `accentText` token (cached per `(accent, brightness)`) for all accent-colored **text** on light/dark surfaces. Keep the raw accent color for fills, borders, chart bars, and the bottom dock pill.
4. **Light Mode Surfaces & Cards:**
   - Page background uses `backgroundLight` (a very light neutral tinted slightly toward the accent hue).
   - **ALL Light Mode cards** across every screen must use **opaque pure white `colors.surfaceLevel1` (`#FFFFFF`)** with `surfaceTintColor: Colors.transparent`, a subtle 1px `surfaceBorder`, and soft elevation. Never use semi-transparent fills or `surfaceLevel0`/`surfaceLevel2` for primary cards in Light Mode.
   - Keep Dark Mode surfaces completely unchanged unless explicitly requested.
5. **Quiet UX & Badges:** Do NOT show redundant default status badges (e.g., no green "Active" badge on normal members). Reserve badges for actionable states only (`Expiring Soon`, `Expired`). Keep filter chips strictly single-line (`maxLines: 1`, `softWrap: false`).
6. **Member Avatar Fallback Hierarchy:**
   - Valid `photoUrl` -> Cached network image.
   - Else `gender == 1` -> `assets/images/avatar_male.jpg`.
   - Else `gender == 2` -> `assets/images/avatar_female.jpg`.
   - Else (`gender == 0`) -> Clean initial-letter avatar.

---

## 4. Offline-First & Drift Sync Rules (CRITICAL — DO NOT REGRESS)
The Offline-First Sync engine is **already implemented and production-critical**. Treat it as a protected core subsystem:

- **Never Disconnect or Stub Sync:** NEVER replace, detach, or revert `SyncStatusPill`, `sync_provider.dart`, `sync_engine.dart`, or the Drift DAOs to dummy/idle states during UI or theme refactors. Any UI change to sync indicators must ONLY touch visual styling (e.g., color/icon) while keeping all live state bindings, tap-to-sync, and error/retry bottom sheets 100% intact.
- **Local Source of Truth:** Operational reads and writes (check-ins, members, etc.) must continue to work offline via Drift (`MembersDao`, local providers) and sync in the background via `SyncEngine`.
- **Stream & Field Completeness:** Whenever a new field is added to a synced entity (e.g., `photoUrl`, `gender`), it MUST be mapped consistently across all 4 layers:
  1. Backend DTO (`[property: JsonPropertyName("...")]`).
  2. Drift table + incremented `schemaVersion` with a safe `onUpgrade` (`addColumn`) migration.
  3. `SyncEngine` pull/push mappers and `MembersDao.upsertMembersFromServer`.
  4. Riverpod stream mappers (e.g., `members_provider.dart` `_initStream()` & `localMembersProvider`).
- **Data Preservation on Pull:** In `SyncEngine` and DAOs, NEVER overwrite existing local fields (such as `photoUrl`) with `null` when a sync payload omits or leaves them empty (`Value.absent()`). Only clear a field on explicit user delete/clear actions.
- **Honest Sync Status & Error Handling:**
  - `SyncStatusPill` must always reflect real state: synced (neutral/green), pending (`pendingCount > 0`, orange), or failed (`failedCount > 0`, red with error log details and a retry action).
  - Never swallow `4xx`/sync errors silently or fake a "synced" state.
  - Keep Dashboard KPIs and charts stable during background sync (no flashing zeros or resetting state while refreshing).

---

## 5. Motion & Micro-interactions Guidelines
Animations are mandatory for perceived quality, but must remain subtle, fast, and purposeful.

- **Standard Package:** Use `flutter_animate` for declarative UI entrances and effects (avoid boilerplate `AnimationController` unless building custom complex gestures).
- **Timing & Curves:**
  - Entrances: `300ms` to `450ms` using `Curves.easeOutCubic`.
  - Micro-interactions (Taps/Toggles): `120ms` to `180ms`.
  - **Never** exceed `600ms` so the app always feels snappy for busy gym staff.
- **Core Patterns:**
  1. **Staggered Entrance:** Lists and Grid cards enter sequentially with a `50ms–80ms` delay (`fadeIn` + slight `slideY`).
  2. **Animated KPIs:** Numeric stats count up smoothly using `AnimatedCounter` in `lib/core/ui/`.
  3. **Live Indicators:** Real-time metrics (e.g., Currently Inside) use a subtle looping pulse effect.
  4. **Tactile Feedback:** Action buttons and cards provide scale-down feedback (`0.96`) on press.
  5. **Loading States:** Prefer Shimmer skeletons over raw `CircularProgressIndicator` where possible.

---

## 6. Localization & Internationalization (i18n / l10n)
The application strictly enforces official Flutter Localization (`flutter_localizations` + `intl`) supporting Arabic (default, RTL) and English (LTR).

- **Zero Hardcoded Strings:** Hardcoding user-facing strings (Arabic or English) in the presentation layer is strictly forbidden. All UI text, error messages, placeholders, and tooltips must reside in `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`.
- **Access via Context Extension:** Access strings uniformly using `context.l10n.<key>` provided by `LocalizationX` in `lib/core/l10n/l10n_extension.dart`.
- **ICU Formats & Parameterization:** Always use typed ICU placeholders for numbers, names, and relative times (e.g., `{count}`, `{minutes}`, `{memberName}`).
- **Directional Layout & Icons:** Always use directional widgets (`EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`) and directional icons adapting to `Directionality.of(context)` or `Icons.adaptive`.
- **State Persistence:** App language is managed via Riverpod `localeProvider` and persisted via `SharedPreferences`.

---

## 7. STRICT CODE PRESERVATION & VERIFICATION RULES
- **Minimal Diff Only:** Modify ONLY the exact lines/widgets required for the current task. Never rewrite or reformat untouched sections of a file.
- **Preserve Manual UI Tweaks:** Treat all existing colors, paddings, font sizes, border radii, icon choices, and widget ordering in the current working tree as intentional user customizations. NEVER revert, "normalize", or override them unless explicitly instructed.
- **Check `git diff` First:** Before editing any file, inspect `git status` and `git diff` to see uncommitted manual changes made by the user, and preserve 100% of them.
- **No Unrequested Dependency/Native Changes:** Do NOT modify `pubspec.yaml`, `ios/`, or `android/` unless explicitly requested.
- **Verification Gate:** Always run `dotnet build GymOS.slnx && dotnet test GymOS.slnx` (Backend) or `flutter analyze && flutter test` (Mobile) with 0 errors before reporting completion.