# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Simulator Setup

The test runner (`ci_scripts/run_tests.rb`) handles simulator setup automatically. The project requires an iPhone 12 mini with iOS 16.4 for consistent screenshot tests.

**If simulator issues occur**, clear the cache and retry:
```bash
./ci_scripts/setup_simulator.sh --clear-cache
```

## Build Commands

### Test Runner

`ci_scripts/run_tests.rb` is the primary way to run tests locally. It handles simulator setup, scheme resolution, and xcodebuild invocation.

```bash
# Run a single test (scheme is inferred from the target name)
ci_scripts/run_tests.rb --test StripeCoreTests/URLEncoderTest/testQueryStringFromParameters

# Run all tests for a specific scheme
ci_scripts/run_tests.rb --scheme StripePaymentSheet

# Run all framework tests
ci_scripts/run_tests.rb --all

# Record snapshot reference images (tests will fail during recording)
ci_scripts/run_tests.rb --record-snapshots --test StripePaymentSheetTests/SomeSnapshotTest

# Record network responses (tests will fail during recording)
ci_scripts/run_tests.rb --record-network --test StripePaymentsTests/STPCardFunctionalTest

# Run UI tests
ci_scripts/run_tests.rb --ui

# Retry flaky tests (up to 5 times)
ci_scripts/run_tests.rb --scheme StripeCore --retry

# Preview the xcodebuild command without executing
ci_scripts/run_tests.rb --scheme StripeCore --dry-run

# Build without running tests
ci_scripts/run_tests.rb --scheme StripePaymentSheet --build-only

# Inspect failures from the last test run
ci_scripts/run_tests.rb --failures

# Inspect failures from a specific xcresult bundle
ci_scripts/run_tests.rb --failures /path/to/result.xcresult

# Use a custom result bundle path
ci_scripts/run_tests.rb --scheme StripeCore --result-bundle-path /tmp/my-results.xcresult

# Full usage
ci_scripts/run_tests.rb --help
```

### Inspecting Test Failures

When tests fail, the runner saves an xcresult bundle and prints an inspection hint. Use `--failures` to get a structured summary:

```bash
ci_scripts/run_tests.rb --failures
```

This prints:
- Test summary with pass/fail/skip counts
- Failure messages for each failed test
- Re-run commands for each failed test
- Paths to exported failure screenshot attachments

**For Claude Code**: after a test failure, run `--failures` and use the Read tool to view any exported screenshot paths. Analyzing the screenshots alongside the failure messages helps determine root cause (e.g. snapshot mismatches, unexpected UI state).

### CI Commands (Fastlane)

These are used by CI and can also be run locally:
- **Run main tests**: `bundle exec fastlane stripeios_tests`
- **Run StripeConnect tests**: `bundle exec fastlane stripeconnect_tests`
- **Run all integration tests**: `bundle exec fastlane integration_all`
- **Run 3DS2 tests**: `bundle exec fastlane threeds2_tests`

### Manual xcodebuild

When you need raw xcodebuild commands, always source the simulator setup first and suppress warnings for test targets:
```bash
source ci_scripts/setup_simulator.sh && xcodebuild test \
  -workspace Stripe.xcworkspace \
  -scheme StripePaymentSheet \
  -destination "id=$DEVICE_ID_FROM_USER_SETTINGS,arch=arm64" \
  -quiet SWIFT_SUPPRESS_WARNINGS=YES SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
```

## Code Quality

### Code Formatting and Linting
The project has an automated hook (`.claude/settings.json`) that runs format and lint checks before every git commit or push. This ensures code quality standards are maintained automatically.

If you need to run these checks manually:
- **Format modified files**: `ci_scripts/format_modified_files.sh`
- **Lint modified files**: `ci_scripts/lint_modified_files.sh`

**Branch Requirements**: If you are on the `master` branch, you MUST check out a new branch before making commits.

### Filing PRs
When using the GitHub `gh` command, ALWAYS set `GH_HOST=github.com`. For example: `GH_HOST=github.com gh pr create --title [...]`

## Project Architecture

### Module Structure
The Stripe iOS SDK is organized as a multi-module framework with clear dependency hierarchies:

**Core Dependencies:**
- `StripeCore` - Foundational networking, utilities, analytics
- `StripeUICore` - Shared UI components and themes
- `Stripe3DS2` - 3D Secure 2.0 authentication

**Payment Modules:**
- `StripePayments` - Core payment APIs (depends on StripeCore, Stripe3DS2)
- `StripePaymentsUI` - Payment UI components (depends on StripePayments, StripeUICore)
- `StripePaymentSheet` - Prebuilt payment flow (depends on StripePaymentsUI, StripeApplePay). (This is the main product we work on.)
- `StripeApplePay` - Apple Pay integration (depends on StripeCore)

**Specialized Modules:**
- `StripeIdentity` - Identity verification (depends on StripeCore, StripeUICore, StripeCameraCore)
- `StripeFinancialConnections` - Bank account linking (depends on StripeCore, StripeUICore)
- `StripeConnect` - Connect embedded components (depends on StripeCore, StripeUICore, StripeFinancialConnections)
- `StripeCardScan` - Card scanning functionality (depends on StripeCore)

**Legacy Stripe Module:**
- `Stripe` - Legacy umbrella framework including most modules plus additional issuing features.

### Key Workspaces and Projects
- **Main workspace**: `Stripe.xcworkspace` - Contains all modules and examples
- **Individual projects**: Each module has its own `.xcodeproj`
- **Test configurations**: Located in `BuildConfigurations/` directories

### Package Manager Support
- **Swift Package Manager**: Defined in `Package.swift` with iOS 13+ minimum deployment
- **CocoaPods**: Individual `.podspec` files for each module

## Development Workflow

### Requirements
- Xcode 15+ required
- iOS 13+ minimum deployment target
- Bundle/Fastlane for automation

### Testing Strategy
- Comprehensive unit tests for each module in corresponding `*Tests/` directories
- Snapshot tests for UI components using FBSnapshotTestCase
- Integration tests with real backend APIs (marked as functional tests)
- Example apps for manual testing in `Example/` directory

### Dependencies Installation
Run `bundle install && bundle exec fastlane stripeios_tests` initially to install test dependencies.

### Special Testing Notes
- Legacy iOS versions: Separate fastlane lanes for iOS 13-16 compatibility testing
