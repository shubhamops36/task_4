# Fieldnotes

Fieldnotes is an offline-first community journal demo built with Flutter.

## Included

- A seeded feed that is cached on-device with `shared_preferences`.
- Create a private note, browse by category, and search the cached stories.
- Save and remove bookmarks; the library is available offline.
- Local test notifications, with optional Firebase Cloud Messaging for remote updates.

## Implementation Steps

1. **Bootstrap the app:** `lib/main.dart` initializes Flutter bindings and the notification service, then starts `FieldnotesApp` from `lib/fieldnotes_app.dart`.
2. **Define the feed model:** `Fieldnote` represents a story and supports JSON serialization. Starter stories provide content on first launch, without requiring a network connection.
3. **Add local persistence:** `FeedStore` uses `shared_preferences` to cache feed JSON, saved story IDs, and the notification preference. If cached feed data is invalid, the app restores the starter feed.
4. **Build the user interface:** The Discover screen provides category filters, search, pull-to-refresh, bookmarking, and a daily writing prompt. Saved lists bookmarked stories, and Settings contains notification and cache controls.
5. **Persist user notes:** Writing a note adds it to the local feed cache, so it remains available after restarting the app and while offline.
6. **Integrate notifications:** `NotificationService` initializes local notifications and attempts Firebase initialization. With Firebase configured, the app requests permission, subscribes to `fieldnotes_updates`, and displays foreground FCM messages. Without Firebase, local demo alerts remain available.
7. **Configure Android:** The manifest declares internet and notification permissions. Gradle enables core-library desugaring for the local-notification plugin.
8. **Verify the app:** Run analysis and widget tests, then build the Android debug APK:

	```sh
	flutter analyze lib test
	flutter test
	flutter build apk --debug
	```

The resulting debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. Build outputs are ignored by Git; downloadable APKs can be attached to a GitHub Release.

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
