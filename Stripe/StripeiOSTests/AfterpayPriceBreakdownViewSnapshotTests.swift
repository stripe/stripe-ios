//
//  AfterpayPriceBreakdownViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/15/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class AfterpayPriceBreakdownViewSnapshotTests: STPSnapshotTestCase {
    func embedInRenderableView(
        _ priceBreakdownView: AfterpayPriceBreakdownView,
        width: Int,
        height: Int
    ) -> UIView {
        let containingView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        containingView.addSubview(priceBreakdownView)
        priceBreakdownView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            priceBreakdownView.leadingAnchor.constraint(equalTo: containingView.leadingAnchor),
            containingView.trailingAnchor.constraint(equalTo: priceBreakdownView.trailingAnchor),
            priceBreakdownView.topAnchor.constraint(equalTo: containingView.topAnchor),
            containingView.bottomAnchor.constraint(equalTo: priceBreakdownView.bottomAnchor),
        ])

        return containingView
    }

    func testAfterpayInSingleRow() {
        let priceBreakdownView = AfterpayPriceBreakdownView(currency: "eur")
        let containingView = embedInRenderableView(priceBreakdownView, width: 500, height: 30)

        STPSnapshotVerifyView(containingView)
    }

    func testCashAppAfterpayInSingleRow() {
        let priceBreakdownView = AfterpayPriceBreakdownView(currency: "usd")
        let containingView = embedInRenderableView(priceBreakdownView, width: 500, height: 30)

        STPSnapshotVerifyView(containingView)
    }

    func testCustomAppearance() {
        var appearance = PaymentSheet.Appearance()
        appearance.colors.text = UIColor.red
        appearance.colors.icon = UIColor.purple
        appearance.font.base = UIFont(name: "AmericanTypewriter", size: 20)!
        let priceBreakdownView = AfterpayPriceBreakdownView(currency: "usd", appearance: appearance)
    }
}
