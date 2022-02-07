//
//  STPAnalyticsClient+ApplePay.swift
//  StripeApplePay
//
//  Created by David Estes on 1/21/22.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAnalyticsClient {
    // MARK: - Log events
    
    func logPaymentMethodCreationAttempt(paymentMethodType: String?) {
        log(analytic: PaymentAPIAnalytic(
            event: .paymentMethodCreation,
            productUsage: productUsage,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }
    
    func logTokenCreationAttempt(tokenType: String?) {
        log(analytic: PaymentAPIAnalytic(
            event: .tokenCreation,
            productUsage: productUsage,
            additionalParams: [
                "token_type": tokenType ?? "unknown"
            ]
        ))
    }
}

struct PaymentAPIAnalytic: PaymentAnalytic {
    let event: STPAnalyticEvent
    let productUsage: Set<String>
    let additionalParams: [String : Any]
}
