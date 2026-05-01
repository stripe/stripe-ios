//
//  BankAccountInfoViewSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by Till Hellmund on 12/17/24.
//

import StripeCoreTestUtils
@testable import StripePaymentSheet
import UIKit

// @iOS26
final class BankAccountInfoViewSnapshotTests: STPSnapshotTestCase {

    private static let frame = CGRect(x: 0, y: 0, width: 320, height: 1000)

    func test_noPromoBadge() {
        let view = BankAccountInfoView(
            frame: Self.frame,
            appearance: PaymentSheet.Appearance.default.applyingLiquidGlassIfPossible(),
            incentive: nil
        )
        view.setBankName(text: "Stripe Bank")
        view.setLastFourOfBank(text: "••••4242")
        view.setIncentiveEligible(false)

        verify(view)
    }

    func test_eligibleForPromo() {
        let view = BankAccountInfoView(
            frame: Self.frame,
            appearance: PaymentSheet.Appearance.default.applyingLiquidGlassIfPossible(),
            incentive: .init(identifier: "link_instant_debits", displayText: "$5")
        )
        view.setBankName(text: "Stripe Bank")
        view.setLastFourOfBank(text: "••••4242")
        view.setIncentiveEligible(true)

        verify(view)
    }

    func test_eligibleForPromo_longName() {
        let view = BankAccountInfoView(
            frame: Self.frame,
            appearance: PaymentSheet.Appearance.default.applyingLiquidGlassIfPossible(),
            incentive: .init(identifier: "link_instant_debits", displayText: "$5")
        )
        view.setBankName(text: "The Official Stripe Bank")
        view.setLastFourOfBank(text: "••••4242")
        view.setIncentiveEligible(true)

        verify(view)
    }

    func test_ineligibleForPromo() {
        let view = BankAccountInfoView(
            frame: Self.frame,
            appearance: PaymentSheet.Appearance.default.applyingLiquidGlassIfPossible(),
            incentive: .init(identifier: "link_instant_debits", displayText: "$5")
        )
        view.setBankName(text: "Stripe Bank")
        view.setLastFourOfBank(text: "•••• 4242")
        view.setIncentiveEligible(false)

        verify(view)
    }

    private func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.backgroundColor = .white
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
