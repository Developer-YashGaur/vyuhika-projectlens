# Foundation validation

## PR #4 CI keyboard/scrolling correction — 2026-10-27

Investigated GitHub Actions run `40539514406` (Xcode 26.6, iOS 26.5, iPhone 17 Pro). Its 34 unit tests and six existing UI tests passed; both new project workflows failed at the shared `scrollTo` helper's final reachability assertion while revealing `project.budget`.

The source helper chose an arbitrary first collection/scroll/table and performed full-container swipes immediately after typing the project name, without ending editing. The CI recording confirms that the keyboard remained open, budget stayed below the visible area and repeated swipes did not reveal it. The log then shows native `tap()` scrolling the same correctly identified field into view, entering the budget and completing the remaining workflow. This is keyboard-occluded test interaction, not a missing accessibility identifier, budget calculation or persisted-project defect. On a smaller local simulator, the same issue also prevented a pinned Save button from receiving a computed hit point while editing.

The fix uses the existing Hide Keyboard toolbar action, waits for keyboard nonexistence, then scopes gestures to named project/transaction forms or the project detail. It also ends editing before pinned saves. Reachability remains asserted with fail-fast XCTUnwrap; missing containers, keyboard dismissal and unreachable controls retain screenshots plus the accessibility hierarchy/target geometry. No fixed sleeps or increased timeouts were added to tests, no tests were disabled, and CI configuration/protection and finance code are unchanged. Both forms gained identifiers for their existing containers and keyboard action.

Isolation was checked in source: each test uses a fresh UUID-scoped DEBUG ledger; relaunch within that test retains its UUID intentionally. Both create workflows now assert the initial empty Projects state and exact typed budget. The CI failure happens before the first project save and is not caused by shared project data.

Local validation uses Xcode 27.1 / iOS 27.0:

- Both originally failing tests passed together on **iPhone 17e**, zero failures; `build/Phase3CIFixFocusedFinal.xcresult`, `build/phase3-ci-fix-focused-final.log`. An intermediate run revealed the additional pinned-save keyboard interaction, which was corrected before this passing rerun.
- **All 34 unit tests passed**, zero failures, completed `build/Phase3CIFixAllUnit.xcresult`, `build/phase3-ci-fix-all-unit.log`.
- **All eight UI tests passed in one complete run** on **iPhone 18 Pro**, zero failures; `build/Phase3CIFixAllUI.xcresult`, `build/phase3-ci-fix-all-ui.log`. This includes the two corrected workflows, existing finance CRUD/persistence, navigation, branding and accessibility-size Quick Add checks.
- `git diff --check` passed. No workflow, scheme, unit test, domain or persistence changes were made.

The exact Xcode 26.6/iOS 26.5 runtime is unavailable locally; the unchanged GitHub workflow validates that environment after the branch is pushed. Physical-device and manual accessibility release audits remain outside this test fix.


## Phase 3 projects, budgets and profitability — 2026-10-27

Branch: `feat/koshvya-project-finance`, based on fetched latest main `c18d245` (approved branding merge). Main is unchanged. Existing LedgerRepository/LedgerStore, transaction forms, branding, scheme and CI are reused; no dependency or backend was added.

### Passed locally

- **34 unit tests, zero failures**, finalized `build/Phase3FinalUnitTests.xcresult`, log `build/phase3-final-unit-tests.log`. Includes 14 existing ledger tests, 5 configuration/branding/contrast/motion tests and 15 project-finance tests. Coverage includes project CRUD/reload/archive/restore, validation and exact budget encoding, stable link/relink/unlink/rename, project deletion preserving transactions/totals, missing-link and currency guards, exact profitability versus budget consumption, over-budget profitable projects, schema-1 migration with unchanged transaction data and persistent project IDs, original-backup protection, corrupt/future schemas, concurrent project/transaction mutations, failed project disk writes and linked-transaction recalculation.
- **All 8 UI tests passed across runs**: six existing navigation/branding/income/expense/Quick Add/accessibility-size tests passed in `build/Phase3UITests.xcresult`; both new project tests passed on corrected rerun in `build/Phase3ProjectUITests.xcresult` (**TEST SUCCEEDED**). New workflows create/edit/archive/relaunch a project and create a linked expense, verify budget/profit, relaunch, then unlink in Money while retaining the amount. The initial full UI run failed only the two new tests because their helper searched scroll/table containers, whereas this iOS SwiftUI form uses a collection view. The helper was corrected to support all three and both failed tests were rerun successfully. No untouched clean full-suite pass is claimed for that first bundle.
- Final unsigned Release generic iPhone build: **BUILD SUCCEEDED**, `build/phase3-final-release.log`. Debug tests build app and both test targets. No special compiler flags or project/CI sandbox changes were required.
- Inspected the retained project-finance screenshot exported to `build/phase3-project-screenshots/`: readable stacked budget metrics, remaining INR 87.66 after INR 12.34 expense, native linked-entry/actions list and Neon Orbit styling.
- Project plist lint, shared-scheme XML and asset JSON parsing, CI shell syntax and `git diff --check` pass. Built Release Info.plist retains Koshvya display name, original bundle ID, phone-only family and AppIcon; both approved PNGs still match asset copies byte-for-byte.

Local toolchain: Xcode 27.1 (27A9275), iPhone 18 Pro simulator / iOS 27.0. Host access was approved for CoreSimulator/builds. SDK build-version, duplicate simulator accessibility-class, AppIntents metadata and transient invalid-frame warnings occurred without assertion failures in passing runs. No Xcode toolchain warning is treated as a test result.

### Remaining release verification

Minimum iOS 17 runtime, physical-device locked-file behavior, complete light/dark/large-text project review and manual VoiceOver/Increase Contrast/Reduce Motion audits are not claimed. Existing accessibility-size Quick Add and asset contrast/motion unit checks passed. Signing, privacy disclosures and App Store packaging remain release work. Schema migration retains a historical financial backup with no in-app restore/erase UI; see [project finance](project-finance.md) and SECURITY.md for retention and recovery limitations. GitHub CI uses the unchanged Xcode 26.6/macOS 26 workflow; its status is reported separately on the PR.


## Phase 2.1 approved branding — 2026-10-27

Branch: `feat/koshvya-approved-branding`, based on current `origin/main` (fetched and matched before publication). Main was not modified.

- Final simulator execution: **19 unit tests and 6 UI tests passed, zero failures**, recorded in `build/branding-final-tests.log`. Includes all existing ledger/finance/navigation tests, asset bundle metadata checks, Home logo assertions with empty/saved ledgers, accessibility-size Quick Add reachability and the installed Springboard icon. Xcode stalled after reporting passed suites while finalizing full-suite diagnostics; a finalized full-suite xcresult and clean process exit are not claimed. The initial 24-test run also passed its tests and stalled in diagnostics.
- Focused branding UI runs completed with **TEST SUCCEEDED**. `build/BrandingVisualFinal.xcresult` retains Home and iPhone Home Screen screenshots; exported images are in `build/branding-final-screenshots/`. Visually verified approved logo proportions, readable light-mode Home title and the approved installed Koshvya icon. Fixed the dark logo backing extending behind the navigation title during visual QA.
- Final unsigned Release generic iPhone build: **BUILD SUCCEEDED**, log `build/branding-release-final.log`. Built Info.plist selects AppIcon, display name Koshvya, unchanged bundle ID and iPhone-only family.
- Both approved PNGs are copied byte-for-byte into the asset catalog; original icon is 1024×1024 with no alpha, logo is 1448×1086 with alpha. Asset JSON parsing, project plist lint and `git diff --check` pass.
- Validation used Xcode 27.1 (27A9275), booted iPhone 18 Pro / iOS 27.0, with host access approved for builds and CoreSimulator. No sandbox workaround compiler flag was needed or committed. Runtime emitted SDK/build-version, duplicate simulator accessibility class and transient invalid-frame warnings; no test assertion failed.

Physical-device review, minimum-iOS 17 runtime validation, complete light/dark/VoiceOver audit, signing and App Store packaging remain release work. Historical blockers below describe earlier milestones; branding assets are now supplied and integrated.


## Koshvya local-finance milestone — current validation

Branch: `feat/koshvya-local-finance`, based on local main `ec711e7`. Work is isolated in `/tmp/koshvya-local-finance` because workspace Git metadata is read-only to the agent. Current remote main could not be fetched/verified. Foundation/navigation notes below are historical.

### Passed

- **14 new ledger tests executed, 0 failures**, using a temporary macOS SwiftPM harness that copies the production Domain/Transaction.swift, Persistence/LedgerRepository.swift, Persistence/LedgerStore.swift and LedgerTests.swift (only the test import is renamed). No package or dependency was added to the repository. Tests cover CRUD/reload, concurrent writes, validation, locale/precision, exact Decimal encoding and currency-separated totals, corrupt/future schemas, failed writes, published state and retry.
- Debug iPhone simulator **build-for-testing succeeded** for app, 18 unit tests and 5 UI tests; this compiles tests but does not execute them.
- Unsigned Release generic iPhone device **build succeeded**. Debug explicitly defines DEBUG for isolated UI-test ledgers; Release has no test-ledger override. Built Info.plist confirms Koshvya display name, unchanged bundle ID, iPhone-only family and iOS 17 minimum.
- Xcode object/source references, plist, asset JSON and shared scheme XML checks; existing CI YAML/shell syntax; `git diff --check`. CI scripts, workflow requirements and dependencies are unchanged.

Local iOS builds use Xcode 27.1 and command-only `OTHER_SWIFT_FLAGS='$(inherited) -disable-sandbox'` to let the SDK's State macro subprocess run inside the agent sandbox. No compiler sandbox flag is committed to project or workflow configuration. AppIntents metadata warnings are expected because the app has no AppIntents dependency.

### Blocked / not claimed

- Existing `bash scripts/ci-ios.sh` fails at CoreSimulator discovery with invalid/refused service connections. **0 iOS unit or UI tests executed in this session.** macOS ledger tests do not validate UIKit, native form interaction or iOS file-protection enforcement.
- No simulator screenshots, device/VoiceOver audit, minimum iOS 17 runtime pass or Xcode 26.6 CI pass is claimed. Run the unchanged workflow outside the sandbox, then check large text, light/dark, Reduce Motion, keyboard dismissal and locked-device storage behavior on device.
- App icon artwork is not supplied: the catalog slot is intentionally unassigned. See branding.md. App Store signing/privacy/packaging remain release work.
- GitHub authentication reports invalid/unavailable credentials and GitHub DNS access is restricted. Remote push, PR creation and CI verification depend on restoring host-terminal access; no remote success is claimed.


Validated locally on 2026-10-27 with Xcode 27.1 (27A9275), Swift 6.4 and iOS 27.1 SDK.

## Neon Orbit navigation milestone — latest follow-up

Implemented on `feat/neon-orbit-navigation` in `/tmp/projectlens-neon-orbit`, isolated from the original workspace. Original workspace main remains unchanged at `cda5758` (foundation). Local main and cached origin/main match that commit; **latest remote main could not be verified**. The workspace `.git` is read-only in this sandbox (`FETCH_HEAD: Operation not permitted`; feature-ref creation also denied), so a writable local clone was used. No remote history was overwritten.

### Implemented scope

Adaptive native Home/Money/Projects/Upcoming tabs with individual NavigationStacks, shared honest empty states, one Quick Add sheet presenter and four selectable preview-only entry types. Refined light/dark palette, scalable typography, surface/elevation tokens, safe-area action placement and reduced-motion-aware selection feedback. No forms, save operation, financial models, persistence or networking were added.

### Validation results

- Standard generic simulator build reaches Swift compilation but Xcode 27's `@State` macro subprocess fails with `sandbox-exec: sandbox_apply: Operation not permitted`. This is a nested compiler sandbox failure, not evidence of a Swift source error.
- The following **command-only** compiler workaround permits validation; no compiler flag or sandbox relaxation was committed to project/CI configuration:

```bash
xcodebuild -project ProjectLens.xcodeproj -scheme ProjectLens \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO \
  'OTHER_SWIFT_FLAGS=$(inherited) -disable-sandbox' build-for-testing
```

- With that workaround: **TEST BUILD SUCCEEDED**, app and both test targets compiled for arm64 and x86_64 simulators. AppIntents metadata warnings are benign; no AppIntents integration exists.
- `bash scripts/ci-ios.sh`: **blocked at CoreSimulator discovery; zero unit or UI tests executed**. No runtime test pass, screenshot, VoiceOver audit or visual QA is claimed. Existing workflow and CI configuration were retained.
- Asset JSON parsing, static contrast calculations, Xcode project plist/reference checks, shared scheme XML, shell syntax and `git diff --check` pass. Across primary/secondary text and violet/cyan/lime on both surfaces in both appearances, lowest computed contrast is **5.05:1**. White action labels also exceed 4.5:1.
- Added compiled unit coverage for resolving the actual light/dark asset palette and contrast, plus Reduce Motion animation policy. UI tests cover all tabs, Quick Add selection, repeated presentation, native dismissal, selection reset and reachability at accessibility text size. Execution remains pending.
- Before release: run the unchanged workflow outside this sandbox, verify small/large iPhones and landscape, both appearances, VoiceOver, Increase Contrast, Reduce Motion and the minimum iOS 17 runtime. Local validation used Xcode 27.1; the Xcode 26.6 CI baseline remains unexecuted for this change.

### GitHub handoff

GitHub DNS resolution still fails for github.com; `gh auth status` reports invalid authentication but cannot establish credential validity without API access. Feature push and PR creation cannot complete in this session. CI status is **unknown**, not passed. No branch protection was modified or bypassed. Publication requires fetching current main and reviewing/reconciling any intervening changes before pushing. Foundation publication notes below are historical and do not describe current local Git state.

## Passed

- `plutil -lint ProjectLens.xcodeproj/project.pbxproj`.
- `xcodebuild -list -project ProjectLens.xcodeproj`: app, unit tests, UI tests and shared ProjectLens scheme found.
- `xcodebuild -project ProjectLens.xcodeproj -scheme ProjectLens -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build-for-testing`: app and both test targets compiled successfully for arm64 and x86_64 simulators. This compiles tests; it does not execute them.
- Built application plist: display name ProjectLens, bundle ID com.vyuhika.projectlens, minimum iOS 17.0, phone device family [1], generated launch screen present.
- Xcode object references and source paths resolve; shared scheme XML parses; CI shell syntax passes.
- Primary and secondary text contrast against both initial background/surface tokens exceeds 4.5:1 (lowest measured pair approximately 9.97:1).

## Environment blockers

`bash scripts/ci-ios.sh` stops at simulator discovery. CoreSimulator reports sandbox-denied log access, invalid/refused service connections, and a loaded/expected service version mismatch (1171.7 versus 1174.9.2). No unit or UI test execution, visual inspection, VoiceOver audit or minimum-iOS runtime validation succeeded. Run the script outside this restricted session with a working iPhone simulator; restart/update simulator services if the version mismatch persists.

The initial preview macro could not start its plugin in this environment; the checked-in view uses a macro-free PreviewProvider. A missing Debug testability setting was corrected before the successful test build. AppIntents metadata extraction reports a benign warning because the app has no AppIntents dependency.

## Publication status

- Empty workspace at start; no existing files or Git history were overwritten.
- Git identity is configured. `gh auth status` reports an invalid credential for Developer-YashGaur, but actual credential validity cannot be established while API access fails.
- `gh repo view Developer-YashGaur/vyuhika-projectlens` cannot reach the API; direct curl reports DNS resolution failure for api.github.com. Repository existence is **unknown**, not confirmed absent.
- Apache-2.0 was explicitly approved and added.
- No Git repository, commit, remote repository, push, branch rule or ruleset was created because publishing prerequisites remain unresolved.

## Resume release work

1. Restore working GitHub authentication and API connectivity; run simulator tests successfully.
2. Inspect `Developer-YashGaur/vyuhika-projectlens` and its default branch/history. If it exists, reconcile non-destructively; never overwrite or force-push.
3. If absent, initialize local main, review the exact staged file list, commit using `chore: initialize iOS foundation`, create the public repository and push main.
4. Require PRs and the actual `build-and-test` job status check after its first successful run; block force pushes and branch deletion, and require resolved conversations. Zero approvals may be appropriate while there is only one maintainer. Enable private vulnerability reporting. Record any permission or plan limitations rather than claiming protection is active.

Publication is not App Store distribution readiness. App icon, signing, privacy disclosures, minimum-runtime testing and device accessibility verification remain separate release work.

## Phase 0 blocker follow-up — 2026-10-27

Only this validation document changed in the follow-up. Application source, project configuration, CI and tests were preserved.

### Simulator diagnosis

- `xcode-select -p` selects `/Applications/Xcode.app/Contents/Developer`; `xcrun --find simctl` resolves under that same Xcode. `xcodebuild -version` reports Xcode 27.1 (27A9275). No command-line tools mismatch was found.
- `xcrun simctl list runtimes` and `xcrun simctl list devices available` both fail with `CoreSimulatorService connection became invalid`, `Connection refused` and `Operation not permitted` opening the user's simulator log. Process inspection (`ps`) is also sandbox-denied.
- Smallest safe isolation attempt: created an empty ignored `build/DiagnosticDevices` directory and ran `xcrun simctl --set "$PWD/build/DiagnosticDevices" list runtimes`. It fails with the same XPC/service errors. A writable device-set location does not resolve service access. No existing devices were changed, reset or deleted; no global Xcode setting or service was modified.
- `/Library/Developer/CoreSimulator/Images/images.plist` contains empty `images` and `standaloneBundles` arrays; the Volumes directory is empty and no legacy Profiles/Runtimes directory exists. No mounted runtime was observable. This is not an authoritative available-runtime inventory while CoreSimulator is unreachable.
- `xcodebuild -showdestinations` offers only generic iOS/device simulator placeholders, no concrete simulator. Its default log-directory access is also denied. The earlier loaded-service version mismatch remains a possible additional host-service issue; the follow-up cannot distinguish that from sandbox service isolation conclusively.
- Re-ran the existing `bash scripts/ci-ios.sh`: **blocked at simulator discovery; zero unit/UI tests executed**. Log: ignored `build/phase0-tests.log`.
- Re-ran the existing generic simulator `build-for-testing` command above using workspace-local DerivedData: **TEST BUILD SUCCEEDED**. Log: ignored `build/phase0-build.log`. Project plist validation also passes. The observed launch/test blocker is environmental, not a project compilation failure; runtime behavior remains unverified.

### GitHub and publication diagnosis

- No local `.git` exists; `git status` and `git remote -v` report that the directory is not a Git repository. No commit or remote was created.
- `dscacheutil` returns no host records for github.com or api.github.com; `scutil --dns` reports `No DNS configuration available` in this session.
- Both HTTPS probes fail with curl exit 6 (`Could not resolve host`) before TCP/TLS or authentication. This proves DNS failure in this execution environment, not a GitHub HTTPS rejection. Whether the normal host terminal has the same failure remains unverified.
- `gh auth status` reports an invalid credential for Developer-YashGaur. No token was requested, printed or changed. Do not interpret this as a verified GitHub credential rejection until connectivity works.
- `gh repo view Developer-YashGaur/vyuhika-projectlens --json nameWithOwner,url,visibility,defaultBranchRef` fails to reach api.github.com; `git ls-remote https://github.com/Developer-YashGaur/vyuhika-projectlens.git` fails DNS. Repository existence, public visibility, history and protections remain **unknown**.
- Apache-2.0 owner approval remains in force. LICENSE contains the full terms including patent grant, and NOTICE identifies Vyuhika. Representative build, signing-key, environment-file, local-credential and database paths were checked against `.gitignore` using a temporary Git index outside the workspace; all were excluded. The publishable inventory contains only foundation source, configuration and documentation. A filename-only scan found no common GitHub/AWS credential or private-key markers; this is not an exhaustive secret audit.
- Publication and protection configuration remain blocked. No success URL or commit hash exists. Sandbox escalation is disabled in this session; host service/network changes cannot be performed here.

### Exact checks in a normal VS Code terminal

Run outside the restricted agent terminal:

```bash
cd /Users/developer_yash_gaur/Projects/vyuhika_lens
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcode-select -p
xcodebuild -version
xcrun simctl list runtimes
xcrun simctl list devices available
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app
bash scripts/ci-ios.sh
```

The export applies only to this shell and does not change global command-line tools selection. If no usable iOS runtime exists after service access works, install it using Xcode Settings → Components, then rerun discovery and tests. If the earlier service-version mismatch persists outside the sandbox, quit Xcode/Simulator normally and reopen them; if still unresolved, restart macOS when convenient. Do not erase devices or switch global developer directories as a first response.

```bash
dscacheutil -q host -a name github.com
dscacheutil -q host -a name api.github.com
curl -I --connect-timeout 8 --max-time 12 https://github.com
curl -I --connect-timeout 8 --max-time 12 https://api.github.com
gh auth status
```

If DNS/HTTPS work here but fail in the agent session, that isolates the network restriction to the agent execution environment. If they also fail here, resolve host DNS/network/VPN connectivity before attempting authentication. Only if authentication still fails after connectivity works, use browser login:

```bash
gh auth login --hostname github.com --web --git-protocol https
gh auth status
```

After working authentication, inspect the repository before any mutation:

```bash
gh repo view Developer-YashGaur/vyuhika-projectlens --json nameWithOwner,url,visibility,defaultBranchRef
git ls-remote --symref https://github.com/Developer-YashGaur/vyuhika-projectlens.git HEAD
git ls-remote --heads --tags https://github.com/Developer-YashGaur/vyuhika-projectlens.git
gh api 'repos/Developer-YashGaur/vyuhika-projectlens/commits?per_page=20' --jq '.[] | [.sha, .commit.message] | @tsv'
```

An API/network/auth error is not proof that the repository is absent. If it exists, inspect its visibility and full relevant history and reconcile deliberately; do not run the new-repository commands below against an existing remote.

Only after tests pass and repository absence is confirmed under working authentication, these commands initialize and publish this foundation (stop if any command fails):

```bash
git init -b main
git add .gitignore .github README.md CONTRIBUTING.md SECURITY.md CHANGELOG.md LICENSE NOTICE ProjectLens.xcodeproj ProjectLens ProjectLensTests ProjectLensUITests docs scripts
git diff --cached --check
git diff --cached --stat
git diff --cached
# Review the staged files above before committing.
git commit -m "chore: initialize iOS foundation"
gh repo create Developer-YashGaur/vyuhika-projectlens --public --source=. --remote=origin --push
gh repo view Developer-YashGaur/vyuhika-projectlens --json url,visibility,defaultBranchRef
git rev-parse HEAD
gh run list --repo Developer-YashGaur/vyuhika-projectlens --workflow ios.yml --limit 5
```

After the first successful CI run, inspect the actual check name and configure protection under Repository Settings → Branches/Rulesets for main: require PRs, the `build-and-test` check, up-to-date branches and resolved conversations; block force pushes and deletions. Zero required approvals allows a solo maintainer to merge. Record permission/plan limitations if GitHub rejects configuration. Protection has **not** been applied or verified here.
