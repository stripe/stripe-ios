//
//  STPClientAttributionMetadata+Factory.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/14/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPClientAttributionMetadata {
    @MainActor
    static func makeClientAttributionMetadata(intent: Intent, elementsSession: STPElementsSession, checkoutAttribution: CheckoutAttributionContext? = nil) -> STPClientAttributionMetadata {
        let elementsSessionConfigId = elementsSession.configID
        switch intent {
        case .paymentIntent(let paymentIntent):
            let isAutomaticPaymentMethodsEnabled = paymentIntent.automaticPaymentMethods?.enabled ?? false // if automaticPaymentMethods is nil, default to merchant_specified
            return .init(elementsSessionConfigId: elementsSessionConfigId,
                         paymentIntentCreationFlow: .standard,
                         paymentMethodSelectionFlow: isAutomaticPaymentMethodsEnabled ? .automatic : .merchantSpecified)
        case .setupIntent(let setupIntent):
            let isAutomaticPaymentMethodsEnabled = setupIntent.automaticPaymentMethods?.enabled ?? false // if automaticPaymentMethods is nil, default to merchant_specified
            return .init(elementsSessionConfigId: elementsSessionConfigId,
                         paymentIntentCreationFlow: .standard,
                         paymentMethodSelectionFlow: isAutomaticPaymentMethodsEnabled ? .automatic : .merchantSpecified)
        case .deferredIntent(let intentConfig):
            let isAutomaticPaymentMethodsEnabled = intentConfig.paymentMethodTypes?.isEmpty ?? true // if no payment method types specified in the intent config, default to automatic
            return .init(elementsSessionConfigId: elementsSessionConfigId,
                         paymentIntentCreationFlow: .deferred,
                         paymentMethodSelectionFlow: isAutomaticPaymentMethodsEnabled ? .automatic : .merchantSpecified)
        case .checkout(let session):
            return makeClientAttributionMetadata(checkoutSession: session, attribution: checkoutAttribution)
        }
    }

    @MainActor
    static func makeClientAttributionMetadata(
        checkoutSession: CheckoutController.Session,
        attribution: CheckoutAttributionContext?
    ) -> STPClientAttributionMetadata {
        stpAssert(attribution != nil, "Checkout CAM requires attribution context.")
        return .init(
            elementsSessionConfigId: checkoutSession.elementsSession.configID,
            checkoutSessionId: checkoutSession.id,
            checkoutConfigId: checkoutSession.checkoutConfigID,
            merchantIntegrationSource: "checkout",
            merchantIntegrationSubtype: attribution?.confirmingElement.rawValue ?? "mobile",
            merchantIntegrationAdditionalElements: attribution?.configuredElements,
            paymentMethodSelectionFlow: checkoutSession.automaticPaymentMethodTypes.map {
                $0 ? .automatic : .merchantSpecified
            }
        )
    }

    static func makeClientAttributionMetadataForCustomerSheet(elementsSessionConfigId: String?) -> STPClientAttributionMetadata {
        return .init(elementsSessionConfigId: elementsSessionConfigId)
    }
}
