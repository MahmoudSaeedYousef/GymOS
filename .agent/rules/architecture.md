---
trigger: always_on
---
Always read and strictly follow `ARCHITECTURE.md` at the repository root before planning or editing any file.
- Zero hardcoded UI strings (always use `context.l10n` + ARB files).
- Never regress Drift/SyncEngine offline-first logic.
- Keep diffs minimal and preserve existing UI tweaks.
