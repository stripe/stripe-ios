//
//  ExpressCheckoutElementUtilities.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/28/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

enum ExpressCheckoutElementUtilities {
    enum LinkDisabledReason: String {
        case notSupportedInSession = "not_supported_in_session"
        case linkConfiguration = "link_configuration"
        case shippingAddressCollection = "shipping_address_collection"
        case billingDetailsCollection = "billing_details_collection"
        case automaticTaxAddress = "automatic_tax_address"
    }

    static func resolveButtons(
        for session: CheckoutController.Session,
        configuration: ExpressCheckoutElement.Configuration,
        apiClient: STPAPIClient = .shared
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        var buttons: [ExpressCheckoutElement.PaymentMethod] = []
        for button in session.availableExpressButtonTypes {
            switch button {
            case .applePay:
                if let applePayConfiguration = configuration.applePayConfiguration,
                   applePayConfiguration.display != .never,
                   StripeAPI.deviceSupportsApplePay() {
                    buttons.append(.applePay)
                }
            case .link:
                if linkDisabledReasons(for: session, configuration: configuration, apiClient: apiClient).isEmpty {
                    buttons.append(.link)
                }
            }
        }
        return buttons
    }

    static func linkDisabledReasons(
        for session: CheckoutController.Session,
        configuration: ExpressCheckoutElement.Configuration,
        apiClient: STPAPIClient = .shared
    ) -> [LinkDisabledReason] {
        var reasons: [LinkDisabledReason] = []

        if !session.availableExpressButtonTypes.contains(.link) {
            reasons.append(.notSupportedInSession)
        }
        if configuration.linkConfiguration.display == .never {
            reasons.append(.linkConfiguration)
        }
        if configuration.shippingAddressRequired {
            reasons.append(.shippingAddressCollection)
        }

        let requiresBillingDetails = configuration.billingDetailsCollectionConfiguration.name == .always
        || configuration.billingDetailsCollectionConfiguration.address == .full
        let nativeLinkAvailable = deviceCanUseNativeLink(
            useAttestationEndpoints: session.elementsSession.linkSettings?.useAttestationEndpoints,
            apiClient: apiClient
        )
        if requiresBillingDetails && !nativeLinkAvailable {
            reasons.append(.billingDetailsCollection)
        }
        if session.automaticTaxEnabled {
            reasons.append(.automaticTaxAddress)
        }

        return reasons
    }
}
