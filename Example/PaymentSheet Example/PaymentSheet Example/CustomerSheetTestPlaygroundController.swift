//
//  CustomerSheetTestPlaygroundController.swift
//  PaymentSheet Example
//

import Combine
@_spi(STP) @_spi(CustomerSessionBetaAccess) @_spi(CardBrandFilteringBeta) @_spi(AllowsSetAsDefaultPM) import StripePaymentSheet
import SwiftUI

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
    var _customerAdapter: CustomerAdapter?
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
        self.appearance = PaymentSheet.Appearance.default
        load()
    }
    func didTapSetToUnsupported() {
        Task {
            do {
                try await _customerAdapter?.setSelectedPaymentOption(paymentOption: .link)
                self.load()
            } catch {
                // no-op
            }
        }
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

    func customerSheetConfiguration() -> CustomerSheet.Configuration {
        var configuration = CustomerSheet.Configuration()
        configuration.appearance = appearance
        configuration.returnURL = "payments-example://stripe-redirect"
        configuration.headerTextForSelectionScreen = settings.headerTextForSelectionScreen
        configuration.allowsRemovalOfLastSavedPaymentMethod = settings.allowsRemovalOfLastSavedPaymentMethod == .on

        if settings.defaultBillingAddress == .on {
            configuration.defaultBillingDetails.name = "Jane Doe"
            configuration.defaultBillingDetails.email = "foo-\(UUID().uuidString)@bar.com"
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
        configuration.preferredNetworks = settings.preferredNetworksEnabled == .on ? [.visa, .cartesBancaires] : nil
        configuration.applePayEnabled = self.applePayEnabled()
        switch settings.cardBrandAcceptance {
        case .all:
            configuration.cardBrandAcceptance = .all
        case .blockAmEx:
            configuration.cardBrandAcceptance = .disallowed(brands: [.amex])
        case .allowVisa:
            configuration.cardBrandAcceptance = .allowed(brands: [.visa])
        }
        configuration.allowsSetAsDefaultPM = settings.allowsSetAsDefaultPM == .on
        return configuration
    }

    func createCustomerSheet(configuration: CustomerSheet.Configuration,
                             customerAdapter: CustomerAdapter) -> CustomerSheet {

        return CustomerSheet(configuration: configuration, customer: customerAdapter)
    }

    func createCustomerSheet(configuration: CustomerSheet.Configuration,
                             customerId: String,
                             customerSessionClientSecret: String?) -> CustomerSheet {
        let intentConfiguration = CustomerSheet.IntentConfiguration(setupIntentClientSecretProvider: {
            return try await self.backend.createSetupIntent(customerId: customerId, merchantCountryCode: self.settings.merchantCountryCode.rawValue)
        })
        return CustomerSheet(configuration: configuration,
                             intentConfiguration: intentConfiguration,
                             customerSessionClientSecretProvider: {
            .init(customerId: customerId, clientSecret: customerSessionClientSecret!)
        })
    }

    func customerAdapter(customerId: String, ephemeralKey: String) -> StripeCustomerAdapter {
        switch settings.paymentMethodMode {
        case .setupIntent:
            return StripeCustomerAdapter(customerEphemeralKeyProvider: {
                // This should be a block that fetches this from your server
                return .init(customerId: customerId, ephemeralKeySecret: ephemeralKey)
            }, setupIntentClientSecretProvider: {
                return try await self.backend.createSetupIntent(customerId: customerId, merchantCountryCode: self.settings.merchantCountryCode.rawValue)
            })
        case .createAndAttach:
            return StripeCustomerAdapter(customerEphemeralKeyProvider: {
                // This should be a block that fetches this from your server
                return .init(customerId: customerId, ephemeralKeySecret: ephemeralKey)
            }, setupIntentClientSecretProvider: nil)
        }
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
        case .customID:
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
        self.backend.loadBackendCustomerEphemeralKey(customerType: customerType,
                                                     settings: settings) { result in
            if settingsToLoad != self.settings {
                DispatchQueue.main.async {
                    self.load()
                }
                return
            }
            guard let json = result,
                  let customerId = json["customerId"], !customerId.isEmpty,
                  let publishableKey = json["publishableKey"] else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.currentlyRenderedSettings = self.settings
                }
                return
            }
            let ephemeralKey = json["customerEphemeralKeySecret"]
            let customerSessionClientSecret = json["customerSessionClientSecret"]
            guard ephemeralKey != nil || customerSessionClientSecret != nil else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.currentlyRenderedSettings = self.settings
                    print("Error: Backend did not return a customerSessionClientSecret or customerEphemeralKeySecret")
                }
                return
            }

            STPAPIClient.shared.publishableKey = publishableKey

            let configuration = self.customerSheetConfiguration()
            if let ephemeralKey {
                // Create Customer Sheet using CustomerAdapter w/ legacy ephemeral key
                let customerAdapter = self.customerAdapter(customerId: customerId,
                                                           ephemeralKey: ephemeralKey)
                self._customerAdapter = customerAdapter
                self.customerSheet = self.createCustomerSheet(configuration: configuration, customerAdapter: customerAdapter)
                Task { @MainActor in
                    do {
                        self.paymentOptionSelection = try await customerAdapter.retrievePaymentOptionSelection()
                    } catch {}
                }
            } else {
                // Create Customer Sheet using CustomerSession
                let customerSheet = self.createCustomerSheet(configuration: configuration,
                                                             customerId: customerId,
                                                             customerSessionClientSecret: customerSessionClientSecret)
                self.customerSheet = customerSheet
                Task { @MainActor in
                    do {
                        self.paymentOptionSelection = try await customerSheet.retrievePaymentOptionSelection()
                    } catch {}
                }
            }
            DispatchQueue.main.async {
                self.settings.customerId = customerId
                self.settings.customerMode = .customID
                self.currentlyRenderedSettings = self.settings
                self.serializeSettingsToNSUserDefaults()
                self.isLoading = false
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

    func loadBackendCustomerEphemeralKey(customerType: String,
                                         settings: CustomerSheetTestPlaygroundSettings,
                                         completion: @escaping ([String: String]?) -> Void) {

        var body = [ "customer_type": customerType,
                     "customer_key_type": settings.customerKeyType.rawValue,
                     "merchant_country_code": settings.merchantCountryCode.rawValue,
                     "customer_session_payment_method_remove": settings.paymentMethodRemove.rawValue,
                     "customer_session_payment_method_remove_last": settings.paymentMethodRemoveLast.rawValue,
        ] as [String: Any]

        if let allowRedisplayValue = settings.paymentMethodAllowRedisplayFilters.arrayValue() {
            body["customer_session_payment_method_allow_redisplay_filters"] = allowRedisplayValue
        }

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

    func createSetupIntent(customerId: String, merchantCountryCode: String) async throws -> String {
        let body = [ "customer_id": customerId,
                     "merchant_country_code": merchantCountryCode,
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
