//
//  CustomerSheetTestPlaygroundController.swift
//  PaymentSheet Example
//

import Combine
@_spi(PrivateBetaCustomerSheet) import StripePaymentSheet
import StripeApplePay
import SwiftUI
import PassKit

class MyApplePayContextDelegate: NSObject, ApplePayContextDelegate {
    var paymentMethodContinuation: CheckedContinuation<String?, Never>?
    var setupIntentClientSecret: String?
    
    func applePayContext(_ context: StripeApplePay.STPApplePayContext, didCreatePaymentMethod paymentMethod: StripeCore.StripeAPI.PaymentMethod, paymentInformation: PKPayment, completion: @escaping StripeApplePay.STPIntentClientSecretCompletionBlock) {
        paymentMethodContinuation?.resume(with: .success(paymentMethod.id))
        completion(setupIntentClientSecret, nil)
    }
    
    func applePayContext(_ context: StripeApplePay.STPApplePayContext, didCompleteWith status: StripeApplePay.STPApplePayContext.PaymentStatus, error: Error?) {
        
    }
}

class MyApplePaySupportingCustomerAdapter: StripeCustomerAdapter {
    let applePayContextDelegate = MyApplePayContextDelegate()
    
    @MainActor
    override func setSelectedPaymentOption(paymentOption: CustomerPaymentOption?) async throws {
        if paymentOption == .applePay,
        let setupIntentClientSecret = try? await setupIntentClientSecretForCustomerAttach(){
            // Set up Apple Pay
            let merchantIdentifier = "merchant.com.your_app_name"
            let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantIdentifier, country: "US", currency: "USD")
            
            applePayContextDelegate.setupIntentClientSecret = setupIntentClientSecret

            // Configure the line items on the payment request
            paymentRequest.paymentSummaryItems = [
                // The final line should represent your company;
                // it'll be prepended with the word "Pay" (that is, "Pay iHats, Inc $50")
                PKPaymentSummaryItem(label: "Setup Subscription", amount: 0),
            ]
            if let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: applePayContextDelegate) {
                // Present Apple Pay payment sheet
                applePayContext.presentApplePay()
                if let applePayPM = await withCheckedContinuation({ continuation in
                    applePayContextDelegate.paymentMethodContinuation = continuation
                }) {
                    try await super.setSelectedPaymentOption(paymentOption: .stripeId(applePayPM))
                } else {
                    // Throw error, no PM from Apple Pay
                }
            } else {
                // Throw error
            }
            
        } else {
            try await super.setSelectedPaymentOption(paymentOption: paymentOption)
        }
    }
}

class CustomerSheetTestPlaygroundController: ObservableObject {
    static let defaultEndpoint = "https://stp-mobile-playground-backend-v7.stripedemos.com"

    @Published var settings: CustomerSheetTestPlaygroundSettings
    @Published var currentlyRenderedSettings: CustomerSheetTestPlaygroundSettings
    @Published var isLoading: Bool = false
    @Published var paymentOptionSelection: CustomerSheet.PaymentOptionSelection?

    private var subscribers: Set<AnyCancellable> = []
    init(settings: CustomerSheetTestPlaygroundSettings) {
        // Hack to ensure we don't force the native flow unless we're in a UI test
        if ProcessInfo.processInfo.environment["UITesting"] == nil {
            UserDefaults.standard.removeObject(forKey: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE")
        } else {
            // This makes the Financial Connections SDK use the native UI instead of webview. Native is much easier to test.
            UserDefaults.standard.set(true, forKey: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE")
        }
        self.settings = settings
        self.currentlyRenderedSettings = .defaultValues()
        $settings
            .sink { newValue in
            if !self.isLoading && newValue.autoreload == .on {
                self.load()
            }
        }.store(in: &subscribers)
    }

    var customerSheet: CustomerSheet?
    var backend: CustomerSheetBackend!
    var currentEndpoint: String = defaultEndpoint
    var appearance = PaymentSheet.Appearance.default

    var rootViewController: UIViewController {
        // Hack, should do this in SwiftUI
        return UIApplication.shared.windows.first!.rootViewController!
    }

    func makeAlertController() -> UIAlertController {
        let alertController = UIAlertController(
            title: "Complete", message: "Completed", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        return alertController
    }

    func didTapResetConfig() {
        self.settings = CustomerSheetTestPlaygroundSettings.defaultValues()
    }

    func appearanceButtonTapped() {
        if #available(iOS 14.0, *) {
            let vc = UIHostingController(rootView: AppearancePlaygroundView(appearance: appearance, doneAction: { updatedAppearance in
                self.appearance = updatedAppearance
                self.rootViewController.dismiss(animated: true, completion: nil)
                self.load()
            }))
            rootViewController.present(vc, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Unavailable", message: "Appearance playground is only available in iOS 14+.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }

    func presentCustomerSheet() {
        customerSheet?.present(from: rootViewController, completion: { result in
            switch result {
            case .selected(let paymentOptionSelection), .canceled(let paymentOptionSelection):
                self.paymentOptionSelection = paymentOptionSelection

                var status = "canceled"
                if case .selected = result {
                    status = "selected"
                }

                let alertController = self.makeAlertController()
                if let selection = paymentOptionSelection {
                    alertController.message = "Success: \(selection.displayData().label), \(status)"
                } else {
                    alertController.message = "Success: payment method not set, \(status)"
                }

                self.rootViewController.present(alertController, animated: true)

            case .error(let error):
                print("Something went wrong: \(error)")
            }
        })
    }

    func customerSheetConfiguration(customerId: String, ephemeralKey: String) -> CustomerSheet.Configuration {
        var configuration = CustomerSheet.Configuration()
        configuration.appearance = appearance
        configuration.returnURL = "payments-example://stripe-redirect"
        configuration.headerTextForSelectionScreen = settings.headerTextForSelectionScreen

        if settings.defaultBillingAddress == .on {
            configuration.defaultBillingDetails.name = "Jane Doe"
            configuration.defaultBillingDetails.email = "foo@bar.com"
            configuration.defaultBillingDetails.phone = "+13105551234"
            configuration.defaultBillingDetails.address = .init(
                city: "San Francisco",
                country: "US",
                line1: "510 Townsend St.",
                postalCode: "94102",
                state: "California"
            )
        }

        configuration.billingDetailsCollectionConfiguration.name = .init(rawValue: settings.collectName.rawValue)!
        configuration.billingDetailsCollectionConfiguration.phone = .init(rawValue: settings.collectPhone.rawValue)!
        configuration.billingDetailsCollectionConfiguration.email = .init(rawValue: settings.collectEmail.rawValue)!
        configuration.billingDetailsCollectionConfiguration.address = .init(rawValue: settings.collectAddress.rawValue)!
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = settings.attachDefaults == .on

        var paymentMethodTypes: [STPPaymentMethodType] = []
        switch settings.paymentMethodTypes {
        case .card:
            paymentMethodTypes = [.card]
        case .usBank:
            paymentMethodTypes = [.USBankAccount]
        case .card_usbank:
            paymentMethodTypes = [.card, .USBankAccount]
        case .usBank_card:
            paymentMethodTypes = [.USBankAccount, .card]
        }
        configuration.paymentMethodTypes = paymentMethodTypes

        return configuration
    }

    func customerAdapter(customerId: String, ephemeralKey: String, configuration: CustomerSheet.Configuration) -> StripeCustomerAdapter {
        let customerAdapter: StripeCustomerAdapter
        switch settings.paymentMethodMode {
        case .setupIntent:
            customerAdapter = MyApplePaySupportingCustomerAdapter(customerEphemeralKeyProvider: {
                // This should be a block that fetches this from your server
                .init(customerId: customerId, ephemeralKeySecret: ephemeralKey)
            }, setupIntentClientSecretProvider: {
                return try await self.backend.createSetupIntent(customerId: customerId)
            }, configuration: configuration)
        case .createAndAttach:
            customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
                // This should be a block that fetches this from your server
                .init(customerId: customerId, ephemeralKeySecret: ephemeralKey)
            }, setupIntentClientSecretProvider: nil,
            configuration: configuration)
        }
        return customerAdapter
    }

    func applePayEnabled() -> Bool {
        switch settings.applePay {
        case .on:
            return true
        case .off:
            return false
        }
    }
    func customerMode() -> String {
        switch settings.customerMode {
        case .returning:
            return "returning"
        case .new:
            return "new"
        case .id:
            return self.settings.customerId ?? ""
        }
    }
}

// MARK: - Backend

extension CustomerSheetTestPlaygroundController {
    @objc
    func load() {
        serializeSettingsToNSUserDefaults()
        loadBackend()
    }

    func loadBackend() {
        customerSheet = nil
        paymentOptionSelection = nil
        isLoading = true
        let settingsToLoad = self.settings
        let customerType: String = customerMode()

        self.backend = CustomerSheetBackend(endpoint: currentEndpoint)

        // TODO: Refactor this to make the ephemeral key and customerId fetching async
        self.backend.loadBackendCustomerEphemeralKey(customerType: customerType) { result in
            if settingsToLoad != self.settings {
                DispatchQueue.main.async {
                    self.load()
                }
                return
            }
            guard let json = result,
                  let ephemeralKey = json["customerEphemeralKeySecret"], !ephemeralKey.isEmpty,
                  let customerId = json["customerId"], !customerId.isEmpty,
                  let publishableKey = json["publishableKey"] else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.currentlyRenderedSettings = self.settings
                }
                return
            }

            StripeAPI.defaultPublishableKey = publishableKey

            Task {
                // Create Customer Sheet
                var configuration = self.customerSheetConfiguration(customerId: customerId, ephemeralKey: ephemeralKey)
                configuration.applePayEnabled = self.applePayEnabled()
                let customerAdapter = self.customerAdapter(customerId: customerId, ephemeralKey: ephemeralKey, configuration: configuration)
                self.customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)

                // Retrieve selected PM
                do {
                    let selection = try await customerAdapter.retrievePaymentOptionSelection()
                    DispatchQueue.main.async {
                        self.paymentOptionSelection = selection
                        self.settings.customerId = customerId
                        self.settings.customerMode = .id
                        self.currentlyRenderedSettings = self.settings
                        self.serializeSettingsToNSUserDefaults()
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.settings.customerId = customerId
                        self.settings.customerMode = .id
                        self.currentlyRenderedSettings = self.settings
                        self.serializeSettingsToNSUserDefaults()
                        self.isLoading = false
                    }
                    throw error
                }
            }
        }
    }
}

// MARK: - Helpers
extension CustomerSheetTestPlaygroundController {

    func serializeSettingsToNSUserDefaults() {
        let data = try! JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: CustomerSheetTestPlaygroundSettings.nsUserDefaultsKey)
    }

    static func settingsFromDefaults() -> CustomerSheetTestPlaygroundSettings? {
        if let data = UserDefaults.standard.value(forKey: CustomerSheetTestPlaygroundSettings.nsUserDefaultsKey) as? Data {
            do {
                return try JSONDecoder().decode(CustomerSheetTestPlaygroundSettings.self, from: data)
            } catch {
                print("Unable to deserialize saved settings")
                UserDefaults.standard.removeObject(forKey: CustomerSheetTestPlaygroundSettings.nsUserDefaultsKey)
            }
        }
        return nil
    }
}

class CustomerSheetBackend {

    let endpoint: String
    public init(endpoint: String) {
        self.endpoint = endpoint
    }

    func loadBackendCustomerEphemeralKey(customerType: String, completion: @escaping ([String: String]?) -> Void) {

        let body = [ "customer_type": customerType
        ] as [String: Any]

        let url = URL(string: "\(endpoint)/customer_ephemeral_key")!
        let session = URLSession.shared

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, _, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONDecoder().decode([String: String].self, from: data) else {
                print(error as Any)
                completion(nil)
                return
            }
            completion(json)
        }
        task.resume()
    }

    func createSetupIntent(customerId: String) async throws -> String {
        let body = [ "customer_id": customerId,
        ] as [String: Any]
        let url = URL(string: "\(endpoint)/create_setup_intent")!
        let session = URLSession.shared

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let (data, _) = try await session.data(for: urlRequest)
        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let secret = jsonResponse?["client_secret"] as? String else {
            throw NSError(domain: "test", code: 0, userInfo: nil) // Throw more specific error
        }
        return secret
    }
}
