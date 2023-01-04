# Stripe CardScan iOS SDK

This library provides support for the standalone Stripe CardScan product.

## Overview

This library provides a user interface through which users can scan payment cards and extract information from them. It uses the Stripe Publishable Key to authenticate with Stripe services.

Note that this is a standalone SDK and, while compatible with, does not directly integrate with the [PaymentIntent](https://stripe.com/docs/api/payment_intents) API nor with [next_action](https://stripe.com/docs/api/errors#errors-payment_intent-next_action).

This library can be used entirely outside of a Stripe integration and with other payment processing providers.

## Requirements

- iOS 13.0 or higher
- XCode 13.2.1 or higher

## Example

See the [CardImageVerification Example](https://github.com/stripe/stripe-ios/tree/master/Example/CardImageVerification%20Example) directory for an example application that you can try for yourself!

## Installation

- Cocoapod
    - `pod install StripeCardScan`
- SPM
    - In Xcode, select File > Add Packages… and enter https://github.com/stripe/stripe-ios-spm as the repository URL.
    - Select the latest version number from our releases page.
    - Add the `StripeCardScan` product to the target of your app.

## Integration
### Credit Card OCR
Add `CardScanSheet` in your view controller where you want to invoke the credit card scanning flow.

1. Set up camera permissions
    * The SDK uses the camera, so you'll need to add an description of camera usage to your Info.plist file:
![info.plist camera permissions](https://gblobscdn.gitbook.com/assets%2F-MAfqrnL3d-uke0sAFsI%2Fsync%2F573e3f05043e4d903189b5fb107d4b3565bdb11b.png?alt=media)
![camera permissions prompt](https://gblobscdn.gitbook.com/assets%2F-MAfqrnL3d-uke0sAFsI%2Fsync%2F0d7119d3cbe2f519e5e5c04b56fe43539e4435e1.png?alt=media)

    * Alternatively, you can add this permission directly to your Info.plist file:
    ```
    <key>NSCameraUsageDescriptionkey>
    <string>We need access to your camera to scan your cardstring>
    ```
2. Add `CardScanSheet` in your app where you want to invoke the scan flow
    * Initialize `CardScanSheet`
    * When it’s time to invoke the scan flow, display the sheet with `CardScanSheet.present()`
    * When the verification flow is finished, the sheet will be dismissed and the completion block will be called with a [Result](https://stripe.dev/stripe-ios/)

### Example Implementation
```swift

import UIKit
import StripeCardScan

class ViewController: UIViewController {

    @IBAction func cardScanSheetButtonPressed() {
        let cardScanSheet = CardScanSheet()

        cardScanSheet.present(from: self) { [weak self] result in
            switch result {
                case .completed(let scannedCard):
                /*
                 * The user scanned a card. The result of the scan are detailed 
                 * in the `scannedCard` field of the result.
                 */
                print("scan success")
            case .canceled:
                /*
                * The scan was canceled by the user.
                */
                print("scan canceled")
            case .failed(let error):
                 /*
                 * The scan failed. The displayable error is
                 * included in the `localizedDescription`. 
                 */
                 print("scan failed: \(error.localizedDescription)")
            }
        }
    }
}
```

## Credit Card Verification
🚧
