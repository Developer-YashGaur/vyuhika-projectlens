# ADR 0001: Native iOS-first foundation

- Status: Accepted for foundation
- Date: 2026-10-27

## Context

ProjectLens targets developers, freelancers, indie hackers and founders with future personal and project finance tools. The current milestone establishes engineering foundations only. The workspace was empty; installed tools are Xcode 27.1 with iOS 27.1 SDK and Swift 6.4.

## Decision

Use native SwiftUI, iPhone only, a single app module and Swift 6 language mode. Set minimum deployment to iOS 17.0. This supports modern SwiftUI and Observation APIs, preserves broader device reach than targeting only iOS 26/27, and leaves persistence options open. The installed compiler accepts iOS 17; older device-runtime validation remains separate from compilation. No usage analytics exist to justify dropping older devices. Apple's Xcode support matrix lists iOS 17 within the Xcode 27 deployment range: https://developer.apple.com/xcode/system-requirements/.

Keep domain rules independent from UI, storage and service adapters. Document future boundaries without unused protocols or frameworks. Defer backend, sync and storage-engine selection until actual data requirements exist. Use Decimal or explicit minor units for future money calculations; decide currency and rounding policy before implementation.

Commit a standard Xcode project and shared scheme. No project-generation tool or third-party runtime dependency is required. CI uses available stable Xcode 26.6 on macos-26; local validation uses Xcode 27.1.

Apache-2.0 was explicitly approved by the owner. It allows commercial services and proprietary forks, includes an explicit patent grant, and requires notice preservation. MIT was simpler but lacked an explicit patent grant; stronger copyleft was not selected. See https://www.apache.org/licenses/LICENSE-2.0.

## Consequences

No Android or web client is included. Physical-device signing is local configuration. SwiftData remains an option rather than a commitment. App Store packaging, privacy disclosures, real-device accessibility testing and validation on the minimum iOS runtime are required before release.
