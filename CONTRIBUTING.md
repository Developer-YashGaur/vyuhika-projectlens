# Contributing

This repository is an early engineering foundation. Discuss larger changes before implementation. Keep pull requests small, use Conventional Commits (for example `chore: initialize iOS foundation`), explain the outcome and record relevant checks.

Use native SwiftUI and existing platform APIs. Add dependencies only for a demonstrated need. Put financial rules in Domain and keep storage/network concerns outside those rules. Use explicit currency and rounding semantics; test allocation, precision and boundary cases before implementing money calculations. Never use binary floating point for financial values.

Run `bash scripts/ci-ios.sh` with an installed iPhone simulator before opening a pull request. Verify Dynamic Type, VoiceOver, contrast, Reduce Motion and light/dark system appearances for changed UI. Never commit real financial records, credentials, generated build output or signing files.

Contributions intentionally submitted for inclusion are under Apache-2.0, as described in LICENSE. No CLA or additional contribution agreement is established.

After publication, maintainers should require the `iOS / build-and-test` check, pull requests, resolved conversations, and block force pushes/deletions on main. A solo maintainer may use zero required approvals initially. These settings are planned, not currently applied.
