//
//  LinkAvailabilityDiagnostic.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripePayments

struct LinkAvailabilityDiagnostic {
    private enum Reason {
        case notSupportedInElementsSession
        case notSupportedInCheckoutSession
        case linkConfiguration
        case cardBrandFiltering
        case billingDetailsCollection
        case automaticTaxBillingAddress
        case shippingAddressRequired
        case billingAddressCollection
        case walletButtonHidden
        case buttonLayout

        var debugDescription: String {
            switch self {
            case .notSupportedInElementsSession:
                return "Link is not supported by this Elements Session."
            case .notSupportedInCheckoutSession:
                return "Link is not supported by this Checkout Session."
            case .linkConfiguration:
                return "LinkConfiguration.display is set to .never."
            case .cardBrandFiltering:
                return "Card brand filtering requires native Link; the web Link flow does not support it."
            case .billingDetailsCollection:
                return "Collecting additional billing details requires native Link; the web Link flow does not support it."
            case .automaticTaxBillingAddress:
                return "Checkout Sessions with automatic tax using the billing address do not support Link."
            case .shippingAddressRequired:
                return "The Link button in Express Checkout Element does not support collecting a shipping address."
            case .billingAddressCollection:
                return "Collecting a billing address requires native Link; the web Link flow does not support it."
            case .walletButtonHidden:
                return "LinkConfiguration.display is set to .walletButtonHidden and no existing Link user was found."
            case .buttonLayout:
                return "The configured button layout does not have room for the Link button."
            }
        }
    }

    private let elementName: String
    private let buttonOnly: Bool
    private let reasons: [Reason]

    private init?(elementName: String, buttonOnly: Bool = false, reasons: [Reason]) {
        guard !reasons.isEmpty else { return nil }
        self.elementName = elementName
        self.buttonOnly = buttonOnly
        self.reasons = reasons
    }

    var debugDescription: String {
        let message = buttonOnly ? "could not show the Link button" : "could not offer Link"
        return "\(elementName) \(message):\n\t* \(reasons.map { $0.debugDescription }.joined(separator: "\n\t* "))"
    }

    static func paymentElementAvailability(elementsSession: STPElementsSession, configuration: PaymentElementConfiguration, elementName: String = "PaymentSheet") -> Self? {
        // The server's messages explain its availability decision, not the shadowed local rules.
        guard elementsSession.serverPaymentMethodAvailability == nil else { return nil }
        let reasons = PaymentSheet.linkDisabledReasons(elementsSession: elementsSession, configuration: configuration).map { reason -> Reason in
            switch reason {
            case .notSupportedInElementsSession: return .notSupportedInElementsSession
            case .linkConfiguration: return .linkConfiguration
            case .cardBrandFiltering: return .cardBrandFiltering
            case .billingDetailsCollection: return .billingDetailsCollection
            case .automaticTaxBillingAddress: return .automaticTaxBillingAddress
            }
        }
        return Self(elementName: elementName, reasons: reasons)
    }

    static func paymentElementButton(elementsSession: STPElementsSession, configuration: PaymentElementConfiguration, elementName: String = "PaymentSheet") -> Self? {
        guard PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration),
              !PaymentSheet.shouldShowLinkButton(elementsSession: elementsSession, configuration: configuration) else {
            return nil
        }
        switch configuration.link.display {
        case .automatic:
            return nil
        case .never:
            return Self(elementName: elementName, buttonOnly: true, reasons: [.linkConfiguration])
        case .walletButtonHidden:
            return Self(elementName: elementName, buttonOnly: true, reasons: [.walletButtonHidden])
        }
    }

    static func expressCheckout(session: CheckoutElementsController.Session, configuration: ExpressCheckoutElement.Configuration, apiClient: STPAPIClient) -> Self? {
        let reasons = ExpressCheckoutElementUtilities.linkDisabledReasons(
            for: session.elementsSession,
            configuration: configuration,
            usesWebLink: !deviceCanUseNativeLink(elementsSession: session.elementsSession, apiClient: apiClient),
            requiresShippingAddress: session.requiresShippingAddress,
            billingDetailsCollectionRequired: session.billingAddressCollection == .required
        ).map { reason -> Reason in
            switch reason {
            case .notSupportedInSession: return .notSupportedInCheckoutSession
            case .linkConfiguration: return .linkConfiguration
            case .automaticTaxAddress: return .automaticTaxBillingAddress
            case .shippingAddressRequired: return .shippingAddressRequired
            case .billingDetailsCollection: return .billingAddressCollection
            }
        }
        if !reasons.isEmpty {
            return Self(elementName: "Express Checkout Element", reasons: reasons)
        }
        if !session.availableExpressCheckoutPaymentMethods.contains(.link) {
            return Self(elementName: "Express Checkout Element", buttonOnly: true, reasons: [.buttonLayout])
        }
        return nil
    }
}
