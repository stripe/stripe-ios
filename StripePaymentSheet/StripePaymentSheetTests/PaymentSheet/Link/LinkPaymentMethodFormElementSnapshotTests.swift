//
//  LinkPaymentMethodFormElementSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 10/3/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

final class LinkPaymentMethodFormElementSnapshotTests: STPSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        self.recordMode = true

        // `LinkPaymentMethodFormElement` depends on `AddressSectionElement`, which requires
        // address specs to be loaded in memory.
        let expectation = expectation(description: "Load address specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testDefault() {
        let sut = makeSUT(isDefault: true)
        verify(sut)
    }

    func testNonDefault() {
        let sut = makeSUT(isDefault: false)
        verify(sut)
    }

    func testBillingDetailsUpdate() {
        let sut = makeSUT(isDefault: false, useCVCPlaceholder: true)
        verify(sut)
    }

    func testCoBrandedCard() {
        let sut = makeSUT(isDefault: false, networks: ["cartes_bancaires", "visa"])
        verify(sut)
    }

    func verify(
        _ element: LinkPaymentMethodFormElement,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.view.autosizeHeight(width: 340)
        STPSnapshotVerifyView(element.view, identifier: identifier, file: file, line: line)
    }

}

extension LinkPaymentMethodFormElementSnapshotTests {

    func makeSUT(
        isDefault: Bool,
        useCVCPlaceholder: Bool = false,
        networks: [String] = ["visa"]
    ) -> LinkPaymentMethodFormElement {
        let paymentMethod = ConsumerPaymentDetails(
            stripeID: "1",
            details: .card(
                card: .init(
                    expiryYear: 2032,
                    expiryMonth: 1,
                    brand: "visa",
                    networks: networks,
                    last4: "4242",
                    funding: .credit,
                    checks: nil
                )
            ),
            billingAddress: nil,
            billingEmailAddress: nil,
            nickname: nil,
            isDefault: isDefault
        )

        return LinkPaymentMethodFormElement(
            paymentMethod: paymentMethod,
            configuration: PaymentSheet.Configuration(),
            useCVCPlaceholder: useCVCPlaceholder
        )
    }
}
