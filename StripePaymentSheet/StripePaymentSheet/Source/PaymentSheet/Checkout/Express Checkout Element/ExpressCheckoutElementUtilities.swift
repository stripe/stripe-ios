//
//  ExpressCheckoutElementUtilities.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/28/26.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

enum ExpressCheckoutElementUtilities {
    enum LinkDisabledReason: String {
        case notSupportedInSession = "not_supported_in_session"
        case linkConfiguration = "link_configuration"
        case automaticTaxAddress = "automatic_tax_address"
        case shippingAddressRequired = "shipping_address_required"
        case billingDetailsCollection = "billing_details_collection"

        var debugDescription: String {
            switch self {
            case .notSupportedInSession:
                return "Link is not supported by this Checkout Session."
            case .linkConfiguration:
                return "LinkConfiguration.display is set to .never."
            case .automaticTaxAddress:
                return "Checkout Sessions with automatic tax using the billing address do not support Link."
            case .shippingAddressRequired:
                return "The Link button in Express Checkout Element does not support collecting a shipping address."
            case .billingDetailsCollection:
                return "Collecting a billing address requires native Link; the web Link flow does not support it."
            }
        }
    }

    static func availablePaymentMethods(
        for apiResponse: CheckoutClientAPIResponse,
        configuration: CheckoutElementsController.Configuration
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        guard let expressCheckoutConfiguration = configuration.expressCheckoutElement else {
            return []
        }
        let elementsSession = apiResponse.elementsSession.value
        let usesWebLink = !deviceCanUseNativeLink(elementsSession: elementsSession, apiClient: configuration.apiClient)

        return availablePaymentMethods(
            for: elementsSession,
            configuration: expressCheckoutConfiguration,
            applePayMerchantId: configuration.applePayMerchantId,
            usesWebLink: usesWebLink,
            requiresShippingAddress: apiResponse.shippingAddressCollection != nil,
            billingDetailsCollectionRequired: apiResponse.billingAddressCollection == "required"
        )
    }

    static func availablePaymentMethods(
        for elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration,
        applePayMerchantId: String?,
        usesWebLink: Bool,
        requiresShippingAddress: Bool,
        billingDetailsCollectionRequired: Bool
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        var paymentMethods: [ExpressCheckoutElement.PaymentMethod] = []
        for paymentMethod in availablePaymentMethodTypes(for: elementsSession) {
            switch paymentMethod {
            case .applePay:
                if applePayMerchantId != nil,
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
        return visiblePaymentMethods(for: paymentMethods, layout: configuration.appearance.buttonLayout)
    }

    static func visiblePaymentMethods(
        for paymentMethods: [ExpressCheckoutElement.PaymentMethod],
        layout: ExpressCheckoutElement.Configuration.Appearance.ButtonLayout
    ) -> [ExpressCheckoutElement.PaymentMethod] {
        // A single limit affects how the buttons are arranged, but it cannot
        // limit the grid's total capacity without the other dimension.
        guard let maxColumns = layout.maxColumns, let maxRows = layout.maxRows else {
            return paymentMethods
        }
        return Array(paymentMethods.prefix(min(maxRows * maxColumns, paymentMethods.count)))
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

    static func logLinkAvailability(session: CheckoutElementsController.Session, configuration: ExpressCheckoutElement.Configuration, apiClient: STPAPIClient) {
        #if DEBUG
        let reasons = linkDisabledReasons(
            for: session.elementsSession,
            configuration: configuration,
            usesWebLink: !deviceCanUseNativeLink(elementsSession: session.elementsSession, apiClient: apiClient),
            requiresShippingAddress: session.requiresShippingAddress,
            billingDetailsCollectionRequired: session.billingAddressCollection == .required
        )
        if !reasons.isEmpty {
            PaymentSheetLoader.logUnavailableLink(reasons: reasons.map { $0.debugDescription }, elementName: "Express Checkout Element")
        } else if !session.availableExpressCheckoutPaymentMethods.contains(.link) {
            PaymentSheetLoader.logUnavailableLink(
                reasons: ["The configured button layout does not have room for the Link button."],
                elementName: "Express Checkout Element",
                buttonOnly: true
            )
        }
        #endif
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
