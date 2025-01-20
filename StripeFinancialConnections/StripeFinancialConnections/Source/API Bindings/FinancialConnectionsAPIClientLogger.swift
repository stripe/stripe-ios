//
//  FinancialConnectionsAPIClientLogger.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-20.
//

import Foundation

struct FinancialConnectionsAPIClientLogger {
    private var analyticsClient = FinancialConnectionsAnalyticsClient()

    enum Event {
        /// When checking if generating attestation is supported succeeds.
        case attestationInitSucceeded
        /// When checking if generating attestation is supported does not succeed.
        case attestationInitFailed
        /// When an attestation token gets generated successfully.
        case attestationRequestTokenSucceeded
        /// When a token generation attempt fails client-side.
        case attestationRequestTokenFailed
        /// When an attestation verdict fails backend side and we get an attestation related error.
        case attestationVerdictFailed

        var name: String {
            switch self {
            case .attestationInitSucceeded:
                return "attestation.init_succeeded"
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
            default:
                return [:]
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
