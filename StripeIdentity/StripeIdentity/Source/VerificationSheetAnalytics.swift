//
//  VerificationSheetAnalytics.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

#if !targetEnvironment(macCatalyst)

import Foundation
@_spi(STP) import StripeCore

/// Analytic that contains a `verification_session` payload param
protocol VerificationSheetAnalytic: Analytic {
    var verificationSessionId: String? { get }
    var additionalParams: [String: Any] { get }
}

extension VerificationSheetAnalytic {
    var params: [String : Any] {
        var params = additionalParams
        params["verification_session"] = verificationSessionId
        return params
    }
}

/// Logged when the sheet is presented
struct VerificationSheetPresentedAnalytic: VerificationSheetAnalytic {
    let event = STPAnalyticEvent.verificationSheetPresented
    let verificationSessionId: String?
    let additionalParams: [String : Any] = [:]
}

/// Logged when the sheet is closed by the end-user
struct VerificationSheetClosedAnalytic: VerificationSheetAnalytic {
    let event = STPAnalyticEvent.verificationSheetClosed
    let verificationSessionId: String?
    let sessionResult: String

    var additionalParams: [String : Any] {
        return [
            "session_result": sessionResult,
        ]
    }
}

/// Logged if there's an error presenting the sheet
struct VerificationSheetFailedAnalytic: VerificationSheetAnalytic {
    let event = STPAnalyticEvent.verificationSheetFailed
    let verificationSessionId: String?
    let error: Error

    var additionalParams: [String : Any] {
        return [
            "error_dictionary": STPAnalyticsClient.serializeError(error as NSError)
        ]
    }
}

/// Helper to determine if we should log a failed analytic or closed analytic from the sheet's completion block
struct VerificationSheetCompletionAnalytic {
    /// Returns either a `VerificationSheetClosedAnalytic` or `VerificationSheetFailedAnalytic` depending on the result
    static func make(
        verificationSessionId: String?,
        sessionResult result: IdentityVerificationSheet.VerificationFlowResult
    ) -> VerificationSheetAnalytic {
        switch result {
        case .flowCompleted:
            assert(verificationSessionId != nil, "Verification Session ID is nil with completed result.")
            return VerificationSheetClosedAnalytic(
                verificationSessionId: verificationSessionId,
                sessionResult: "flow_completed"
            )
        case .flowCanceled:
            assert(verificationSessionId != nil, "Verification Session ID is nil with canceled result.")
            return VerificationSheetClosedAnalytic(
                verificationSessionId: verificationSessionId,
                sessionResult: "flow_canceled"
            )
        case .flowFailed(let error):
            return VerificationSheetFailedAnalytic(
                verificationSessionId: verificationSessionId,
                error: error
            )
        }
    }
}

#endif
