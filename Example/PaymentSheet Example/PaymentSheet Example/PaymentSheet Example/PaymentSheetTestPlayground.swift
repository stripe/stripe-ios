//
//  PaymentSheetTestPlayground.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 9/14/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//
//  ⚠️🏗 This is a playground for internal Stripe engineers to help us test things, and isn't
//  an example of what you should do in a real app!
//  Note: Do not import Stripe using `@_spi(STP)` in production.
//  This exposes internal functionality which may cause unexpected behavior if used directly.
@_spi(STP) import Stripe
@_spi(STP) import StripeCore
import Contacts
import UIKit
import SwiftUI

class PaymentSheetTestPlayground: UIViewController {
    static var paymentSheetPlaygroundSettings: PaymentSheetPlaygroundSettings? = nil

    // Configuration
    @IBOutlet weak var customerModeSelector: UISegmentedControl!
    @IBOutlet weak var applePaySelector: UISegmentedControl!
    @IBOutlet weak var allowsDelayedPaymentMethodsSelector: UISegmentedControl!
    @IBOutlet weak var shippingInfoSelector: UISegmentedControl!
    @IBOutlet weak var currencySelector: UISegmentedControl!
    @IBOutlet weak var merchantCountryCodeSelector: UISegmentedControl!
    @IBOutlet weak var modeSelector: UISegmentedControl!
    @IBOutlet weak var defaultBillingAddressSelector: UISegmentedControl!
    @IBOutlet weak var automaticPaymentMethodsSelector: UISegmentedControl!
    @IBOutlet weak var linkSelector: UISegmentedControl!
    @IBOutlet weak var loadButton: UIButton!
    // Inline
    @IBOutlet weak var selectPaymentMethodImage: UIImageView!
    @IBOutlet weak var selectPaymentMethodButton: UIButton!
    @IBOutlet weak var shippingAddressButton: UIButton!
    @IBOutlet weak var checkoutInlineButton: UIButton!
    // Complete
    @IBOutlet weak var checkoutButton: UIButton!
    // Other
    var newCustomerID: String? // Stores the new customer returned from the backend for reuse

    enum CustomerMode: String, CaseIterable {
        case guest
        case new
        case returning
    }

    enum Currency: String, CaseIterable {
        case usd
        case eur
        case aud
    }

    enum MerchantCountryCode: String, CaseIterable {
        case US
        case GB
        case AU
    }

    enum IntentMode: String, CaseIterable {
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
    
    var shouldSetDefaultBillingAddress: Bool {
        return defaultBillingAddressSelector.selectedSegmentIndex == 0
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

    var merchantCountryCode: MerchantCountryCode {
        let index = merchantCountryCodeSelector.selectedSegmentIndex
        guard index >= 0 && index < MerchantCountryCode.allCases.count else {
            return .US
        }
        return MerchantCountryCode.allCases[index]
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
        configuration.appearance = appearance
        configuration.returnURL = "payments-example://stripe-redirect"
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        if shouldSetDefaultBillingAddress {
            configuration.defaultBillingDetails.name = "Jane Doe"
            configuration.defaultBillingDetails.email = "foo@bar.com"
            configuration.defaultBillingDetails.phone = "+13105551234"
            configuration.defaultBillingDetails.address = defaultAddress
        }
        if shippingInfoSelector.selectedSegmentIndex == 1 {
            configuration.shippingAddress.defaultValues = .init(address: defaultAddress, name: "Jane Doe")
            configuration.shippingAddress.allowedCountries = ["US", "CA", "MX", "GB"]
            configuration.shippingAddress.additionalFields = .init(name: .required, phone: .optional, company: .optional)
        }
        if allowsDelayedPaymentMethodsSelector.selectedSegmentIndex == 0 {
            configuration.allowsDelayedPaymentMethods = true
        }
        return configuration
    }

    var clientSecret: String?
    var ephemeralKey: String?
    var customerID: String?
    var paymentSheetFlowController: PaymentSheet.FlowController?
    var appearance = PaymentSheet.Appearance.default
    
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

        // Enable experimental payment methods.
        // PaymentSheet.supportedPaymentMethods += [.link]

        checkoutButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        checkoutButton.isEnabled = false
        
        shippingAddressButton.addTarget(self, action: #selector(didTapShippingAddressButton), for: .touchUpInside)
        shippingAddressButton.titleLabel?.adjustsFontSizeToFitWidth = true
        shippingAddressButton.titleLabel?.textAlignment = .right
        shippingAddressButton.isEnabled = false

        loadButton.addTarget(self, action: #selector(load), for: .touchUpInside)

        selectPaymentMethodButton.isEnabled = false
        selectPaymentMethodButton.addTarget(
            self, action: #selector(didTapSelectPaymentMethodButton), for: .touchUpInside)

        checkoutInlineButton.addTarget(
            self, action: #selector(didTapCheckoutInlineButton), for: .touchUpInside)
        checkoutInlineButton.isEnabled = false
        if let paymentSheetPlaygroundSettings = PaymentSheetTestPlayground.paymentSheetPlaygroundSettings {
            loadSettingsFrom(settings: paymentSheetPlaygroundSettings)
        } else if let nsUserDefaultSettings = settingsFromDefaults() {
            loadSettingsFrom(settings: nsUserDefaultSettings)
            loadBackend()
        }
    }

    @objc
    func didTapCheckoutInlineButton() {
        checkoutInlineButton.isEnabled = false
        paymentSheetFlowController?.confirm(from: self) { result in
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
        paymentSheetFlowController?.presentPaymentOptions(from: self) {
            self.updateButtons()
        }
    }
    
    @objc
    func didTapShippingAddressButton() {
        paymentSheetFlowController?.presentShippingAddress(from: self) {
            self.updateButtons()
        }
    }

    func updateButtons() {
        // Update the shipping address
        if let shippingAddressDetails = paymentSheetFlowController?.shippingAddressDetails {
            let shippingText = shippingAddressDetails.localizedDescription.replacingOccurrences(of: "\n", with: ", ")
            shippingAddressButton.setTitle(shippingText, for: .normal)
        } else {
            shippingAddressButton.setTitle("Add", for: .normal)
        }

        // Update the payment method selection button
        if let paymentOption = paymentSheetFlowController?.paymentOption {
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
        self.selectPaymentMethodButton.setNeedsLayout()
    }

    @IBAction func didTapResetConfig(_ sender: Any) {
        loadSettingsFrom(settings: PaymentSheetPlaygroundSettings.defaultValues())
    }

    @IBAction func appearanceButtonTapped(_ sender: Any) {
        if #available(iOS 14.0, *) {
            let vc = UIHostingController(rootView: AppearancePlaygroundView(appearance: appearance, doneAction: { updatedAppearance in
                self.appearance = updatedAppearance
                self.dismiss(animated: true, completion: nil)
            }))

            self.navigationController?.present(vc, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Unavailable", message: "Appearance playground is only available in iOS 14+.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - Backend

extension PaymentSheetTestPlayground {
    @objc
    func load() {
        serializeSettingsToNSUserDefaults()
        loadBackend()
    }
    func loadBackend() {
        checkoutButton.isEnabled = false
        checkoutInlineButton.isEnabled = false
        selectPaymentMethodButton.isEnabled = false
        paymentSheetFlowController = nil

        let session = URLSession.shared
        let url = URL(string: "https://stripe-mobile-payment-sheet-test-playground-v6.glitch.me/checkout")!
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
        
        let body = [
            "customer": customer,
            "currency": currency.rawValue,
            "merchant_country_code": merchantCountryCode.rawValue,
            "mode": intentMode.rawValue,
            "set_shipping_address": shippingInfoSelector.selectedSegmentIndex == 1,
            "automatic_payment_methods": automaticPaymentMethodsSelector.selectedSegmentIndex == 0,
            "use_link": linkSelector.selectedSegmentIndex == 0
        ] as [String: Any]
        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
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
                    self.paymentSheetFlowController = manualFlow
                    self.selectPaymentMethodButton.isEnabled = true
                    self.shippingAddressButton.isEnabled = true
                    self.updateButtons()
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

struct PaymentSheetPlaygroundSettings: Codable {
    static let nsUserDefaultsKey = "playgroundSettings"
    let modeSelectorValue: Int
    let customerModeSelectorValue: Int
    let currencySelectorValue: Int
    let merchantCountryCode: Int
    let automaticPaymentMethodsSelectorValue: Int

    let applePaySelectorValue: Int
    let allowsDelayedPaymentMethodsSelectorValue: Int
    let defaultBillingAddressSelectorValue: Int
    let shippingInfoSelectorValue: Int
    let linkSelectorValue: Int

    static func defaultValues() -> PaymentSheetPlaygroundSettings {
        return PaymentSheetPlaygroundSettings(
            modeSelectorValue: 0,
            customerModeSelectorValue: 0,
            currencySelectorValue: 0,
            merchantCountryCode: 0,
            automaticPaymentMethodsSelectorValue: 0,
            applePaySelectorValue: 0,
            allowsDelayedPaymentMethodsSelectorValue: 1,
            defaultBillingAddressSelectorValue: 1,
            shippingInfoSelectorValue: 0,
            linkSelectorValue: 1
        )
    }
}

// MARK: - Helpers

extension PaymentSheetTestPlayground {
    func serializeSettingsToNSUserDefaults() -> Void {
        let settings = PaymentSheetPlaygroundSettings(
            modeSelectorValue: modeSelector.selectedSegmentIndex,
            customerModeSelectorValue: customerModeSelector.selectedSegmentIndex,
            currencySelectorValue: currencySelector.selectedSegmentIndex,
            merchantCountryCode: merchantCountryCodeSelector.selectedSegmentIndex,
            automaticPaymentMethodsSelectorValue: automaticPaymentMethodsSelector.selectedSegmentIndex,
            applePaySelectorValue: applePaySelector.selectedSegmentIndex,
            allowsDelayedPaymentMethodsSelectorValue: allowsDelayedPaymentMethodsSelector.selectedSegmentIndex,
            defaultBillingAddressSelectorValue: defaultBillingAddressSelector.selectedSegmentIndex,
            shippingInfoSelectorValue: shippingInfoSelector.selectedSegmentIndex,
            linkSelectorValue: linkSelector.selectedSegmentIndex
        )
        let data = try! JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: PaymentSheetPlaygroundSettings.nsUserDefaultsKey)
    }

    func settingsFromDefaults() -> PaymentSheetPlaygroundSettings? {
        if let data = UserDefaults.standard.value(forKey: PaymentSheetPlaygroundSettings.nsUserDefaultsKey) as? Data {
            do {
                return try JSONDecoder().decode(PaymentSheetPlaygroundSettings.self, from: data)
            } catch {
                print("Unable to deserialize saved settings")
                UserDefaults.standard.removeObject(forKey: PaymentSheetPlaygroundSettings.nsUserDefaultsKey)
            }
        }
        return nil
    }

    func loadSettingsFrom(settings: PaymentSheetPlaygroundSettings) {
        customerModeSelector.selectedSegmentIndex = settings.customerModeSelectorValue
        applePaySelector.selectedSegmentIndex = settings.applePaySelectorValue
        allowsDelayedPaymentMethodsSelector.selectedSegmentIndex = settings.allowsDelayedPaymentMethodsSelectorValue
        shippingInfoSelector.selectedSegmentIndex = settings.shippingInfoSelectorValue
        currencySelector.selectedSegmentIndex = settings.currencySelectorValue
        merchantCountryCodeSelector.selectedSegmentIndex = settings.merchantCountryCode
        modeSelector.selectedSegmentIndex = settings.modeSelectorValue
        defaultBillingAddressSelector.selectedSegmentIndex = settings.defaultBillingAddressSelectorValue
        automaticPaymentMethodsSelector.selectedSegmentIndex = settings.automaticPaymentMethodsSelectorValue
        linkSelector.selectedSegmentIndex = settings.linkSelectorValue
    }
}

extension PaymentSheet.ShippingAddressDetails {
    var localizedDescription: String {
        let formatter = CNPostalAddressFormatter()

        let postalAddress = CNMutablePostalAddress()
        if let line1 = address.line1, !line1.isEmpty,
           let line2 = address.line2, !line2.isEmpty {
            postalAddress.street = "\(line1), \(line2)"
        } else {
            postalAddress.street = "\(address.line1 ?? "")\(address.line2 ?? "")"
        }
        postalAddress.postalCode = address.postalCode ?? ""
        postalAddress.city = address.city ?? ""
        postalAddress.state = address.state ?? ""
        postalAddress.country = address.country ?? ""

        return [name, company, formatter.string(from: postalAddress), phone].compactMap { $0 }.joined(separator: "\n")
    }
}
