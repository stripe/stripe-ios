//
//  PaymentSheetTestPlayground.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 9/14/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import UIKit
import Stripe

class PaymentSheetTestPlayground: UIViewController {
    // Configuration
    @IBOutlet weak var customerModeSelector: UISegmentedControl!
    @IBOutlet weak var applePaySelector: UISegmentedControl!
    @IBOutlet weak var billingModeSelector: UISegmentedControl!
    @IBOutlet weak var loadButton: UIButton!
    // Inline
    @IBOutlet weak var selectPaymentMethodImage: UIImageView!
    @IBOutlet weak var selectPaymentMethodButton: UIButton!
    @IBOutlet weak var checkoutInlineButton: UIButton!
    // Complete
    @IBOutlet weak var checkoutButton: UIButton!

    enum CustomerMode {
        case guest
        case new
        case returning
    }
    var customerMode: CustomerMode {
        switch customerModeSelector.selectedSegmentIndex {
        case 0:
            return .guest
        case 1:
            return .new
        default:
            return .returning
        }
    }

    var applePayConfiguration: PaymentSheet.ApplePayConfiguration? {
        if applePaySelector.selectedSegmentIndex == 0 {
            return PaymentSheet.ApplePayConfiguration(merchantId: "com.foo.example", merchantCountryCode: "US")
        } else {
            return nil
        }
    }
    var customerConfiguration: PaymentSheet.CustomerConfiguration? {
        switch customerMode {
        case .guest:
            return nil
        default:
            return PaymentSheet.CustomerConfiguration(id: customerID, ephemeralKeySecret: ephemeralKey)
        }
    }
    var configuration: PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = applePayConfiguration
        configuration.customer = customerConfiguration
        configuration.billingAddressCollectionLevel = billingModeSelector.selectedSegmentIndex == 0 ? .automatic : .required
        return configuration
    }

    var clientSecret: String!
    var ephemeralKey: String!
    var customerID: String!
    var manualFlow: PaymentSheet.FlowController?

    func makeAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: "Complete", message: "Completed", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        return alertController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        checkoutButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        checkoutButton.isEnabled = false

        loadButton.addTarget(self, action: #selector(load), for: .touchUpInside)

        selectPaymentMethodButton.isEnabled = false
        selectPaymentMethodButton.addTarget(self, action: #selector(didTapSelectPaymentMethodButton), for: .touchUpInside)

        checkoutInlineButton.addTarget(self, action: #selector(didTapCheckoutInlineButton), for: .touchUpInside)
        checkoutInlineButton.isEnabled = false
    }

    @objc
    func didTapCheckoutInlineButton() {
        checkoutInlineButton.isEnabled = false
        manualFlow?.confirmPayment(from: self) { result in
            let alertController = self.makeAlertController()
            switch result {
            case .canceled:
                alertController.message = "canceled"
                self.checkoutInlineButton.isEnabled = true
            case .failed(error: let error, paymentIntent: _):
                alertController.message = "\(error)"
                self.present(alertController, animated: true)
                self.checkoutInlineButton.isEnabled = true
            case .completed(paymentIntent: let paymentIntent):
                alertController.message = "success! \(paymentIntent)"
                self.present(alertController, animated: true)
            }
        }
    }

    @objc
    func didTapCheckoutButton() {
        let mc = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
        mc.present(from: self) { result in
            let alertController = self.makeAlertController()
            switch result {
            case .canceled:
                print("Canceled!")
            case .failed(error: let error, paymentIntent: _):
                alertController.message = error.localizedDescription
                print(error)
                self.present(alertController, animated: true)
            case .completed(paymentIntent: let paymentIntent):
                alertController.message = "Success!"
                print(paymentIntent)
                self.present(alertController, animated: true)
                self.checkoutButton.isEnabled = false
            }
        }
    }

    @objc
    func didTapSelectPaymentMethodButton() {
        manualFlow?.presentPaymentOptions(from: self) {
            self.updatePaymentMethodSelection()
        }
    }

    func updatePaymentMethodSelection() {
        // Update the payment method selection button
        if let paymentOption = manualFlow?.paymentOption {
            self.selectPaymentMethodButton.setTitle(paymentOption.label, for: .normal)
            self.selectPaymentMethodButton.setTitleColor(.label, for: .normal)
            self.selectPaymentMethodImage.image = paymentOption.image
            self.checkoutInlineButton.isEnabled = true
        } else {
            self.selectPaymentMethodButton.setTitle("Select", for: .normal)
            self.selectPaymentMethodButton.setTitleColor(.systemBlue, for: .normal)
            self.selectPaymentMethodImage.image = nil
            self.checkoutInlineButton.isEnabled = false
        }
    }
}

// MARK: - Backend

extension PaymentSheetTestPlayground {
    @objc
    func load() {
        checkoutButton.isEnabled = false
        checkoutInlineButton.isEnabled = false
        selectPaymentMethodButton.isEnabled = false
        manualFlow = nil

        let session = URLSession.shared
        let url = URL(string: "https://stripe-mobile-payment-sheet-test-playground.glitch.me/checkout")!
        let json = try! JSONEncoder().encode(["customer": customerMode == .returning ? "returning" : "new"])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, response, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONDecoder().decode([String: String].self, from: data)
            else {
                print(error as Any)
                return
            }
            
            self.clientSecret = json["paymentIntentClientSecret"]
            self.ephemeralKey = json["customerEphemeralKeySecret"]
            self.customerID = json["customerId"]
            StripeAPI.defaultPublishableKey = json["publishableKey"]

            DispatchQueue.main.async {
                self.checkoutButton.isEnabled = true
                PaymentSheet.FlowController.create(paymentIntentClientSecret: self.clientSecret,
                                                   configuration: self.configuration) { result in
                    switch result {
                    case .failure(let error):
                        print(error as Any)
                    case .success(let manualFlow):
                        self.manualFlow = manualFlow
                        self.selectPaymentMethodButton.isEnabled = true
                        self.updatePaymentMethodSelection()
                    }
                }
            }
        }
        task.resume()
    }
}
