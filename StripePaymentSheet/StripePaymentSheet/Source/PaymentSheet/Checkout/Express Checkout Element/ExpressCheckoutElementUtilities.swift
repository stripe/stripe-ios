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
        case automaticTaxAddress = "automatic_tax_address"
        case shippingAddressRequired = "shipping_address_required"
        case billingDetailsCollection = "billing_details_collection"
    }

    static func availablePaymentMethods(
        for apiResponse: PaymentPagesAPIResponse,
        configuration: CheckoutController.Configuration
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        guard let expressCheckoutConfiguration = configuration.expressCheckoutElement else {
            return []
        }
        let elementsSession = apiResponse.elementsSession.value
        let usesWebLink = !deviceCanUseNativeLink(elementsSession: elementsSession, apiClient: configuration.apiClient)

        return availablePaymentMethods(
            for: elementsSession,
            configuration: expressCheckoutConfiguration,
            usesWebLink: usesWebLink,
            requiresShippingAddress: apiResponse.shippingAddressCollection != nil,
            billingDetailsCollectionRequired: apiResponse.billingAddressCollection == "required"
        )
    }

    static func availablePaymentMethods(
        for elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration,
        usesWebLink: Bool,
        requiresShippingAddress: Bool,
        billingDetailsCollectionRequired: Bool
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        var paymentMethods: [ExpressCheckoutElement.PaymentMethod] = []
        for paymentMethod in availablePaymentMethodTypes(for: elementsSession) {
            switch paymentMethod {
            case .applePay:
                if let applePayConfiguration = configuration.applePayConfiguration,
                   applePayConfiguration.display != .never,
                   StripeAPI.deviceSupportsApplePay() {
                    paymentMethods.append(paymentMethod)
                }
            case .link:
                if linkDisabledReasons(
                    for: elementsSession,
                    configuration: configuration,
                    usesWebLink: usesWebLink,
                    requiresShippingAddress: requiresShippingAddress,
                    billingDetailsCollectionRequired: billingDetailsCollectionRequired
                ).isEmpty {
                    paymentMethods.append(paymentMethod)
                }
            }
        }
        guard let paymentMethodOrder = configuration.paymentMethodOrder else {
            return paymentMethods
        }

        var remainingPaymentMethods = paymentMethods
        var orderedPaymentMethods: [ExpressCheckoutElement.PaymentMethod] = []
        for paymentMethod in paymentMethodOrder {
            guard
                let index = remainingPaymentMethods.firstIndex(where: {
                    $0.rawValue.caseInsensitiveCompare(paymentMethod) == .orderedSame
                }),
                !orderedPaymentMethods.contains(where: {
                    $0.rawValue.caseInsensitiveCompare(paymentMethod) == .orderedSame
                })
            else {
                continue
            }
            orderedPaymentMethods.append(remainingPaymentMethods.remove(at: index))
        }
        orderedPaymentMethods.append(contentsOf: remainingPaymentMethods)
        return orderedPaymentMethods
    }

    static func linkDisabledReasons(
        for elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration,
        usesWebLink: Bool,
        requiresShippingAddress: Bool,
        billingDetailsCollectionRequired: Bool
    ) -> [LinkDisabledReason] {
        var reasons: [LinkDisabledReason] = []

        if !availablePaymentMethodTypes(for: elementsSession).contains(.link) {
            reasons.append(.notSupportedInSession)
        }
        if configuration.linkConfiguration.display == .never {
            reasons.append(.linkConfiguration)
        }
        if elementsSession.disableLinkForAutomaticTaxBilling {
            reasons.append(.automaticTaxAddress)
        }
        if requiresShippingAddress {
            reasons.append(.shippingAddressRequired)
        }
        if usesWebLink && billingDetailsCollectionRequired {
            reasons.append(.billingDetailsCollection)
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
