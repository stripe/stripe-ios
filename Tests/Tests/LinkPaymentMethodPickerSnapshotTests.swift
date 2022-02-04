//
//  LinkPaymentMethodPickerSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe

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
        picker.toggleExpanded(animated: false)
        picker.tintColor = .linkBrand

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
        FBSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }

}

private final class MockDataSource: LinkPaymentMethodPickerDataSource {
    let paymentMethods: [ConsumerPaymentDetails] = [
        ConsumerPaymentDetails(
            stripeID: "1",
            details: .card(card: .init(
                expiryYear: 2030,
                expiryMonth: 1,
                brand: "visa",
                last4: "4242",
                allResponseFields: [:]
            )),
            isDefault: true,
            allResponseFields: [:]
        ),
        ConsumerPaymentDetails(
            stripeID: "2",
            details: .card(card: .init(
                expiryYear: 2030,
                expiryMonth: 1,
                brand: "mastercard",
                last4: "4444",
                allResponseFields: [:]
            )),
            isDefault: false,
            allResponseFields: [:]
        ),
        ConsumerPaymentDetails(stripeID: "3",
                               details: .bankAccount(bankAccount: .init(iconCode: "capitalone",
                                                                        name: "Capital One",
                                                                        last4: "4242",
                                                                        allResponseFields: [:])),
                               isDefault: false,
                               allResponseFields: [:]),
    ]

    func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int {
        return paymentMethods.count
    }

    func paymentPicker(_ picker: LinkPaymentMethodPicker, paymentMethodAt index: Int) -> ConsumerPaymentDetails {
        return paymentMethods[index]
    }
}
