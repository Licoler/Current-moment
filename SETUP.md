# CurrentMoment Setup

## Goal

Run the project locally without a paid Apple Developer account.

## Requirements

- Xcode 26+
- iOS 17+
- Firebase project with `Auth`, `Firestore`, `Storage`
- Personal Team or Simulator

## 1. Open The Project

Open [currentMoment.xcodeproj](/Users/albekhalapov/Desktop/currentMoment/currentMoment.xcodeproj) in Xcode.

## 2. Set Signing

For `currentMoment`:

1. Open `Signing & Capabilities`
2. Select your `Personal Team`
3. If Xcode asks to fix signing, allow it

For `currentMomentWidgetExtension`:

1. Select the same `Personal Team`
2. Let Xcode generate provisioning automatically

There are no paid capabilities left in the project:

- no Sign in with Apple entitlement
- no Push Notifications entitlement
- no App Groups entitlement
- no APS environment

## 3. Add Firebase Packages

In Xcode:

1. `File -> Add Package Dependencies`
2. Add `https://github.com/firebase/firebase-ios-sdk`
3. Attach:
   - `FirebaseAuth`
   - `FirebaseCore`
   - `FirebaseFirestore`
   - `FirebaseStorage`

Attach them only to:

- `currentMoment`

## 4. Add GoogleService-Info.plist

1. Create an iOS app in Firebase for bundle id `halapov.currentMoment`
2. Download `GoogleService-Info.plist`
3. Add it into the main app target root [currentMoment](/Users/albekhalapov/Desktop/currentMoment/currentMoment)

## 5. Firebase Auth Mode

Enable in Firebase Auth:

- `Anonymous`

The app now uses free-safe auth modes:

- `Demo account` in mock mode
- `Anonymous Firebase auth` in live Firebase mode

## 6. Firestore Collections

Create these collections:

- `users`
- `moments`
- `friendships`

Expected fields:

- `users`: `username`, `fullName`, `email`, `avatarURL`, `friendIDs`, `friendsCount`, `createdAt`
- `moments`: `senderId`, `recipientIds`, `imageURL`, `thumbnailURL`, `caption`, `senderName`, `isLivePhoto`, `createdAt`
- `friendships`: `requesterId`, `receiverId`, `status`, `createdAt`, `participants`

## 7. Storage

The app uploads images into:

- `moments/<moment-id>.jpg`
- `moments/<moment-id>-thumb.jpg`

## 8. Notifications

Remote push was removed for free-account compatibility.

Current fallback:

- local notifications
- in-app realtime updates through Firestore listeners

No Apple push certificate or APNs key is required.

## 9. Widget

The widget target remains in the project as a demo-safe extension:

- target: `currentMomentWidgetExtension`
- folder: [WidgetExtension](/Users/albekhalapov/Desktop/currentMoment/WidgetExtension)

Because App Groups were removed, the widget now works in static demo mode. It is safe for Simulator and Personal Team builds.

## 10. Deep Links

Supported schemes:

- `currentmoment://history/<moment-id>`
- `locketclone://history/<moment-id>`

## 11. Build Commands

Build:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme currentMoment -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Build for testing:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme currentMoment -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build-for-testing
```

## 12. Notes

- Without Firebase packages the app still runs on the built-in mock repository.
- Camera UX is best validated on a physical device, but the simulator uses a generated demo capture.
- The project is now designed for interview/demo use first, not App Store release signing.
