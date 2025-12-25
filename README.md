# Test App

Internal monitoring toolkit built with Flutter. The project now ships with a
repeatable release process so we can confidently cut production builds.

## Development

```bash
flutter pub get
flutter run
```

## Configure Android Release Signing

1. **Create/obtain the keystore**
   ```bash
   keytool -genkey -v \
     -keystore my-release-key.jks \
     -alias <your-key-alias> \
     -keyalg RSA -keysize 2048 -validity 10000
   ```
   Keep the resulting `.jks` out of version control. You can store it in the
   project root (same directory as this README) so the relative path works
   across machines.

2. **Populate `android/key.properties`** (never commit real secrets):
   ```properties
   storePassword=<keystore password>
   keyPassword=<alias password>
   keyAlias=<your-key-alias>
   storeFile=../my-release-key.jks  # relative to android/ directory
   ```
   The Gradle script automatically picks up these values and signs release
   builds. If the file is missing, the build falls back to the debug key so you
   can still run locally.

3. **Update the package name/version** before Play Store submission:
   - Set a unique `applicationId` in `android/app/build.gradle.kts`.
   - Update the `version` field (e.g. `1.0.0+1`) in `pubspec.yaml`; the
     Play Store uses the numeric suffix as `versionCode`.

## Build a Play Store Artifact

1. Ensure code is on the desired tag/commit and run tests as needed.
2. Build the Android App Bundle (required by Google Play):
   ```bash
   flutter build appbundle --release
   ```
   The signed bundle is created at
   `build/app/outputs/bundle/release/app-release.aab`.
3. (Optional) Create a release APK for side-loading:
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`.

## Publish to Google Play

1. Log into the Play Console and select the production track (or create an
   internal testing track first if desired).
2. Upload `app-release.aab`, provide release notes, and confirm the version
   code bump.
3. Complete policy questionnaires (Data Safety, Content Rating) if prompted.
4. Start the rollout and monitor the console for status updates once the review
   finishes.

Keep the keystore and `key.properties` backed up securely; losing them means
future updates cannot be signed with the same key. Consider storing encrypted
copies in a password manager or a secure secrets vault.
