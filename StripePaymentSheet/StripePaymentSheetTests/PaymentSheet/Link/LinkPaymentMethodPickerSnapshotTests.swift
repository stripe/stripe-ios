//
//  LinkPaymentMethodPickerSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

// @iOS26
class LinkPaymentMethodPickerSnapshotTests: STPSnapshotTestCase {

    func testNormal() {
        let mockDataSource = MockDataSource()

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker, identifier: "First Option")

        mockDataSource.selectedIndex = 1
        picker.reloadData()
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
        let paymentMethods = LinkStubs.paymentMethods()
        let mockDataSource = MockDataSource(paymentMethods: paymentMethods)
        mockDataSource.set(paymentMethod: paymentMethods[LinkStubs.PaymentMethodIndices.bankAccount], supported: false)

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.supportedPaymentMethodTypes = [.card]
        picker.layoutSubviews()
        picker.setExpanded(true, animated: false)

        verify(picker)
    }

    func testUnsupportedSelectedNotCollapsed() {
        let paymentMethods = Array(LinkStubs.paymentMethods()[0..<1])
        let mockDataSource = MockDataSource(paymentMethods: paymentMethods)
        mockDataSource.set(paymentMethod: paymentMethods.first!, supported: false)

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.setExpanded(true, animated: false)
        picker.layoutSubviews()

        verify(picker)
    }

    func testFirstOptionUnsupported() {
        let paymentMethods = LinkStubs.paymentMethods()
        let mockDataSource = MockDataSource(paymentMethods: paymentMethods)
        mockDataSource.set(paymentMethod: paymentMethods.first!, supported: false)
        let picker = LinkPaymentMethodPicker()
        mockDataSource.selectedIndex = 1
        picker.dataSource = mockDataSource
        picker.setExpanded(true, animated: false)
        picker.layoutSubviews()

        verify(picker)
    }

    func testEmpty() {
        let mockDataSource = MockDataSource(paymentMethods: [])

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker)
    }

    func testLongEmail() {
        let mockDataSource = MockDataSource(
            paymentMethods: [],
            email: "thisemailislong@example.com"
        )

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker)
    }

    func testLongerEmail() {
        let mockDataSource = MockDataSource(
            paymentMethods: [],
            email: "thisemailisnotreal@examplecompany.com"
        )

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

        let accountEmail: String

        var selectedIndex: Int = 0

        let paymentMethods: [ConsumerPaymentDetails]

        private var supportOverrides: [String: Bool] = [:]

        init(
            paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
            email: String = "test@example.com"
        ) {
            self.paymentMethods = paymentMethods
            self.accountEmail = email
        }

        func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int {
            return paymentMethods.count
        }

        func set(paymentMethod: ConsumerPaymentDetails, supported: Bool) {
            supportOverrides[paymentMethod.stripeID] = supported
        }

        func paymentPicker(
            _ picker: LinkPaymentMethodPicker,
            paymentMethodAt index: Int
        ) -> ConsumerPaymentDetails {
            return paymentMethods[index]
        }

        func isPaymentMethodSupported(_ paymentMethod: ConsumerPaymentDetails?) -> Bool {
            supportOverrides[paymentMethod?.stripeID ?? "", default: true]
        }
    }

}
