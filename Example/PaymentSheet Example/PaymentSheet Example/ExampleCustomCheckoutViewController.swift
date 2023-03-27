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

    private var paymentSheetFlowController: PaymentSheet.FlowController!
    private let baseUrl = "https://stripe-mobile-payment-sheet-custom.glitch.me"
    private var backendCheckoutUrl: URL {
        return URL(string: baseUrl + "/checkout")!
    }
    private var createIntentUrl: URL {
        return URL(string: baseUrl + "/create_intent")!
    }

    private let taxMultiplier = 0.0825

    private var subtotal: Double {
        let hotDogPrice = 0.99
        let saladPrice = 8.00
        let discountMultiplier = subscribeSwitch.isOn ? 0.95 : 1
        let subtotal = (saladStepper.value * saladPrice + hotDogStepper.value * hotDogPrice) * discountMultiplier
        return subtotal
    }

    private var total: Double {
        subtotal + (subtotal * taxMultiplier)
    }

    private var intentConfig: PaymentSheet.IntentConfiguration {
        if subscribeSwitch.isOn {
            return .init(mode: .payment(amount: Int(total * 100),
                                        currency: "USD",
                                        setupFutureUsage: .offSession),
                         confirmHandler: confirmHandler(_:_:))
        }

        return .init(mode: .payment(amount: Int(total * 100), currency: "USD"), confirmHandler: confirmHandler(_:_:))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        paymentMethodButton.addTarget(self, action: #selector(didTapPaymentMethodButton), for: .touchUpInside)
        paymentMethodButton.isEnabled = false

        hotDogStepper.isEnabled = false
        saladStepper.isEnabled = false
        subscribeSwitch.isEnabled = false

        loadCheckout()
    }

    func loadCheckout() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, _, error) in
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
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
                DispatchQueue.main.async {
                    PaymentSheet.FlowController.create(
                        intentConfig: self.intentConfig,
                        configuration: configuration
                    ) { [weak self] result in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let paymentSheetFlowController):
                            self?.paymentSheetFlowController = paymentSheetFlowController
                            self?.paymentMethodButton.isEnabled = true
                            self?.hotDogStepper.isEnabled = true
                            self?.saladStepper.isEnabled = true
                            self?.subscribeSwitch.isEnabled = true
                            self?.updateButtons()
                        }
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
        // Disable buy and payment method buttons
        buyButton.isEnabled = false
        paymentMethodButton.isEnabled = false

        updateLabels()

        // Update PaymentSheet with the latest `intentConfig`
        paymentSheetFlowController.update(intentConfiguration: intentConfig) { error  in
            if error != nil {
                // Retry
                self.updateUI()
            } else {
                // Re-enable your "Buy" and "Payment method" buttons
                self.updateButtons()
              }
        }
    }

    func updateButtons() {
        paymentMethodButton.isEnabled = true

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

        let tax = subtotal * taxMultiplier

        subtotalLabel.text = "\(subtotal.truncate(places: 2))"
        salesTaxLabel.text = "\(tax.truncate(places: 2))"
        totalLabel.text = "\((subtotal + tax).truncate(places: 2))"
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

    func confirmHandler(_ paymentMethodID: String,
                        _ intentCreationCallback: @escaping (Result<String, Error>) -> Void) {
        // Create an intent on your server and invoke `intentCreationCallback` with the client secret
        createIntent(paymentMethodID: paymentMethodID) { result in
            switch result {
            case .success(let clientSecret):
                intentCreationCallback(.success(clientSecret))
            case .failure(let error):
                intentCreationCallback(.failure(error))
            }
        }
    }

    // MARK: Helpers

    func createIntent(paymentMethodID: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: createIntentUrl)
        request.httpMethod = "POST"
        request.httpBody = createIntentRequestBody(paymentMethodID: paymentMethodID)
        request.setValue("application/json", forHTTPHeaderField: "Content-type")

        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { (data, _, error) in
                guard
                    error == nil,
                    let data = data,
                    let json = try? JSONDecoder().decode([String: String].self, from: data),
                    let clientSecret = json["intentClientSecret"]
                else {
                    completion(.failure(error!))
                    return
                }

                completion(.success(clientSecret))
        })

        task.resume()
    }

    func createIntentRequestBody(paymentMethodID: String) -> Data {
        var body: [String: Any?] = [
            "payment_method_id": paymentMethodID,
            "currency": "USD",
            "amount": Int(total * 100),
        ]

        if subscribeSwitch.isOn {
            body["setup_future_usage"] = "off_session"
        }

        return try! JSONSerialization.data(withJSONObject: body, options: [])
    }
}

extension Double {
    func truncate(places: Int) -> Double {
        return Double(floor(pow(10.0, Double(places)) * self)/pow(10.0, Double(places)))
    }
}
