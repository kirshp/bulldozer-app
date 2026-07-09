# Releasing BullDozer

## Where builds land

| What | Path |
|------|------|
| Android split APKs | `build/app/outputs/flutter-apk/app-<abi>-release.apk` |
| — the one we ship | `app-arm64-v8a-release.apk` (~18 MB, modern phones) |
| Android App Bundle | `build/app/outputs/bundle/release/app-release.aab` (Play Store) |
| iOS app | `build/ios/iphoneos/Runner.app` |
| iOS archive | `build/ios/archive/Runner.xcarchive` (App Store upload) |

## How a version ships today (sideload / direct download)

1. Bump `version:` in `pubspec.yaml` (e.g. `1.13.5+24`).
2. `flutter build apk --release --split-per-abi`
3. Copy `app-arm64-v8a-release.apk` to the website download folder
   (`bulldozer/downloads/bulldozer-stats.apk`) and deploy.
4. `git tag vX.Y.Z && gh release create` with the APK attached.

Live link: **https://shpara.com/bulldozer/downloads/bulldozer-stats.apk**
GitHub releases: **https://github.com/kirshp/bulldozer-app/releases**

> Cloudflare Pages has a 25 MiB per-file limit — that is why we ship the
> arm64 **split** APK (~18 MB), never the fat `app-release.apk` (~47 MB).

The website APK and the GitHub release are the current distribution: users
download and sideload. The stores below are the next step.

---

## Google Play Store

**Prerequisites**
- Google Play Console account — **one-time $25** (play.google.com/console).
- Play requires an **App Bundle** (`.aab`), not an APK.

**Steps**
1. Build the bundle: `flutter build appbundle --release`
   → `build/app/outputs/bundle/release/app-release.aab`.
2. In Play Console: *Create app* → name **BullDozer**, category, free.
3. Let Google manage signing (**Play App Signing** — recommended). Upload
   an upload key (`keytool -genkey -v -keystore upload.jks ...`) and wire it
   in `android/key.properties` + `android/app/build.gradle.kts`.
4. Fill the store listing: short + full description, **feature graphic
   (1024×500)**, phone screenshots (≥2), app icon 512×512.
5. Complete the questionnaires: content rating, data-safety form (we only
   read public data, no accounts), target audience, ads = none.
6. Upload the `.aab` to a track: **Internal testing** first (instant, up to
   100 testers by email), then Closed/Open, then Production.
7. First Production submission triggers a review (hours–days).

**applicationId** is `com.shpara.bulldozer_app` — fixed once published.

---

## Apple App Store

**Prerequisites**
- Apple Developer Program — **$99 / year** (developer.apple.com).
- Team ID already in use for signing: **ARY46X758B**.
- Bundle ID: `com.shpara.bulldozerApp`.

**Steps**
1. In App Store Connect: *My Apps* → **+** → new app, pick the bundle ID.
2. Archive from Xcode: open `ios/Runner.xcworkspace` → *Any iOS Device* →
   **Product ▸ Archive** → *Distribute App ▸ App Store Connect ▸ Upload*.
   (CLI alt: `flutter build ipa --release`, then upload the `.ipa` via
   **Transporter**.)
3. TestFlight: the build appears after processing; add internal testers
   (no review) or external testers (light review) by email.
4. Store listing: description, keywords, support URL, **screenshots per
   device size** (6.7", 6.5", 5.5", iPad if supported), privacy policy URL.
5. App Privacy: declare "Data Not Collected" (thin client over public data).
6. Submit for review. Apple review is stricter — expect 1–3 days and
   occasional back-and-forth.

---

## Assets still needed for both stores
- Privacy policy page (a short one on shpara.com/bulldozer would do).
- Feature graphic + polished screenshots (dark and light theme).
- 512×512 (Play) / 1024×1024 (Apple) icon — already generated from
  `assets/icon/icon.png`.
