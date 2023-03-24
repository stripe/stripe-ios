//
//  ExampleCheckoutViewController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 12/4/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import Foundation
@_spi (STP) import StripePaymentSheet
import UIKit

class ExampleCustomCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var paymentMethodImage: UIImageView!
    
    @IBOutlet weak var hotDogQuantityLabel: UILabel!
    @IBOutlet weak var saladQuantityLabel: UILabel!
    @IBOutlet weak var hotDogStepper: UIStepper!
    @IBOutlet weak var saladStepper: UIStepper!
    @IBOutlet weak var subtotalLabel: UILabel!
    @IBOutlet weak var salesTaxLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var subscribeSwitch: UISwitch!
    
    var paymentSheetFlowController: PaymentSheet.FlowController!
    let backendCheckoutUrl = URL(string: "https://stp-mobile-ci-test-backend-v7.stripedemos.com/checkout")!  // An example backend endpoint

    private var subtotal: Double {
        let hotDogPrice = 0.99
        let saladPrice = 8.00
        let discountMultiplier = subscribeSwitch.isOn ? 0.95 : 1
        let subtotal = (saladStepper.value * saladPrice + hotDogStepper.value * hotDogPrice) * discountMultiplier
        return subtotal
    }
    
    private var intentConfig: PaymentSheet.IntentConfiguration {
        return .init(mode: .payment(amount: Int(subtotal) * 100, currency: "EUR"), confirmHandler: confirmHandler(_:_:))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        paymentMethodButton.addTarget(self, action: #selector(didTapPaymentMethodButton), for: .touchUpInside)
        paymentMethodButton.isEnabled = false

        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, _, error) in
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
                // Set allowsDelayedPaymentMethods to true if your business can handle payment methods that complete payment after a delay, like SEPA Debit and Sofort.
                configuration.allowsDelayedPaymentMethods = true
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
    
    @IBAction func hotDogStepperDidChange() {
        updateUI()
    }
    
    @IBAction func saladStepperDidChange() {
        updateUI()
    }
    
    @IBAction func subscribeSwitchDidChange() {
        updateUI()
    }
    
    // MARK: - Helper methods
    
    private func updateUI() {
        updateLabels()
        paymentSheetFlowController.update
    }

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
    
    func updateLabels() {
        hotDogQuantityLabel.text = "\(Int(hotDogStepper.value))"
        saladQuantityLabel.text = "\(Int(saladStepper.value))"
        
        let hotDogPrice = 0.99
        let saladPrice = 8.00
        let discountMultiplier = subscribeSwitch.isOn ? 0.95 : 1
        let subtotal = (saladStepper.value * saladPrice + hotDogStepper.value * hotDogPrice) * discountMultiplier
        let tax = subtotal * 0.0825
        
        subtotalLabel.text = String(format:"€%.2f", subtotal)
        salesTaxLabel.text = String(format:"€%.2f", tax)
        totalLabel.text = String(format:"€%.2f", (subtotal + tax))
        
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
    
    // MARK: Confirm handler
    // Client-side confirmation handler
    func confirmHandler(_ paymentMethodID: String,
                        _ intentCreationCallback: @escaping (Result<String, Error>) -> Void) {
        
    }
}
