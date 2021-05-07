# PaymentSheet Example App

### To run the app
1. Open `Stripe.xcworkspace` in Xcode
2. Choose the **PaymentSheet Example** target in the top left
3. Choose any simulator and click Run

The example app will appear with buttons that show different view controllers in this project. 

The view controllers correspond to different ways to integrate PaymentSheet into your app.

### UIKit
- `ExampleCheckoutViewController.swift`: ["one-step" integration](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet&uikit-swiftui=uikit)
- `ExampleCustomCheckoutViewController.swift`: ["multi-step" integration](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet-custom&uikit-swiftui=uikit)

### SwiftUI
- `ExampleSwiftUIPaymentSheet.swift`: ["one-step" integration](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet&uikit-swiftui=swiftui)
- `ExampleSwiftUICustomPaymentFlow.swift`: ["multi-step" integration](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet-custom&uikit-swiftui=swiftui)

