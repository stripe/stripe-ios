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
        }
    }

    static func makeClientAttributionMetadataForCustomerSheet(elementsSessionConfigId: String?) -> STPClientAttributionMetadata {
        return .init(elementsSessionConfigId: elementsSessionConfigId)
    }
}
