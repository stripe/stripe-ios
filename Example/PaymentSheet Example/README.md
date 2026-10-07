# PaymentSheet Example App

PaymentSheet is a pre-built UI that combines all the steps required to accept payment - collecting payment information, billing details, and confirming the payment - into a single sheet that displays on top of your app.

### Features
- Supports 10+ payment methods
- Card scanning
- Light and dark mode
- Helps you stay PCI compliant

<p align="center">
<img src="https://user-images.githubusercontent.com/89988962/153276097-9b3369a0-e732-45c4-96ec-ff9d48ad0fb6.png" width="480" alt="PaymentSheet Example App" align="center">
</p>

### To run the app
1. Open `Stripe.xcworkspace` in Xcode
2. Choose the **PaymentSheet Example** target in the top left
3. Choose any simulator and click Run

The example app will appear with buttons that show different view controllers in this project. 

The view controllers correspond to different ways to integrate PaymentSheet into your app.

### Toggling Liquid Glass (iOS 26 only)

Use the **PaymentSheet Example** scheme for the default (Liquid Glass enabled) app design. Use **PaymentSheet Example No Glass** to build the app with `UIDesignRequiresCompatibility` set to `YES`, disabling Liquid Glass.

This is independent of the Liquid Glass appearance setting in the Payment Sheet Playground (which calls the setting on the MPE appearance config).

The compatibility key is ignored if the app is both built with Xcode 27+ and running on an iOS 27+ device.

The No Glass scheme builds a separate app target that shares the default target's source files and resources, using the existing Debug and Release configurations. Both targets use the same bundle identifier, so switching schemes preserves playground settings. Automated tests use the default example scheme.

### UIKit
- `ExampleCheckoutViewController.swift`: ["one-step" integration](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet&uikit-swiftui=uikit)
- `ExampleCustomCheckoutViewController.swift`: ["multi-step" integration](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet-custom&uikit-swiftui=uikit)

### SwiftUI
- `ExampleSwiftUIPaymentSheet.swift`: ["one-step" integration](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet&uikit-swiftui=swiftui)
- `ExampleSwiftUICustomPaymentFlow.swift`: ["multi-step" integration](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet-custom&uikit-swiftui=swiftui)

