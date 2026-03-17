# Vercel Deployment Guide for Flutter Web

This document explains how the Flutter web app is configured for deployment on Vercel.

## Configuration Files

### `vercel.json`
- **buildCommand**: Builds Flutter web in release mode
- **installCommand**: 
  - Clones Flutter SDK if not present
  - Runs `flutter doctor`, `flutter clean`, `flutter config --enable-web`, and `flutter pub get`
- **outputDirectory**: `build/web` - where Flutter outputs the web build
- **rewrites**: SPA routing support (all routes redirect to index.html)

### `.vercelignore`
Excludes build artifacts and platform-specific folders from Vercel uploads:
- `/android/`, `/ios/`, `/build/` - Platform-specific builds
- `.dart_tool/`, `.flutter-plugins*` - Flutter tooling
- IDE folders, logs, etc.

**Includes** (source code needed for build):
- `lib/` - Dart source code
- `web/` - Web configuration
- `pubspec.yaml` - Dependencies
- `assets/` - App assets

### `.gitignore`
Ensures only source code is committed to git:
- Excludes `/build/`, `/android/`, `/ios/` folders
- Excludes `.dart_tool/`, `.flutter-plugins*`
- Excludes IDE files, logs, etc.

## Deployment Flow

1. **Git Push**: Only source code is pushed (build folders excluded by .gitignore)
2. **Vercel Detects Push**: Vercel webhook triggers build
3. **Install Phase**: 
   - Clones Flutter SDK if needed
   - Runs `flutter pub get` to install dependencies
4. **Build Phase**: 
   - Runs `flutter build web --release`
   - Outputs to `build/web/`
5. **Deploy Phase**: 
   - Vercel serves files from `build/web/`
   - Routes configured for SPA

## What Gets Pushed to Git?

✅ **Included** (source code):
- `lib/` - All Dart source files
- `web/` - Web configuration (index.html, manifest.json, etc.)
- `pubspec.yaml` & `pubspec.lock` - Dependencies
- `assets/` - App icons, images, etc.
- `vercel.json` - Vercel configuration
- `firebase.json` - Firebase configuration
- `README.md`, `analysis_options.yaml` - Project files

❌ **Excluded** (build artifacts):
- `/build/` - Build output (generated)
- `/android/` - Android-specific files (not needed for web)
- `/ios/` - iOS-specific files (not needed for web)
- `.dart_tool/` - Flutter tooling cache
- `.flutter-plugins*` - Generated plugin files
- IDE folders, logs, etc.

## Manual Deployment

If you need to deploy manually:

```bash
# Build locally (optional, for testing)
flutter build web --release

# Deploy to Vercel
cd Flutter-Mobile
vercel --prod
```

## Troubleshooting

### Error: "Root Directory 'lib' does not exist"
- **Solution**: Remove any root directory setting in Vercel project settings
- The root should be `.` (current directory, i.e., `Flutter-Mobile/`)

### Build Fails: Flutter not found
- **Solution**: The installCommand should clone Flutter automatically
- Check Vercel build logs to see if Flutter clone succeeded

### Build Fails: Dependencies not found
- **Solution**: Ensure `pubspec.yaml` and `pubspec.lock` are committed
- Check that `.vercelignore` includes `!pubspec.yaml` and `!pubspec.lock`

### Routes not working (404 on refresh)
- **Solution**: The `rewrites` in `vercel.json` should handle this
- Ensure all routes redirect to `/index.html` for SPA routing

## Environment Variables

If needed, add environment variables in Vercel dashboard:
- Project Settings → Environment Variables
- These are available during build via `--dart-define` if needed

## Notes

- Vercel automatically detects changes on git push
- Build time: ~2-5 minutes (includes Flutter SDK clone on first build)
- Subsequent builds are faster (Flutter SDK cached)
- The Flutter SDK is cloned to the project root during build
- Build output is in `build/web/` and served by Vercel

