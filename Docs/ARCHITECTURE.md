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
6. Avoid duplicate writes and serialize conflicting commands per characteristic.
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
- On/off control.
- Brightness where supported.
- Room-level overview.
- Favorite rooms.
- Widget with room buttons and a prominent all-lights action, once entitlement and widget execution are validated.

## Explicitly deferred
- Matter commissioning / pairing.
- Cameras and live video.
- Energy analytics unless accessories expose reliable energy characteristics.
- Custom cloud sync.
- Complex automation authoring.
- Apple Watch app.