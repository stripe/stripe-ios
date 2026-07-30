//
//  SavedPaymentMethodBillingSyncTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
@testable @_spi(STP) import StripeUICore
import XCTest

@MainActor
final class SavedPaymentMethodBillingSyncTests: APIStubbedTestCase {
    override func setUp() async throws {
        try await super.setUp()
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        await AddressSpecProvider.shared.loadAddressSpecs()
        await FormSpecProvider.shared.load()
    }

    func testSelectionSyncsBeforeCompleting() async throws {
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let updateRequest = stubCheckoutUpdate(checkout: checkout)
        let paymentMethods: [STPPaymentMethod] = [
            ._testCard(id: "pm_first", country: "US"),
            ._testCard(id: "pm_second", country: "CA"),
        ]
        let delegate = MockVerticalSavedPaymentMethodsDelegate()
        let sut = makeController(checkout: checkout, paymentMethods: paymentMethods)
        sut.delegate = delegate
        sut.loadViewIfNeeded()
        let selectedRow = rows(in: sut)[1]

        selectedRow.rowButton.handleTap()

        XCTAssertFalse(sut.allowsDragToDismiss)
        XCTAssertTrue(activityIndicator(in: selectedRow)?.isAnimating == true)
        XCTAssertEqual(delegate.completionCount, 0)
        await fulfillment(of: [updateRequest, delegate.completed], timeout: 5)
        XCTAssertEqual(delegate.selectedPaymentMethod?.stripeId, "pm_second")
        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: nil),
            .stripeId("pm_second")
        )
    }

    func testFailureRestoresSelectionAndShowsError() async throws {
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let updateRequest = stubCheckoutUpdate(checkout: checkout, statusCode: 500)
        let paymentMethods: [STPPaymentMethod] = [
            ._testCard(id: "pm_first", country: "US"),
            ._testCard(id: "pm_second", country: "CA"),
        ]
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId("pm_first"), forCustomer: nil)
        let sut = makeController(checkout: checkout, paymentMethods: paymentMethods)
        sut.loadViewIfNeeded()
        let rows = rows(in: sut)

        rows[1].rowButton.handleTap()
        await fulfillment(of: [updateRequest], timeout: 5)
        try await waitUntil { sut.view.isUserInteractionEnabled }

        XCTAssertTrue(rows[0].isSelected, "Previous row should be restored")
        XCTAssertFalse(rows[1].isSelected, "Failed row should be unselected")
        XCTAssertNotEqual(activityIndicator(in: rows[1])?.isAnimating, true)
        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: nil),
            .stripeId("pm_first")
        )
        let errorLabels = labels(in: sut)
        XCTAssertTrue(
            errorLabels.contains { $0.text == "Tax update failed" },
            "Labels: \(errorLabels.compactMap(\.text))"
        )
    }

    func testSelectionWithoutBillingTaxCompletesWithoutLoading() async throws {
        let checkout = try await makeCheckout(automaticTaxEnabled: false)
        let paymentMethods: [STPPaymentMethod] = [
            ._testCard(id: "pm_first", country: "US"),
            ._testCard(id: "pm_second", country: "CA"),
        ]
        let delegate = MockVerticalSavedPaymentMethodsDelegate()
        let sut = makeController(checkout: checkout, paymentMethods: paymentMethods)
        sut.delegate = delegate
        sut.loadViewIfNeeded()
        let selectedRow = rows(in: sut)[1]

        selectedRow.rowButton.handleTap()

        XCTAssertNil(activityIndicator(in: selectedRow))
        await fulfillment(of: [delegate.completed], timeout: 5)
    }
}

private extension SavedPaymentMethodBillingSyncTests {
    func makeCheckout(automaticTaxEnabled: Bool) async throws -> Checkout {
        var sessionJSON = CheckoutTestHelpers.openSessionJSON
        sessionJSON["tax_context"] = [
            "automatic_tax_enabled": automaticTaxEnabled,
            "automatic_tax_address_source": "session.billing",
        ]
        let session = try XCTUnwrap(
            PaymentPagesAPIResponse.decodedObject(fromAPIResponse: sessionJSON)
        )
        return try await Checkout(
            configuration: CheckoutTestHelpers.makeConfiguration(apiResponse: session)
        )
    }

    func stubCheckoutUpdate(
        checkout: Checkout,
        statusCode: Int32 = 200
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Checkout tax region update")
        var responseJSON = CheckoutTestHelpers.openSessionJSON
        responseJSON["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.billing",
        ]
        stub { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/payment_pages/\(checkout.session.id)"
                && RequestBodyTestHelpers.formEncodedBodyParams(from: request)[
                    "tax_region[country]"
                ] != nil
        } response: { _ in
            expectation.fulfill()
            if statusCode >= 400 {
                return HTTPStubsResponse(
                    jsonObject: [
                        "error": [
                            "type": "card_error",
                            "message": "Tax update failed",
                        ],
                    ],
                    statusCode: statusCode,
                    headers: nil
                )
            }
            return HTTPStubsResponse(
                jsonObject: responseJSON,
                statusCode: statusCode,
                headers: nil
            )
        }
        return expectation
    }

    func makeController(
        checkout: Checkout,
        paymentMethods: [STPPaymentMethod]
    ) -> VerticalSavedPaymentMethodsViewController {
        return VerticalSavedPaymentMethodsViewController(
            configuration: EmbeddedPaymentElement.Configuration(),
            intent: .checkout(checkout.session),
            checkout: checkout,
            selectedPaymentMethod: paymentMethods[0],
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
    }

    func rows(
        in viewController: VerticalSavedPaymentMethodsViewController
    ) -> [SavedPaymentMethodRowButton] {
        return viewController.view.subviews
            .compactMap { $0 as? UIStackView }
            .flatMap(\.arrangedSubviews)
            .compactMap { $0 as? SavedPaymentMethodRowButton }
    }

    func labels(
        in viewController: VerticalSavedPaymentMethodsViewController
    ) -> [UILabel] {
        return viewController.view.subviews
            .compactMap { $0 as? UIStackView }
            .flatMap(\.arrangedSubviews)
            .compactMap { $0 as? UILabel }
    }

    func activityIndicator(in row: SavedPaymentMethodRowButton) -> ActivityIndicator? {
        return row.rowButton.subviews.first { $0 is ActivityIndicator } as? ActivityIndicator
    }

    func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<500 where !condition() {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertTrue(condition())
    }
}

@MainActor
private final class MockVerticalSavedPaymentMethodsDelegate:
    VerticalSavedPaymentMethodsViewControllerDelegate
{
    let completed = XCTestExpectation(description: "Selection completed")
    private(set) var completionCount = 0
    private(set) var selectedPaymentMethod: STPPaymentMethod?

    func didComplete(
        viewController: VerticalSavedPaymentMethodsViewController,
        with selectedPaymentMethod: STPPaymentMethod?,
        latestPaymentMethods: [STPPaymentMethod],
        didTapToDismiss: Bool,
        defaultPaymentMethod: STPPaymentMethod?
    ) {
        completionCount += 1
        self.selectedPaymentMethod = selectedPaymentMethod
        completed.fulfill()
    }
}
