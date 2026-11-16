//
//  EmbeddedLinkInlineAuthRegistry.swift
//  StripePaymentSheet
//

import Foundation

/// Remembers inline Link verification across Embedded instances for the rest of the app session, so recreating the element
/// doesn't resend a code or bring back a card the customer closed.
@MainActor
enum EmbeddedLinkInlineAuthRegistry {
    /// How long after an automatic code another instance won't send one, which is about as long as the code is valid.
    static let autoSendCooldown: TimeInterval = 10 * 60

    private static var dismissedEmails: Set<String> = []
    private static var autoSendDates: [String: Date] = [:]
    private static weak var activeOwner: AnyObject?

    static func ineligibleReason(
        email: String,
        now: Date = Date()
    ) -> EmbeddedLinkInlineVerificationEligibility.IneligibleReason? {
        let key = email.lowercased()
        if dismissedEmails.contains(key) {
            return .dismissedThisSession
        }
        if activeOwner != nil {
            return .shownElsewhere
        }
        if let sentDate = autoSendDates[key], now.timeIntervalSince(sentDate) < autoSendCooldown {
            return .codeRecentlySent
        }
        return nil
    }

    /// Marks `owner` as the one instance showing the card.
    static func claim(_ owner: AnyObject) {
        activeOwner = owner
    }

    static func release(_ owner: AnyObject) {
        if activeOwner === owner {
            activeOwner = nil
        }
    }

    static func recordDismissal(email: String) {
        dismissedEmails.insert(email.lowercased())
    }

    static func recordAutoSend(email: String, now: Date = Date()) {
        autoSendDates[email.lowercased()] = now
    }

    /// For tests.
    static func reset() {
        dismissedEmails = []
        autoSendDates = [:]
        activeOwner = nil
    }
}
