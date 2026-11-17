# IPA and FlareStore Signing Plan

## Goal
Deliver a sideloadable iPhone IPA as the first distribution format.

## Build pipeline
1. Build the Swift project with a compatible Xcode/macOS environment.
2. Configure the app bundle identifier and required usage descriptions.
3. Enable the HomeKit capability in the app target.
4. Archive/export using a signing identity and provisioning profile that contain the required HomeKit entitlement.
5. Inspect the exported app's entitlements and embedded provisioning profile.
6. Sign/install using the user's FlareStore workflow, if the provided certificate/profile supports the required capability.
7. Install on the user's iPhone and test authorization, discovery and a real lamp command.

## Do not assume
- A certificate label alone proves that the final IPA has the HomeKit entitlement.
- Re-signing preserves every entitlement. Inspect the final signed app.
- Successful installation proves HomeKit access. Test the permission prompt and actual accessory operations.
- Widget extension signing automatically matches the main app. Verify the extension's bundle ID, entitlements and profile separately.

## Validation checklist
- [ ] Confirm FlareStore certificate type and expiration.
- [ ] Confirm provisioning profile App ID matches the app bundle identifier.
- [ ] Inspect profile entitlements for HomeKit.
- [ ] Inspect final app entitlements after signing.
- [ ] Verify HomeKit usage-description key is present.
- [ ] Verify widget extension is signed and embedded correctly.
- [ ] Install on a physical iPhone.
- [ ] Confirm HomeKit authorization.
- [ ] Discover existing Apple Home and Matter accessories.
- [ ] Test on/off and brightness on supported lamps.
- [ ] Test unavailable accessory and failed command handling.

## Current status
Not yet validated. This repository does not contain signing certificates, private keys, provisioning profiles or secrets. Never commit these files or credentials to GitHub.

## Security
Keep P12 files, passwords, provisioning profiles and signing secrets out of the repository. Use a secure local signing workflow or protected CI secrets only when appropriate.