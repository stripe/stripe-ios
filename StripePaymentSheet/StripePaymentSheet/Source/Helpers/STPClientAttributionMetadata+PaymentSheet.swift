//
//  STPClientAttributionMetadata+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/14/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPClientAttributionMetadata {
    static func makeClientAttributionMetadataIfNecessary(analyticsHelper: PaymentSheetAnalyticsHelper, intent: Intent, elementsSession: STPElementsSession) -> STPClientAttributionMetadata? {
        if analyticsHelper.integrationShape.isMPE {
            return makeClientAttributionMetadata(intent: intent, elementsSession: elementsSession)
        }
        return nil
    }

    static func makeClientAttributionMetadata(intent: Intent, elementsSession: STPElementsSession) -> STPClientAttributionMetadata {
        switch intent {
        case .paymentIntent(let paymentIntent):
            return .init(elementsSessionConfigId: elementsSession.sessionID,
                         paymentIntentCreationFlow: .standard,
                         paymentMethodSelectionFlow: paymentIntent.automaticPaymentMethods?.enabled ?? false ? .automatic : .merchantSpecified) // if automaticPaymentMethods is nil, default to merchant_specified
        case .setupIntent(let setupIntent):
            return .init(elementsSessionConfigId: elementsSession.sessionID,
                         paymentIntentCreationFlow: .standard,
                         paymentMethodSelectionFlow: setupIntent.automaticPaymentMethods?.enabled ?? false ? .automatic : .merchantSpecified) // if automaticPaymentMethods is nil, default to merchant_specified
        case .deferredIntent(let intentConfig):
            return .init(elementsSessionConfigId: elementsSession.sessionID,
                         paymentIntentCreationFlow: .deferred,
                         paymentMethodSelectionFlow: intentConfig.paymentMethodTypes?.isEmpty ?? true ? .automatic : .merchantSpecified) // if no payment method types specified in the intent config, default to automatic
        }
    }
}
