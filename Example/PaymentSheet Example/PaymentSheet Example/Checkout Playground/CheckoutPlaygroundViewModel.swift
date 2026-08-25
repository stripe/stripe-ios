//
//  CheckoutPlaygroundViewModel.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import Combine
@_spi(STP) import StripePaymentSheet
import SwiftUI

extension CheckoutPlayground {
    struct ExpressCheckoutElementSettings {
        var option: ExpressCheckoutElementOption = .show
        var applePayDisplay: ExpressCheckoutElement.ApplePayConfiguration.Display = .automatic
        var linkDisplay: ExpressCheckoutElement.LinkConfiguration.Display = .automatic
        var shippingAddressRequired: Bool = false
        var billingDetailsCollectionConfiguration = ExpressCheckoutElement.BillingDetailsCollectionConfiguration()
    }

    @MainActor
    final class ViewModel: ObservableObject {

        // Unified mode currently supports card and Link.
        static let availablePaymentMethods = [
            "card", "link",
        ]

        @Published var uiFramework: UIFramework
        @Published var integrationType: IntegrationType {
            didSet {
                if integrationType == .eceOnly && expressCheckoutElement.option == .hide {
                    expressCheckoutElement.option = .show
                }
            }
        }
        @Published var expressCheckoutElement = ExpressCheckoutElementSettings() {
            didSet {
                if expressCheckoutElement.option == .hide && integrationType == .eceOnly {
                    integrationType = .flowController
                }
            }
        }
        @Published var currency: Currency
        @Published var customerType: CustomerType
        @Published var lineItems: [LineItemConfig]
        @Published var shippingAddressCollection: Bool
        @Published var defaultShippingAddressOption: DefaultShippingAddressOption
        @Published var customDefaultShippingAddress: DefaultShippingAddress
        @Published var billingAddressCollection: BillingAddressCollection
        @Published var automaticTax: Bool
        @Published var checkoutSessionPaymentMethodSave: Bool
        @Published var checkoutSessionPaymentMethodRemove: Bool
        @Published var adaptivePricingCountry: AdaptivePricingCountry
        @Published var automaticPaymentMethods: Bool
        @Published var paymentMethodTypes: Set<String>
        @Published var currencySelectorAppearance: CurrencySelectorElement.Appearance
        @Published var checkoutEndpointOption: EndpointOption
        @Published var checkoutEndpoint: String
        @Published var delayPaymentPagesRequests: Bool

        @Published var isCreating = false
        @Published var errorMessage: String?
        @Published var clientSecret: String?
        @Published var navigateToCheckout = false

        private var settingsSaveSubscription: AnyCancellable?

        init() {
            let settings = Self.settingsFromDefaults() ?? Settings()
            uiFramework = settings.uiFramework
            integrationType = settings.integrationType
            expressCheckoutElement = ExpressCheckoutElementSettings(option: settings.expressCheckoutElementOption)
            currency = settings.currency
            customerType = settings.customerType
            lineItems = settings.lineItems
            shippingAddressCollection = settings.shippingAddressCollection
            defaultShippingAddressOption = settings.defaultShippingAddressOption
            customDefaultShippingAddress = settings.customDefaultShippingAddress
            billingAddressCollection = settings.billingAddressCollection
            automaticTax = settings.automaticTax
            checkoutSessionPaymentMethodSave = settings.checkoutSessionPaymentMethodSave
            checkoutSessionPaymentMethodRemove = settings.checkoutSessionPaymentMethodRemove
            adaptivePricingCountry = settings.adaptivePricingCountry
            automaticPaymentMethods = settings.automaticPaymentMethods
            paymentMethodTypes = settings.paymentMethodTypes
            currencySelectorAppearance = settings.currencySelectorAppearance
            checkoutEndpointOption = settings.checkoutEndpointOption
            checkoutEndpoint = settings.checkoutEndpoint
            delayPaymentPagesRequests = settings.delayPaymentPagesRequests

            settingsSaveSubscription = objectWillChange.sink { [weak self] _ in
                guard let self else {
                    return
                }

                // @Published sends objectWillChange before updating the property.
                DispatchQueue.main.async {
                    self.serializeSettingsToNSUserDefaults()
                }
            }
        }

        var isButtonDisabled: Bool {
            isCreating || (!automaticPaymentMethods && paymentMethodTypes.isEmpty) || lineItems.isEmpty
        }

        var defaultShippingAddress: DefaultShippingAddress? {
            switch defaultShippingAddressOption {
            case .none:
                return nil
            case .usTestAddress:
                return .usTestAddress
            case .custom:
                return customDefaultShippingAddress
            }
        }

        func createSession() async {
            serializeSettingsToNSUserDefaults()
            isCreating = true
            errorMessage = nil
            defer {
                isCreating = false
            }

            do {
                guard let backendURL = URL(string: checkoutEndpoint) else {
                    throw NSError(domain: "CheckoutPlayground", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid endpoint URL: \(checkoutEndpoint)",
                    ])
                }
                let body = buildRequestBody()
                var request = URLRequest(url: backendURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)
                let httpResponse = response as? HTTPURLResponse
                let responseString = String(data: data, encoding: .utf8) ?? "(not utf8)"
                print("[CheckoutPlayground] HTTP status: \(httpResponse?.statusCode ?? -1)")
                print("[CheckoutPlayground] Response body: \(responseString)")

                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let publishableKey = json["publishableKey"] as? String,
                      let clientSecret = json["checkoutSessionClientSecret"] as? String else {
                    throw NSError(domain: "CheckoutPlayground", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid backend response: \(responseString)",
                    ])
                }

                // Example app behavior: the local backend response controls the Stripe publishable key.
                STPAPIClient.shared.publishableKey = publishableKey
                self.clientSecret = clientSecret
                navigateToCheckout = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        func reset() {
            apply(Settings())
        }

        private func buildRequestBody() -> [String: Any] {
            var body: [String: Any] = [
                "merchant_country_code": "us_tax",
                "mode": "unified",
                "use_one_time_price": true,
                "currency": currency.rawValue,
                "customer": customerType.rawValue,
                "shipping_address_collection": shippingAddressCollection,
                "billing_address_collection": billingAddressCollection == .required,
                "automatic_tax": automaticTax,
                "checkout_session_payment_method_save": checkoutSessionPaymentMethodSave ? "enabled" : "disabled",
                "checkout_session_payment_method_remove": checkoutSessionPaymentMethodRemove ? "enabled" : "disabled",
            ]
            if automaticPaymentMethods {
                body["automatic_payment_methods"] = true
            } else {
                body["payment_method_types"] = Array(paymentMethodTypes)
            }
            if adaptivePricingCountry != .none {
                let countryCode = adaptivePricingCountry.rawValue.uppercased()
                body["customer_email"] = "test+location_\(countryCode)@example.com"
            }

            return body
        }

        private var settings: Settings {
            Settings(
                uiFramework: uiFramework,
                integrationType: integrationType,
                expressCheckoutElementOption: expressCheckoutElement.option,
                currency: currency,
                customerType: customerType,
                lineItems: lineItems,
                shippingAddressCollection: shippingAddressCollection,
                defaultShippingAddressOption: defaultShippingAddressOption,
                customDefaultShippingAddress: customDefaultShippingAddress,
                billingAddressCollection: billingAddressCollection,
                automaticTax: automaticTax,
                checkoutSessionPaymentMethodSave: checkoutSessionPaymentMethodSave,
                checkoutSessionPaymentMethodRemove: checkoutSessionPaymentMethodRemove,
                adaptivePricingCountry: adaptivePricingCountry,
                automaticPaymentMethods: automaticPaymentMethods,
                paymentMethodTypes: paymentMethodTypes,
                currencySelectorAppearance: currencySelectorAppearance,
                checkoutEndpointOption: checkoutEndpointOption,
                checkoutEndpoint: checkoutEndpoint,
                delayPaymentPagesRequests: delayPaymentPagesRequests
            )
        }

        private func apply(_ settings: Settings) {
            uiFramework = settings.uiFramework
            integrationType = settings.integrationType
            expressCheckoutElement.option = settings.expressCheckoutElementOption
            currency = settings.currency
            customerType = settings.customerType
            lineItems = settings.lineItems
            shippingAddressCollection = settings.shippingAddressCollection
            defaultShippingAddressOption = settings.defaultShippingAddressOption
            customDefaultShippingAddress = settings.customDefaultShippingAddress
            billingAddressCollection = settings.billingAddressCollection
            automaticTax = settings.automaticTax
            checkoutSessionPaymentMethodSave = settings.checkoutSessionPaymentMethodSave
            checkoutSessionPaymentMethodRemove = settings.checkoutSessionPaymentMethodRemove
            adaptivePricingCountry = settings.adaptivePricingCountry
            automaticPaymentMethods = settings.automaticPaymentMethods
            paymentMethodTypes = settings.paymentMethodTypes
            currencySelectorAppearance = settings.currencySelectorAppearance
            checkoutEndpointOption = settings.checkoutEndpointOption
            checkoutEndpoint = settings.checkoutEndpoint
            delayPaymentPagesRequests = settings.delayPaymentPagesRequests
        }

        private func serializeSettingsToNSUserDefaults() {
            do {
                let data = try JSONEncoder().encode(settings)
                UserDefaults.standard.set(data, forKey: Settings.nsUserDefaultsKey)
            } catch {
                print("Unable to serialize Checkout playground settings: \(error)")
            }
        }

        private static func settingsFromDefaults() -> Settings? {
            guard let data = UserDefaults.standard.data(forKey: Settings.nsUserDefaultsKey) else {
                return nil
            }

            do {
                return try JSONDecoder().decode(Settings.self, from: data)
            } catch {
                print("Unable to deserialize Checkout playground settings: \(error)")
                UserDefaults.standard.removeObject(forKey: Settings.nsUserDefaultsKey)
                return nil
            }
        }
    }
}
