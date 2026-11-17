# HEMMA – Technical Architecture

## Product decisions (locked)
- Name: HEMMA
- Platform: iPhone first
- Distribution: sideloaded IPA as the first delivery
- Smart-home source: Apple HomeKit
- Accessory ecosystem: Matter accessories already paired to Apple Home
- Visual direction: combination of the five supplied references; dark premium
- Widget: room buttons plus a large primary all-lights button

## System boundaries
HEMMA is a controller and presentation layer over the user's existing Apple Home. It does not replace Apple Home, act as a Matter commissioner, or create a separate accessory database.

SwiftUI screens -> Feature/domain layer -> HomeKit adapter -> Apple Home (including supported Matter accessories).

## Core engineering rules
1. HomeKit is the source of truth. Do not maintain a competing copy of device state.
2. Discover capabilities from services and characteristics. Never show dimming, color or color-temperature controls unless the accessory supports them.
3. Distinguish on, off, unavailable and unknown. A missing or stale value must never be presented as confirmed off.
4. A command is pending until HomeKit reports completion. Surface errors; do not optimistically claim success.
5. Bulk all-lights actions target light-capable accessories only, not every switch or outlet.
6. Avoid duplicate writes and serialize conflicting commands per characteristic, including brightness and color controls.
7. Request only permissions needed for the current feature set.
8. Keep the first release local and simple; no backend or account system.

## Initial modules
- App: app lifecycle and root navigation.
- DesignSystem: colors, typography, cards, controls and motion.
- HomeKit: authorization, discovery, observation and commands.
- Features/Dashboard: home summary and favorites.
- Features/Rooms: room list and room detail.
- Features/Devices: accessory list and capability-specific controls.
- Features/Scenes: read and activate supported HomeKit scenes.
- WidgetExtension: widget timeline and App Intents, implemented after core control is stable.
- Tests: domain mapping and command-state tests.

## First release scope
- Read homes and rooms.
- Discover accessories and supported light controls.
- On/off, brightness and color writes with per-characteristic pending-command locking and HomeKit completion/error feedback.
- Brightness where supported.
- Room-level overview.
- Favorite rooms, persisted locally and surfaced on the dashboard.
- Widget with room buttons and a prominent all-lights action, once entitlement and widget execution are validated.

## Explicitly deferred
- Matter commissioning / pairing.
- Cameras and live video.
- Energy analytics unless accessories expose reliable energy characteristics.
- Custom cloud sync.
- Complex automation authoring.
- Apple Watch app.

## Widget implementation constraints (checked against Apple App Intents and WidgetKit documentation, November 2026)
- Interactive widget buttons and toggles invoke App Intents. The intent's asynchronous `perform()` must finish the action and persist any data needed by the next timeline before returning. WidgetKit guarantees a timeline reload after a button or toggle interaction.
- Widget extension code runs in a separate process. App Intent code in the main app bundle can run in the app process; code in an App Intents extension or Widget extension always runs in the background. `supportedModes` expresses preferred runtime modes but is not a guarantee and cannot override extension runtime restrictions.
- Apple documents `allowedExecutionTargets = .main` for intents whose writes must execute in the main app process. Intent packaging and target membership must follow Apple's guidance; do not assume the widget can call the main app's in-memory `HomeKitStore`.
- A widget `Button` is a good fit for an all-lights action because it doesn't display a persistent on/off state. A widget `Toggle` updates optimistically before its intent finishes; if used, the intent must reconcile the displayed state with the confirmed HomeKit result or restore the prior state and show an error after failure. Do not treat the optimistic animation as proof of a successful HomeKit write.
- A standard interactive widget can perform useful actions without opening the app. Opening HEMMA is a fallback only if the intended HomeKit execution path cannot be made reliable.
- WidgetKit Control widgets have their own execution rules: their action runs in the widget extension's background process. Do not assume `supportedModes` can move a Control widget action into the app process.
- Before choosing a standard interactive widget versus a Control widget, build a minimal proof of concept using the exact CI Xcode SDK and test a real HomeKit write on a physical iPhone with the intended sideload signing profile. If the process cannot access HomeKit reliably, the widget must open HEMMA rather than report a false success.
- Widget timeline content must not imply a live HomeKit state unless it has been read from an authorized HomeKit manager. Unknown or stale values must be labelled as such.
- Keep the first widget iteration conservative: prove an end-to-end all-lights action and confirmed result before adding room-specific controls.
- App Group storage is not assumed for the sideload build. Do not make it a prerequisite until its signing and provisioning implications are validated for the distribution route.
- HomeKit authorization is determined from `HMHomeManager.authorizationStatus`; never infer authorization merely because the homes callback ran.

### Apple documentation reviewed
- [Adopting App Intents to support system experiences](https://developer.apple.com/documentation/appintents/adopting-app-intents-to-support-system-experiences)
- [IntentExecutionTargets](https://developer.apple.com/documentation/appintents/intentexecutiontargets)
- [Configuring the runtime behavior of your app intents](https://developer.apple.com/documentation/appintents/configuring-the-runtime-behavior-of-your-app-intents)
- [AppIntent.supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes)
