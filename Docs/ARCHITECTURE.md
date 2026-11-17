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

## Widget implementation constraints (verified against Apple documentation)
- Interactive WidgetKit buttons and toggles invoke App Intents. The intent must finish the action and persist any required result before returning; WidgetKit then reloads the timeline.
- Widget extensions execute in a separate process. App Intents can declare supported execution modes and allowed execution targets; choose these deliberately after validating where HomeKit access is authorized and available.
- Do not assume that an intent running in the widget extension can reuse the main app's in-memory HomeKit manager.
- Prefer an App Intent that is restricted to the main app process when the action needs the app's HomeKit access; Apple's current App Intents guidance documents `.main` as an execution target. Validate the exact SDK availability on the CI Xcode version before implementation.
- Widget timeline content must not imply a live HomeKit state unless it has been read from an authorized HomeKit manager. Unknown or stale values must be labelled as such.
- Keep the first widget iteration conservative: prove an end-to-end all-lights action and confirmed result before adding room-specific controls.
- App Group storage is not assumed for the sideload build. Do not make it a prerequisite until its signing and provisioning implications are validated for the distribution route.
- HomeKit authorization is determined from `HMHomeManager.authorizationStatus`; never infer authorization merely because the homes callback ran.
