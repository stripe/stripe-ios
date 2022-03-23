//
//  ConnectionsSheetAnalytics.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/9/21.
//

import Foundation
@_spi(STP) import StripeCore

/// Analytic that contains a `link account session clientSecret` payload param
protocol ConnectionsSheetAnalytic: Analytic {
    var clientSecret: String { get }
    var additionalParams: [String: Any] { get }
}

extension ConnectionsSheetAnalytic {
    var params: [String : Any] {
        var params = additionalParams
        params["las_client_secret"] = clientSecret
        return params
    }
}

/// Logged when the sheet is presented
struct ConnectionsSheetPresentedAnalytic: ConnectionsSheetAnalytic {
    let event = STPAnalyticEvent.connectionsSheetPresented
    let clientSecret: String
    let additionalParams: [String : Any] = [:]
}

/// Logged when the sheet is closed by the end-user
struct ConnectionsSheetClosedAnalytic: ConnectionsSheetAnalytic {
    let event = STPAnalyticEvent.connectionsSheetClosed
    let clientSecret: String
    let result: String

    var additionalParams: [String : Any] {
        return [
            "session_result": result,
        ]
    }
}

/// Logged if there's an error presenting the sheet
struct ConnectionsSheetFailedAnalytic: ConnectionsSheetAnalytic, ErrorAnalytic {
    let event = STPAnalyticEvent.connectionsSheetFailed
    let clientSecret: String
    let additionalParams: [String : Any] = [:]
    let error: AnalyticLoggableError
}

/// Helper to determine if we should log a failed analytic or closed analytic from the sheet's completion block
struct ConnectionsSheetCompletionAnalytic {
    /// Returns either a `ConnectionsSheetClosedAnalytic` or `ConnectionsSheetFailedAnalytic` depending on the result
    static func make(
        clientSecret: String,
        result: ConnectionsSheet.Result
    ) -> ConnectionsSheetAnalytic {
        switch result {
        case .completed(session: _):
            return ConnectionsSheetClosedAnalytic(
                clientSecret: clientSecret,
                result: "completed"
            )
        case .canceled:
            return ConnectionsSheetClosedAnalytic(
                clientSecret: clientSecret,
                result: "cancelled"
            )
        case .failed(let error):
            return ConnectionsSheetFailedAnalytic(
                clientSecret: clientSecret,
                error: error as AnalyticLoggableError
            )
        }
    }
}
