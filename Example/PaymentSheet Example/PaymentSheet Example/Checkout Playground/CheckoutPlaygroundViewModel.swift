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
        var isEnabled = true
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
                if integrationType == .eceOnly && !expressCheckoutElement.isEnabled {
                    expressCheckoutElement.isEnabled = true
                }
            }
        }
        @Published var expressCheckoutElement = ExpressCheckoutElementSettings() {
            didSet {
                if !expressCheckoutElement.isEnabled && integrationType == .eceOnly {
                    integrationType = .flowController
                }
            }
        }
        @Published var linkMode: LinkMode {
            didSet {
                if isLinkModeOverrideActive {
                    PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = linkMode == .native
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
        private var isLinkModeOverrideActive = false

        init() {
            let settings = Self.settingsFromDefaults() ?? Settings()
            uiFramework = settings.uiFramework
            integrationType = settings.integrationType
            expressCheckoutElement = ExpressCheckoutElementSettings(isEnabled: settings.showExpressCheckoutElement)
            linkMode = settings.linkMode
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
            checkoutEndpoint = EndpointOption.normalizedBaseURL(from: settings.checkoutEndpoint)
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

        func activateLinkModeOverride() {
            isLinkModeOverrideActive = true
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = linkMode == .native
        }

        func deactivateLinkModeOverride() {
            isLinkModeOverrideActive = false
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
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
                guard let backendURL = URL(string: EndpointOption.normalizedBaseURL(from: checkoutEndpoint)) else {
                    throw NSError(domain: "CheckoutPlayground", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid backend URL: \(checkoutEndpoint)",
                    ])
                }
                let backend = PlaygroundBackend(baseURL: backendURL)
                let publishableKey = try await backend.fetchPublishableKey()
                let apiClient = STPAPIClient(publishableKey: publishableKey)
                let clientSecret = try await SessionFactory(backend: backend, apiClient: apiClient).create(
                    currency: currency,
                    customerType: customerType,
                    lineItems: lineItems,
                    shippingAddressCollection: shippingAddressCollection,
                    billingAddressCollection: billingAddressCollection,
                    automaticTax: automaticTax,
                    paymentMethodSave: checkoutSessionPaymentMethodSave,
                    paymentMethodRemove: checkoutSessionPaymentMethodRemove,
                    adaptivePricingCountry: adaptivePricingCountry,
                    automaticPaymentMethods: automaticPaymentMethods,
                    paymentMethodTypes: paymentMethodTypes
                )

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

        private var settings: Settings {
            Settings(
                uiFramework: uiFramework,
                integrationType: integrationType,
                showExpressCheckoutElement: expressCheckoutElement.isEnabled,
                linkMode: linkMode,
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
            expressCheckoutElement.isEnabled = settings.showExpressCheckoutElement
            linkMode = settings.linkMode
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
