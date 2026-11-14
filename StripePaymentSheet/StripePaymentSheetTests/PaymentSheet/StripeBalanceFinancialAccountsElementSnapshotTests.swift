//
//  StripeBalanceFinancialAccountsElementSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 11/12/26.
//

import StripeCoreTestUtils
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
@_spi(InternalOnlyAPI) @testable import StripeUICore
import XCTest

@MainActor
final class StripeBalanceFinancialAccountsElementSnapshotTests: STPSnapshotTestCase {

    func testLoadedAccounts() {
        // Given a selected account, an unnamed account, and accounts that can't cover the payment
        let accounts = [
            makeAccount(id: "fa_operating", displayName: "Operating account", balance: 250_000),
            makeAccount(id: "fa_test_1234", displayName: nil, balance: 12_050),
            makeAccount(id: "fa_reserve", displayName: "Reserve", balance: 2_500, eligible: false, ineligibleReason: .insufficientBalance),
            StripeBalanceFinancialAccount(
                id: "fa_gbp",
                displayName: "UK account",
                balance: .init(available: ["gbp": .init(value: 100_000, currency: "gbp")]),
                eligible: false,
                ineligibleReason: .currencyMismatch
            ),
        ]

        // When
        let element = makeElement(accounts: accounts, defaultFinancialAccountID: "fa_operating")

        // Then
        verify(element)
    }

    // MARK: - Helpers

    private func verify(_ element: StripeBalanceFinancialAccountsElement, file: StaticString = #filePath, line: UInt = #line) {
        let view = element.view
        view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(view, file: file, line: line)
    }

    private func makeAccount(
        id: String,
        displayName: String?,
        balance: Int,
        eligible: Bool = true,
        ineligibleReason: StripeBalanceFinancialAccount.IneligibleReason? = nil
    ) -> StripeBalanceFinancialAccount {
        StripeBalanceFinancialAccount(
            id: id,
            displayName: displayName,
            balance: .init(available: ["usd": .init(value: balance, currency: "usd")]),
            eligible: eligible,
            ineligibleReason: ineligibleReason
        )
    }

    private func makeElement(
        accounts: [StripeBalanceFinancialAccount],
        defaultFinancialAccountID: String? = nil
    ) -> StripeBalanceFinancialAccountsElement {
        StripeBalanceFinancialAccountsElement(
            financialAccounts: .init(accounts: accounts, currency: "usd"),
            defaultFinancialAccountID: defaultFinancialAccountID,
            appearance: .default
        )
    }
}
