# WatchWeeks remote signed builds — Xcode Cloud

Status: repository prepared; Apple/GitHub authorization, workflows, cloud signing,
compute allowance and one successful signed upload are NOT verified or activated.
No Apple remote workflow was created, run or billed by this commit. This document
uses the existing app: com.watchweeks.app, App Store Connect ID 6832395283.

## Why this service

Apple runs macOS/Xcode and manages cloud signing. The owner can use Codex Cloud
and GitHub from iPad Safari; no traveling Mac or exported signing private key is
required after a successful setup rehearsal. Existing public production app remains
unchanged until a separate, explicitly approved release. Uploading a build does not
submit it to App Review or publish it. Never automate those last steps here.

Xcode Cloud generally includes 25 compute hours/month with paid Developer Program
membership. Verify the actual plan and remaining allowance in App Store Connect
before starting. Choose included allowance only, never purchase/upgrade implicitly.
Manual promotions avoid building on every development commit. Allowance and limits
are Apple configuration; this shell script cannot enforce the account billing plan.

## One-time setup before travel (Codex on the Mac should own this)

1. Fetch `ci/xcode-cloud` and inspect its diff against the current development HEAD.
   Bring over only ci_scripts/ci_post_clone.sh and release/REMOTE_BUILDS.md; preserve
   uncommitted Mac work and newer changes. Do not reset or replace the app.
2. Confirm paid team access, existing bundle ID and shared WatchWeeks scheme.
   In Xcode use Integrate > Create Workflow (or the Cloud tab in the report
   navigator). Select the existing WatchWeeks app/team. Owner signs in
   securely, accepts any service terms personally and authorizes GitHub access only
   to rreibstein/watchweeks-ios when Apple requests it. Use Apple's supported
   connection, not a token or certificate pasted into chat.
3. Verify the selected compute plan is included/authorized. Select a stable Xcode
   26+ environment compatible with the project's Swift version and current upload
   requirements. Use latest appropriate stable runtime, not beta by default.
4. Configure the TWO workflows below. Apple stores configuration in its service;
   these instructions and scripts alone do not create it. Verify UI options in the
   actual account rather than inventing workflow YAML.

### Workflow A — WatchWeeks Verify

Source: dedicated `ci/cloud-candidate` branch, created by a normal push of a selected
source commit. Restrict branch-change triggers to this branch, not every edit on
development/native-launch. One iPhone simulator destination, not a device matrix.
Action: Test, WatchWeeks shared scheme, Debug configuration. No distribution or
archive/upload actions. ci_post_clone.sh must execute source/core checks before
Xcode's own build/UI tests. Default UI smoke runs without WW_CAPTURE. The optional
live-data tests are separate acceptance work; skipped tests must not be reported
as passed. Do not enable live Singapore-specific tests blindly after dates change.

### Workflow B — WatchWeeks Upload

Source: dedicated `release/cloud-upload` branch. Owner/Codex promotes ONLY the exact
commit that passed Verify after inspecting its results; never promote a newer tip
by assumption. Restrict branch triggers to this branch. Action: Archive,
WatchWeeks scheme, Release, iOS/App Store distribution using Apple cloud-managed
signing for the correct team and com.watchweeks.app. Post-action: TestFlight internal
testing, to the owner's internal tester group only. Use App Store distribution
preparation for the archive so the same processed build can later be selected for
review. The archive option named TestFlight (Internal Testing Only) limits reuse. Do not auto-submit for review,
enable external distribution, or release publicly. Internal testers need the proper
App Store Connect role. External TestFlight testers may require Beta App Review.

Keep these workflows separate: Test and Archive actions within one Xcode Cloud
workflow can run in parallel, so an archive's existence does not prove UI tests
passed. Verify results first, then deliberately promote that SAME SHA for upload.
The archive still reruns source/core checks through ci_post_clone.sh.

### Build numbers and package state

The live iOS app is 1.0 and App Store Connect showed only the 1.0.0 build train,
with builds 1 through 4, on November 10, 2026. The rehearsal candidate is 1.0.1.
Check the build train again before uploading if another operator may have added
a build.

Apple's cloud build number must exceed already uploaded numbers for the selected
marketing version. Check the existing ASC build list and set the next cloud build
number appropriately using service settings where available. Inspect the first
archive's actual CFBundleShortVersionString/CFBundleVersion and processed ASC build;
use the number shown by Xcode Cloud, which can differ from the local number. Keep version
increment intentional and preserve App Store Connect history. If Xcode Cloud's
numbering/setup needs a project adjustment, have local Codex make and validate it
before relying on the pipeline. Do not put personal team credentials into Git.

## Rehearsal — mandatory before leaving the Mac behind

- Run Verify on the intended source SHA and inspect all action results.
- Promote the identical source SHA to Upload only after Verify succeeds.
- Confirm automatic signing and the correct team/bundle/version/build in archive.
- Confirm build processing completes in the EXISTING WatchWeeks ASC app.
- Confirm the owner can access both workflows, logs and processed build in iPad Safari.
- Install through TestFlight on available Apple devices and check real data,
  persisted existing selections and upgrade behavior. Try iPad TestFlight now;
  iPhone-only compatibility on that iPad must be demonstrated, not promised. It
  does not replace physical-iPhone QA. A simulator run is not a device run.
- Do NOT submit or publish as part of rehearsal. One successful signed upload and
  processed build—not just a green compile—is the readiness criterion.
- Resolve any compute allowance, GitHub authorization, cloud signing, agreements,
  numbering or processing failure while a Mac remains available.

## While in Singapore — iPad alone

1. Open this Codex Cloud project in Safari. Work on the dedicated iOS repository;
   cloud editing needs no local Mac. Read latest pushed source; do not assume local
   Mac changes were pushed. Make one small change and commit/push it for verification.
2. Explicitly promote the chosen source commit to ci/cloud-candidate; watch Workflow A
   in App Store Connect > WatchWeeks > Xcode Cloud. Codex can inspect available logs
   when authorized; without Apple API access, owner supplies exact results/errors.
   No background monitoring is implied by these scripts.
3. If Verify passes, promote that exact SHA to release/cloud-upload with an ordinary
   fast-forward Git push. No force pushes. If branch history diverged, stop and
   reconcile rather than rewriting it. Cloud creates signed archive/internal upload.
4. On iPad, confirm TestFlight processing, install if supported, inspect changes,
   then complete the new version's metadata/privacy/review notes in ASC Safari.
5. Present exact build/SHA, privacy, territories/seller and remaining QA limits to
   owner. Only explicit approval permits App Review submission. Manual public
   release requires owner authorization as well. Existing public build remains live.

## Failure recovery and limits

Read test/build/signing/processing logs rather than retrying unchanged failures.
Codex Cloud can patch source and rerun with deliberate branch promotions within
allowance. Apple login, agreements, expiring account access and service outages may
require owner action; no pipeline removes those dependencies. iPad-only review is
less complete than physical-iPhone QA. Avoid major auth, data migration, replay or
new-permission releases when no suitable device is available for testing.

There is no GitHub Actions signing-key export, App Store Connect private API key,
remote-control service, public review submission or automatic publication in this
setup. Additional automation can be added later with separate authorization.

## Ready-to-paste instruction for local Mac Codex

Set up and rehearse Xcode Cloud using release/REMOTE_BUILDS.md and the ci/xcode-cloud
preparation branch. Preserve newer local work. You may prepare repository changes
and guide secure Apple/GitHub connection. Verify included compute allowance before
running; never buy a plan. Configure separate Verify and Upload workflows, verify
one signed processed internal TestFlight build, and prove access from my iPad. Do
not submit for App Review or publish. Handle technical troubleshooting and ask me
only for secure account authorization, required terms, expenditure, or essential
owner decisions. Report exact source SHA, workflows, test results, build number,
processing status, costs/allowance and any blocker. Do not call it ready until the
signed-upload rehearsal succeeds.
