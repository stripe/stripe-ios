//
//  AuthenticationHandler.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Result type for authentication handler operations
enum AuthenticationHandlerResult {
    case succeeded
    case canceled
    case failed(NSError)
}

/// Protocol for handling different types of payment authentication actions.
///
/// Each implementation handles a specific type of `STPIntentActionType`, allowing
/// the `STPPaymentHandler` to delegate authentication logic to focused, testable components.
protocol AuthenticationHandler {
    /// Determines if this handler can process the given action type.
    /// - Parameter actionType: The type of action to check
    /// - Returns: `true` if this handler can process the action type
    func canHandle(actionType: STPIntentActionType) -> Bool

    /// Handles the authentication action.
    /// - Parameters:
    ///   - action: The intent action containing authentication details
    ///   - currentAction: The current action params containing context and completion
    ///   - paymentHandler: The payment handler instance for accessing shared functionality
    func handle(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    )
}

/// Context passed to authentication handlers containing shared dependencies
struct AuthenticationHandlerContext {
    let apiClient: STPAPIClient
    let analyticsClient: STPAnalyticsClient
    let threeDSCustomizationSettings: STPThreeDSCustomizationSettings

    init(
        apiClient: STPAPIClient,
        analyticsClient: STPAnalyticsClient = .sharedClient,
        threeDSCustomizationSettings: STPThreeDSCustomizationSettings
    ) {
        self.apiClient = apiClient
        self.analyticsClient = analyticsClient
        self.threeDSCustomizationSettings = threeDSCustomizationSettings
    }
}

/// Extension providing error creation helpers for authentication handlers
extension AuthenticationHandler {
    func createError(
        for code: STPPaymentHandlerErrorCode,
        loggingSafeErrorMessage: String? = nil
    ) -> NSError {
        var userInfo: [String: Any] = [:]
        if let loggingSafeErrorMessage {
            userInfo[STPError.errorMessageKey] = loggingSafeErrorMessage
        }
        userInfo[NSLocalizedDescriptionKey] = NSError.stp_unexpectedErrorMessage()

        return NSError(
            domain: STPPaymentHandler.errorDomain,
            code: code.rawValue,
            userInfo: userInfo
        )
    }
}
