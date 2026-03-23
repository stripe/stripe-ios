//
//  PaymentSheetViewControllerTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 3/23/26.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheetViewControllerTest: XCTestCase {

    override func setUpWithError() throws {
        let expectation = expectation(description: "Load specs")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    private func makeLoadResult(savedPaymentMethods: [STPPaymentMethod]) -> PaymentSheetLoader.LoadResult {
        return .init(
            intent: ._testValue(),
            elementsSession: ._testValue(paymentMethodTypes: ["card"], isLinkPassthroughModeEnabled: false),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)]
        )
    }

    private func makeSUT(loadResult: PaymentSheetLoader.LoadResult) -> PaymentSheetViewController {
        return PaymentSheetViewController(
            configuration: ._testValue_MostPermissive(isApplePayEnabled: false),
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            delegate: self
        )
    }

    // MARK: - update(with:) tests

    func testUpdateWithLoadResult_updatesState() {
        let sut = makeSUT(loadResult: makeLoadResult(savedPaymentMethods: []))

        let updatedLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .SEPADebit]),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "sepa_debit"]),
            savedPaymentMethods: [._testCard()],
            paymentMethodTypes: [.stripe(.card), .stripe(.SEPADebit)]
        )

        sut.update(with: updatedLoadResult)

        XCTAssertEqual(sut.loadResult.paymentMethodTypes, [.stripe(.card), .stripe(.SEPADebit)])
        XCTAssertEqual(sut.savedPaymentMethods.count, 1)
    }

    func testUpdateWithLoadResult_switchesToAddingNewWhenSavedPMsEmpty() {
        let sut = makeSUT(loadResult: makeLoadResult(savedPaymentMethods: [._testCard()]))
        XCTAssertTrue(
            sut.children.contains(where: { $0 is SavedPaymentOptionsViewController }),
            "Should initially show saved payment options"
        )

        sut.update(with: makeLoadResult(savedPaymentMethods: []))

        XCTAssertTrue(
            sut.children.contains(where: { $0 is AddPaymentMethodViewController }),
            "Should show add payment method after saved PMs removed"
        )
    }

    func testUpdateWithLoadResult_staysInAddingNewMode() {
        let sut = makeSUT(loadResult: makeLoadResult(savedPaymentMethods: []))
        XCTAssertTrue(
            sut.children.contains(where: { $0 is AddPaymentMethodViewController }),
            "Should initially show add payment method"
        )

        let updatedLoadResult = PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card, .SEPADebit]),
            elementsSession: ._testValue(paymentMethodTypes: ["card", "sepa_debit"]),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card), .stripe(.SEPADebit)]
        )
        sut.update(with: updatedLoadResult)

        XCTAssertTrue(
            sut.children.contains(where: { $0 is AddPaymentMethodViewController }),
            "Should still show add payment method"
        )
    }

    func testUpdateWithLoadResult_clearsFormCache() {
        let sut = makeSUT(loadResult: makeLoadResult(savedPaymentMethods: []))

        // The card form is populated during init; verify it exists
        XCTAssertNotNil(sut.formCache[.stripe(.card)])

        sut.update(with: makeLoadResult(savedPaymentMethods: []))

        // After update, cache was cleared; a PM type not in the new result should be nil
        XCTAssertNil(sut.formCache[.stripe(.SEPADebit)], "Form cache should be cleared after update")
    }
}

extension PaymentSheetViewControllerTest: PaymentSheetViewControllerDelegate {
    func paymentSheetViewControllerShouldConfirm(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {}

    func paymentSheetViewControllerDidFinish(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol,
        result: PaymentSheetResult
    ) {}

    func paymentSheetViewControllerDidCancel(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol
    ) {}

    func paymentSheetViewControllerDidSelectPayWithLink(
        _ paymentSheetViewController: PaymentSheetViewControllerProtocol
    ) {}
}
