//
//  STPAPIClient+StripeBalance.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/12/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// A buyer's financial account that a Stripe balance payment can be made from.
struct StripeBalanceFinancialAccount: Decodable {
    struct Amount: Decodable, Equatable {
        /// The amount in the currency's minor unit
        let value: Int
        let currency: String
    }

    struct Balance: Decodable {
        /// Available balances keyed by lowercased currency code
        let available: [String: Amount]
    }

    enum IneligibleReason: String, SafeEnumDecodable {
        /// The account holds the currency, but less than the amount
        case insufficientBalance = "insufficient_balance"
        /// The account doesn't hold the currency
        case currencyMismatch = "currency_mismatch"
        /// A reason this version of the SDK doesn't know about
        case unparsable
    }

    let id: String
    let displayName: String?
    let balance: Balance
    /// Whether the account can cover the amount, or `nil` if there's no amount, e.g. when setting up.
    let eligible: Bool?
    /// Why the account can't cover the amount, when `eligible` is `false`.
    let ineligibleReason: IneligibleReason?

    /// Whether the buyer can select this account. Accounts are selectable unless the server says they can't cover the amount.
    var isSelectable: Bool {
        return eligible != false
    }

    /// The available balance in `currency`, if the account holds any.
    func availableBalance(in currency: String) -> Amount? {
        return balance.available[currency.lowercased()]
    }
}

extension STPAPIClient {
    private struct StripeBalanceFinancialAccountList: Decodable {
        let data: [StripeBalanceFinancialAccount]
    }

    /// Lists the financial accounts of the CustomerSession's customer that a Stripe balance payment can be made from.
    /// - Parameters:
    ///   - customerSessionClientSecret: The merchant's CustomerSession client secret
    ///   - ephemeralKeySecret: The ephemeral key that `v1/elements/sessions` issued for the CustomerSession
    ///   - amount: The amount to pay, in the currency's minor unit. The server tags each account's eligibility only when given an amount and currency, so it doesn't when setting up.
    ///   - currency: The currency of `amount`
    func listStripeBalanceFinancialAccounts(
        customerSessionClientSecret: String,
        ephemeralKeySecret: String,
        amount: Int?,
        currency: String?
    ) async throws -> [StripeBalanceFinancialAccount] {
        var parameters: [String: Any] = ["customer_session_client_secret": customerSessionClientSecret]
        if let amount, let currency {
            parameters["amount"] = amount
            parameters["currency"] = currency.lowercased()
        }
        return try await withCheckedThrowingContinuation { continuation in
            get(
                resource: "elements/stripe_balance/customer_session/financial_accounts",
                parameters: parameters,
                ephemeralKeySecret: ephemeralKeySecret
            ) { (result: Result<StripeBalanceFinancialAccountList, Error>) in
                continuation.resume(with: result.map { $0.data })
            }
        }
    }
}
