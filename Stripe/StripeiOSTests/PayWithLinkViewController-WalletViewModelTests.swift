//
//  PayWithLinkViewController-WalletViewModelTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class PayWithLinkViewController_WalletViewModelTests: XCTestCase {

    func test_shouldRecollectCardCVC() throws {
        let sut = try makeSUT()

        // Card with passing CVC checks
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertFalse(sut.shouldRecollectCardCVC)

        // Card with failing CVC checks
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.cardWithFailingChecks
        XCTAssertTrue(
            sut.shouldRecollectCardCVC,
            "Should recollect CVC when CVC checks are failing"
        )

        // Expired card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.expiredCard
        XCTAssertTrue(sut.shouldRecollectCardCVC, "Should recollect CVC when card has expired")

        // Bank account (CVC not supported)
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertFalse(sut.shouldRecollectCardCVC)
    }

    func test_shouldRecollectCardExpiry() throws {
        let sut = try makeSUT()

        // Non-expired card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertFalse(sut.shouldRecollectCardExpiryDate)

        // Expired card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.expiredCard
        XCTAssertTrue(
            sut.shouldRecollectCardExpiryDate,
            "Should recollect new expiry date when card has expired"
        )

        // Bank account (CVC not supported)
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertFalse(sut.shouldRecollectCardCVC)
    }

    func test_shouldShowInstantDebitMandate() throws {
        let sut = try makeSUT()

        // Card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertFalse(sut.shouldShowInstantDebitMandate)

        // Bank account
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertTrue(sut.shouldShowInstantDebitMandate)
    }

    func test_confirmButtonStatus_shouldHandleNoSelection() throws {
        let sut = try makeSUT()

        // No selection
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.notExisting
        XCTAssertEqual(
            sut.confirmButtonStatus,
            .disabled,
            "Button should be disabled when no payment method is selected"
        )

        // Selection
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertEqual(sut.confirmButtonStatus, .enabled)
    }

    func test_confirmButtonStatus_shouldHandleCVCRecollectionRequirements() throws {
        let sut = try makeSUT()

        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.cardWithFailingChecks
        XCTAssertEqual(
            sut.confirmButtonStatus,
            .disabled,
            "Button should be disabled when no CVC is provided and a card with failing CVC checks is selected"
        )

        // Provide a CVC
        sut.cvc = "123"
        XCTAssertEqual(sut.confirmButtonStatus, .enabled)
    }
}

extension PayWithLinkViewController_WalletViewModelTests {

    func makeSUT() throws -> PayWithLinkViewController.WalletViewModel {
        // Link settings don't live in the PaymentIntent object itself, but in the /elements/sessions API response
        // So we construct a minimal response (see STPPaymentIntentTest.testDecodedObjectFromAPIResponseMapping) to parse them
        let paymentIntentJson = try XCTUnwrap(STPTestUtils.jsonNamed(STPTestJSONPaymentIntent))
        let orderedPaymentJson = ["card", "link"]
        let paymentIntentResponse = [
            "payment_intent": paymentIntentJson,
            "ordered_payment_method_types": orderedPaymentJson,
        ] as [String: Any]
        let linkSettingsJson = ["link_funding_sources": ["CARD"]]
        let response = [
            "payment_method_preference": paymentIntentResponse,
            "link_settings": linkSettingsJson,
        ]
        let paymentIntent = try XCTUnwrap(
            STPPaymentIntent.decodedObject(fromAPIResponse: response)
        )

        return PayWithLinkViewController.WalletViewModel(
            // TODO(ramont): Fully mock `PaymentSheetLinkAccount and remove this.
            linkAccount: .init(
                email: "user@example.com",
                session: LinkStubs.consumerSession(),
                publishableKey: nil
            ),
            context: .init(
                intent: .paymentIntent(paymentIntent),
                configuration: .init(),
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                callToAction: nil
            ),
            paymentMethods: LinkStubs.paymentMethods()
        )
    }

}
