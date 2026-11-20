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