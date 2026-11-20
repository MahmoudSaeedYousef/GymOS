# GymOS - Architecture Reference Guide

## 1. Backend (.NET Clean Architecture)
The backend strictly follows Clean Architecture and Vertical Slice patterns. The dependency rule points inwards.

*   **GymOS.Api (Presentation):** 
    *   *Role:* Entry point. Maps HTTP requests to MediatR commands/queries.
    *   *Rule:* **ZERO business logic.** No DbContext, no complex if-conditions.
    *   *Structure:* `/Endpoints`, `Program.cs`, `appsettings.json`.

*   **GymOS.Application (Business Logic):**
    *   *Role:* The core engine. Contains all MediatR Handlers, DTOs, and Interfaces.
    *   *Rule:* Grouped by Feature (Vertical Slices), not by technical layers.
    *   *Structure:* `/Features/{FeatureName}/Commands`, `/Features/{FeatureName}/Queries`, `/DTOs`, `/Interfaces`.

*   **GymOS.Domain (Enterprise Logic):**
    *   *Role:* Defines the core entities and enums.
    *   *Rule:* Independent of all other layers. No external dependencies (No EF Core, No ASP.NET).
    *   *Structure:* `/Entities`, `/Enums`, `/Common`.

*   **GymOS.Infrastructure (Data & External Services):**
    *   *Role:* Communicates with the database and external world.
    *   *Rule:* Implements interfaces defined in the Application layer.
    *   *Structure:* `/Data` (GymDbContext), `/Migrations`, `/Services` (Cache, Tenant).

---

## 2. Frontend (Flutter Feature-First)
The mobile app follows a Feature-First architecture using Riverpod for State Management.

*   **lib/core/:**
    *   *Role:* Shared foundational elements.
    *   *Rule:* Should not import anything from `/features`.
    *   *Structure:* `/network` (Dio, Router), `/theme` (AppTheme, Spacing, Colors), `/widgets` (Reusable Gym-prefixed widgets), `/providers` (Global states like Theme/Locale).

*   **lib/features/:**
    *   *Role:* Vertical slices of app functionality.
    *   *Rule:* Each feature is independent. State is managed via Riverpod `StateNotifier`. No UI logic inside providers.
    *   *Structure:* `/auth`, `/home`, `/members`, `/settings`. 
    *   *Sub-structure per feature:* `/models`, `/providers`, `/services` (API calls), `/ui`.

*   **lib/routes/:**
    *   *Role:* Centralized GoRouter configuration.

## 3. Core Rules
1. **Theme-Awareness:** No hardcoded colors (e.g., `Colors.blue`). Always use `context.gymColors`.
2. **Multi-Tenancy:** Every new entity must include a `TenantId` and be isolated via Global Query Filters in `GymDbContext`.

## 4. Motion & Micro-interactions Guidelines
Animations are mandatory for perceived quality, but must remain subtle, fast, and purposeful.

*   **Standard Package:** Use `flutter_animate` for declarative UI entrances and effects (avoid boilerplate `AnimationController` unless building custom complex gestures).
*   **Timing & Curves:** 
    *   Entrances: `300ms` to `450ms` using `Curves.easeOutCubic`.
    *   Micro-interactions (Taps/Toggles): `120ms` to `180ms`.
    *   **Never** exceed `600ms` so the app always feels snappy for busy gym staff.
*   **Core Patterns to Apply Across Screens:**
    1. **Staggered Entrance:** Lists and Grid cards must enter sequentially with a `50ms–80ms` delay between items (`fadeIn` + slight `slideY`).
    2. **Animated KPIs:** All numeric stats (Revenue, Active Members, Check-ins) must count up smoothly using `AnimatedCounter` in `lib/core/ui/`.
    3. **Live Indicators:** Real-time metrics (e.g., Currently Inside) must use a subtle looping pulse effect.
    4. **Tactile Feedback:** Action buttons and cards must provide scale-down feedback (`0.96`) on press.
    5. **Loading States:** Prefer Shimmer skeletons over raw `CircularProgressIndicator` where possible.

---

## 5. Localization & Internationalization (i18n / l10n)
The application strictly enforces official Flutter Localization (`flutter_localizations` + `intl`) supporting Arabic (default, RTL) and English (LTR).

*   **Zero Hardcoded Strings:** Hardcoding user-facing strings (Arabic or English) in the presentation layer is strictly forbidden. All UI text, error messages, placeholders, and tooltips must reside in `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`.
*   **Access via Context Extension:** Access strings uniformly using `context.l10n.<key>` provided by `LocalizationX` in `lib/core/l10n/l10n_extension.dart`.
*   **ICU Formats & Parameterization:** Always use typed ICU placeholders for numbers, names, and relative times (e.g., `{count}`, `{minutes}`, `{memberName}`).
*   **Directional Adaptation:** Directional icons (e.g., chevrons, arrows, back buttons) must adapt according to `Directionality.of(context)` (pointing opposite in RTL vs. LTR) or use `Icons.adaptive`.
*   **State Persistence:** App language is managed via Riverpod `localeProvider` and persisted to local device storage (`SharedPreferences`).

---

## 5. Localization & Internationalization (i18n / l10n)
The application strictly enforces official Flutter Localization (`flutter_localizations` + `intl`) supporting Arabic (default, RTL) and English (LTR).

*   **Zero Hardcoded Strings:** Hardcoding user-facing strings (Arabic or English) in the presentation layer is strictly forbidden. All UI text, error messages, placeholders, and tooltips must reside in `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`.
*   **Access via Context Extension:** Access strings uniformly using `context.l10n.<key>` provided by `LocalizationX` in `lib/core/l10n/l10n_extension.dart`.
*   **ICU Formats & Parameterization:** Always use typed ICU placeholders for numbers, names, and relative times (e.g., `{count}`, `{minutes}`, `{memberName}`).
*   **Directional Adaptation:** Directional icons (e.g., chevrons, arrows, back buttons) must adapt according to `Directionality.of(context)` (pointing opposite in RTL vs. LTR) or use `Icons.adaptive`.
*   **State Persistence:** App language is managed via Riverpod `localeProvider` and persisted to local device storage (`SharedPreferences`).
