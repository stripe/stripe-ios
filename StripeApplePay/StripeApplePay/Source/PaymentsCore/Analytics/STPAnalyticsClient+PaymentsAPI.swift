//
//  STPAnalyticsClient+PaymentsAPI.swift
//  StripeApplePay
//
//  Created by David Estes on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAnalyticsClient {
    // MARK: - Log events

    func logPaymentMethodCreationAttempt(paymentMethodType: String?) {
        log(
            analytic: PaymentAPIAnalytic(
                event: .paymentMethodCreation,
                additionalParams: [
                    "source_type": paymentMethodType ?? "unknown",
                ]
            )
        )
    }

    func logTokenCreationAttempt(tokenType: String?) {
        log(
            analytic: PaymentAPIAnalytic(
                event: .tokenCreation,
                additionalParams: [
                    "token_type": tokenType ?? "unknown",
                ]
            )
        )
    }

    func logPaymentIntentConfirmationAttempt(
        paymentMethodType: String?
    ) {
        log(
            analytic: PaymentAPIAnalytic(
                event: .paymentMethodIntentCreation,
                additionalParams: [
                    "source_type": paymentMethodType ?? "unknown",
                ]
            )
        )
    }

    func logSetupIntentConfirmationAttempt(
        paymentMethodType: String?
    ) {
        log(
            analytic: PaymentAPIAnalytic(
                event: .setupIntentConfirmationAttempt,
                additionalParams: [
                    "source_type": paymentMethodType ?? "unknown",
                ]
            )
        )
    }
}

struct PaymentAPIAnalytic: PaymentAnalytic {
    let event: STPAnalyticEvent
    let additionalParams: [String: Any]
}
