# Reapplying setup to the latest published environment

The new instance preserved the newer watchweeks.com allowlist addition; API GETs
now work. It restored main (README-only) rather than the development branch, and
lost prior helper files and uncommitted changes. The pushed development branch was
fetched explicitly. Bootstrap tooling was rebuilt and tests rerun.

The draft read endpoint still returns INVALID_ARGUMENT: “current environment draft
could not be verified,” including after retries. Therefore newer script contents
cannot be inspected or merged, and draft persistence cannot be confirmed. No newer
network/repository/secret settings were replaced. There is no confirmed conflict,
but blindly replacing unknown newer script text would not preserve it.

When draft access is restored, merge the following with existing newer instructions:

install_script: `cd /workspace/watchweeks-ios && scripts/cloud-bootstrap.sh`

start_skill: Use the existing isolated /workspace/watchweeks-ios checkout; do not
create worktrees unless explicitly requested. Inspect git status/origin/branch and
preserve changes. Continue dedicated iOS development branch, never the production
website. Run scripts/cloud-bootstrap.sh if tooling is absent, then scripts/swift-linux
test --jobs 4 and python3 scripts/validate-source.py. No service needs startup.
Read docs/STATUS.md, FEATURE_PARITY.md, ANALYTICS.md and MAC_HANDOFF.md. iOS builds,
simulator, signing and upload require stable Xcode 26+ on macOS. Verify public
feed read access without credentials; never modify website data. Replay stays off
for v1; verify native analytics consent and privacy on Mac. No Apple submission
or publication without explicit owner approval.

Only watchweeks.com is needed for current API read probes. Swift/container/package
sources use existing package-manager presets. PostHog ingestion on Mac needs
us.i.posthog.com; cloud transport tests may need a specific domain addition later.
Do not broaden networking or request credentials merely to populate setup fields.
