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
}
