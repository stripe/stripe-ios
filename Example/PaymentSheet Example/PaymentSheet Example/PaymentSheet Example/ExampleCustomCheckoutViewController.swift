//
//  ExampleCheckoutViewController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 12/4/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import Foundation
import Stripe
import UIKit

class ExampleCustomCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var paymentMethodImage: UIImageView!
    var paymentSheetFlowController: PaymentSheet.FlowController!
    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!  // An example backend endpoint

    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        paymentMethodButton.addTarget(
            self, action: #selector(didTapPaymentMethodButton), for: .touchUpInside)
        paymentMethodButton.isEnabled = false

        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, response, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                    let paymentIntentClientSecret = json["paymentIntent"] as? String,
                    let customerId = json["customer"] as? String,
                    let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                    let publishableKey = json["publishableKey"] as? String,
                    let self = self
                else {
                    // Handle error
                    return
                }
                // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                STPAPIClient.shared.publishableKey = publishableKey

                // MARK: Create a PaymentSheet.FlowController instance
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Example, Inc."
                configuration.applePay = .init(
                    merchantId: "com.foo.example", merchantCountryCode: "US")
                configuration.customer = .init(
                    id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                configuration.returnURL = "payments-example://stripe-redirect"
                PaymentSheet.FlowController.create(
                    paymentIntentClientSecret: paymentIntentClientSecret,
                    configuration: configuration
                ) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let paymentSheetFlowController):
                        self?.paymentSheetFlowController = paymentSheetFlowController
                        self?.paymentMethodButton.isEnabled = true
                        self?.updateButtons()
                    }
                }
            })
        task.resume()
    }

    // MARK: - Button handlers

    @objc
    func didTapPaymentMethodButton() {
        // MARK: Present payment options to the customer
        paymentSheetFlowController.presentPaymentOptions(from: self) {
            self.updateButtons()
        }
    }

    @objc
    func didTapCheckoutButton() {
        // MARK: Confirm payment
        paymentSheetFlowController.confirm(from: self) { paymentResult in
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

    // MARK: - Helper methods

    func updateButtons() {
        // MARK: Update the payment method and buy buttons
        if let paymentOption = paymentSheetFlowController.paymentOption {
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
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}
