//
//  AddPaymentMethodViewControllerSnapshotTests.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 3/22/23.
//

#if !os(visionOS)
import iOSSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) @testable import StripeUICore
import XCTest

// ☠️ WARNING: These snapshots are missing selected borders at the corners on iOS 26 - this is a snapshot-test-only-bug and does not repro on simulator/device.
// iOS26
final class AddPaymentMethodViewControllerSnapshotTests: STPSnapshotTestCase {
    override func setUp() {
        super.setUp()
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func test_with_previous_customer_card_details_and_checkbox() {
        // Given the customer previously entered card details...
        let previousCustomerInput = IntentConfirmParams.init(
            params: .paramsWith(card: STPFixtures.paymentMethodCardParams(), billingDetails: STPFixtures.paymentMethodBillingDetails(), metadata: nil),
            type: .stripe(.card)
        )
        previousCustomerInput.saveForFutureUseCheckboxState = .selected
        // ...and the card doesn't show up *first* in the list (so we can exercise the code that switches to the previously entered pm form)...
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.payPal, .card, .cashApp])
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        // ...and a "Save this card" checkbox...
        config.customer = .init(id: "id", customerSessionClientSecret: "cuss_123")
        // ...the AddPMVC should show the card type selected with the form pre-filled with the previous input
        let sut = AddPaymentMethodViewController(
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: config,
            previousCustomerInput: previousCustomerInput,
            paymentMethodTypes: [.stripe(.payPal), .stripe(.card), .stripe(.cashApp)],
            formCache: .init(),
            analyticsHelper: ._testValue()
        )
        STPSnapshotVerifyView(sut.view, autoSizingHeightForWidth: 375   )
    }

    func test_with_previous_customer_card_details_and_default_checkbox() {
        // Given the customer previously entered card details...
        let previousCustomerInput = IntentConfirmParams.init(
            params: .paramsWith(card: STPFixtures.paymentMethodCardParams(), billingDetails: STPFixtures.paymentMethodBillingDetails(), metadata: nil),
            type: .stripe(.card)
        )
        previousCustomerInput.saveForFutureUseCheckboxState = .selected
        // ...and the card doesn't show up *first* in the list (so we can exercise the code that switches to the previously entered pm form)...
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.payPal, .card, .cashApp])
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        // ...and a "Save this card" checkbox...
        config.customer = .init(id: "id", ephemeralKeySecret: "ek")
        // ...the AddPMVC should show the card type selected with the form pre-filled with the previous input
        let sut = AddPaymentMethodViewController(
            intent: intent,
            // ...and a "Set as default" checkbox...
            elementsSession: ._testValue(intent: intent, paymentMethods: [STPPaymentMethod._testCardJSON], allowsSetAsDefaultPM: true),
            configuration: config,
            previousCustomerInput: previousCustomerInput,
            paymentMethodTypes: [.stripe(.payPal), .stripe(.card), .stripe(.cashApp)],
            formCache: .init(),
            analyticsHelper: ._testValue()
        )
        STPSnapshotVerifyView(sut.view, autoSizingHeightForWidth: 375   )
    }

    func test_link_mode_does_not_show_checkbox() {
        // Given a card PM and default options
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        var config = PaymentSheet.Configuration._testValue_MostPermissive()
        // ...and a "Save this card" checkbox...
        config.customer = .init(id: "id", ephemeralKeySecret: "ek")
        // ... but we're in Link PM mode:
        config.linkPaymentMethodsOnly = true
        // ...the AddPMVC should show the card form without the SFU checkbox.
        let sut = AddPaymentMethodViewController(
            intent: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: config,
            previousCustomerInput: nil,
            paymentMethodTypes: [.stripe(.card)],
            formCache: .init(),
            analyticsHelper: ._testValue()
        )
        STPSnapshotVerifyView(sut.view, autoSizingHeightForWidth: 375   )
    }
}
#endif
