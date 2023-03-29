//
//  AddPaymentMethodViewControllerSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 3/22/23.
//

import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import XCTest

final class AddPaymentMethodViewControllerSnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
//        recordMode = true
    }

    func test_with_previous_customer_card_details_and_checkbox() {
        // Given the customer previously entered card details...
        let previousCustomerInput = IntentConfirmParams.init(
            params: .paramsWith(card: STPFixtures.paymentMethodCardParams(), billingDetails: STPFixtures.paymentMethodBillingDetails(), metadata: nil),
            type: .card
        )
        previousCustomerInput.saveForFutureUseCheckboxState = .selected
        // ...and the card doesn't show up *first* in the list (so we can exercise the code that switches to the previously entered pm form)...
        let intent = Intent.paymentIntent(STPFixtures.paymentIntent(paymentMethodTypes: ["paypal", "card", "cashApp"]))
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        // ...and a "Save this card" checkbox...
        config.customer = .init(id: "id", ephemeralKeySecret: "ek")
        // ...the AddPMVC should show the card type selected with the form pre-filled with the previous input
        let sut = AddPaymentMethodViewController(intent: intent, configuration: config, previousCustomerInput: previousCustomerInput)
        sut.view.autosizeHeight(width: 375)
        STPSnapshotVerifyView(sut.view)
    }
}
