//
//  STPPaymentCardTextFieldSnapshotTests.swift
//  StripePaymentsUI
//
//  Created by David Estes on 9/26/23.
//

import iOSSnapshotTestCase
@_spi(STP)@testable import StripeCore
import StripeCoreTestUtils
import StripePaymentsTestUtils
@_spi(STP)@testable import StripePaymentsUI
@_spi(STP)@testable import StripeUICore

class STPPaymentCardTextFieldSnapshotTests: STPSnapshotTestCase {

    var paymentCardTextField: STPPaymentCardTextField {
        return STPPaymentCardTextField(frame: CGRect(x: 0, y: 0, width: 400, height: 50))
    }

    func testPaymentCardTextField() {
        let pctf = paymentCardTextField
        STPSnapshotVerifyView(pctf)
    }

    func testPaymentCardTextFieldWithNumber() {
        let pctf = paymentCardTextField
        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expMonth = 12
        card.expYear = 43
        // dear future engineer in 2043: i'm sorry
        card.cvc = "123"
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        pctf.paymentMethodParams = params
        STPSnapshotVerifyView(pctf)
    }

    func testPaymentCardTextFieldCBC() {
        STPAPIClient.shared.publishableKey = STPTestingDefaultPublishableKey
        let pctf = paymentCardTextField
        pctf.cbcEnabledOverride = true
        let card = STPPaymentMethodCardParams()
        card.number = "4973019750239993"
        card.expMonth = 12
        card.expYear = 43
        card.cvc = "123"
        let params = STPPaymentMethodParams(card: card, billingDetails: nil, metadata: nil)
        pctf.paymentMethodParams = params
        let exp = expectation(description: "Wait for CBC load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.STPSnapshotVerifyView(pctf)
            exp.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

}
