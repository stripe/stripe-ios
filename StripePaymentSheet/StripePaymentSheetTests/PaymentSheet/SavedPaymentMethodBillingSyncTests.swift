//
//  SavedPaymentMethodBillingSyncTests.swift
//  StripePaymentSheetTests
//

import OHHTTPStubs
import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentSheet
import UIKit
import XCTest

@MainActor
final class SavedPaymentMethodBillingSyncTests: XCTestCase {
    private let paymentMethods: [STPPaymentMethod] = [
        ._testCard(id: "pm_first", country: "US"),
        ._testCard(id: "pm_second", country: "CA"),
    ]

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testSelectionWaitsForBillingTaxUpdate() async throws {
        let (sut, updater) = try await makeController(suspendUpdate: true)
        let delegate = MockVerticalSavedPaymentMethodsDelegate()
        sut.delegate = delegate
        sut.loadViewIfNeeded()

        paymentMethodRows(in: sut)[1].rowButton.handleTap()

        await fulfillment(of: [updater.updateStarted])
        XCTAssertFalse(sut.allowsDragToDismiss)
        XCTAssertNil(delegate.selectedPaymentMethod)

        updater.resumeUpdate()
        await fulfillment(of: [delegate.completed])
        XCTAssertEqual(delegate.selectedPaymentMethod?.stripeId, "pm_second")
    }

    func testFailureRestoresSelectionAndShowsError() async throws {
        let error = CheckoutError.apiError(message: "Tax update failed")
        let (sut, updater) = try await makeController(error: error)
        sut.loadViewIfNeeded()
        let rows = paymentMethodRows(in: sut)

        rows[1].rowButton.handleTap()
        let interactionRestored = expectation(
            for: sut.view,
            keyPath: \.isUserInteractionEnabled,
            equalsToValue: true
        )
        await fulfillment(of: [updater.updateStarted, interactionRestored])

        XCTAssertTrue(rows[0].isSelected)
        XCTAssertFalse(rows[1].isSelected)
        XCTAssertTrue(labels(in: sut).contains { $0.text == "Tax update failed" })
    }

    func testHorizontalSelectionWithoutBillingTaxCloses() async throws {
        // Given
        let checkout = try await CheckoutController(configuration: CheckoutTestHelpers.makeConfiguration())
        let sut = makeHorizontalController(checkout: checkout)
        let delegate = MockFlowControllerViewControllerDelegate()
        sut.flowControllerDelegate = delegate

        // When
        let savedOptions = sut.savedPaymentOptionsViewController
        savedOptions.collectionView(
            savedOptions.collectionView,
            didSelectItemAt: IndexPath(item: 2, section: 0)
        )

        // Then
        await fulfillment(of: [delegate.closed])
        XCTAssertEqual(delegate.closeCount, 1)
        XCTAssertFalse(delegate.didCancel)
        XCTAssertTrue(sut.isDismissable)
    }
}

private extension SavedPaymentMethodBillingSyncTests {
    func makeController(
        error: Error? = nil,
        suspendUpdate: Bool = false
    ) async throws -> (VerticalSavedPaymentMethodsViewController, MockCheckoutSessionBillingAddressUpdater) {
        let intent = try await Intent._testCheckoutSession(
            automaticTaxEnabled: true,
            automaticTaxAddressSource: "session.billing"
        )
        guard case .checkout(let context) = intent,
              let session = context.session else {
            fatalError("Expected a Checkout Session")
        }
        let updater = MockCheckoutSessionBillingAddressUpdater(
            session: session,
            error: error,
            suspendUpdate: suspendUpdate
        )
        let viewController = VerticalSavedPaymentMethodsViewController(
            configuration: EmbeddedPaymentElement.Configuration(),
            intent: intent,
            checkout: updater,
            selectedPaymentMethod: paymentMethods[0],
            paymentMethods: paymentMethods,
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            analyticsHelper: ._testValue(),
            defaultPaymentMethod: nil
        )
        return (viewController, updater)
    }

    func makeHorizontalController(
        checkout: CheckoutController
    ) -> PaymentSheetFlowControllerViewController {
        let loadResult = PaymentSheetLoader.LoadResult(
            intent: .checkout(checkout.intentContext),
            elementsSession: ._testValue(
                paymentMethodTypes: ["card"],
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

    func paymentMethodRows(
        in viewController: VerticalSavedPaymentMethodsViewController
    ) -> [SavedPaymentMethodRowButton] {
        return arrangedSubviews(in: viewController)
    }

    func labels(
        in viewController: VerticalSavedPaymentMethodsViewController
    ) -> [UILabel] {
        return arrangedSubviews(in: viewController)
    }

    func arrangedSubviews<T>(
        in viewController: VerticalSavedPaymentMethodsViewController
    ) -> [T] {
        return viewController.view.subviews
            .compactMap { $0 as? UIStackView }
            .flatMap(\.arrangedSubviews)
            .compactMap { $0 as? T }
    }
}

@MainActor
private final class MockCheckoutSessionBillingAddressUpdater: CheckoutSessionBillingAddressUpdater {
    let updateStarted = XCTestExpectation(description: "Billing tax region update started")

    private let session: CheckoutController.Session
    private let error: Error?
    private let suspendUpdate: Bool
    private var updateContinuation: CheckedContinuation<Void, Never>?

    init(session: CheckoutController.Session, error: Error?, suspendUpdate: Bool) {
        self.session = session
        self.error = error
        self.suspendUpdate = suspendUpdate
    }

    func updateBillingTaxRegionIfNecessaryForPaymentSheet(
        address: CheckoutController.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> CheckoutController.Session {
        if suspendUpdate {
            await withCheckedContinuation { continuation in
                updateContinuation = continuation
                updateStarted.fulfill()
            }
        } else {
            updateStarted.fulfill()
        }
        if let error {
            throw error
        }
        return session
    }

    func resumeUpdate() {
        updateContinuation?.resume()
        updateContinuation = nil
    }

    func commitSession(_ apiResponse: PaymentPagesAPIResponse) async throws {
        XCTFail("Unexpected call to commitSession")
    }
}

@MainActor
private final class MockVerticalSavedPaymentMethodsDelegate:
    VerticalSavedPaymentMethodsViewControllerDelegate
{
    let completed = XCTestExpectation(description: "Selection completed")
    private(set) var selectedPaymentMethod: STPPaymentMethod?

    func didComplete(
        viewController: VerticalSavedPaymentMethodsViewController,
        with selectedPaymentMethod: STPPaymentMethod?,
        latestPaymentMethods: [STPPaymentMethod],
        didTapToDismiss: Bool,
        defaultPaymentMethod: STPPaymentMethod?
    ) {
        self.selectedPaymentMethod = selectedPaymentMethod
        completed.fulfill()
    }
}

@MainActor
private final class MockFlowControllerViewControllerDelegate: FlowControllerViewControllerDelegate {
    let closed = XCTestExpectation(description: "Flow controller closed")
    private(set) var closeCount = 0
    private(set) var didCancel = false

    func flowControllerViewControllerShouldClose(
        _ viewController: FlowControllerViewControllerProtocol,
        didCancel: Bool
    ) {
        closeCount += 1
        self.didCancel = didCancel
        closed.fulfill()
    }
}
