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
            return .init(elementsSessionConfigId: elementsSession.configID,
                         paymentIntentCreationFlow: .standard,
                         paymentMethodSelectionFlow: paymentIntent.automaticPaymentMethods?.enabled ?? false ? .automatic : .merchantSpecified)
        case .setupIntent(let setupIntent):
            return .init(elementsSessionConfigId: elementsSession.configID,
                         paymentIntentCreationFlow: .standard,
                         paymentMethodSelectionFlow: setupIntent.automaticPaymentMethods?.enabled ?? false ? .automatic : .merchantSpecified)
        case .deferredIntent(let intentConfig):
            return .init(elementsSessionConfigId: elementsSession.configID,
                         paymentIntentCreationFlow: .deferred,
                         paymentMethodSelectionFlow: intentConfig.paymentMethodTypes?.isEmpty ?? true ? .automatic : .merchantSpecified)
        }
    }

    static func makeClientAttributionMetadataForCustomerSheet(elementsSessionConfigId: String) -> STPClientAttributionMetadata {
        return STPClientAttributionMetadata(elementsSessionConfigId: elementsSessionConfigId)
    }
}
