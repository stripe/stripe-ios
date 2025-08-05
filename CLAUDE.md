# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Simulator Setup

Before running tests or builds, ensure you have the correct simulator configured. The project requires an iPhone 12 mini with iOS 16.4 for consistent screenshot tests.

### Automatic Simulator Detection

**IMPORTANT**: Always include a `source` call to the automated script at `source <(./ci_scripts/setup_simulator.sh) && [...]` to set up the simulator and use the correct device ID:

The script will:
1. Check for cached simulator ID in `.stripe-ios-config`
2. Validate the cached simulator still exists
3. Find existing iPhone 12 mini with iOS 16.4 or create a new one
4. Cache the result for future use

**If simulator issues occur**: Clear the cache and retry:
```bash
./ci_scripts/setup_simulator.sh --clear-cache
source <(./ci_scripts/setup_simulator.sh)
```

### Using the Device ID

You must ALWAYS use the device ID in build commands:
```bash
source <(./ci_scripts/setup_simulator.sh) && xcodebuild -workspace Stripe.xcworkspace -scheme "StripePaymentSheet" -destination "id=$DEVICE_ID_FROM_USER_SETTINGS,arch=arm64" -quiet
```

### Quick Setup Check

To verify the simulator is properly configured, run:
```bash
source <(./ci_scripts/setup_simulator.sh) && echo "✅ Simulator configured: $DEVICE_ID_FROM_USER_SETTINGS"
```

## Adding new files
If you create a new file, it MUST be added to the `.xcodeproj`. There is no reasonable way to do this on your own, you MUST ask the user to add the file manually before continuing.

Ask the user to add the file to the `.xcodeproj`. Once they've completed this task, you can continue making progress.

## Build Commands

### Core Testing Commands
- **Run main tests**: `bundle exec fastlane stripeios_tests`
- **Run StripeConnect tests**: `bundle exec fastlane stripeconnect_tests` 
- **Run all integration tests**: `bundle exec fastlane integration_all`
- **Run 3DS2 tests**: `bundle exec fastlane threeds2_tests`

### Standard Build Using Xcode
For testing, use this standard command:
```bash
source <(./ci_scripts/setup_simulator.sh) && xcodebuild -workspace Stripe.xcworkspace -scheme "StripePaymentSheet" -destination "id=$DEVICE_ID_FROM_USER_SETTINGS,arch=arm64" -quiet SWIFT_SUPPRESS_WARNINGS=YES SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
```
(Replacing "StripePaymentSheet" with your desired test framework, or "AllStripeFrameworks" to test all frameworks.)

### **IMPORTANT: Suppress Warnings for Test Targets**
When building test targets, always suppress warnings to avoid distracting output. Use `SWIFT_SUPPRESS_WARNINGS=YES SWIFT_TREAT_WARNINGS_AS_ERRORS=NO` in xcodebuild commands for test schemes:
```bash
xcodebuild test -scheme StripePaymentSheet -workspace Stripe.xcworkspace -destination "id=$DEVICE_ID_FROM_USER_SETTINGS,arch=arm64" -quiet SWIFT_SUPPRESS_WARNINGS=YES SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
```
(Replace "StripePaymentSheet" with the name of your scheme as needed.)

### Snapshot Tests
- **Record snapshots**: Use `AllStripeFrameworks-RecordMode` scheme (will fail while recording) and a specific test case
- **Run snapshots**: Use `AllStripeFrameworks` scheme to verify recorded snapshots

### Recorded network tests
- **Record network tests**: Use `AllStripeFrameworks-NetworkRecordMode` scheme (will fail while recording) and a specific test case
- **Run network tests**: Use `AllStripeFrameworks` scheme to verify recorded network tests

### UI Tests
- **Run UI tests**: Use `PaymentSheet Example` scheme with target `PaymentSheetUITest`
- **Run specific UI test class**: `-only-testing:PaymentSheetUITest/YourTestClassName`

## Code Quality

### **IMPORTANT: Always Lint Before Committing**
Before any commit, ALWAYS run these commands in order

1. **Check out a branch if needed**: If you are on the `master` branch, you MUST check out a new branch.
2. **Format modified files**: `ci_scripts/format_modified_files.sh`
3. **Lint modified files**: `ci_scripts/lint_modified_files.sh`

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
- **Individual projects**: Each module has its own `.xcodeproj` for focused development
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
