# Fieldnotes

Fieldnotes is an offline-first community journal demo built with Flutter.

## Included

- A seeded feed that is cached on-device with `shared_preferences`.
- Create a private note, browse by category, and search the cached stories.
- Save and remove bookmarks; the library is available offline.
- Local test notifications, with optional Firebase Cloud Messaging for remote updates.

## Run

```sh
flutter pub get
flutter run
```

The feed, note creation, and bookmarks work without a network connection. On a device, open **Settings** to enable demo alerts or send a test alert. Android 13+ and iOS will ask for notification permission.

## Enable Remote Push

Remote push requires your own Firebase project and Apple Push Notification service credentials; they are not included in this workspace.

1. Create a Firebase project and register Android package `com.fieldnotes.fieldnotes` and the iOS bundle identifier shown in Xcode.
2. Add `google-services.json` to `android/app/` and `GoogleService-Info.plist` to the iOS Runner target. Use the Firebase Flutter setup tool to generate platform options if your project requires them.
3. In `android/settings.gradle.kts`, declare the Google Services Gradle plugin in the `plugins` block, then apply `id("com.google.gms.google-services")` in `android/app/build.gradle.kts` after the Android plugin. Use the current plugin version from Firebase's Android setup guide.
4. In Xcode, enable the Push Notifications capability for Runner and upload an APNs authentication key in Firebase Project Settings.
5. Rebuild and run the app, then turn on **Community updates** in Settings. The app subscribes to the `fieldnotes_updates` FCM topic and displays foreground messages as local notifications.

Without Firebase configuration, the app deliberately falls back to local demo alerts and remains usable. A production feed/API and a trusted server for sending FCM messages are not part of this demo.
