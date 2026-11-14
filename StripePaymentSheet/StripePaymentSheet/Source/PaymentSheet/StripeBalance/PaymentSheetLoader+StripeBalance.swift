//
//  PaymentSheetLoader+StripeBalance.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/12/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// The buyer's financial accounts that a Stripe balance payment can be made from, loaded with PaymentSheet.
struct StripeBalanceFinancialAccounts {
    let accounts: [StripeBalanceFinancialAccount]
    /// The currency the buyer pays in, used to show each account's balance. `nil` when setting up.
    let currency: String?
}

extension PaymentSheetLoader {
    /// Fetches the buyer's financial accounts if `elements/sessions` offers Stripe balance with a CustomerSession to list them with.
    /// When setting up, there's no amount to check the accounts against, so they're all selectable.
    /// - Returns: `nil` if PaymentSheet won't offer Stripe balance, or if the accounts couldn't be loaded within `timeout`, in which case
    ///   PaymentSheet doesn't offer it.
    @MainActor
    static func fetchStripeBalanceFinancialAccounts(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        loadTimings: LoadTimings,
        timeout: TimeInterval = 5.0
    ) async -> StripeBalanceFinancialAccounts? {
        // Don't hold up load for accounts PaymentSheet won't show
        guard elementsSession.orderedPaymentMethodTypes.contains(.stripeBalance),
              PaymentSheet.PaymentMethodType.supportsAdding(
                  paymentMethod: .stripeBalance,
                  configuration: configuration,
                  intent: intent,
                  elementsSession: elementsSession
              ) == .supported,
              case .customerSession(let customerSessionClientSecret) = configuration.customer?.customerAccessProvider,
              // A fallback ElementsSession has no CustomerSession
              let ephemeralKeySecret = elementsSession.customer?.customerSession.apiKey else {
            return nil
        }
        loadTimings.logStart("fetchStripeBalanceFinancialAccounts")
        defer {
            loadTimings.logEnd("fetchStripeBalanceFinancialAccounts")
        }
        let apiClient = configuration.apiClient
        let amount = intent.amount
        let currency = intent.currency
        let result = await withTimeout(timeout) {
            try await apiClient.listStripeBalanceFinancialAccounts(
                customerSessionClientSecret: customerSessionClientSecret,
                ephemeralKeySecret: ephemeralKeySecret,
                amount: amount,
                currency: currency
            )
        }
        switch result {
        case .success(let accounts):
            return StripeBalanceFinancialAccounts(accounts: accounts, currency: currency)
        case .failure(let error):
            analyticsHelper.log(event: .paymentSheetStripeBalanceFinancialAccountsLoadFailed, error: error)
            return nil
        }
    }
}
