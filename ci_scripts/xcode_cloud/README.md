# Xcode Cloud CI

These hooks replace the critical Bitrise checks with native Xcode Cloud Test,
Build and Analyze actions. Configure the actions in App Store Connect after
pushing this branch. Xcode Cloud reports the native tests, failures, screenshots
and downloadable `.xcresult` bundles itself.

## Quick setup

1. Use the repository's **`Stripe.xcworkspace`**, not an individual example's
   project. If this product hasn't used Xcode Cloud before, connect it from Xcode
   first; existing products can add workflows in App Store Connect.
2. Pin **Xcode 26.4** and a compatible macOS image. Choose explicit simulator
   versions from the destinations Apple offers; do not select “Latest” for
   snapshot verification. Check the available destinations before making a
   workflow required.
3. Add the environment variable **`STRIPE_XCODE_CLOUD_CI=1`** to each new workflow.
   This opts into the new hooks; leave it unset on existing release/TestFlight
   workflows. Workflow names are arbitrary.
4. Add Pull Request Changes and `master` Branch Changes start conditions. Leave
   test and analyzer actions **Required to Pass**. Xcode Cloud already builds the
   merge with the PR's destination; the scripts do not merge or push commits.
5. Start a manual build on this branch. Confirm that the actions below appear,
   test counts are nonzero, and all four PaymentSheet shards ran. Once green,
   update GitHub branch protection to require the new Xcode Cloud checks and
   remove the unavailable Bitrise requirements.

Native Test actions build for testing automatically; they do not need an extra
Build action. Separate actions run in separate environments. You can put several
actions in one workflow or split them into workflows for scheduling and clearer
required checks.

## Framework and E2E tests

Set `STRIPE_CI_TASK=tests` (the default). Add the following **iOS Test** actions.
Select the named plan where shown, otherwise choose **Use Scheme Settings**.

| Scheme | Test plan | Coverage |
| --- | --- | --- |
| `FrameworkTests-CI` | Scheme settings | Payments, PaymentsUI, CameraCore, Core, Connect, Identity, FinancialConnections, FinancialConnectionsLite, CardScan, ApplePay, UICore |
| `StripeiOS` | `StripeiOSTests` | Legacy Stripe framework and its E2E tests; retains existing exclusions |
| `StripePaymentSheet` | Scheme settings | All PaymentSheet tests, including the full LPM confirmation class |
| `StripeIssuing` | `StripeIssuingTests` | Issuing tests |
| `StripeCryptoOnramp` | Scheme settings | Crypto framework tests |
| `Stripe3DS2` | Scheme settings | 3DS2 unit tests |
| `PaymentSheet Example` | `PaymentSheet Example-Shard1` | PaymentSheet UI shard 1 and localization screenshots |
| `PaymentSheet Example` | `PaymentSheet Example-Shard2` | PaymentSheet UI shard 2 |
| `PaymentSheet Example` | `PaymentSheet Example-Shard3` | PaymentSheet UI shard 3 |
| `PaymentSheet Example` | `PaymentSheet Example-Shard4` | All remaining PaymentSheet UI tests, including new tests |
| `StripeConnect Example` | `StripeConnectExample` | Connect UI tests |
| `CryptoOnramp Example` | `CryptoOnrampExampleUITests` | Crypto UI tests |
| `IntegrationTester` | `IntegrationTester` | Integration UI tests |

Use **iPhone 12 mini / iOS 16.4** for the framework and PaymentSheet/Connect/Crypto
actions if Xcode Cloud offers it with the selected Xcode image. Bitrise ran
IntegrationTester on **iPhone 12 mini / iOS 26.4.1**; give it a separate workflow
if necessary. Existing backend and network-stub configuration stays in the
schemes, test plans and tests. These hooks need no new service credentials.
Live E2E tests still depend on the test backend being reachable.

All four PaymentSheet shards are required. If the workflow editor doesn't allow
repeated actions for the same scheme, make four workflows with the corresponding
plans. Alternatively, one action selecting `PaymentSheet Example` runs the full
unsharded plan; do not also run the shards. The hooks apply Bitrise's maximum of
two attempts to failed tests. Existing per-target parallelization stays intact;
Xcode Cloud controls worker allocation.

### Runtime availability and snapshots

The default `STRIPE_CI_SNAPSHOTS=verify` compares snapshots and fails on missing
references or differences. It requires **iPhone 12 mini / iOS 16.4 or iOS 26.4.1**,
the destinations used to record the current baselines. This is stricter than
Bitrise's workflow that automatically committed updated images.

If Apple doesn't offer iOS 16.4, set **`STRIPE_CI_SNAPSHOTS=skip`** for the main
behavioral-test workflows and select an available runtime, such as iOS 18.5.
This explicitly excludes snapshot classes while keeping unit, network-stub,
integration and UI tests. It is a coverage reduction: old-runtime snapshots and
iOS 16 compatibility are not verified by those workflows. Do not try to install
Bitrise runtimes with `sudo`; Xcode Cloud doesn't provide administrator access.

Create a separate snapshot workflow with `STRIPE_CI_SNAPSHOTS=verify` and a Test
action for **`AllStripeFrameworks-iOS26`**, plan **`AllStripeFrameworks-iOS26`**,
on **iPhone 12 mini / iOS 26.4.1**. The post-clone hook regenerates selections from
the `// @iOS26` annotations. This covers the annotated snapshot and behavioral
tests; it does not replace all older-runtime snapshots. If that exact destination
is also unavailable, snapshot parity requires separately recording and reviewing
baselines on an available destination before extending the runtime check.

For full older-runtime snapshot coverage, also add **`Stripe3DS2DemoUI`** with
Scheme Settings on iOS 16.4. The other snapshot classes run with the framework
actions above when verification is enabled.

The checked-in `ci_scripts/xcode_cloud/ReferenceImages_64` symlink makes the
baseline images available on the separate test worker. The pre-xcodebuild hook
updates test-product `.xctestrun` environments with the worker's reference path.
The Swift and Objective-C snapshot helpers compare only when that environment
variable is present, preserving existing local/Bitrise recording behavior.
New or changed snapshots must be recorded and reviewed using the existing
`ci_scripts/record_snapshots.rb` workflow.

## Quality, builds and static analysis

Create a workflow with `STRIPE_CI_TASK=quality` and one **Build** action for
`StripeiOS`, **Any iOS Simulator**. The post-clone hook installs Ruby 3.3 and the
locked Bundler/gems, then runs:

- Pinned SwiftLint against files changed by a PR, or tracked Swift files on a
  branch/manual build. The PR target commit is fetched if absent in the shallow
  checkout; failures to fetch or diff fail the check.
- Version consistency, PaymentSheet shard completeness and PNG format checks.
- Localization extraction/format/duplicate checks and generated Objective-C enum
  description consistency.
- Swift Package Manager manifest warning checks and CI script regression tests.

Use a **separate workflow with `STRIPE_CI_TASK=tests`** for these native actions,
so the quality checks aren't repeated for every build/analyzer action:

| Action | Scheme | Destination |
| --- | --- | --- |
| Analyze | `StripeiOS` | iOS Simulator |
| Analyze | `Stripe3DS2` | iOS Simulator |
| Build | `AllStripeFrameworks` | Any iOS Simulator |
| Build | `CardImageVerification Example` | Any iOS Simulator |
| Build | `UI Examples` | Any iOS Simulator |
| Build | `Non-Card Payment Examples` | Any iOS Simulator |
| Build | `IntegrationTester` | Any iOS Simulator |
| Build | `PaymentSheet Example` | Any iOS Simulator |
| Build | `AppClipExample` | Any iOS Simulator |
| Build | `StripeIssuing` | Any iOS Simulator |

Mark analyzers Required to Pass and review their diagnostics in the native build
report. The old shell analyzer's blanket grep for any warning is not reproduced.

## Package installation checks

Create a workflow with `STRIPE_CI_TASK=installation` and one **Build** action for
`StripeiOS`, **Any iOS Simulator**. The post-clone hook installs the locked gems
and builds app, extension and test targets for all five CocoaPods/SPM installation
fixtures. It also checks that the SPM Identity trait gates the media dependency.
These commands fail the workflow on errors and put diagnostics in the post-clone
log. They use generic simulator destinations and don't install runtimes.

This ports **installation build coverage**. The fixture's runtime asset and
analytics assertions are not executed here; native framework and E2E tests are
executed by the Test actions above. Native Test actions for the installation
workspaces can be added later if runtime package-installation parity is needed.

## Optional scheduled workflows and remaining gaps

- For nightly/release live-network tests, add `AllStripeFrameworks-NoMocks` as a
  Test action. Use the same snapshot/runtime rules as above. It is additional
  coverage, not a substitute for the main framework action list (which also
  includes Connect and Issuing).
- The Financial Connections stability scheme, `FinancialConnections Example`,
  can be a scheduled native Test action with Scheme Settings and
  `STRIPE_CI_SNAPSHOTS=skip`.
- Snapshot auto-commits, Lokalise uploads, size/latency comparison reports,
  documentation publication, release/deploy automation and downstream React
  Native triggers remain on their existing paths. They are not run by these
  verification workflows.
- Legacy-runtime matrices and podspec linting are not included. Keep the
  installation workflow required to retain the main package-consumer build gate.
- The Bitrise whole-run retry for a hung test runner is not ported; test failures
  get two attempts, and infrastructure failures require an Xcode Cloud rebuild.
- Hook-created files are not automatically downloadable Xcode Cloud artifacts.
  Native Test actions provide test products and results; custom quality and
  installation commands provide hook logs.

## Validation

Run the portable script regression tests with:

```sh
python3 -B -m unittest discover -s ci_scripts/tests -p xcode_cloud_test.py -v
ruby ci_scripts/tests/framework_architecture_validator_test.rb
ruby ci_scripts/check_paymentsheet_test_sharding.rb
```

The scripts have been validated on Linux, including source preparation, test
product rewriting and preserving shard selections. Xcode compilation, simulator
tests, the baseline symlink transfer, and native action configuration still need
the first Xcode Cloud build. On a Mac, use `ci_scripts/run_tests.rb` for focused
SDK validation as usual.

Apple references: [custom build scripts](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts),
[environment variables](https://developer.apple.com/documentation/xcode/environment-variable-reference),
[workflow actions](https://developer.apple.com/documentation/xcode/configuring-your-xcode-cloud-workflow-s-actions).
