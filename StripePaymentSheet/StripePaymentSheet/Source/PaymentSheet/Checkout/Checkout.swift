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
    @Published public private(set) var session: STPCheckoutSession?

    /// A delegate that is notified when the session changes.
    public weak var delegate: CheckoutDelegate?

    // MARK: - Private Properties

    private let clientSecret: String
    private let apiClient: STPAPIClient

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

        do {
            let sessionId = Self.extractSessionId(from: clientSecret)
            let checkoutSession = try await apiClient.initCheckoutSession(checkoutSessionId: sessionId)
            updateSession(checkoutSession)
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

    // MARK: - Internal Methods

    /// Replaces ``session`` and notifies the delegate when the session data has changed.
    func updateSession(_ newSession: STPCheckoutSession) {
        let changed = session?.allResponseFields as NSDictionary? != newSession.allResponseFields as NSDictionary
        session = newSession
        if changed {
            delegate?.checkout(self, didUpdate: newSession)
        }
    }

    // MARK: - Private Methods

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
