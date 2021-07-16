//
//  PaymentSheetTestPlayground.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 9/14/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import Stripe
import UIKit

class PaymentSheetTestPlayground: UIViewController {
    // Configuration
    @IBOutlet weak var customerModeSelector: UISegmentedControl!
    @IBOutlet weak var applePaySelector: UISegmentedControl!
    @IBOutlet weak var billingModeSelector: UISegmentedControl!
    @IBOutlet weak var currencySelector: UISegmentedControl!
    @IBOutlet weak var modeSelector: UISegmentedControl!
    @IBOutlet weak var loadButton: UIButton!
    // Inline
    @IBOutlet weak var selectPaymentMethodImage: UIImageView!
    @IBOutlet weak var selectPaymentMethodButton: UIButton!
    @IBOutlet weak var checkoutInlineButton: UIButton!
    // Complete
    @IBOutlet weak var checkoutButton: UIButton!
    // Other
    var newCustomerID: String? // Stores the new customer returned from the backend for reuse

    enum CustomerMode {
        case guest
        case new
        case returning
    }

    enum Currency: String, CaseIterable {
        case usd
        case eur
    }

    enum IntentMode: String {
        case payment
        case paymentWithSetup = "payment_with_setup"
        case setup
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
            return PaymentSheet.ApplePayConfiguration(
                merchantId: "com.foo.example", merchantCountryCode: "US")
        } else {
            return nil
        }
    }
    var customerConfiguration: PaymentSheet.CustomerConfiguration? {
        if let customerID = customerID,
           let ephemeralKey = ephemeralKey,
           customerMode != .guest {
            return PaymentSheet.CustomerConfiguration(
                id: customerID, ephemeralKeySecret: ephemeralKey)
        }
        return nil
    }

    /// Currency specified in the UI toggle
    var currency: Currency {
        let index = currencySelector.selectedSegmentIndex
        guard index >= 0 && index < Currency.allCases.count else {
            return .usd
        }
        return Currency.allCases[index]
    }

    var intentMode: IntentMode {
        switch modeSelector.selectedSegmentIndex {
        case 0:
            return .payment
        case 1:
            return .paymentWithSetup
        default:
            return .setup
        }
    }

    var configuration: PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = applePayConfiguration
        configuration.customer = customerConfiguration
        configuration.returnURL = "payments-example://stripe-redirect"
        return configuration
    }

    var clientSecret: String?
    var ephemeralKey: String?
    var customerID: String?
    var manualFlow: PaymentSheet.FlowController?

    func makeAlertController() -> UIAlertController {
        let alertController = UIAlertController(
            title: "Complete", message: "Completed", preferredStyle: .alert)
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
        selectPaymentMethodButton.addTarget(
            self, action: #selector(didTapSelectPaymentMethodButton), for: .touchUpInside)

        checkoutInlineButton.addTarget(
            self, action: #selector(didTapCheckoutInlineButton), for: .touchUpInside)
        checkoutInlineButton.isEnabled = false
    }

    @objc
    func didTapCheckoutInlineButton() {
        checkoutInlineButton.isEnabled = false
        manualFlow?.confirm(from: self) { result in
            let alertController = self.makeAlertController()
            switch result {
            case .canceled:
                alertController.message = "canceled"
                self.checkoutInlineButton.isEnabled = true
            case .failed(let error):
                alertController.message = "\(error)"
                self.present(alertController, animated: true)
                self.checkoutInlineButton.isEnabled = true
            case .completed:
                alertController.message = "success!"
                self.present(alertController, animated: true)
            }
        }
    }

    @objc
    func didTapCheckoutButton() {
        let mc: PaymentSheet
        switch intentMode {
        case .payment, .paymentWithSetup:
            mc = PaymentSheet(paymentIntentClientSecret: clientSecret!, configuration: configuration)
        case .setup:
            mc = PaymentSheet(setupIntentClientSecret: clientSecret!, configuration: configuration)
        }
        mc.present(from: self) { result in
            let alertController = self.makeAlertController()
            switch result {
            case .canceled:
                print("Canceled! \(String(describing: mc.mostRecentError))")
            case .failed(let error):
                alertController.message = error.localizedDescription
                print(error)
                self.present(alertController, animated: true)
            case .completed:
                alertController.message = "Success!"
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
        let url = URL(string: "https://stripe-mobile-payment-sheet-test-playground-v3.glitch.me/checkout")!
        let customer: String = {
            switch customerMode {
            case .guest:
                return "guest"
            case .new:
                return newCustomerID ?? "new"
            case .returning:
                return "returning"
            }
        }()
        let json = try! JSONEncoder().encode([
            "customer": customer,
            "currency": currency.rawValue,
            "mode": intentMode.rawValue,
        ])
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

            self.clientSecret = json["intentClientSecret"]
            self.ephemeralKey = json["customerEphemeralKeySecret"]
            self.customerID = json["customerId"]
            StripeAPI.defaultPublishableKey = json["publishableKey"]
            let completion: (Result<PaymentSheet.FlowController, Error>) -> Void = { result in
                switch result {
                case .failure(let error):
                    print(error as Any)
                case .success(let manualFlow):
                    self.manualFlow = manualFlow
                    self.selectPaymentMethodButton.isEnabled = true
                    self.updatePaymentMethodSelection()
                }
            }

            DispatchQueue.main.async {
                if self.customerMode == .new && self.newCustomerID == nil {
                    self.newCustomerID = self.customerID
                }

                self.checkoutButton.isEnabled = true
                switch self.intentMode {
                case .payment, .paymentWithSetup:
                    PaymentSheet.FlowController.create(
                        paymentIntentClientSecret: self.clientSecret!,
                        configuration: self.configuration,
                        completion: completion
                    )
                case .setup:
                    PaymentSheet.FlowController.create(
                        setupIntentClientSecret: self.clientSecret!,
                        configuration: self.configuration,
                        completion: completion
                    )
                }
            }
        }
        task.resume()
    }
}
