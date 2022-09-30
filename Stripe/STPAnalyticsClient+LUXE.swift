//
//  STPAnalyticsClient+LUXE.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

extension STPAnalyticsClient {
    func logLUXESerializeFailure() {
        self.logPaymentSheetEvent(event: .luxeSerializeFailure)
    }
    func logClientFilteredPaymentMethods(clientFilteredPaymentMethods: String) {
        self.logPaymentSheetEvent(event: .luxeClientFilteredPaymentMethods, params: ["client_filtered_payment_methods": clientFilteredPaymentMethods])
    }
    func logClientFilteredPaymentMethodsNone() {
        self.logPaymentSheetEvent(event: .luxeClientFilteredPaymentMethodsNone)
    }
}
