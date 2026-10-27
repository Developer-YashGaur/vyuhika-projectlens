# Foundation validation

Validated locally on 2026-10-27 with Xcode 27.1 (27A9275), Swift 6.4 and iOS 27.1 SDK.

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
