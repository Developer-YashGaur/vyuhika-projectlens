# ProjectLens

Vyuhika's native iPhone foundation for a clearer view of projects and finances.

**Status:** engineering foundation only. The app shows a static, accessible placeholder; no financial tools, persistence, networking, analytics or cloud services are implemented. No sample balances are presented as user data.

## Development

- Open `ProjectLens.xcodeproj`, select the shared `ProjectLens` scheme and an iPhone simulator.
- Minimum deployment: iOS 17.0. Local toolchain verified: Xcode 27.1 / Swift 6.4; Swift 6 language mode. CI uses Xcode 26.6 on `macos-26` to validate a stable baseline.
- No third-party packages or project generator are required. The checked-in Xcode project is authoritative.
- Run `bash scripts/ci-ios.sh` to build and run unit/UI tests on an available iPhone simulator. Results: `build/TestResults-*.xcresult`.
- For a physical device, select your own signing team in Xcode. Credentials and signing assets must remain local.

## Structure

`ProjectLens/App` owns lifecycle; `Features` owns feature UI; `Shared/DesignSystem` owns Neon Orbit tokens. `Domain`, `Persistence`, and `Services` document intended boundaries without speculative protocols or implementations. `ProjectLensTests` and `ProjectLensUITests` cover app configuration and launch. See [architecture](docs/architecture.md), [PRD](docs/PRD.md), [design system](docs/design-system.md), and [ADR 0001](docs/decisions/0001-ios-first-architecture.md).

## Planned scope

Personal finance, project finance, subscriptions, budgets, invoices, cost allocation, release planning and financial intelligence. Future exploration includes sync, provider integrations, collaboration and AI-supported insights. These are plans, not shipped capabilities or delivery commitments.

## License

Copyright 2026 Vyuhika. Licensed under [Apache-2.0](LICENSE), approved by the project owner. This permits commercial reuse and proprietary forks, with an explicit patent grant and notice obligations. It does not grant trademark rights. Separate future cloud services may remain proprietary.

Publication is pending verified GitHub authentication, repository inspection and successful simulator tests. No public repository availability is claimed.
