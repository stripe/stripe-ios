//
//  FinancialConnectionsAPIClientLogger.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-20.
//

import Foundation
@_spi(STP) import StripeCore

struct FinancialConnectionsAPIClientLogger {
    private var analyticsClient = FinancialConnectionsAnalyticsClient()

    enum API: String {
        case consumerSessionLookup = "consumer_session_lookup"
        case linkSignUp = "link_sign_up"
    }

    enum Event {
        /// When checking if generating attestation is supported does not succeed.
        case attestationInitFailed
        /// When an attestation token gets generated successfully.
        case attestationRequestTokenSucceeded(API)
        /// When a token generation attempt fails client-side.
        case attestationRequestTokenFailed(API, Error)
        /// When an attestation verdict fails backend side and we get an attestation related error.
        case attestationVerdictFailed(API)

        var name: String {
            switch self {
            case .attestationInitFailed:
                return "attestation.init_failed"
            case .attestationRequestTokenSucceeded:
                return "attestation.request_token_succeeded"
            case .attestationRequestTokenFailed:
                return "attestation.request_token_failed"
            case .attestationVerdictFailed:
                return "attestation.verdict_failed"
            }
        }

        var parameters: [String: Any] {
            switch self {
            case .attestationInitFailed:
                var reason: String
                if #available(iOS 14.0, *) {
                    // If the iOS version is supported, we assume the device is unsupported (i.e. simulator).
                    reason = "ios_device_unsupported"
                } else {
                    // Otherwise, attestation is unavailable due to the OS version being unsupported.
                    reason = "ios_os_version_unsupported"
                }
                return ["reason": reason]
            case .attestationRequestTokenFailed(let api, let error):
                var errorReason: String
                if let attestationError = error as? StripeAttest.AttestationError {
                    errorReason = attestationError.rawValue
                } else {
                    errorReason = "unknown"
                }
                return [
                    "api": api.rawValue,
                    "error_reason": errorReason,
                ]
            case .attestationRequestTokenSucceeded(let api), .attestationVerdictFailed(let api):
                return ["api": api.rawValue]
            }
        }
    }

    func log(_ event: Event, pane: FinancialConnectionsSessionManifest.NextPane) {
        analyticsClient.log(
            eventName: event.name,
            parameters: event.parameters,
            pane: pane
        )
    }
}
