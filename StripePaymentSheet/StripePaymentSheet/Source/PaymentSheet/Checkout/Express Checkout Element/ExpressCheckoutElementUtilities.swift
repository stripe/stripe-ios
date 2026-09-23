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
        case automaticTaxAddress = "automatic_tax_address"
    }

    static func availablePaymentMethods(
        for elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration
    ) -> [String] {
        var paymentMethods: [String] = []
        for paymentMethod in availablePaymentMethodTypes(for: elementsSession) {
            switch paymentMethod {
            case .applePay:
                if let applePayConfiguration = configuration.applePayConfiguration,
                   applePayConfiguration.display != .never,
                   StripeAPI.deviceSupportsApplePay() {
                    paymentMethods.append(paymentMethod.rawValue)
                }
            case .link:
                if linkDisabledReasons(for: elementsSession, configuration: configuration).isEmpty {
                    paymentMethods.append(paymentMethod.rawValue)
                }
            }
        }
        guard let paymentMethodOrder = configuration.paymentMethodOrder else {
            return paymentMethods
        }

        var orderedPaymentMethods: [String] = []
        for paymentMethod in paymentMethodOrder {
            guard
                let index = paymentMethods.firstIndex(where: {
                    $0.caseInsensitiveCompare(paymentMethod) == .orderedSame
                }),
                !orderedPaymentMethods.caseInsensitiveContains(paymentMethod)
            else {
                continue
            }
            orderedPaymentMethods.append(paymentMethods.remove(at: index))
        }
        orderedPaymentMethods.append(contentsOf: paymentMethods)
        return orderedPaymentMethods
    }

    static func linkDisabledReasons(
        for session: CheckoutController.Session,
        configuration: ExpressCheckoutElement.Configuration
    ) -> [LinkDisabledReason] {
        return linkDisabledReasons(for: session.elementsSession, configuration: configuration)
    }

    static func linkDisabledReasons(
        for elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration
    ) -> [LinkDisabledReason] {
        var reasons: [LinkDisabledReason] = []

        if !availablePaymentMethodTypes(for: elementsSession).contains(.link) {
            reasons.append(.notSupportedInSession)
        }
        if configuration.linkConfiguration.display == .never {
            reasons.append(.linkConfiguration)
        }
        if configuration.shippingAddressRequired {
            reasons.append(.shippingAddressCollection)
        }
        if elementsSession.disableLinkForAutomaticTaxBilling {
            reasons.append(.automaticTaxAddress)
        }

        return reasons
    }

    private static func availablePaymentMethodTypes(
        for elementsSession: STPElementsSession
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        var types: [ExpressCheckoutElement.PaymentMethod] = []
        for type in elementsSession.orderedPaymentMethodTypesAndWallets {
            switch type {
            case "apple_pay" where !types.contains(.applePay) && elementsSession.isApplePayEnabled:
                types.append(.applePay)
            case "link" where !types.contains(.link):
                types.append(.link)
            default:
                continue
            }
        }
        if elementsSession.linkPassthroughModeEnabled, !types.contains(.link) {
            types.append(.link)
        }
        return types
    }
}
