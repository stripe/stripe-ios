//
//  STPClientAttributionMetadata+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 10/14/25.
//

@_spi(STP) import StripeCore

extension STPClientAttributionMetadata {
    static func makeClientAttributionMetadataIfNecessary(analyticsHelper: PaymentSheetAnalyticsHelper, intent: Intent, elementsSession: STPElementsSession) -> STPClientAttributionMetadata? {
        if analyticsHelper.integrationShape.isMPE {
            return intent.clientAttributionMetadata(elementsSessionConfigId: elementsSession.sessionID)
        }
        return nil
    }
}
