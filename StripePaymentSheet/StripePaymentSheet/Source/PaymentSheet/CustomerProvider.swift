//
//  CustomerProvider.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

struct CustomerProvider {
    enum Source: Equatable {
        case none
        case legacyEphemeralKey
        case customerSession
        case checkoutSession
    }

    struct CheckoutSaveConsent: Equatable {
        let enabled: Bool
        let initiallyChecked: Bool
    }

    let source: Source
    let customerID: String?
    let checkoutCustomerEmail: String?
    let checkoutCustomerName: String?
    let checkoutCustomerPhone: String?
    let checkoutSavedPaymentMethods: [STPPaymentMethod]
    let checkoutSaveConsent: CheckoutSaveConsent?

    private let configurationCustomerWasSet: Bool
    private let legacyEphemeralKeySecret: String?
    private let customerSessionClientSecret: String?
}

extension CustomerProvider {
    static func none(configurationCustomerWasSet: Bool = false) -> CustomerProvider {
        CustomerProvider(
            source: .none,
            customerID: nil,
            checkoutCustomerEmail: nil,
            checkoutCustomerName: nil,
            checkoutCustomerPhone: nil,
            checkoutSavedPaymentMethods: [],
            checkoutSaveConsent: nil,
            configurationCustomerWasSet: configurationCustomerWasSet,
            legacyEphemeralKeySecret: nil,
            customerSessionClientSecret: nil
        )
    }

    static func make(
        configuration: PaymentElementConfiguration
    ) -> CustomerProvider {
        let configurationCustomerWasSet = configuration.customer != nil

        guard let customer = configuration.customer else {
            return none()
        }

        switch customer.customerAccessProvider {
        case .legacyCustomerEphemeralKey(let ephemeralKeySecret):
            return CustomerProvider(
                source: .legacyEphemeralKey,
                customerID: customer.id,
                checkoutCustomerEmail: nil,
                checkoutCustomerName: nil,
                checkoutCustomerPhone: nil,
                checkoutSavedPaymentMethods: [],
                checkoutSaveConsent: nil,
                configurationCustomerWasSet: configurationCustomerWasSet,
                legacyEphemeralKeySecret: ephemeralKeySecret,
                customerSessionClientSecret: nil
            )
        case .customerSession(let customerSessionClientSecret):
            return CustomerProvider(
                source: .customerSession,
                customerID: customer.id,
                checkoutCustomerEmail: nil,
                checkoutCustomerName: nil,
                checkoutCustomerPhone: nil,
                checkoutSavedPaymentMethods: [],
                checkoutSaveConsent: nil,
                configurationCustomerWasSet: configurationCustomerWasSet,
                legacyEphemeralKeySecret: nil,
                customerSessionClientSecret: customerSessionClientSecret
            )
        }
    }

    static func make(
        customerAccessProvider: PaymentSheet.CustomerAccessProvider?,
        customerID: String? = nil
    ) -> CustomerProvider {
        switch customerAccessProvider {
        case .legacyCustomerEphemeralKey(let ephemeralKeySecret):
            return CustomerProvider(
                source: .legacyEphemeralKey,
                customerID: customerID,
                checkoutCustomerEmail: nil,
                checkoutCustomerName: nil,
                checkoutCustomerPhone: nil,
                checkoutSavedPaymentMethods: [],
                checkoutSaveConsent: nil,
                configurationCustomerWasSet: true,
                legacyEphemeralKeySecret: ephemeralKeySecret,
                customerSessionClientSecret: nil
            )
        case .customerSession(let customerSessionClientSecret):
            return CustomerProvider(
                source: .customerSession,
                customerID: customerID,
                checkoutCustomerEmail: nil,
                checkoutCustomerName: nil,
                checkoutCustomerPhone: nil,
                checkoutSavedPaymentMethods: [],
                checkoutSaveConsent: nil,
                configurationCustomerWasSet: true,
                legacyEphemeralKeySecret: nil,
                customerSessionClientSecret: customerSessionClientSecret
            )
        case nil:
            return none()
        }
    }

    static func make(
        mode: PaymentSheet.InitializationMode,
        configuration: PaymentElementConfiguration
    ) -> CustomerProvider {
        let configurationCustomerWasSet = configuration.customer != nil

        switch mode {
        case .checkoutSession(let checkoutSession):
            let checkoutSaveConsent = checkoutSession.savedPaymentMethodsOfferSave.map {
                CheckoutSaveConsent(
                    enabled: $0.enabled,
                    initiallyChecked: $0.status == .accepted
                )
            }

            return CustomerProvider(
                source: .checkoutSession,
                customerID: checkoutSession.customer?.id,
                checkoutCustomerEmail: checkoutSession.customer?.email ?? checkoutSession.customerEmail,
                checkoutCustomerName: checkoutSession.customer?.name,
                checkoutCustomerPhone: checkoutSession.customer?.phone,
                checkoutSavedPaymentMethods: checkoutSession.customer?.paymentMethods ?? [],
                checkoutSaveConsent: checkoutSaveConsent,
                configurationCustomerWasSet: configurationCustomerWasSet,
                legacyEphemeralKeySecret: nil,
                customerSessionClientSecret: nil
            )
        case .paymentIntentClientSecret, .setupIntentClientSecret, .deferredIntent:
            return make(configuration: configuration)
        }
    }

    static func make(
        intent: Intent,
        configuration: PaymentElementConfiguration
    ) -> CustomerProvider {
        switch intent {
        case .paymentIntent(let paymentIntent):
            return make(mode: .paymentIntentClientSecret(paymentIntent.clientSecret), configuration: configuration)
        case .setupIntent(let setupIntent):
            return make(mode: .setupIntentClientSecret(setupIntent.clientSecret), configuration: configuration)
        case .deferredIntent(let intentConfig):
            return make(mode: .deferredIntent(intentConfig), configuration: configuration)
        case .checkoutSession(let checkoutSession):
            return make(mode: .checkoutSession(checkoutSession), configuration: configuration)
        }
    }

    var hasCustomer: Bool {
        customerID != nil
    }

    var hasConfigurationCustomer: Bool {
        configurationCustomerWasSet
    }

    var usesLegacyEphemeralKey: Bool {
        source == .legacyEphemeralKey
    }

    var usesCustomerSession: Bool {
        source == .customerSession
    }

    var analyticsValue: String? {
        switch source {
        case .none:
            return nil
        case .legacyEphemeralKey:
            return "legacy"
        case .customerSession:
            return "customer_session"
        case .checkoutSession:
            return "checkout_session"
        }
    }

    func addingElementsSessionCustomerParams(to parameters: inout [String: Any]) {
        switch source {
        case .customerSession:
            if let customerSessionClientSecret {
                parameters["customer_session_client_secret"] = customerSessionClientSecret
            }
        case .legacyEphemeralKey:
            if let legacyEphemeralKeySecret {
                parameters["legacy_customer_ephemeral_key"] = legacyEphemeralKeySecret
            }
        case .none, .checkoutSession:
            break
        }
    }

    func ephemeralKeySecret(basedOn elementsSession: STPElementsSession?) -> String? {
        switch source {
        case .legacyEphemeralKey:
            return legacyEphemeralKeySecret
        case .customerSession:
            return elementsSession?.customer?.customerSession.apiKey
        case .none, .checkoutSession:
            return nil
        }
    }

    var customerSessionClientSecretIfAvailable: String? {
        guard usesCustomerSession else {
            return nil
        }
        return customerSessionClientSecret
    }

    var supportsLinkSetupFutureUsage: Bool {
        usesCustomerSession
    }
}
