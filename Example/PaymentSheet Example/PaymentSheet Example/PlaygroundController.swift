//
//  PlaygroundController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 9/14/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//
//  ⚠️🏗 This is a playground for internal Stripe engineers to help us test things, and isn't
//  an example of what you should do in a real app!
//  Note: Do not import Stripe using `@_spi(STP)` in production.
//  This exposes internal functionality which may cause unexpected behavior if used directly.
import Combine
import Contacts
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(CustomerSessionBetaAccess) @_spi(EarlyAccessCVCRecollectionFeature) import StripePaymentSheet
@_spi(STP) @_spi(PaymentSheetSkipConfirmation) import StripePaymentSheet
@_spi(ExperimentalAllowsRemovalOfLastSavedPaymentMethodAPI) import StripePaymentSheet
import SwiftUI
import UIKit

class PlaygroundController: ObservableObject {
    @Published var paymentSheetFlowController: PaymentSheet.FlowController?
    @Published var paymentSheet: PaymentSheet?
    @Published var settings: PaymentSheetTestPlaygroundSettings
    @Published var currentlyRenderedSettings: PaymentSheetTestPlaygroundSettings
    @Published var addressDetails: AddressViewController.AddressDetails?
    @Published var isLoading: Bool = false
    @Published var lastPaymentResult: PaymentSheetResult?

    var applePayConfiguration: PaymentSheet.ApplePayConfiguration? {
        let buttonType: PKPaymentButtonType = {
            switch settings.applePayButtonType {
            case .buy:
                return .buy
            case .checkout:
                return .checkout
            case .plain:
                return .plain
            case .setup:
                return .setUp
            }
        }()
#if compiler(>=5.7)
        if #available(iOS 16.0, *), settings.applePayEnabled == .onWithDetails {
            let customHandlers = PaymentSheet.ApplePayConfiguration.Handlers(
                paymentRequestHandler: { request in
                    let billing = PKRecurringPaymentSummaryItem(label: "My Subscription", amount: NSDecimalNumber(string: "59.99"))
                    billing.startDate = Date()
                    billing.endDate = Date().addingTimeInterval(60 * 60 * 24 * 365)
                    billing.intervalUnit = .month

                    request.recurringPaymentRequest = PKRecurringPaymentRequest(paymentDescription: "Recurring",
                                                                                regularBilling: billing,
                                                                                managementURL: URL(string: "https://my-backend.example.com/customer-portal")!)
                    request.recurringPaymentRequest?.billingAgreement = "You're going to be billed $59.99 every month for some period of time."
                    request.paymentSummaryItems = [billing]
                    return request
                },
                authorizationResultHandler: { result, completion in
                    //                  Hardcoded order details:
                    //                  In a real app, you should fetch these details from your service and call the completion() block on
                    //                  the main queue.
                    result.orderDetails = PKPaymentOrderDetails(
                        orderTypeIdentifier: "com.myapp.order",
                        orderIdentifier: "ABC123-AAAA-1111",
                        webServiceURL: URL(string: "https://my-backend.example.com/apple-order-tracking-backend")!,
                        authenticationToken: "abc123")
                    completion(result)
                }
            )
            return PaymentSheet.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.umbrella.test",
                merchantCountryCode: "US",
                buttonType: buttonType,
                customHandlers: customHandlers)
        }
#endif
        if settings.applePayEnabled == .on  {
            return PaymentSheet.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.umbrella.test",
                merchantCountryCode: "US",
                buttonType: buttonType)
        } else {
            return nil
        }
    }
    var customerConfiguration: PaymentSheet.CustomerConfiguration? {
        guard settings.customerMode != .guest,
              let customerId = self.customerId else {
            return nil
        }
        switch self.settings.customerKeyType {
        case .legacy:
            if let ephemeralKey {
                return PaymentSheet.CustomerConfiguration(id: customerId, ephemeralKeySecret: ephemeralKey)
            }
        case .customerSession:
            if let customerSessionClientSecret {
                return PaymentSheet.CustomerConfiguration(id: customerId, customerSessionClientSecret: customerSessionClientSecret)
            }
        }
        return nil
    }

    var configuration: PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.externalPaymentMethodConfiguration = externalPaymentMethodConfiguration
        configuration.paymentMethodOrder = ["card", "external_paypal"]
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = applePayConfiguration
        configuration.customer = customerConfiguration
        configuration.appearance = appearance
        if settings.userOverrideCountry != .off {
            configuration.userOverrideCountry = settings.userOverrideCountry.rawValue
        }
        configuration.returnURL = "payments-example://stripe-redirect"

        if settings.defaultBillingAddress != .off {
            configuration.defaultBillingDetails.name = "Jane Doe"
            configuration.defaultBillingDetails.address = .init(
                city: "San Francisco",
                country: "US",
                line1: "510 Townsend St.",
                postalCode: "94102",
                state: "California"
            )
        }
        switch settings.defaultBillingAddress {
        case .on:
            configuration.defaultBillingDetails.email = "foo@bar.com"
            configuration.defaultBillingDetails.phone = "+13105551234"
        case .randomEmail:
            configuration.defaultBillingDetails.email = "test-\(UUID().uuidString)@stripe.com"
            configuration.defaultBillingDetails.phone = "+13105551234"
        case .randomEmailNoPhone:
            configuration.defaultBillingDetails.email = "test-\(UUID().uuidString)@stripe.com"
        case .customEmail:
            configuration.defaultBillingDetails.email = settings.customEmail
        case .off:
            break
        }

        if settings.allowsDelayedPMs == .on {
            configuration.allowsDelayedPaymentMethods = true
        }
        if settings.shippingInfo != .off {
            configuration.allowsPaymentMethodsRequiringShippingAddress = true
            configuration.shippingDetails = { [weak self] in
                return self?.addressDetails
            }
        }
        configuration.primaryButtonLabel = settings.customCtaLabel

        configuration.billingDetailsCollectionConfiguration.name = .init(rawValue: settings.collectName.rawValue)!
        configuration.billingDetailsCollectionConfiguration.phone = .init(rawValue: settings.collectPhone.rawValue)!
        configuration.billingDetailsCollectionConfiguration.email = .init(rawValue: settings.collectEmail.rawValue)!
        configuration.billingDetailsCollectionConfiguration.address = .init(rawValue: settings.collectAddress.rawValue)!
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = settings.attachDefaults == .on
        configuration.preferredNetworks = settings.preferredNetworksEnabled == .on ? [.visa, .cartesBancaires] : nil
        configuration.allowsRemovalOfLastSavedPaymentMethod = settings.allowsRemovalOfLastSavedPaymentMethod == .on
        return configuration
    }

    var addressConfiguration: AddressViewController.Configuration {
        var configuration = AddressViewController.Configuration(additionalFields: .init(phone: .optional), appearance: configuration.appearance)
        if case .onWithDefaults = settings.shippingInfo {
            configuration.defaultValues = .init(
                address: .init(
                    city: "San Francisco",
                    country: "US",
                    line1: "510 Townsend St.",
                    postalCode: "94102",
                    state: "California"
                ),
                name: "Jane Doe",
                phone: "5555555555"
            )
            configuration.allowedCountries = ["US", "CA", "MX", "GB"]
        }
        configuration.additionalFields.checkboxLabel = "Save this address for future orders"
        return configuration
    }

    var intentConfig: PaymentSheet.IntentConfiguration {
        var paymentMethodTypes: [String]?
        // if automatic payment methods is off use what is returned back from the intent
        if settings.apmsEnabled == .off {
            paymentMethodTypes = self.paymentMethodTypes
        }
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { [weak self] in
            self?.confirmHandler($0, $1, $2)
        }
        let isCVCRecollectionEnabledCallback = { [weak self] in
            return self?.settings.requireCVCRecollection == .on
        }
        switch settings.mode {
        case .payment:
            return PaymentSheet.IntentConfiguration(
                mode: .payment(amount: amount!, currency: settings.currency.rawValue, setupFutureUsage: nil),
                paymentMethodTypes: paymentMethodTypes,
                paymentMethodConfigurationId: settings.paymentMethodConfigurationId,
                confirmHandler: confirmHandler,
                isCVCRecollectionEnabledCallback: isCVCRecollectionEnabledCallback
            )
        case .paymentWithSetup:
            return PaymentSheet.IntentConfiguration(
                mode: .payment(amount: amount!, currency: settings.currency.rawValue, setupFutureUsage: .offSession),
                paymentMethodTypes: paymentMethodTypes,
                paymentMethodConfigurationId: settings.paymentMethodConfigurationId,
                confirmHandler: confirmHandler,
                isCVCRecollectionEnabledCallback: isCVCRecollectionEnabledCallback
            )
        case .setup:
            return PaymentSheet.IntentConfiguration(
                mode: .setup(currency: settings.currency.rawValue, setupFutureUsage: .offSession),
                paymentMethodTypes: paymentMethodTypes,
                paymentMethodConfigurationId: settings.paymentMethodConfigurationId,
                confirmHandler: confirmHandler
            )
        }
    }

    var customerIdOrType: String {
        switch settings.customerMode {
        case .guest:
            return "guest"
        case .new:
            return customerId ?? "new"
        case .returning:
            return "returning"
        }
    }

    var externalPaymentMethodConfiguration: PaymentSheet.ExternalPaymentMethodConfiguration? {
        guard settings.externalPayPalEnabled == .on else {
            return nil
        }
        return .init(
            externalPaymentMethods: ["external_paypal"]
        ) { [weak self] externalPaymentMethodType, billingDetails, completion in
            self?.handleExternalPaymentMethod(type: externalPaymentMethodType, billingDetails: billingDetails, completion: completion)
        }
    }

    func handleExternalPaymentMethod(type: String, billingDetails: STPPaymentMethodBillingDetails, completion: @escaping (PaymentSheetResult) -> Void) {
        print("Customer is attempting to complete payment with \(type). Their billing details: \(billingDetails)")
        print(billingDetails)
        let alert = UIAlertController(title: "Confirm \(type)?", message: nil, preferredStyle: .alert)
        alert.addAction(.init(title: "Confirm", style: .default) {_ in
            completion(.completed)
        })
        alert.addAction(.init(title: "Cancel", style: .default) {_ in
            completion(.canceled)
        })
        alert.addAction(.init(title: "Fail", style: .default) {_ in
            let exampleError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Something went wrong!"])
            completion(.failed(error: exampleError))
        })
        if self.settings.uiStyle == .paymentSheet {
            self.rootViewController.presentedViewController?.present(alert, animated: true)
        } else {
            self.rootViewController.present(alert, animated: true)
        }
    }

    var clientSecret: String?
    var customerId: String?
    var ephemeralKey: String?
    var customerSessionClientSecret: String?
    var paymentMethodTypes: [String]?
    var amount: Int?
    var checkoutEndpoint: String = PaymentSheetTestPlaygroundSettings.defaultCheckoutEndpoint
    var addressViewController: AddressViewController?
    var appearance = PaymentSheet.Appearance.default
    var currentDataTask: URLSessionDataTask?
    /// All analytic events sent by the SDK since the playground was loaded.
    @Published var analyticsLog: [[String: Any]] = []

    func makeAlertController() -> UIAlertController {
        let alertController = UIAlertController(
            title: "Complete", message: "Completed", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        return alertController
    }

    var rootViewController: UIViewController {
        // Hack, should do this in SwiftUI
        return UIApplication.shared.windows.first!.rootViewController!
    }

    private var subscribers: Set<AnyCancellable> = []

    init(settings: PaymentSheetTestPlaygroundSettings) {
        // Enable experimental payment methods.
        //        PaymentSheet.supportedPaymentMethods += [.link]

        // Hack to ensure we don't force the native flow unless we're in a UI test
        if ProcessInfo.processInfo.environment["UITesting"] == nil {
            UserDefaults.standard.removeObject(forKey: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE")
        } else {
            // This makes the Financial Connections SDK use the native UI instead of webview. Native is much easier to test.
            UserDefaults.standard.set(true, forKey: "FINANCIAL_CONNECTIONS_EXAMPLE_APP_ENABLE_NATIVE")
        }
        self.settings = settings
        self.currentlyRenderedSettings = .defaultValues()

        $settings.sink { newValue in
            if newValue.autoreload == .on {
                self.load()
            }
        }.store(in: &subscribers)

        // Listen for analytics
        STPAnalyticsClient.sharedClient.delegate = self
    }

    func buildPaymentSheet() {
        let mc: PaymentSheet

        switch self.settings.integrationType {
        case .normal:
            switch self.settings.mode {
            case .payment, .paymentWithSetup:
                mc = PaymentSheet(paymentIntentClientSecret: self.clientSecret!, configuration: configuration)
            case .setup:
                mc = PaymentSheet(setupIntentClientSecret: self.clientSecret!, configuration: configuration)
            }
        case .deferred_csc, .deferred_ssc, .deferred_mp, .deferred_mc:
            mc = PaymentSheet(intentConfiguration: intentConfig, configuration: configuration)
        }

        self.paymentSheet = mc
    }

    func didTapShippingAddressButton() {
        // Hack, should do this in SwiftUI
        rootViewController.present(UINavigationController(rootViewController: addressViewController!), animated: true)
    }

    func didTapEndpointConfiguration() {
        let endpointSelector = EndpointSelectorViewController(delegate: self,
                                                              endpointSelectorEndpoint: PaymentSheetTestPlaygroundSettings.endpointSelectorEndpoint,
                                                              currentCheckoutEndpoint: checkoutEndpoint)
        let navController = UINavigationController(rootViewController: endpointSelector)
        rootViewController.present(navController, animated: true, completion: nil)
    }

    func didTapResetConfig() {
        self.settings = PaymentSheetTestPlaygroundSettings.defaultValues()
        PaymentSheet.resetCustomer()
        self.appearance = PaymentSheet.Appearance.default
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

    // Completion

    func onOptionsCompletion() {
        // Tell our observer to refresh
        objectWillChange.send()
    }

    func onPSFCCompletion(result: PaymentSheetResult) {
        self.lastPaymentResult = result
    }

    func onPSCompletion(result: PaymentSheetResult) {
        self.lastPaymentResult = result
    }
}
// MARK: - Backend

extension PlaygroundController {
    @objc
    func load() {
        loadLastSavedCustomer()
        serializeSettingsToNSUserDefaults()
        loadBackend()
    }

    func makeRequest(with url: String, body: [String: Any], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let session = URLSession.shared
        let url = URL(string: url)!

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        if self.currentDataTask?.state == .running {
            self.currentDataTask?.cancel()
        }
        self.currentDataTask = session.dataTask(with: urlRequest) { data, response, error in
            completionHandler(data, response, error)
        }

        self.currentDataTask?.resume()
    }

    func loadBackend() {
        paymentSheetFlowController = nil
        addressViewController = nil
        paymentSheet = nil
        lastPaymentResult = nil
        isLoading = true
        let settingsToLoad = self.settings

        let body = [
            "customer": customerIdOrType,
            "customer_key_type": settings.customerKeyType.rawValue,
            "currency": settings.currency.rawValue,
            "merchant_country_code": settings.merchantCountryCode.rawValue,
            "mode": settings.mode.rawValue,
            "automatic_payment_methods": settings.apmsEnabled == .on,
            "use_link": settings.linkEnabled == .on,
            "use_manual_confirmation": settings.integrationType == .deferred_mc,
            "require_cvc_recollection": settings.requireCVCRecollection == .on,
            //            "set_shipping_address": true // Uncomment to make server vend PI with shipping address populated
        ] as [String: Any]
        makeRequest(with: checkoutEndpoint, body: body) { data, response, error in
            // If the completed load state doesn't represent the current state, reload again
            if settingsToLoad != self.settings {
                DispatchQueue.main.async {
                    self.load()
                }
                return
            }
            if let nserror = error as? NSError, nserror.code == NSURLErrorCancelled {
                // Ignore, we canceled and following up with another request
                return
            }
            guard
                error == nil,
                let data = data,
                let json = try? JSONDecoder().decode([String: String].self, from: data),
                (response as? HTTPURLResponse)?.statusCode != 400
            else {
                print(error as Any)
                DispatchQueue.main.async {
                    var errorMessage = "An error occurred communicating with the example backend."
                    if let data = data,
                       let json = try? JSONDecoder().decode([String: String].self, from: data),
                       let jsonError = json["error"] {
                        errorMessage = jsonError
                    }
                    let error = NSError(domain: "com.stripe.paymentsheetplayground", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    self.lastPaymentResult = .failed(error: error)
                    self.isLoading = false
                    self.currentlyRenderedSettings = self.settings
                }
                return
            }

            DispatchQueue.main.async {
                self.analyticsLog.removeAll()
                self.lastPaymentResult = nil
                self.clientSecret = json["intentClientSecret"]
                self.ephemeralKey = json["customerEphemeralKeySecret"]
                self.customerId = json["customerId"]
                self.customerSessionClientSecret = json["customerSessionClientSecret"]
                self.paymentMethodTypes = json["paymentMethodTypes"]?.components(separatedBy: ",")
                self.amount = Int(json["amount"] ?? "")
                STPAPIClient.shared.publishableKey = json["publishableKey"]

                self.addressViewController = AddressViewController(configuration: self.addressConfiguration, delegate: self)
                self.addressDetails = nil
                // Persist customerId / customerMode
                self.serializeSettingsToNSUserDefaults()
                let intentID = STPPaymentIntent.id(fromClientSecret: self.clientSecret ?? "") // Avoid logging client secrets as a matter of best practice even though this is testmode
                print("✅ Test playground finished loading with intent id: \(intentID ?? "")) and customer id: \(self.customerId ?? "") ")

                if self.settings.uiStyle == .paymentSheet {
                    self.buildPaymentSheet()
                    self.isLoading = false
                    self.currentlyRenderedSettings = self.settings
                } else {
                    let completion: (Result<PaymentSheet.FlowController, Error>) -> Void = { result in
                        self.currentlyRenderedSettings = self.settings
                        switch result {
                        case .failure(let error):
                            print(error as Any)
                        case .success(let manualFlow):
                            self.paymentSheetFlowController = manualFlow
                        }
                        // If the completed load state doesn't represent the current state, reload again
                        if settingsToLoad != self.settings {
                            DispatchQueue.main.async {
                                self.load()
                            }
                            return
                        } else {
                            self.isLoading = false
                        }
                    }
                    switch self.settings.integrationType {
                    case .normal:
                        switch self.settings.mode {
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

                    case .deferred_csc, .deferred_ssc, .deferred_mc, .deferred_mp:
                        PaymentSheet.FlowController.create(
                            intentConfiguration: self.intentConfig,
                            configuration: self.configuration,
                            completion: completion
                        )
                    }
                }
            }
        }
    }
}

// MARK: - AddressViewControllerDelegate
extension PlaygroundController: AddressViewControllerDelegate {
    func addressViewControllerDidFinish(_ addressViewController: AddressViewController, with address: AddressViewController.AddressDetails?) {
        addressViewController.dismiss(animated: true)
        self.addressDetails = address
    }
}

// MARK: - EndpointSelectorViewControllerDelegate
extension PlaygroundController: EndpointSelectorViewControllerDelegate {
    func selected(endpoint: String) {
        checkoutEndpoint = endpoint
        serializeSettingsToNSUserDefaults()
        loadBackend()
        rootViewController.dismiss(animated: true)
    }
    func cancelTapped() {
        rootViewController.dismiss(animated: true)
    }
}

// MARK: Deferred intent callbacks
extension PlaygroundController {
    enum ConfirmHandlerError: Error, LocalizedError {
        case clientSecretNotFound
        case confirmError(String)
        case unknown

        public var errorDescription: String? {
            switch self {
            case .clientSecretNotFound:
                return "Client secret not found in response from server."
            case .confirmError(let errorMesssage):
                return errorMesssage
            case .unknown:
                return "An unknown error occurred."
            }
        }
    }

    // Deferred confirmation handler
    func confirmHandler(_ paymentMethod: STPPaymentMethod,
                        _ shouldSavePaymentMethod: Bool,
                        _ intentCreationCallback: @escaping (Result<String, Error>) -> Void) {
        switch settings.integrationType {
        case .deferred_mp:
            // multiprocessor
            intentCreationCallback(.success(PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT))
            return
        case .deferred_csc:
            if settings.integrationType == .deferred_csc {
                DispatchQueue.global(qos: .background).async {
                    intentCreationCallback(.success(self.clientSecret!))
                }
            }
            return
        case .deferred_mc, .deferred_ssc:
            break
        case .normal:
            assertionFailure()
        }

        let body = [
            "client_secret": clientSecret!,
            "payment_method_id": paymentMethod.stripeId,
            "merchant_country_code": settings.merchantCountryCode.rawValue,
            "should_save_payment_method": shouldSavePaymentMethod,
            "mode": intentConfig.mode.requestBody,
            "return_url": configuration.returnURL ?? "",
        ] as [String: Any]

        makeRequest(with: PaymentSheetTestPlaygroundSettings.confirmEndpoint, body: body, completionHandler: { data, response, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            else {
                if let data = data,
                   (response as? HTTPURLResponse)?.statusCode == 400,
                   let errorMessage = String(data: data, encoding: .utf8){
                    // read the error message
                    intentCreationCallback(.failure(ConfirmHandlerError.confirmError(errorMessage)))
                } else {
                    intentCreationCallback(.failure(error ?? ConfirmHandlerError.unknown))
                }
                return
            }

            guard let clientSecret = json["client_secret"] as? String else {
                intentCreationCallback(.failure(ConfirmHandlerError.clientSecretNotFound))
                return
            }

            intentCreationCallback(.success(clientSecret))
        })
    }
}

extension PaymentSheet.IntentConfiguration.Mode {
    var requestBody: String {
        switch self {
        case .payment:
            return "payment"
        case .setup:
            return "setup"
        @unknown default:
            fatalError()
        }
    }
}

// MARK: - STPAnalyticsClientDelegate

extension PlaygroundController: STPAnalyticsClientDelegate {
    func analyticsClientDidLog(analyticsClient: StripeCore.STPAnalyticsClient, payload: [String: Any]) {
        DispatchQueue.main.async {
            self.analyticsLog.append(payload)
        }
    }
}

// MARK: - Helpers

extension PlaygroundController {
    func serializeSettingsToNSUserDefaults() {
        let data = try! JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: PaymentSheetTestPlaygroundSettings.nsUserDefaultsKey)

        if let customerId {
            let customerIdData = try! JSONEncoder().encode(customerId)
            UserDefaults.standard.set(customerIdData, forKey: PaymentSheetTestPlaygroundSettings.nsUserDefaultsCustomerIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: PaymentSheetTestPlaygroundSettings.nsUserDefaultsCustomerIDKey)
        }
    }

    static func settingsFromDefaults() -> PaymentSheetTestPlaygroundSettings? {
        if let data = UserDefaults.standard.value(forKey: PaymentSheetTestPlaygroundSettings.nsUserDefaultsKey) as? Data {
            do {
                return try JSONDecoder().decode(PaymentSheetTestPlaygroundSettings.self, from: data)
            } catch {
                print("Unable to deserialize saved settings")
                UserDefaults.standard.removeObject(forKey: PaymentSheetTestPlaygroundSettings.nsUserDefaultsKey)
            }
        }
        return nil
    }

    func loadLastSavedCustomer() {
        if let customerIdData = UserDefaults.standard.value(forKey: PaymentSheetTestPlaygroundSettings.nsUserDefaultsCustomerIDKey) as? Data {
            do {
                self.customerId = try JSONDecoder().decode(String.self, from: customerIdData)
            } catch {
                print("Unable to deserialize customerId")
                UserDefaults.standard.removeObject(forKey: PaymentSheetTestPlaygroundSettings.nsUserDefaultsCustomerIDKey)
            }
        } else {
            self.customerId = nil
        }
    }
    static func resetCustomer() {
        UserDefaults.standard.removeObject(forKey: PaymentSheetTestPlaygroundSettings.nsUserDefaultsCustomerIDKey)
    }
}

extension AddressViewController.AddressDetails {
    var localizedDescription: String {
        let formatter = CNPostalAddressFormatter()

        let postalAddress = CNMutablePostalAddress()
        if !address.line1.isEmpty,
           let line2 = address.line2, !line2.isEmpty {
            postalAddress.street = "\(address.line1), \(line2)"
        } else {
            postalAddress.street = "\(address.line1)\(address.line2 ?? "")"
        }
        postalAddress.postalCode = address.postalCode ?? ""
        postalAddress.city = address.city ?? ""
        postalAddress.state = address.state ?? ""
        postalAddress.country = address.country

        return [name, formatter.string(from: postalAddress), phone].compactMap { $0 }.joined(separator: "\n")
    }
}
