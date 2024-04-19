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

class ExampleCustomCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var paymentMethodImage: UIImageView!
    var paymentSheetFlowController: PaymentSheet.FlowController!
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!  // An example backend endpoint

    var configuration: PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = .init(
            merchantId: "merchant.com.stripe.umbrella.test", // Be sure to use your own merchant ID here!
            merchantCountryCode: "US"
        )

        configuration.returnURL = "payments-example://stripe-redirect"
        // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        
        return configuration
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        paymentMethodButton.addTarget(self, action: #selector(didTapPaymentMethodButton), for: .touchUpInside)
        paymentMethodButton.isEnabled = false

        Task {
            await loadBackend()
        }
    }
    
    func loadBackend() async {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data, options: [])
                    as? [String: Any],
                let paymentIntentClientSecret = json["paymentIntent"] as? String,
                let customerId = json["customer"] as? String,
                let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                let publishableKey = json["publishableKey"] as? String
            else {
                // Handle error
                return
            }
            
            // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
            STPAPIClient.shared.publishableKey = publishableKey
            
            // MARK: Create your PaymentSheet configuration
            var configuration = self.configuration
            configuration.customer = .init(
                id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)

            // MARK: Create a PaymentSheet.FlowController instance
            self.paymentSheetFlowController = try await PaymentSheet.FlowController.create(paymentIntentClientSecret: paymentIntentClientSecret,
                                                                                           configuration: configuration)
            self.paymentMethodButton.isEnabled = true
            self.updateButtons(paymentOption: paymentSheetFlowController.paymentOption)
        } catch {
            // Handle error
        }
        
    }


    // MARK: - Button handlers

    @objc
    func didTapPaymentMethodButton() {
        // MARK: Present payment options to the customer
        Task {
            let paymentOption = await paymentSheetFlowController.presentPaymentOptions(from: self)
            updateButtons(paymentOption: paymentOption)
        }
    }

    @objc
    func didTapCheckoutButton() {
        Task {
            // MARK: Confirm payment
            do {
                try await paymentSheetFlowController.confirm(from: self)
                self.displayAlert("Your order is confirmed!")
            } catch {
                print(error)
                self.displayAlert("Payment failed: \n\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helper methods

    func updateButtons(paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData?) {
        // MARK: Update the payment method and buy buttons
        if let paymentOption {
            paymentMethodButton.setTitle(paymentOption.label, for: .normal)
            paymentMethodButton.setTitleColor(.black, for: .normal)
            paymentMethodImage.image = paymentOption.image
            buyButton.isEnabled = true
        } else {
            paymentMethodButton.setTitle("Select", for: .normal)
            paymentMethodButton.setTitleColor(.systemBlue, for: .normal)
            paymentMethodImage.image = nil
            buyButton.isEnabled = false
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
