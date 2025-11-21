//
//  ExampleCheckoutViewController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 12/4/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import Foundation
import StripePaymentSheet
import UIKit

class ExampleCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!
    var paymentSheet: PaymentSheet?
    // View and fork the backend code  here: https://codesandbox.io/p/devbox/gvs8t4
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.stripedemos.com/checkout")!  // An example backend endpoint

    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        Task {
            do {
                try await loadCheckout()
            } catch {
                print("Failed to load checkout: \(error)")
            }
        }
    }

    private func loadCheckout() async throws {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard
            let customerId = json?["customer"] as? String,
            let customerEphemeralKeySecret = json?["ephemeralKey"] as? String,
            let paymentIntentClientSecret = json?["paymentIntent"] as? String,
            let publishableKey = json?["publishableKey"] as? String
        else {
            throw ExampleError(errorDescription: "Invalid response from backend")
        }
        // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
        STPAPIClient.shared.publishableKey = publishableKey

        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = .init(
            merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
            merchantCountryCode: "US"
        )
        configuration.customer = .init(
            id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
        configuration.returnURL = "payments-example://stripe-redirect"
        // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit.
        configuration.allowsDelayedPaymentMethods = true
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: paymentIntentClientSecret,
            configuration: configuration)

        self.buyButton.isEnabled = true
    }

    struct ExampleError: LocalizedError {
       var errorDescription: String?
    }

    @objc
    func didTapCheckoutButton() {
        // MARK: Start the checkout process
        paymentSheet?.present(from: self) { paymentResult in
            // MARK: Handle the payment result
            switch paymentResult {
            case .completed:
                self.displayAlert("Your order is confirmed!")
            case .canceled:
                print("Canceled!")
            case .failed(let error):
                print(error)
                self.displayAlert("Payment failed: \n\(error.localizedDescription)")
            }
        }
    }

    func displayAlert(_ message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            alertController.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}
