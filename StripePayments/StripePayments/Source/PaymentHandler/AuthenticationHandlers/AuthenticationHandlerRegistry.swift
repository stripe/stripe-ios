//
//  AuthenticationHandlerRegistry.swift
//  StripePayments
//
//  Created by Claude Code on 2026-01-14.
//  Copyright 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Registry that manages authentication handlers and routes actions to the appropriate handler.
///
/// The registry maintains a list of handlers and provides a single entry point for handling
/// authentication actions. This allows `STPPaymentHandler` to delegate authentication logic
/// to focused, testable components while maintaining a simple interface.
final class AuthenticationHandlerRegistry {

    /// The registered authentication handlers, checked in order
    private let handlers: [AuthenticationHandler]

    /// Creates a new registry with the default set of handlers.
    init() {
        self.handlers = [
            RedirectAuthenticationHandler(),
            VoucherDisplayHandler(),
            PollingAuthenticationHandler(),
            ThreeDS2AuthenticationHandler(),
        ]
    }

    /// Creates a registry with custom handlers (useful for testing).
    /// - Parameter handlers: The handlers to use
    init(handlers: [AuthenticationHandler]) {
        self.handlers = handlers
    }

    /// Finds a handler that can process the given action type.
    /// - Parameter actionType: The action type to find a handler for
    /// - Returns: A handler that can process the action, or nil if none found
    func handler(for actionType: STPIntentActionType) -> AuthenticationHandler? {
        return handlers.first { $0.canHandle(actionType: actionType) }
    }

    /// Handles an authentication action by routing it to the appropriate handler.
    /// - Parameters:
    ///   - action: The intent action to handle
    ///   - currentAction: The current action params
    ///   - paymentHandler: The payment handler instance
    /// - Returns: `true` if a handler was found and invoked, `false` otherwise
    @discardableResult
    func handle(
        action: STPIntentAction,
        currentAction: STPPaymentHandlerActionParams,
        paymentHandler: STPPaymentHandler
    ) -> Bool {
        guard let handler = handler(for: action.type) else {
            return false
        }

        handler.handle(
            action: action,
            currentAction: currentAction,
            paymentHandler: paymentHandler
        )
        return true
    }

    /// Returns whether the registry has a handler for the given action type.
    /// - Parameter actionType: The action type to check
    /// - Returns: `true` if a handler exists for this action type
    func canHandle(actionType: STPIntentActionType) -> Bool {
        return handler(for: actionType) != nil
    }
}
