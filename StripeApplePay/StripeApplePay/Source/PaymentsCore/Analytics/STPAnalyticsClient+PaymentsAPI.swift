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
    
    func logPaymentIntentConfirmationAttempt(
        paymentMethodType: String?
    ) {
        log(analytic: PaymentAPIAnalytic(
            event: .paymentMethodIntentCreation,
            productUsage: productUsage,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }

    func logSetupIntentConfirmationAttempt(
        paymentMethodType: String?
    ) {
        log(analytic: PaymentAPIAnalytic(
            event: .setupIntentConfirmationAttempt,
            productUsage: productUsage,
            additionalParams: [
                "source_type": paymentMethodType ?? "unknown"
            ]
        ))
    }
}

struct PaymentAPIAnalytic: PaymentAnalytic {
    let event: STPAnalyticEvent
    let productUsage: Set<String>
    let additionalParams: [String : Any]
}
