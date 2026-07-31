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

    // MARK: Embedded manage selection

    func testEmbeddedManageSelection_syncsBeforeCompleting() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let updateRequest = stubCheckoutUpdate(checkout: checkout)
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let secondPaymentMethod = makeSavedPaymentMethod(id: "pm_second", country: "CA")
        let delegate = MockVerticalSavedPaymentMethodsDelegate()
        let sut = makeEmbeddedManageController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, secondPaymentMethod],
            selectedPaymentMethod: firstPaymentMethod
        )
        sut.delegate = delegate
        sut.loadViewIfNeeded()
        let selectedRow = sut.paymentMethodRows[1]

        // When
        selectedRow.rowButton.handleTap()

        // Then
        XCTAssertEqual(selectedRow.rowButton.alpha, 0.6, accuracy: 0.001)
        XCTAssertEqual(activityIndicator(in: selectedRow)?.isAnimating, true)
        XCTAssertFalse(sut.allowsDragToDismiss)
        XCTAssertEqual(delegate.completionCount, 0)
        await fulfillment(of: [updateRequest, delegate.completed], timeout: 5)
        XCTAssertEqual(selectedRow.rowButton.alpha, 0.6, accuracy: 0.001)
        XCTAssertEqual(delegate.selectedPaymentMethod?.stripeId, secondPaymentMethod.stripeId)
    }

    func testEmbeddedManageSelection_syncFails_restoresSelectionAndShowsError() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let updateRequest = stubCheckoutUpdate(checkout: checkout, statusCode: 500)
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let secondPaymentMethod = makeSavedPaymentMethod(id: "pm_second", country: "CA")
        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: nil)
        let delegate = MockVerticalSavedPaymentMethodsDelegate()
        let sut = makeEmbeddedManageController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, secondPaymentMethod],
            selectedPaymentMethod: firstPaymentMethod
        )
        sut.delegate = delegate
        sut.loadViewIfNeeded()
        let firstRow = sut.paymentMethodRows[0]
        let secondRow = sut.paymentMethodRows[1]

        // When
        secondRow.rowButton.handleTap()
        await fulfillment(of: [updateRequest], timeout: 5)
        try await waitUntil { sut.view.isUserInteractionEnabled }

        // Then
        XCTAssertTrue(firstRow.isSelected)
        XCTAssertFalse(secondRow.isSelected)
        XCTAssertEqual(secondRow.rowButton.alpha, 1)
        XCTAssertEqual(activityIndicator(in: secondRow)?.isAnimating, false)
        XCTAssertFalse(sut.errorLabel.isHidden)
        XCTAssertEqual(sut.errorLabel.text, "Tax update failed")
        XCTAssertTrue(sut.allowsDragToDismiss)
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: nil), .link)
        XCTAssertEqual(delegate.completionCount, 0)
    }

    func testEmbeddedManageSelection_syncFails_restoresAlreadySelectedRow() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let updateRequest = stubCheckoutUpdate(checkout: checkout, statusCode: 500)
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let secondPaymentMethod = makeSavedPaymentMethod(id: "pm_second", country: "CA")
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId(firstPaymentMethod.stripeId),
            forCustomer: nil
        )
        let sut = makeEmbeddedManageController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, secondPaymentMethod],
            selectedPaymentMethod: firstPaymentMethod
        )
        sut.loadViewIfNeeded()
        let selectedRow = sut.paymentMethodRows[0]

        // When
        selectedRow.rowButton.handleTap()
        await fulfillment(of: [updateRequest], timeout: 5)
        try await waitUntil { sut.view.isUserInteractionEnabled }

        // Then
        XCTAssertTrue(selectedRow.isSelected)
        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: nil),
            .stripeId(firstPaymentMethod.stripeId)
        )
        XCTAssertEqual(selectedRow.rowButton.alpha, 1)
        XCTAssertEqual(activityIndicator(in: selectedRow)?.isAnimating, false)
    }

    func testEmbeddedManageSelection_withoutBillingTax_completesWithoutLoading() async throws {
        try await assertEmbeddedSelectionCompletesWithoutLoading(
            checkout: makeCheckout(automaticTaxEnabled: false)
        )
    }

    func testEmbeddedManageSelection_withShippingTax_completesWithoutLoading() async throws {
        try await assertEmbeddedSelectionCompletesWithoutLoading(
            checkout: makeCheckout(
                automaticTaxEnabled: true,
                automaticTaxAddressSource: "session.shipping"
            )
        )
    }

    func testEmbeddedManageSelection_withoutBillingCountry_completesWithoutLoading() async throws {
        try await assertEmbeddedSelectionCompletesWithoutLoading(
            checkout: makeCheckout(automaticTaxEnabled: true),
            selectedCountry: ""
        )
    }

    func testEmbeddedManageSelection_withoutCheckout_completesWithoutLoading() async throws {
        try await assertEmbeddedSelectionCompletesWithoutLoading(checkout: nil)
    }

    // MARK: Billing sync requirement

    func testBillingSyncRequirement_requiresBillingTaxAndCountry() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let paymentMethodWithCountry = makeSavedPaymentMethod(id: "pm_country", country: "US")
        let paymentMethodWithoutCountry = makeSavedPaymentMethod(id: "pm_no_country", country: "")

        // Then
        XCTAssertTrue(
            checkout.requiresBillingAddressSync(
                from: paymentMethodWithCountry.billingDetails
            )
        )
        XCTAssertFalse(
            checkout.requiresBillingAddressSync(
                from: paymentMethodWithoutCountry.billingDetails
            )
        )
    }

    // MARK: Horizontal FlowController

    func testHorizontalSavedCell_loadingUsesSelectionIndicatorAndShowsSuccess() {
        // Given
        let paymentMethod = makeSavedPaymentMethod(id: "pm_saved", country: "US")
        let cell = SavedPaymentMethodCollectionView.PaymentOptionCell(
            frame: CGRect(x: 0, y: 0, width: 100, height: 64)
        )
        cell.setViewModel(
            .saved(paymentMethod: paymentMethod),
            cbcEligible: false,
            allowsPaymentMethodRemoval: true,
            allowsPaymentMethodUpdate: true
        )

        // When
        cell.setLoading(true)

        // Then
        XCTAssertEqual(cell.paymentMethodLogo.alpha, 1)
        XCTAssertFalse(cell.selectedIcon.isHidden)
        XCTAssertEqual(cell.selectedIcon.imageView.alpha, 0)
        XCTAssertEqual(activityIndicatorCount(in: cell.selectableRectangle), 0)
        XCTAssertEqual(activityIndicatorCount(in: cell.selectedIcon), 1)
        XCTAssertEqual(activityIndicator(in: cell.selectedIcon)?.alpha, 1)

        // When
        cell.showSuccess()

        // Then
        XCTAssertEqual(cell.selectedIcon.imageView.alpha, 1)
        // When
        cell.setLoading(false)

        // Then
        XCTAssertEqual(cell.paymentMethodLogo.alpha, 1)
        XCTAssertEqual(activityIndicator(in: cell.selectedIcon)?.isAnimating, false)
    }

    func testHorizontalSavedSelection_withoutCTA_syncsBeforeClosing() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let updateRequest = stubCheckoutUpdate(checkout: checkout)
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let secondPaymentMethod = makeSavedPaymentMethod(id: "pm_second", country: "CA")
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId(firstPaymentMethod.stripeId),
            forCustomer: nil
        )
        let delegate = MockFlowControllerViewControllerDelegate()
        let sut = makeHorizontalController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, secondPaymentMethod]
        )
        sut.flowControllerDelegate = delegate
        sut.loadViewIfNeeded()
        let savedOptions = sut.savedPaymentOptionsViewController
        savedOptions.loadViewIfNeeded()
        sut.view.autosizeHeight(width: 375)
        let selectedCell = try XCTUnwrap(
            savedOptions.collectionView.cellForItem(at: IndexPath(item: 2, section: 0))
                as? SavedPaymentMethodCollectionView.PaymentOptionCell
        )

        // When
        savedOptions.collectionView(
            savedOptions.collectionView,
            didSelectItemAt: IndexPath(item: 2, section: 0)
        )

        // Then
        XCTAssertFalse(sut.isDismissable)
        XCTAssertEqual(selectedCell.paymentMethodLogo.alpha, 0.6, accuracy: 0.001)
        XCTAssertEqual(selectedCell.selectedIcon.imageView.alpha, 0)
        XCTAssertEqual(activityIndicatorCount(in: selectedCell.selectableRectangle), 0)
        XCTAssertEqual(activityIndicatorCount(in: selectedCell.selectedIcon), 1)
        XCTAssertEqual(delegate.closeCount, 0)
        await fulfillment(of: [updateRequest], timeout: 5)
        try await waitUntil {
            selectedCell.selectedIcon.imageView.alpha == 1
                && activityIndicator(in: selectedCell.selectedIcon)?.isAnimating == false
        }
        XCTAssertEqual(delegate.closeCount, 0)
        await fulfillment(of: [delegate.closed], timeout: 5)
        XCTAssertEqual(delegate.closeCount, 1)
        XCTAssertFalse(delegate.didCancel)
        XCTAssertTrue(sut.isDismissable)
        XCTAssertTrue(sut.view.isUserInteractionEnabled)
        XCTAssertEqual(selectedCell.paymentMethodLogo.alpha, 1)
        XCTAssertEqual(activityIndicator(in: selectedCell.selectedIcon)?.isAnimating, false)
    }

    func testHorizontalSavedSelection_syncFails_restoresSelectionAndShowsError() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let updateRequest = stubCheckoutUpdate(checkout: checkout, statusCode: 500)
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let secondPaymentMethod = makeSavedPaymentMethod(id: "pm_second", country: "CA")
        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: nil)
        let delegate = MockFlowControllerViewControllerDelegate()
        let sut = makeHorizontalController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, secondPaymentMethod]
        )
        sut.flowControllerDelegate = delegate
        sut.loadViewIfNeeded()
        let savedOptions = sut.savedPaymentOptionsViewController
        savedOptions.loadViewIfNeeded()
        sut.view.autosizeHeight(width: 375)
        let selectedCell = try XCTUnwrap(
            savedOptions.collectionView.cellForItem(at: IndexPath(item: 2, section: 0))
                as? SavedPaymentMethodCollectionView.PaymentOptionCell
        )

        // When
        savedOptions.collectionView(
            savedOptions.collectionView,
            didSelectItemAt: IndexPath(item: 2, section: 0)
        )
        await fulfillment(of: [updateRequest], timeout: 5)
        try await waitUntil { sut.isDismissable }

        // Then
        XCTAssertEqual(
            sut.selectedPaymentOption?.savedPaymentMethod?.stripeId,
            firstPaymentMethod.stripeId
        )
        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: nil),
            .link
        )
        XCTAssertFalse(sut.errorLabel.isHidden)
        XCTAssertEqual(sut.errorLabel.text, "Tax update failed")
        XCTAssertEqual(selectedCell.paymentMethodLogo.alpha, 1)
        XCTAssertEqual(activityIndicator(in: selectedCell.selectedIcon)?.isAnimating, false)
        XCTAssertEqual(delegate.closeCount, 0)
    }

    func testHorizontalSavedSelection_withCTA_defersSyncUntilContinue() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let requestRecorder = CheckoutSessionRequestRecorder()
        let updateRequest = stubCheckoutUpdate(
            checkout: checkout,
            requestRecorder: requestRecorder
        )
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let sepaPaymentMethod = makeSavedPaymentMethod(
            id: "pm_sepa",
            country: "CA",
            type: "sepa_debit"
        )
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId(firstPaymentMethod.stripeId),
            forCustomer: nil
        )
        let delegate = MockFlowControllerViewControllerDelegate()
        let sut = makeHorizontalController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, sepaPaymentMethod]
        )
        sut.flowControllerDelegate = delegate
        sut.loadViewIfNeeded()
        let savedOptions = sut.savedPaymentOptionsViewController
        savedOptions.loadViewIfNeeded()
        sut.view.autosizeHeight(width: 375)
        let selectedCell = try XCTUnwrap(
            savedOptions.collectionView.cellForItem(at: IndexPath(item: 2, section: 0))
                as? SavedPaymentMethodCollectionView.PaymentOptionCell
        )

        // When selecting the saved payment method
        savedOptions.collectionView(
            savedOptions.collectionView,
            didSelectItemAt: IndexPath(item: 2, section: 0)
        )

        // Then no sync or dismissal happens until the CTA is tapped
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(requestRecorder.requests.count, 0)
        XCTAssertTrue(sut.isDismissable)
        XCTAssertEqual(selectedCell.paymentMethodLogo.alpha, 1)
        XCTAssertEqual(activityIndicator(in: selectedCell.selectedIcon)?.isAnimating, false)
        XCTAssertEqual(delegate.closeCount, 0)

        // When tapping Continue
        sut.confirmButton.sendActions(for: .touchUpInside)

        // Then the CTA owns the loading state and closes after syncing
        guard case .processing = sut.confirmButton.status else {
            return XCTFail("Expected the Continue button to be processing")
        }
        XCTAssertFalse(sut.isDismissable)
        await fulfillment(of: [updateRequest, delegate.closed], timeout: 5)
        XCTAssertEqual(requestRecorder.requests.count, 1)
        XCTAssertEqual(delegate.closeCount, 1)
        XCTAssertTrue(sut.isDismissable)
        XCTAssertTrue(sut.view.isUserInteractionEnabled)
        guard case .enabled = sut.confirmButton.status else {
            return XCTFail("Expected the Continue button to reset before re-presentation")
        }
    }

    func testHorizontalSavedSelection_withCTA_withoutRequiredSync_closesSynchronously() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: false)
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let sepaPaymentMethod = makeSavedPaymentMethod(
            id: "pm_sepa",
            country: "CA",
            type: "sepa_debit"
        )
        let delegate = MockFlowControllerViewControllerDelegate()
        let sut = makeHorizontalController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, sepaPaymentMethod]
        )
        sut.flowControllerDelegate = delegate
        sut.loadViewIfNeeded()
        let savedOptions = sut.savedPaymentOptionsViewController
        savedOptions.loadViewIfNeeded()
        savedOptions.collectionView(
            savedOptions.collectionView,
            didSelectItemAt: IndexPath(item: 2, section: 0)
        )

        // When
        sut.confirmButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertEqual(delegate.closeCount, 1)
        XCTAssertTrue(sut.isDismissable)
        XCTAssertTrue(sut.view.isUserInteractionEnabled)
        guard case .enabled = sut.confirmButton.status else {
            return XCTFail("Expected the Continue button to remain enabled")
        }
    }

    func testHorizontalSavedSelection_withCTA_syncFails_remainsSelectedAndRetryable() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let requestRecorder = CheckoutSessionRequestRecorder()
        let updateRequests = expectation(description: "Checkout tax region updates")
        updateRequests.expectedFulfillmentCount = 2
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
            requestRecorder.append(
                CheckoutSessionRequest(kind: .updateSession, params: [:])
            )
            updateRequests.fulfill()
            if requestRecorder.requests.count == 1 {
                return HTTPStubsResponse(
                    jsonObject: [
                        "error": [
                            "type": "card_error",
                            "message": "Tax update failed",
                        ],
                    ],
                    statusCode: 500,
                    headers: nil
                )
            }
            return HTTPStubsResponse(
                jsonObject: responseJSON,
                statusCode: 200,
                headers: nil
            )
        }
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let sepaPaymentMethod = makeSavedPaymentMethod(
            id: "pm_sepa",
            country: "CA",
            type: "sepa_debit"
        )
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId(firstPaymentMethod.stripeId),
            forCustomer: nil
        )
        let delegate = MockFlowControllerViewControllerDelegate()
        let sut = makeHorizontalController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, sepaPaymentMethod]
        )
        sut.flowControllerDelegate = delegate
        sut.loadViewIfNeeded()
        let savedOptions = sut.savedPaymentOptionsViewController
        savedOptions.loadViewIfNeeded()
        savedOptions.collectionView(
            savedOptions.collectionView,
            didSelectItemAt: IndexPath(item: 2, section: 0)
        )

        // When
        sut.confirmButton.sendActions(for: .touchUpInside)
        try await waitUntil {
            requestRecorder.requests.count == 1 && sut.isDismissable
        }

        // Then
        XCTAssertEqual(
            sut.selectedPaymentOption?.savedPaymentMethod?.stripeId,
            sepaPaymentMethod.stripeId
        )
        XCTAssertFalse(sut.errorLabel.isHidden)
        XCTAssertEqual(sut.errorLabel.text, "Tax update failed")
        XCTAssertEqual(delegate.closeCount, 0)
        guard case .enabled = sut.confirmButton.status else {
            return XCTFail("Expected the Continue button to be retryable")
        }

        // When retrying
        sut.confirmButton.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(sut.errorLabel.isHidden)
        await fulfillment(of: [updateRequests, delegate.closed], timeout: 5)
        XCTAssertEqual(requestRecorder.requests.count, 2)
        XCTAssertEqual(delegate.closeCount, 1)
        XCTAssertTrue(sut.isDismissable)
        XCTAssertTrue(sut.view.isUserInteractionEnabled)
        XCTAssertTrue(sut.errorLabel.isHidden)
        guard case .enabled = sut.confirmButton.status else {
            return XCTFail("Expected the Continue button to reset after retry success")
        }
    }

    // MARK: Saved payment method updates

    func testSavedPaymentMethodManager_checkoutUpdate_commitsSessionAndSyncsEditedBilling() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let paymentMethodUpdate = expectation(description: "Saved payment method updated")
        let taxRegionUpdate = expectation(description: "Edited billing address synced")
        var updatedSessionJSON = CheckoutTestHelpers.openSessionJSON
        updatedSessionJSON["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.billing",
        ]
        updatedSessionJSON["customer"] = [
            "id": "cus_123",
            "payment_methods": [
                makeSavedPaymentMethodJSON(
                    id: "pm_edited",
                    country: "CA",
                    city: "Toronto"
                ),
            ],
        ]
        stub { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/payment_pages/\(checkout.session.id)"
        } response: { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
            if params["payment_method_to_update[payment_method_id]"] == "pm_edited" {
                paymentMethodUpdate.fulfill()
            } else if params["tax_region[country]"] == "CA" {
                taxRegionUpdate.fulfill()
            }
            return HTTPStubsResponse(
                jsonObject: updatedSessionJSON,
                statusCode: 200,
                headers: nil
            )
        }

        // When
        let manager = makeSavedPaymentMethodManager(checkout: checkout)
        let updatedPaymentMethod = try await manager.update(
            paymentMethod: makeSavedPaymentMethod(id: "pm_edited", country: "US"),
            with: makeBillingUpdateParams(country: "CA")
        )

        // Then
        await fulfillment(of: [paymentMethodUpdate, taxRegionUpdate], timeout: 5)
        XCTAssertEqual(updatedPaymentMethod.billingDetails?.address?.country, "CA")
        XCTAssertEqual(updatedPaymentMethod.billingDetails?.address?.city, "Toronto")
        XCTAssertEqual(
            checkout.session.customer?.paymentMethods.first?.billingDetails?.address?.country,
            "CA"
        )
    }

    func testSavedPaymentMethodManager_taxSyncFailure_commitsEditAndThrowsError() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let paymentMethodUpdate = expectation(description: "Saved payment method updated")
        let taxRegionUpdate = expectation(description: "Edited billing address sync attempted")
        var updatedSessionJSON = CheckoutTestHelpers.openSessionJSON
        updatedSessionJSON["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.billing",
        ]
        updatedSessionJSON["customer"] = [
            "id": "cus_123",
            "payment_methods": [
                makeSavedPaymentMethodJSON(id: "pm_edited", country: "CA"),
            ],
        ]
        stub { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/payment_pages/\(checkout.session.id)"
        } response: { request in
            let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
            if params["payment_method_to_update[payment_method_id]"] == "pm_edited" {
                paymentMethodUpdate.fulfill()
                return HTTPStubsResponse(
                    jsonObject: updatedSessionJSON,
                    statusCode: 200,
                    headers: nil
                )
            }
            taxRegionUpdate.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "error": [
                        "type": "card_error",
                        "message": "Tax update failed",
                    ],
                ],
                statusCode: 500,
                headers: nil
            )
        }
        let manager = makeSavedPaymentMethodManager(checkout: checkout)

        // When
        do {
            _ = try await manager.update(
                paymentMethod: makeSavedPaymentMethod(id: "pm_edited", country: "US"),
                with: makeBillingUpdateParams(country: "CA")
            )
            XCTFail("Expected the tax sync to fail")
        } catch {
            // Then
            XCTAssertEqual(error.nonGenericDescription, "Tax update failed")
        }

        await fulfillment(of: [paymentMethodUpdate, taxRegionUpdate], timeout: 5)
        XCTAssertEqual(
            checkout.session.customer?.paymentMethods.first?.billingDetails?.address?.country,
            "CA"
        )
    }

    func testSavedPaymentMethodManager_updateFailure_throwsWithoutChangingSession() async throws {
        // Given
        let checkout = try await makeCheckout(automaticTaxEnabled: true)
        let paymentMethodUpdate = expectation(description: "Saved payment method update attempted")
        stub { request in
            request.httpMethod == "POST"
                && request.url?.path == "/v1/payment_pages/\(checkout.session.id)"
                && RequestBodyTestHelpers.formEncodedBodyParams(from: request)[
                    "payment_method_to_update[payment_method_id]"
                ] == "pm_edited"
        } response: { _ in
            paymentMethodUpdate.fulfill()
            return HTTPStubsResponse(
                jsonObject: [
                    "error": [
                        "type": "card_error",
                        "message": "Payment method update failed",
                    ],
                ],
                statusCode: 500,
                headers: nil
            )
        }
        let paymentMethodIDsBeforeUpdate = checkout.session.customer?.paymentMethods.map(\.stripeId)
        let manager = makeSavedPaymentMethodManager(checkout: checkout)

        // When
        do {
            _ = try await manager.update(
                paymentMethod: makeSavedPaymentMethod(id: "pm_edited", country: "US"),
                with: makeBillingUpdateParams(country: "CA")
            )
            XCTFail("Expected the payment method update to fail")
        } catch {
            // Then
            XCTAssertEqual(error.nonGenericDescription, "Payment method update failed")
        }

        await fulfillment(of: [paymentMethodUpdate], timeout: 5)
        XCTAssertEqual(
            checkout.session.customer?.paymentMethods.map(\.stripeId),
            paymentMethodIDsBeforeUpdate
        )
    }
}

// MARK: - Helpers

private extension SavedPaymentMethodBillingSyncTests {
    func makeCheckout(
        automaticTaxEnabled: Bool,
        automaticTaxAddressSource: String = "session.billing"
    ) async throws -> Checkout {
        var sessionJSON = CheckoutTestHelpers.openSessionJSON
        sessionJSON["tax_context"] = [
            "automatic_tax_enabled": automaticTaxEnabled,
            "automatic_tax_address_source": automaticTaxAddressSource,
        ]
        let session = try XCTUnwrap(
            PaymentPagesAPIResponse.decodedObject(fromAPIResponse: sessionJSON)
        )
        let configuration = CheckoutTestHelpers.makeConfiguration(apiResponse: session)
        return try await Checkout(configuration: configuration)
    }

    func stubCheckoutUpdate(
        checkout: Checkout,
        statusCode: Int32 = 200,
        requestRecorder: CheckoutSessionRequestRecorder? = nil
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
            requestRecorder?.append(
                CheckoutSessionRequest(kind: .updateSession, params: [:])
            )
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

    func makeEmbeddedManageController(
        checkout: Checkout?,
        paymentMethods: [STPPaymentMethod],
        selectedPaymentMethod: STPPaymentMethod
    ) -> VerticalSavedPaymentMethodsViewController {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.apiClient = APIStubbedTestCase.stubbedAPIClient()
        return VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            intent: checkout.map { .checkout($0.session) } ?? ._testValue(),
            checkout: checkout,
            syncsCheckoutBillingBeforeCompletion: checkout != nil,
            selectedPaymentMethod: selectedPaymentMethod,
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card", "sepa_debit"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
    }

    func assertEmbeddedSelectionCompletesWithoutLoading(
        checkout: Checkout?,
        selectedCountry: String = "CA"
    ) async throws {
        let firstPaymentMethod = makeSavedPaymentMethod(id: "pm_first", country: "US")
        let selectedPaymentMethod = makeSavedPaymentMethod(
            id: "pm_second",
            country: selectedCountry
        )
        let delegate = MockVerticalSavedPaymentMethodsDelegate()
        let sut = makeEmbeddedManageController(
            checkout: checkout,
            paymentMethods: [firstPaymentMethod, selectedPaymentMethod],
            selectedPaymentMethod: firstPaymentMethod
        )
        sut.delegate = delegate
        sut.loadViewIfNeeded()
        let selectedRow = sut.paymentMethodRows[1]

        selectedRow.rowButton.handleTap()

        XCTAssertEqual(selectedRow.rowButton.alpha, 1)
        XCTAssertEqual(activityIndicator(in: selectedRow)?.isAnimating, false)
        await fulfillment(of: [delegate.completed], timeout: 5)
    }

    func makeHorizontalController(
        checkout: Checkout,
        paymentMethods: [STPPaymentMethod]
    ) -> PaymentSheetFlowControllerViewController {
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: .checkout(checkout.session),
            elementsSession: ._testValue(
                paymentMethodTypes: ["card", "sepa_debit"],
                isLinkPassthroughModeEnabled: false
            ),
            savedPaymentMethods: paymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .horizontal
        )
        return PaymentSheetFlowControllerViewController(
            configuration: PaymentSheet.Configuration(),
            loadResult: loadResult,
            analyticsHelper: ._testValue(),
            checkout: checkout
        )
    }

    func makeSavedPaymentMethodManager(checkout: Checkout) -> SavedPaymentMethodManager {
        return SavedPaymentMethodManager(
            configuration: PaymentSheet.Configuration(),
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            intent: .checkout(checkout.session),
            checkout: checkout
        )
    }

    func makeBillingUpdateParams(country: String) -> STPPaymentMethodUpdateParams {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.country = country
        let updateParams = STPPaymentMethodUpdateParams()
        updateParams.billingDetails = billingDetails
        return updateParams
    }

    func makeSavedPaymentMethod(
        id: String,
        country: String,
        type: String = "card"
    ) -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(
            fromAPIResponse: makeSavedPaymentMethodJSON(
                id: id,
                country: country,
                type: type
            )
        )!
    }

    func makeSavedPaymentMethodJSON(
        id: String,
        country: String,
        city: String? = nil,
        type: String = "card"
    ) -> [AnyHashable: Any] {
        var address: [String: String] = [
            "country": country,
        ]
        address["city"] = city
        var response: [AnyHashable: Any] = [
            "id": id,
            "type": type,
            "created": 1_700_000_000,
            "billing_details": [
                "address": address,
            ],
        ]
        if type == "card" {
            response["card"] = [
                "brand": "visa",
                "last4": "4242",
                "exp_month": 12,
                "exp_year": 2050,
            ]
        } else if type == "sepa_debit" {
            response["sepa_debit"] = [
                "last4": "6789",
            ]
        }
        return response
    }

    func waitUntil(
        timeout: TimeInterval = 5,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline {
                XCTFail("Condition not met within \(timeout) seconds")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    func activityIndicatorCount(in view: UIView) -> Int {
        return view.subviews.compactMap { $0 as? ActivityIndicator }.count
    }

    func activityIndicator(in view: UIView) -> ActivityIndicator? {
        return view.subviews.first { $0 is ActivityIndicator } as? ActivityIndicator
    }
}

@MainActor
private final class MockVerticalSavedPaymentMethodsDelegate:
    VerticalSavedPaymentMethodsViewControllerDelegate
{
    let completed = XCTestExpectation(description: "Saved payment method selection completed")
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

@MainActor
private final class MockFlowControllerViewControllerDelegate:
    FlowControllerViewControllerDelegate
{
    let closed = XCTestExpectation(description: "FlowController closed")
    private(set) var closeCount = 0
    private(set) var didCancel = false

    func flowControllerViewControllerShouldClose(
        _ PaymentSheetFlowControllerViewController: FlowControllerViewControllerProtocol,
        didCancel: Bool
    ) {
        closeCount += 1
        self.didCancel = didCancel
        closed.fulfill()
    }
}
