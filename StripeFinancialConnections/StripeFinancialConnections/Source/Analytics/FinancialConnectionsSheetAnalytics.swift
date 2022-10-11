//
//  FinancialConnectionsSheetAnalytics.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore

/// Analytic that contains a `financial connections session clientSecret` payload param
@available(iOSApplicationExtension, unavailable)
protocol FinancialConnectionsSheetAnalytic: Analytic {
    var clientSecret: String { get }
    var additionalParams: [String: Any] { get }
}

@available(iOSApplicationExtension, unavailable)
extension FinancialConnectionsSheetAnalytic {
    var params: [String : Any] {
        var params = additionalParams
        params["las_client_secret"] = clientSecret
        return params
    }
}

/// Logged when the sheet is presented
@available(iOSApplicationExtension, unavailable)
struct FinancialConnectionsSheetPresentedAnalytic: FinancialConnectionsSheetAnalytic {
    let event = STPAnalyticEvent.financialConnectionsSheetPresented
    let clientSecret: String
    let additionalParams: [String : Any] = [:]
}

/// Logged when the sheet is closed by the end-user
@available(iOSApplicationExtension, unavailable)
struct FinancialConnectionsSheetClosedAnalytic: FinancialConnectionsSheetAnalytic {
    let event = STPAnalyticEvent.financialConnectionsSheetClosed
    let clientSecret: String
    let result: String

    var additionalParams: [String : Any] {
        return [
            "session_result": result,
        ]
    }
}

/// Logged if there's an error presenting the sheet
@available(iOSApplicationExtension, unavailable)
struct FinancialConnectionsSheetFailedAnalytic: FinancialConnectionsSheetAnalytic, ErrorAnalytic {
    let event = STPAnalyticEvent.financialConnectionsSheetFailed
    let clientSecret: String
    let additionalParams: [String : Any] = [:]
    let error: Error
}

/// Helper to determine if we should log a failed analytic or closed analytic from the sheet's completion block
@available(iOSApplicationExtension, unavailable)
struct FinancialConnectionsSheetCompletionAnalytic {
    /// Returns either a `FinancialConnectionsSheetClosedAnalytic` or `FinancialConnectionsSheetFailedAnalytic` depending on the result
    static func make(
        clientSecret: String,
        result: FinancialConnectionsSheet.Result
    ) -> FinancialConnectionsSheetAnalytic {
        switch result {
        case .completed(session: _):
            return FinancialConnectionsSheetClosedAnalytic(
                clientSecret: clientSecret,
                result: "completed"
            )
        case .canceled:
            return FinancialConnectionsSheetClosedAnalytic(
                clientSecret: clientSecret,
                result: "cancelled"
            )
        case .failed(let error):
            return FinancialConnectionsSheetFailedAnalytic(
                clientSecret: clientSecret,
                error: error
            )
        }
    }
}
