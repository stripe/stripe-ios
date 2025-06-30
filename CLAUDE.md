# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Simulator Setup

Before running tests or builds, ensure you have the correct simulator configured. The project requires an iPhone 12 mini with iOS 16.4 for consistent screenshot tests.

### Automatic Simulator Detection

**IMPORTANT**: Always check if `.stripe-ios-config` exists and contains a valid device ID before running tests or builds. Use the automated script to set up the simulator:

```bash
# Set up simulator (finds existing or creates new iPhone 12 mini with iOS 16.4)
source <(./ci_scripts/setup_simulator.sh)
```

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

Once configured, you can use the device ID in build commands:
```bash
source <(./ci_scripts/setup_simulator.sh)
xcodebuild -workspace Stripe.xcworkspace -scheme "StripePaymentSheet" -destination "id=$DEVICE_ID_FROM_USER_SETTINGS,arch=arm64" -quiet
```

### Quick Setup Check

To verify the simulator is properly configured, run:
```bash
source <(./ci_scripts/setup_simulator.sh)
echo "✅ Simulator configured: $DEVICE_ID_FROM_USER_SETTINGS"
```

## Build Commands

### Core Testing Commands
- **Run main tests**: `bundle exec fastlane stripeios_tests`
- **Run StripeConnect tests**: `bundle exec fastlane stripeconnect_tests` 
- **Run all integration tests**: `bundle exec fastlane integration_all`
- **Run 3DS2 tests**: `bundle exec fastlane threeds2_tests`

### Test with CI Script
Use `./ci_scripts/test.rb` for more granular control:
- **Build only**: `./ci_scripts/test.rb --build-only --scheme 'SCHEME_NAME'`
- **Run specific scheme**: `./ci_scripts/test.rb --scheme 'SCHEME_NAME' --device 'iPhone 12 mini' --version 16.4 --retry-on-failure`

### Standard Build Using Xcode
For compilation testing, use this standard command:
```bash
source <(./ci_scripts/setup_simulator.sh)
xcodebuild -workspace Stripe.xcworkspace -scheme "StripePaymentSheet" -destination "id=$DEVICE_ID_FROM_USER_SETTINGS,arch=arm64" -quiet
```

### Snapshot Tests
- **Record snapshots**: Use `AllStripeFrameworks-RecordMode` scheme (will fail while recording)
- **Run snapshots**: Use `AllStripeFrameworks` scheme to verify recorded snapshots
- **Record via CLI**: `bundle exec ruby ci_scripts/snapshots.rb --record`

## Code Quality

### **IMPORTANT: Always Run Before Committing**
Before any commit, ALWAYS run these commands in order: If you are on the `master` branch, you MUST check out a branch before running these commands.
1. **Format modified files**: `ci_scripts/format_modified_files.sh`
2. **Lint modified files**: `ci_scripts/lint_modified_files.sh`

### Linting
- **Format modified files**: `ci_scripts/format_modified_files.sh` 
- **Lint modified files**: `ci_scripts/lint_modified_files.sh`

### Filing PRs
When using the GitHub `gh` command, ALWAYS set `GH_HOST=github.com`. For example: `GH_HOST=github.com gh pr create --title [...]`

### Analysis
- **Run static analyzer**: `bundle exec fastlane analyze`

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
- `StripePaymentSheet` - Prebuilt payment flow (depends on StripePaymentsUI, StripeApplePay)
- `StripeApplePay` - Apple Pay integration (depends on StripeCore)

**Specialized Modules:**
- `StripeIdentity` - Identity verification (depends on StripeCore, StripeUICore, StripeCameraCore)
- `StripeFinancialConnections` - Bank account linking (depends on StripeCore, StripeUICore)
- `StripeConnect` - Connect embedded components (depends on StripeCore, StripeUICore, StripeFinancialConnections)
- `StripeCardScan` - Card scanning functionality (depends on StripeCore)

**Main Stripe Module:**
- `Stripe` - Umbrella framework including most modules plus additional issuing features

### Key Workspaces and Projects
- **Main workspace**: `Stripe.xcworkspace` - Contains all modules and examples
- **Individual projects**: Each module has its own `.xcodeproj` for focused development
- **Test configurations**: Located in `BuildConfigurations/` directories

### Package Manager Support
- **Swift Package Manager**: Defined in `Package.swift` with iOS 13+ minimum deployment
- **CocoaPods**: Individual `.podspec` files for each module
- **Carthage**: Supported with proper framework linking

## Development Workflow

### Requirements
- Xcode 15+ required
- iOS 13+ minimum deployment target  
- Carthage 0.37+ for dependency management
- Bundle/Fastlane for automation

### Testing Strategy
- Comprehensive unit tests for each module in corresponding `*Tests/` directories
- Snapshot tests for UI components using FBSnapshotTestCase
- Integration tests with real backend APIs (marked as functional tests)
- Example apps for manual testing in `Example/` directory

### Dependencies Installation
Run `bundle install && bundle exec fastlane stripeios_tests` initially to install test dependencies.

### Special Testing Notes
- E2E tests: Use `bundle exec fastlane e2e_only` for end-to-end testing
- Legacy iOS versions: Separate fastlane lanes for iOS 13-16 compatibility testing
- Network recording: Use `AllStripeFrameworks-NetworkRecordMode` scheme for network test recording