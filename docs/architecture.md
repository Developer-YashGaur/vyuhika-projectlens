# Architecture

## Current foundation

One native SwiftUI application target with one unit-test target and one UI-test target. No external packages. `ProjectLensApp` launches `NavigationShell`; `NeonOrbit` contains adaptive semantic design tokens. Each of the four native tabs owns a NavigationStack. The shell owns tab selection and one Quick Add sheet presentation state; the reusable sheet owns only its transient entry-type selection. `OrbitEmptyState` supplies the shared scrollable empty-state layout, reused by Home and the other destinations. No backend, database, authentication, dependency container or financial model is implemented.

| Location | Responsibility |
| --- | --- |
| App | Application lifecycle and eventual composition |
| Features | Feature UI and state: Home and preview-only Quick Add |
| Shared/DesignSystem | Shared visual tokens and future reusable components |
| Domain | Future money value types and deterministic financial rules |
| Persistence | Future storage adapters and migrations |
| Services | Future network/provider adapters |
| ProjectLensTests | Hosted configuration, adaptive contrast and motion-policy tests |
| ProjectLensUITests | Navigation, sheet lifecycle and accessibility-size smoke tests |
| docs | Product decisions, architecture and design guidance |

Domain, Persistence and Services currently contain boundary documentation only. Keep one app module until real complexity justifies extracting packages. Do not introduce generic repositories, protocols, state frameworks or service locators speculatively.

## Intended dependency direction

Feature orchestration may depend on domain rules and concrete adapters composed at the app boundary. Domain must remain independent of SwiftUI, persistence SDKs and networking. Introduce narrow injected interfaces when actual dependencies require them. Keep UI state on the main actor; isolate mutable shared state as needed under Swift 6 concurrency checking.

## Financial correctness

Prefer Foundation Decimal or checked integer minor units with explicit currency metadata. Decide precision and rounding per operation. Never aggregate unlike currencies without explicit conversion metadata. Allocation must conserve totals. Test overflow, negative amounts, rounding remainders, date boundaries and migration behavior before adding related features. No currency or accounting policy has been selected yet.

## Privacy and persistence

Begin with deliberate local data requirements; no storage technology is selected. Define protection, backup, retention, export and deletion semantics before saving sensitive records. No financial information in diagnostics by default. Future provider integrations must keep server secrets off the device. Sync and AI processing require separate ADRs and consent/threat-model reviews.

## Build and release

Bundle ID `com.vyuhika.projectlens`; iPhone only; iOS 17 minimum; Swift 6 mode. Generated Info.plist and launch screen keep configuration small. No signing team is committed. App icon, distribution signing, App Store metadata and privacy disclosures remain release work; this shell is not App Store ready.

CI uses `macos-26` with `/Applications/Xcode_26.6.app`, currently listed in GitHub's runner image documentation, and selects an available iPhone simulator dynamically. Local Xcode 27.1 builds provide newer SDK validation. Revisit the CI pin when runner images change. See https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md.
