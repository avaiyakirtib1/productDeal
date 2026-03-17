# Push Notifications – Setup & Troubleshooting

## Error: "Registration failed - push service error" (Web)

If you see `❌ Error getting FCM token: AbortError: Registration failed - push service error`:

1. **Enable FCM Registration API** (required for FCM web SDK 6.7.0+):
   - Go to [Google Cloud Console](https://console.cloud.google.com/apis/library/fcmregistrations.googleapis.com)
   - Select your Firebase project (same as Firebase Console)
   - Click **Enable**

2. **Brave Browser only** – Brave disables Google push by default:
   - Open `brave://settings/privacy`
   - Enable **"Use Google Services for Push Messaging"**
   - Restart Brave and retry

3. **Verify VAPID key** – Copy it again from Firebase Console → Project Settings → Cloud Messaging → Web Push certificates. Ensure no extra spaces and it matches exactly.

4. **Service worker scope** – The service worker must be at the root. If your app uses a base path (e.g. `/app/`), ensure `firebase-messaging-sw.js` is served at `https://yourdomain.com/firebase-messaging-sw.js`.

---

## One-time setup for all platforms

### Web (required for Chrome, Brave, Safari)

1. **Generate VAPID key** in [Firebase Console](https://console.firebase.google.com):
   - Project Settings → **Cloud Messaging** → **Web Push certificates** → **Generate key pair**
   - Copy the public key (starts with `B...`)

2. **Add VAPID key** in `lib/core/config/app_config.dart`:
   ```dart
   static const String _vapidKeyOverride = 'BGpdLRs...';  // paste your key
   ```
   Or build with: `flutter build web --dart-define=VAPID_KEY=YourKeyHere`

3. **Service worker** is registered in `web/index.html` – no extra setup needed.

4. **HTTPS** required (or `localhost` for dev).

### Android

- `POST_NOTIFICATIONS` in manifest + runtime grant (Android 13+) – handled by `requestPermission()`.
- `high_importance_channel` exists in manifest and app.

### iOS

- APNs certificate/key in Firebase Console.
- Push Notifications capability in Xcode.
- Physical device (not simulator).

---

## Why it works on some platforms and not others

### Web (Chrome, Brave, Safari on macOS)

| Browser | Works? | Why |
|---------|--------|-----|
| **Chromium** | ✅ Often works | May use different Web Push implementation |
| **Chrome** | ❌ Without VAPID | **Requires VAPID key** – Chrome's Push API strictly requires it |
| **Brave** | ❌ Without VAPID | Same as Chrome; also check Brave Shields |
| **Safari** | ❌ Without VAPID | Same VAPID requirement; limited Web Push support |

#### Fix for Chrome / Brave / Safari

1. Add VAPID key (see One-time setup above).
2. **Brave**: Site settings → Notifications → Allow; if Shields blocks, allow for your site.

---

### Android

| Symptom | Possible cause | Fix |
|---------|----------------|-----|
| Token saved, no notification | App in **foreground** | We show a local notification – ensure `high_importance_channel` exists (we create it in code) |
| Token saved, no notification | App in **background** | FCM should auto-display – check payload has both `notification` and `data` |
| Token saved, no notification | **Android 13+** | Runtime `POST_NOTIFICATIONS` – user must grant when prompted |
| Token saved, no notification | **Battery / Doze** | Device may throttle – disable battery optimization for the app |
| Token saved, no notification | **App notifications disabled** | System Settings → Apps → Your app → Notifications → Enable |
| Token saved, no notification | **Google Play Services** | Ensure device has up-to-date Google Play Services |

#### Verification

1. **Token registration**: Backend logs `[SendNotificationToUser] Step 3: Sending FCM` with `tokenCount` – confirms token is used
2. **FCM response**: Logs `successCount` / `failureCount` – if `successCount > 0`, FCM accepted the message
3. **Device**: Settings → Apps → Your app → Notifications – ensure enabled
4. **Test**: Put app in **background** (home button), trigger a notification – system should show it

---

### iOS

- Requires physical device (not simulator)
- APNs certificate/key in Firebase Console
- Push Notifications capability in Xcode
- User must grant notification permission

---

## Quick checklist

| Platform | Requirement |
|----------|-------------|
| **Web** | VAPID key in `app_config.dart` or `--dart-define=VAPID_KEY=...` |
| **Web** | `firebase-messaging-sw.js` at root (registered in index.html) |
| **Web** | HTTPS (or localhost) |
| **Web** | User allowed notifications |
| **Android** | `POST_NOTIFICATIONS` in manifest + runtime grant (Android 13+) |
| **Android** | `high_importance_channel` in manifest + created in app |
| **iOS** | APNs configured, physical device |
