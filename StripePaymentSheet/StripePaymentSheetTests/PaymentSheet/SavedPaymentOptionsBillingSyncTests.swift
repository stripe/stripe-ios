//
//  SavedPaymentOptionsBillingSyncTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import OHHTTPStubsSwift
@testable @_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils
import XCTest

/// Tests that tapping a saved payment method syncs its billing address to the checkout session
/// before notifying the delegate, and reverts the selection when the sync fails.
@MainActor
final class SavedPaymentOptionsBillingSyncTests: APIStubbedTestCase {

    private let customerID = "cus_billing_sync_test"

    // MARK: - Checkout.requiresBillingSync

    func testRequiresBillingSync() {
        XCTAssertTrue(Checkout.requiresBillingSync(for: makeSavedCard(id: "pm_1", country: "US").billingDetails))
        XCTAssertFalse(Checkout.requiresBillingSync(for: makeSavedCard(id: "pm_2", country: nil).billingDetails))
        XCTAssertFalse(Checkout.requiresBillingSync(for: nil))
    }

    // MARK: - SavedPaymentOptionsViewController

    func testTapSavedPM_checkoutIntent_syncsBillingThenNotifiesDelegate() async throws {
        // Given a checkout session (no automatic tax -> the sync is a local-only update)
        let checkout = await CheckoutTestHelpers.makeCheckoutWithOpenSession()
        let pm1 = makeSavedCard(id: "pm_1", country: "US")
        let pm2 = makeSavedCard(id: "pm_2", country: "CA", city: "Toronto")
        let delegate = MockSavedPaymentOptionsDelegate()
        let controller = makeController(intent: .checkout(checkout), savedPaymentMethods: [pm1, pm2], delegate: delegate)

        // When tapping the second saved payment method (viewModels are [add, pm1, pm2])
        let didNotifyDelegate = expectation(description: "delegate notified after sync")
        delegate.onDidUpdateSelection = { didNotifyDelegate.fulfill() }
        controller.collectionView(makeDummyCollectionView(), didSelectItemAt: IndexPath(item: 2, section: 0))

        // Then the delegate is not notified synchronously (it's deferred until the sync completes)
        XCTAssertTrue(delegate.selections.isEmpty)

        await fulfillment(of: [didNotifyDelegate], timeout: 5)

        // Then the billing address was synced onto the checkout session
        XCTAssertEqual(checkout.session.billingAddress?.address.country, "CA")
        XCTAssertEqual(checkout.session.billingAddress?.address.city, "Toronto")
        guard case .saved(let selectedPM) = delegate.selections.first else {
            XCTFail("Expected a saved payment method selection")
            return
        }
        XCTAssertEqual(selectedPM.stripeId, pm2.stripeId)
    }

    func testTapSavedPM_checkoutIntent_syncFails_revertsSelectionAndDoesNotNotify() async throws {
        // Given a checkout session with automatic tax on billing (the sync requires a server call)
        // and an API client that fails all requests
        stub { _ in true } response: { _ in
            HTTPStubsResponse(jsonObject: ["error": ["message": "something went wrong"]], statusCode: 500, headers: nil)
        }
        var sessionJSON = CheckoutTestHelpers.openSessionJSON
        sessionJSON["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.billing",
        ]
        let sessionResponse = STPCheckoutSessionAPIResponse.decodedObject(fromAPIResponse: sessionJSON)!
        let checkout = await Checkout(clientSecret: "cs_test_123_secret_abc", apiResponse: sessionResponse, apiClient: stubbedAPIClient())

        let pm1 = makeSavedCard(id: "pm_1", country: "US")
        let pm2 = makeSavedCard(id: "pm_2", country: "CA")
        let delegate = MockSavedPaymentOptionsDelegate()
        let controller = makeController(intent: .checkout(checkout), savedPaymentMethods: [pm1, pm2], delegate: delegate)
        XCTAssertEqual(controller.selectedPaymentOption?.savedPaymentMethod?.stripeId, pm1.stripeId)

        // When tapping the second saved payment method and the sync fails
        controller.collectionView(makeDummyCollectionView(), didSelectItemAt: IndexPath(item: 2, section: 0))

        // Then the selection reverts to the previously selected payment method
        try await waitUntil {
            controller.selectedPaymentOption?.savedPaymentMethod?.stripeId == pm1.stripeId
        }

        // Then the delegate was never notified of the failed selection
        XCTAssertTrue(delegate.selections.isEmpty)
        // Then the billing address was not synced
        XCTAssertNil(checkout.session.billingAddress)
    }

    // MARK: - Helpers

    private func makeController(
        intent: Intent,
        savedPaymentMethods: [STPPaymentMethod],
        delegate: MockSavedPaymentOptionsDelegate
    ) -> SavedPaymentOptionsViewController {
        // Ensure the first saved payment method is the initial selection
        if let firstPM = savedPaymentMethods.first {
            CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(firstPM.stripeId), forCustomer: customerID)
        }
        let configuration = SavedPaymentOptionsViewController.Configuration(customerID: customerID,
                                                                            showApplePay: false,
                                                                            showLink: false,
                                                                            linkBrand: .link,
                                                                            removeSavedPaymentMethodMessage: nil,
                                                                            merchantDisplayName: "abc",
                                                                            isCVCRecollectionEnabled: false,
                                                                            isTestMode: true,
                                                                            allowsRemovalOfLastSavedPaymentMethod: true,
                                                                            allowsRemovalOfPaymentMethods: true,
                                                                            allowsSetAsDefaultPM: false,
                                                                            allowsUpdatePaymentMethod: false)
        return SavedPaymentOptionsViewController(savedPaymentMethods: savedPaymentMethods,
                                                 configuration: configuration,
                                                 paymentSheetConfiguration: PaymentSheet.Configuration._testValue_MostPermissive(),
                                                 intent: intent,
                                                 appearance: .default,
                                                 elementsSession: .emptyElementsSession,
                                                 cbcEligible: false,
                                                 analyticsHelper: ._testValue(),
                                                 delegate: delegate)
    }

    private func makeSavedCard(id: String, country: String?, city: String? = nil) -> STPPaymentMethod {
        var address: [String: String] = [:]
        if let country {
            address["country"] = country
        }
        if let city {
            address["city"] = city
        }
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": id,
            "type": "card",
            "created": "12345",
            "card": [
                "last4": "4242",
                "brand": "visa",
                "exp_month": "01",
                "exp_year": "2040",
            ],
            "billing_details": [
                "address": address,
            ],
        ])!
    }

    private func makeDummyCollectionView() -> UICollectionView {
        return UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    private func waitUntil(
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline {
                XCTFail("Condition not met within \(timeout) seconds", file: file, line: line)
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

// MARK: - Mock delegate

@MainActor
private class MockSavedPaymentOptionsDelegate: SavedPaymentOptionsViewControllerDelegate {
    var selections: [SavedPaymentOptionsViewController.Selection] = []
    var onDidUpdateSelection: (() -> Void)?

    func didUpdate(_ viewController: SavedPaymentOptionsViewController) {}

    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        selections.append(paymentMethodSelection)
        onDidUpdateSelection?()
    }

    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {}

    func didSelectUpdateCardBrand(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection,
        updateParams: STPPaymentMethodUpdateParams
    ) async throws -> STPPaymentMethod {
        throw PaymentSheetError.unknown(debugDescription: "Not implemented")
    }

    func didSelectUpdateDefault(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) async throws -> STPCustomer {
        throw PaymentSheetError.unknown(debugDescription: "Not implemented")
    }

    func shouldCloseSheet(_ viewController: SavedPaymentOptionsViewController) {}
}
