//
//  PaymentSheetCancelPersistenceTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP) import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class PaymentSheetCancelPersistenceTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        let expectation = expectation(description: "specs loaded")
        AddressSpecProvider.shared.loadAddressSpecs {
            FormSpecProvider.shared.load { _ in
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1)
    }

    private func makeCard(id: String, last4: String) -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": id,
            "type": "card",
            "created": "12345",
            "card": [
                "last4": last4,
                "brand": "visa",
                "exp_month": "01",
                "exp_year": "2040",
            ],
        ])!
    }

    private func makeConfiguration(customerID: String) -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: false)
        configuration.customer = .init(id: customerID, ephemeralKeySecret: "ek_test")
        return configuration
    }

    private func makeLoadResult(
        savedPaymentMethods: [STPPaymentMethod]
    ) -> PaymentSheetLoader.LoadResult {
        return PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
    }

    func testCancelRevertsPersistedSelectionAfterDismissal() {
        // Given card A is persisted when PaymentSheet is presented
        let customerID = "cus_ps_cancel"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = makeCard(id: "pm_a", last4: "4242")
        let cardB = makeCard(id: "pm_b", last4: "0005")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let configuration = makeConfiguration(customerID: customerID)
        let sheet = PaymentSheet(
            paymentIntentClientSecret: "pi_123_secret_456",
            configuration: configuration
        )
        let loadResult = makeLoadResult(savedPaymentMethods: [cardA, cardB])
        _ = sheet.makePaymentSheetVC(
            loadResult: loadResult,
            previousPaymentOption: nil
        )
        let viewController = DeferredDismissPaymentSheetVerticalViewController(
            configuration: configuration,
            loadResult: loadResult,
            isFlowController: false,
            analyticsHelper: sheet.analyticsHelper
        )
        viewController.loadViewIfNeeded()
        var didComplete = false
        sheet.completion = { _ in
            didComplete = true
        }

        // When the customer selects card B and then cancels
        viewController.didTapPaymentMethod(.saved(paymentMethod: cardB))
        sheet.paymentSheetViewControllerDidCancel(viewController)

        // Then the in-flight dismissal leaves card B persisted
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardB.stripeId))
        XCTAssertFalse(didComplete)

        // When dismissal finishes
        viewController.completeDismissal()

        // Then the persisted selection reverts to card A
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardA.stripeId))
        XCTAssertTrue(didComplete)
    }

    func testSnapshotDoesNotRestoreDeletedSavedPaymentMethod() {
        let customerID = "cus_deleted"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let deletedCard = makeCard(id: "pm_deleted", last4: "4242")
        let remainingCard = makeCard(id: "pm_remaining", last4: "0005")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(deletedCard.stripeId), forCustomer: customerID)
        let snapshot = CustomerPaymentOption.PersistedSelectionSnapshot(
            customerID: customerID,
            availableSavedPaymentMethods: [deletedCard, remainingCard]
        )

        // A deleted selection is cleared when deletion did not persist a fallback.
        snapshot.revertPersistedSelection(using: [remainingCard])
        XCTAssertNil(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID))

        // A fallback persisted by deletion is preserved.
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(deletedCard.stripeId), forCustomer: customerID)
        let snapshotWithFallback = CustomerPaymentOption.PersistedSelectionSnapshot(
            customerID: customerID,
            availableSavedPaymentMethods: [deletedCard, remainingCard]
        )
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(remainingCard.stripeId), forCustomer: customerID)
        snapshotWithFallback.revertPersistedSelection(using: [remainingCard])
        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
            .stripeId(remainingCard.stripeId)
        )
    }

    func testSnapshotRestoresSavedPaymentMethodUnavailableAtBothTimes() {
        let customerID = "cus_filtered"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let hiddenCard = makeCard(id: "pm_hidden", last4: "4242")
        let visibleCard = makeCard(id: "pm_visible", last4: "0005")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(hiddenCard.stripeId), forCustomer: customerID)
        let snapshot = CustomerPaymentOption.PersistedSelectionSnapshot(
            customerID: customerID,
            availableSavedPaymentMethods: [visibleCard]
        )
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(visibleCard.stripeId), forCustomer: customerID)

        snapshot.revertPersistedSelection(using: [visibleCard])

        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
            .stripeId(hiddenCard.stripeId)
        )
    }
}

private final class DeferredDismissPaymentSheetVerticalViewController: PaymentSheetVerticalViewController {
    private var dismissalCompletion: (() -> Void)?

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissalCompletion = completion
    }

    func completeDismissal() {
        dismissalCompletion?()
        dismissalCompletion = nil
    }
}
