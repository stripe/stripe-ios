//
//  LinkPaymentMethodPickerSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class LinkPaymentMethodPickerSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testNormal() {
        let mockDataSource = MockDataSource()

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker, identifier: "First Option")

        picker.selectedIndex = 1
        verify(picker, identifier: "Second Option")
    }

    func testExpanded() {
        let mockDataSource = MockDataSource()

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()
        picker.setExpanded(true, animated: false)

        verify(picker)
    }

    func testUnsupportedBankAccount() {
        let mockDataSource = MockDataSource()

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.supportedPaymentMethodTypes = [.card]
        picker.layoutSubviews()
        picker.setExpanded(true, animated: false)

        verify(picker)
    }

    func testEmpty() {
        let mockDataSource = MockDataSource(empty: true)

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 335)
        view.backgroundColor = .white
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }

}

extension LinkPaymentMethodPickerSnapshotTests {

    fileprivate final class MockDataSource: LinkPaymentMethodPickerDataSource {
        let paymentMethods: [ConsumerPaymentDetails]

        init(
            empty: Bool = false
        ) {
            self.paymentMethods = empty ? [] : LinkStubs.paymentMethods()
        }

        func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int {
            return paymentMethods.count
        }

        func paymentPicker(
            _ picker: LinkPaymentMethodPicker,
            paymentMethodAt index: Int
        ) -> ConsumerPaymentDetails {
            return paymentMethods[index]
        }
    }

}
