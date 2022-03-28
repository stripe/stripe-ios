//
//  STPAnalyticsClient+Link.swift
//  StripeiOS
//
//  Created by Ramon Torres on 2/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAnalyticsClient {

    // MARK: - Signup

    func logLinkSignupCheckboxChecked() {
        self.logPaymentSheetEvent(event: .linkSignupCheckboxChecked)
    }

    func logLinkSignupFlowPresented() {
        self.logPaymentSheetEvent(event: .linkSignupFlowPresented)
    }

    func logLinkSignupStart() {
        AnalyticsHelper.shared.startTimeMeasurement(.linkSignup)
        self.logPaymentSheetEvent(event: .linkSignupStart)
    }

    func logLinkSignupComplete() {
        let duration = AnalyticsHelper.shared.getDuration(for: .linkSignup)
        self.logPaymentSheetEvent(event: .linkSignupComplete, duration: duration)
    }

    func logLinkSignupFailure() {
        self.logPaymentSheetEvent(event: .linkSignupFailure)
    }

    // MARK: - 2FA

    func logLink2FAStart() {
        self.logPaymentSheetEvent(event: .link2FAStart)
    }

    func logLink2FAStartFailure() {
        self.logPaymentSheetEvent(event: .link2FAStartFailure)
    }

    func logLink2FAComplete() {
        self.logPaymentSheetEvent(event: .link2FAComplete)
    }

    func logLink2FAFailure() {
        self.logPaymentSheetEvent(event: .link2FAFailure)
    }

    func logLink2FACancel() {
        self.logPaymentSheetEvent(event: .link2FACancel)
    }

    func logLinkAccountLookupFailure() {
        self.logPaymentSheetEvent(event: .linkAccountLookupFailure)
    }

}
