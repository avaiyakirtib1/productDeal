# Localization Documentation

This folder contains tracking documents for the Flutter app localization effort.

## Files

| File | Purpose |
|------|---------|
| **[LOCALIZATION_TRACKER.md](./LOCALIZATION_TRACKER.md)** | Main tracker: all Dart files by module with status (Done / Partial / Pending / N/A) and notes |
| **[LOCALIZATION_FILES_CSV.md](./LOCALIZATION_FILES_CSV.md)** | Same data in comma-separated format for quick scan and scripting |

## Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ Done | Fully localized |
| ⚠️ Partial | Some localized, some hardcoded |
| ❌ Pending | Has strings, not localized |
| ➖ N/A | No user-facing strings |

## How to Use

1. **Find what to localize next:** Open `LOCALIZATION_TRACKER.md` and search for `❌ Pending` or `⚠️ Partial`.
2. **Script/parse:** Use `LOCALIZATION_FILES_CSV.md` for grep/awk or custom scripts.
3. **Update after changes:** Edit the MD files when you localize a file.

## Quick Stats (as of 2025-02-23)

- **Done:** 83 files
- **Partial:** 0 files
- **Pending:** 0 files
- **N/A:** 92 files
- **Total:** 175 Dart files
