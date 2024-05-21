//
//  PaymentTypeCellSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 12/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class PaymentTypeCellSnapshotTests: STPSnapshotTestCase {

    func testCardUnselected() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.paymentMethodType = .stripe(.card)
        cell.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: PaymentMethodTypeCollectionView.cellHeight,
                height: PaymentMethodTypeCollectionView.cellHeight
            )
        )
        STPSnapshotVerifyView(cell)
    }

    func testCardSelected() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.paymentMethodType = .stripe(.card)
        cell.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: PaymentMethodTypeCollectionView.cellHeight,
                height: PaymentMethodTypeCollectionView.cellHeight
            )
        )
        cell.isSelected = true
        STPSnapshotVerifyView(cell)
    }

    func testCardUnselected_forceDarkMode() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.overrideUserInterfaceStyle = .dark
        cell.paymentMethodType = .stripe(.card)
        cell.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: PaymentMethodTypeCollectionView.cellHeight,
                height: PaymentMethodTypeCollectionView.cellHeight
            )
        )
        STPSnapshotVerifyView(cell)
    }

    func testCardSelected_forceDarkMode() {
        let cell = PaymentMethodTypeCollectionView.PaymentTypeCell()
        cell.appearance.colors.componentBackground = .black
        cell.overrideUserInterfaceStyle = .dark
        cell.paymentMethodType = .stripe(.card)
        cell.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: PaymentMethodTypeCollectionView.cellHeight,
                height: PaymentMethodTypeCollectionView.cellHeight
            )
        )
        cell.isSelected = true
        STPSnapshotVerifyView(cell)
    }
}
