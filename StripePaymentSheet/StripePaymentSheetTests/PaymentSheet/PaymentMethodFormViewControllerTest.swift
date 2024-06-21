//
//  PaymentMethodFormViewControllerTest.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 5/24/24.
//

import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import XCTest

final class PaymentMethodFormViewControllerTest: XCTestCase {
    var didUpdateDelegateMethodCalled: Bool = false
    override func setUp() {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                PaymentMethodFormViewController.clearFormCache()
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testUpdatesFormWithLatestShippingDetails() {
        // Given a Configuration w/ shipping details...
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        var shippingDetails: AddressViewController.AddressDetails?
        configuration.shippingDetails = {
            return shippingDetails
        }
        // ...and collects billing address...
        configuration.billingDetailsCollectionConfiguration = .init(address: .full)
        // ...and no default billing address...
        XCTAssertEqual(configuration.defaultBillingDetails, PaymentSheet.Configuration().defaultBillingDetails)
        // ...PaymentMethodFormVC...
        let sut = PaymentMethodFormViewController(type: .stripe(.card), intent: ._testPaymentIntent(paymentMethodTypes: [.card]), previousCustomerInput: nil, configuration: configuration, isLinkEnabled: false, headerView: nil, delegate: self)

        // ...should fill its address fields with the shipping address
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()
        XCTAssertEqual(sut.form.getTextFieldElement("Address line 1")?.text, "")

        // ...and updating the shipping address...
        shippingDetails = AddressViewController.AddressDetails(address: .init(country: "US", line1: "Updated line1"))

        // ...and simulating a re-display of the form...
        sut.beginAppearanceTransition(true, animated: false)
        sut.endAppearanceTransition()

        // ...should update its address fields with the shipping address
        XCTAssertEqual(sut.form.getTextFieldElement("Address line 1")?.text, "Updated line1")
    }

    func testHandlesViewDidAppear() {
        // Given a PaymentMethodFormViewController...
        let sut = PaymentMethodFormViewController(
            // ..using cash app as an example b/c it contains a SimpleMandateTextView that we can inspect to test behavior below...
            type: .stripe(.cashApp),
            intent: ._testPaymentIntent(paymentMethodTypes: [.cashApp], setupFutureUsage: .offSession),
            previousCustomerInput: nil,
            configuration: ._testValue_MostPermissive(),
            isLinkEnabled: false,
            headerView: nil,
            delegate: self
        )
        // ...when viewDidAppear is called...
        let mandate = sut.form.getMandateElement()!
        XCTAssertFalse(mandate.mandateTextView.viewDidAppear)
        XCTAssertFalse(didUpdateDelegateMethodCalled)
        sut.viewDidAppear(true)
        // ...sut should notify the form...
        XCTAssertTrue(mandate.mandateTextView.viewDidAppear)
        // ...and notify the delegate
        XCTAssertTrue(didUpdateDelegateMethodCalled)
    }
}

extension PaymentMethodFormViewControllerTest: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: StripePaymentSheet.PaymentMethodFormViewController) {
        didUpdateDelegateMethodCalled = true
    }

    func updateErrorLabel(for error: (any Error)?) {

    }
}
