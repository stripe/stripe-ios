//
//  FinancialConnectionsPreCollectedConsent.swift
//  StripeCore
//

import Foundation

/// Evidence that a customer affirmatively accepted the consent text issued
/// through a Financial Connections Consent object.
///
/// Stripe evaluates this evidence on the server. Supplying it does not
/// guarantee that Financial Connections will skip its consent pane.
///
/// Capture `collectedAt` when the customer affirmatively accepts the complete
/// Stripe-issued consent text, and preserve that value across retries or modal
/// reopen. Do not replace it with the Financial Connections launch time.
@objc(STPFinancialConnectionsPreCollectedConsent)
public final class FinancialConnectionsPreCollectedConsent: NSObject, Encodable {
    /// ID of the `financial_connections.consent` object returned by the merchant's server.
    @objc
    public let consent: String

    /// Unix timestamp, in seconds, when the customer accepted the consent text.
    @objc
    public let collectedAt: Int

    /// Creates evidence for one Financial Connections launch.
    ///
    /// Stripe validates this evidence on the server. The SDK does not validate
    /// the Consent ID, timestamp plausibility, expiry, or clock skew.
    @objc
    public init(
        consent: String,
        collectedAt: Int
    ) {
        self.consent = consent
        self.collectedAt = collectedAt
    }

    private enum CodingKeys: String, CodingKey {
        case consent
        case collectedAt = "collected_at"
    }
}
