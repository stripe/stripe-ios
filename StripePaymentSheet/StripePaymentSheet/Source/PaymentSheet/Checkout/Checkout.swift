//
//  Checkout.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Combine
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Manages a Checkout Session lifecycle.
///
/// Create a `Checkout` instance with your session's client secret, then call
/// ``load()`` to fetch the session from Stripe's servers.
///
/// ```swift
/// let checkout = Checkout(clientSecret: "cs_xxx_secret_yyy")
/// try await checkout.load()
/// print(checkout.session)
/// ```
///
/// In SwiftUI, `Checkout` publishes changes to ``session`` as an `ObservableObject`.
/// In UIKit, set a ``delegate`` to receive ``CheckoutDelegate/checkout(_:didUpdate:)`` callbacks.
@_spi(CheckoutSessionsPreview)
@MainActor
public final class Checkout: ObservableObject {
    // MARK: - Public Properties

    /// The loaded session, or `nil` if ``load()`` hasn't completed yet.
    @Published public private(set) var session: Checkout.Session?

    /// A delegate that is notified when the session changes.
    public weak var delegate: CheckoutDelegate?

    // MARK: - Private Properties

    /// Concrete accessor for internal use where `STPCheckoutSession`-specific
    /// properties (e.g. `allResponseFields`, `billingAddressOverride`) are needed.
    private var stpSession: STPCheckoutSession? {
        get { session as? STPCheckoutSession }
        set { session = newValue }
    }

    /// Whether a session-mutating API call is currently in progress.
    private(set) var isPerformingSessionUpdate: Bool = false
    private let clientSecret: String
    private let apiClient: STPAPIClient

    weak var integrationDelegate: CheckoutIntegrationDelegate?

    // MARK: - Initialization

    /// Creates a new instance.
    /// - Parameters:
    ///   - clientSecret: The client secret for your Checkout Session (e.g. `cs_xxx_secret_yyy`).
    ///   - apiClient: The API client to use. Defaults to ``STPAPIClient.shared``.
    public init(clientSecret: String, apiClient: STPAPIClient = .shared) {
        self.clientSecret = clientSecret
        self.apiClient = apiClient
    }

    // MARK: - Loading

    /// Fetches the Checkout Session from the Stripe API and populates ``session``.
    /// - Throws: ``CheckoutError`` if the request fails.
    public func load() async throws {
        guard !clientSecret.isEmpty else {
            throw CheckoutError.invalidClientSecret
        }
        guard integrationDelegate?.isSheetPresented != true else {
            throw CheckoutError.sheetCurrentlyPresented
        }

        try await withSessionUpdateGuard {
            do {
                let sessionId = Self.extractSessionId(from: clientSecret)
                let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId)
                updateSession(checkoutSession)
            } catch {
                throw CheckoutError.apiError(message: error.nonGenericDescription)
            }
        }
    }

    // MARK: - Promotion Codes

    /// Applies a promotion code to the session.
    /// - Parameter code: The promotion code to apply.
    /// - Throws: ``CheckoutError`` if applying the promotion code fails.
    public func applyPromotionCode(_ code: String) async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setPromotionCode(code))
        }
    }

    /// Removes the currently applied promotion code.
    /// - Throws: `CheckoutError` if removing the promotion code fails.
    public func removePromotionCode() async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setPromotionCode(""))
        }
    }

    // MARK: - Line Items

    /// Updates the quantity of a line item.
    /// - Parameter params: The line item ID and new quantity to set.
    /// - Throws: ``CheckoutError`` if the update fails.
    public func updateQuantity(with params: LineItemUpdate) async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setLineItemQuantity(lineItemId: params.lineItemId, quantity: params.quantity))
        }
    }

    // MARK: - Shipping

    /// Selects a shipping option for the session.
    /// - Parameter optionId: The ID of the shipping rate to select.
    /// - Throws: ``CheckoutError`` if the update fails.
    public func selectShippingOption(_ optionId: String) async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setShippingRate(optionId))
        }
    }

    // MARK: - Addresses

    /// Sets the billing address for this checkout.
    ///
    /// The address is stored locally and merged into PaymentSheet configuration
    /// when presenting payment UI. If automatic tax is enabled and the tax
    /// address source is "billing", the address is also sent to the server to
    /// compute updated tax amounts.
    ///
    /// - Parameter params: The billing address to set. To reset tax computation
    ///   to a country-only region, pass an ``AddressUpdate`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not loaded/open, or if
    ///   the server request fails.
    public func updateBillingAddress(_ params: AddressUpdate) async throws {
        try requireOpenSession()
        if stpSession?.shouldSendTaxRegion(for: "billing") == true {
            try await withSessionUpdateGuard {
                try await performAPIUpdate(.setTaxRegion(params.address))
            }
            stpSession?.billingAddressOverride = params
        } else {
            stpSession?.billingAddressOverride = params
            if let stpSession {
                self.session = stpSession
                delegate?.checkout(self, didUpdate: stpSession)
            }
        }
    }

    /// Sets the shipping address for this checkout.
    ///
    /// The address is stored locally and merged into PaymentSheet configuration
    /// when presenting payment UI. If automatic tax is enabled and the tax
    /// address source is "shipping", the address is also sent to the server to
    /// compute updated tax amounts.
    ///
    /// - Parameter params: The shipping address to set. To reset tax computation
    ///   to a country-only region, pass an ``AddressUpdate`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not loaded/open, or if
    ///   the server request fails.
    public func updateShippingAddress(_ params: AddressUpdate) async throws {
        try requireOpenSession()
        if stpSession?.shouldSendTaxRegion(for: "shipping") == true {
            try await withSessionUpdateGuard {
                try await performAPIUpdate(.setTaxRegion(params.address))
            }
            stpSession?.shippingAddressOverride = params
        } else {
            stpSession?.shippingAddressOverride = params
            if let stpSession {
                self.session = stpSession
                delegate?.checkout(self, didUpdate: stpSession)
            }
        }
    }

    // MARK: - Tax ID

    /// Sets the customer's tax ID on the session.
    /// - Parameter params: The tax ID type and value to set.
    /// - Throws: ``CheckoutError`` if the update fails.
    public func updateTaxId(with params: TaxIdUpdate) async throws {
        try requireOpenSession()
        try await withSessionUpdateGuard {
            try await performAPIUpdate(.setTaxId(type: params.type, value: params.value))
        }
    }

    // MARK: - Internal Methods

    /// Replaces ``session`` and notifies the delegate when the session data has changed.
    func updateSession(_ newSession: STPCheckoutSession) {
        // Carry over client-side address overrides to the new session.
        newSession.billingAddressOverride = stpSession?.billingAddressOverride
        newSession.shippingAddressOverride = stpSession?.shippingAddressOverride
        let changed = stpSession?.allResponseFields as NSDictionary? != newSession.allResponseFields as NSDictionary
        session = newSession
        if changed {
            delegate?.checkout(self, didUpdate: newSession)
        }
    }

    // MARK: - Private Methods

    /// Sets ``isPerformingSessionUpdate`` for the duration of the given async operation.
    private func withSessionUpdateGuard<T>(_ body: () async throws -> T) async rethrows -> T {
        isPerformingSessionUpdate = true
        defer { isPerformingSessionUpdate = false }
        return try await body()
    }

    /// Validates that the session is loaded, open, and no sheet is presented.
    private func requireOpenSession() throws {
        guard let currentSession = session else {
            throw CheckoutError.sessionNotLoaded
        }
        guard currentSession.status == .open else {
            throw CheckoutError.sessionNotOpen
        }
        guard integrationDelegate?.isSheetPresented != true else {
            throw CheckoutError.sheetCurrentlyPresented
        }
    }

    /// Performs an API update, then reloads full session state from init.
    /// The update endpoint can return partial data, so we always refresh from init
    /// to keep ``session`` as the single source of truth.
    private func performAPIUpdate(_ update: SessionUpdate) async throws {
        do {
            let sessionId = Self.extractSessionId(from: clientSecret)
            _ = try await apiClient.updateCheckoutSession(
                checkoutSessionId: sessionId,
                parameters: update.parameters
            )
            let refreshedCheckoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId)
            updateSession(refreshedCheckoutSession)
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

    /// Returns the session ID portion of a client secret.
    ///
    /// Client secrets use the format `cs_xxx_secret_yyy`; this method returns `cs_xxx`.
    nonisolated static func extractSessionId(from clientSecret: String) -> String {
        guard let range = clientSecret.range(of: "_secret_") else {
            return clientSecret
        }
        return String(clientSecret[..<range.lowerBound])
    }

}
