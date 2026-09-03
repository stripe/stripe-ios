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
@objc(STPFinancialConnectionsPreCollectedConsent)
public final class FinancialConnectionsPreCollectedConsent: NSObject, Encodable {
    /// ID of the `financial_connections.consent` object returned by the merchant's server.
    @objc
    public let consent: String

    /// Creates evidence for one Financial Connections launch.
    @objc
    public init(
        consent: String
    ) {
        self.consent = consent
    }
}
