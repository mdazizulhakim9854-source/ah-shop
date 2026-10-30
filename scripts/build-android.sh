#!/usr/bin/env bash
set -euo pipefail
# Requires Java 21, Android SDK platform 36/build tools and Node 20+.
npm ci
npm run build
npx cap sync android
chmod +x android/gradlew
(cd android && ./gradlew --no-daemon bundleRelease assembleDebug)
printf '\nAAB: android/app/build/outputs/bundle/release/app-release.aab\n'
printf 'No signing secrets = UNSIGNED AAB, not upload-ready. Debug APK = testing only.\n'
