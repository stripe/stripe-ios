# Stripe AppKit Example

This example demonstrates how to integrate the Stripe iOS & macOS SDK into a native macOS AppKit application.

## Features

- Native AppKit UI components
- Platform abstraction layer for cross-platform compatibility
- Sheet-based modal presentation for payment flows
- Automatic framework selection (AppKit vs UIKit)

## Requirements

- macOS 11.0 or later
- Xcode 15 or later
- Swift 5.7 or later

## Getting Started

### 1. Installation

#### Swift Package Manager

Add the Stripe SDK to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/stripe/stripe-ios.git", from: "24.14.0")
]
```

#### CocoaPods

Add to your `Podfile`:

```ruby
platform :osx, '11.0'

target 'YourAppKitApp' do
  pod 'Stripe', '~> 24.14.0'
  pod 'StripePaymentSheet', '~> 24.14.0'
end
```

### 2. Basic Integration

```swift
import AppKit
import StripePaymentSheet
@_spi(STP) import StripeUICore

class MainViewController: NSViewController {
    
    private var paymentSheet: PaymentSheet?
    
    func presentPaymentSheet() {
        // Configure PaymentSheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Your App Name"
        
        // Create PaymentSheet with client secret from your backend
        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        
        // Present the payment sheet
        paymentSheet?.present(from: self) { [weak self] result in
            switch result {
            case .completed:
                print("Payment completed successfully")
            case .canceled:
                print("Payment was canceled")
            case .failed(let error):
                print("Payment failed: \(error)")
            }
        }
    }
}
```

### 3. Platform Abstraction

The SDK automatically detects the platform and uses the appropriate UI framework:

- **iOS**: Uses UIKit components (UIViewController, UIView, etc.)
- **macOS**: Uses AppKit components (NSViewController, NSView, etc.)

The platform abstraction layer provides unified APIs:

```swift
// These work on both iOS and macOS
extension StripeViewController {
    func stripePresent(_ viewController: StripeViewController, animated: Bool, completion: (() -> Void)?)
    func stripeDismiss(animated: Bool, completion: (() -> Void)?)
}

extension StripeView {
    func addAndPinSubview(_ subview: StripeView)
    var stripeBackgroundColor: StripeColor?
}
```

## Key Differences from iOS

### Modal Presentation

On macOS, the SDK uses native sheet presentation instead of bottom sheets:

- **iOS**: Custom bottom sheet with gesture-based dismissal
- **macOS**: Native `NSWindow` sheet presentation

### Navigation

- **iOS**: Uses `UINavigationController` for navigation stacks
- **macOS**: Uses view controller containment and custom navigation

### Styling

The SDK automatically adapts to macOS design patterns:

- Uses `NSColor.controlBackgroundColor` instead of `UIColor.systemBackground`
- Adapts button styles and spacing for macOS
- Uses appropriate fonts and sizing

## Running the Example

1. Clone the repository
2. Navigate to `Example/AppKit Example/`
3. Open the project in Xcode or run with Swift Package Manager:

```bash
swift run StripeAppKitExample
```

## Next Steps

- Integrate with your backend to create PaymentIntents
- Customize the appearance to match your app's design
- Add error handling and analytics
- Test with different payment methods

For more information, see the [main SDK documentation](../../README.md). 