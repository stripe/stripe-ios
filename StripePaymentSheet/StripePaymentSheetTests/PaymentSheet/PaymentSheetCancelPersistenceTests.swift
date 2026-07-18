//
//  PaymentSheetCancelPersistenceTests.swift
//  StripePaymentSheetTests
//  Created by Nick Porter on 7/17/26.
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
        savedPaymentMethods: [STPPaymentMethod],
        orientation: PaymentSheet.PaymentMethodLayout.ResolvedLayout
    ) -> PaymentSheetLoader.LoadResult {
        return PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: orientation
        )
    }

    private func makePaymentSheet(
        configuration: PaymentSheet.Configuration,
        savedPaymentMethods: [STPPaymentMethod],
        orientation: PaymentSheet.PaymentMethodLayout.ResolvedLayout
    ) -> (PaymentSheet, PaymentSheetViewControllerProtocol) {
        let sheet = PaymentSheet(
            paymentIntentClientSecret: "pi_123_secret_456",
            configuration: configuration
        )
        let viewController = sheet.makePaymentSheetVC(
            loadResult: makeLoadResult(
                savedPaymentMethods: savedPaymentMethods,
                orientation: orientation
            ),
            previousPaymentOption: nil
        )
        return (sheet, viewController)
    }

    private func tapSavedPaymentMethod(
        at index: Int,
        in viewController: PaymentSheetViewController
    ) throws {
        viewController.loadViewIfNeeded()
        let collectionView = try XCTUnwrap(
            firstSubview(ofType: SavedPaymentMethodCollectionView.self, in: viewController.view)
        )
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

    private func firstSubview<T: UIView>(ofType: T.Type, in view: UIView) -> T? {
        if let match = view as? T {
            return match
        }
        return view.subviews.lazy.compactMap { self.firstSubview(ofType: T.self, in: $0) }.first
    }

    func testVerticalCancel_revertsPersistedSavedPaymentMethod() {
        // Given card A is persisted when vertical PaymentSheet is presented
        let customerID = "cus_ps_cancel_vertical"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = makeCard(id: "pm_vertical_a", last4: "4242")
        let cardB = makeCard(id: "pm_vertical_b", last4: "0005")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let configuration = makeConfiguration(customerID: customerID)
        let (sheet, paymentSheetViewController) = makePaymentSheet(
            configuration: configuration,
            savedPaymentMethods: [cardA, cardB],
            orientation: .vertical
        )
        let viewController = paymentSheetViewController as! PaymentSheetVerticalViewController
        viewController.loadViewIfNeeded()

        // When the customer selects card B and then cancels
        viewController.didTapPaymentMethod(.saved(paymentMethod: cardB))
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardB.stripeId))
        sheet.paymentSheetViewControllerDidCancel(viewController)

        // Then the persisted selection reverts to card A
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardA.stripeId))
    }

    func testHorizontalCancel_revertsPersistedSavedPaymentMethod() throws {
        // Given card A is persisted when horizontal PaymentSheet is presented
        let customerID = "cus_ps_cancel_horizontal"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = makeCard(id: "pm_horizontal_a", last4: "4242")
        let cardB = makeCard(id: "pm_horizontal_b", last4: "0005")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let configuration = makeConfiguration(customerID: customerID)
        let (sheet, paymentSheetViewController) = makePaymentSheet(
            configuration: configuration,
            savedPaymentMethods: [cardA, cardB],
            orientation: .horizontal
        )
        let viewController = paymentSheetViewController as! PaymentSheetViewController

        // When the customer selects card B and then cancels
        try tapSavedPaymentMethod(at: 2, in: viewController)
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardB.stripeId))
        sheet.paymentSheetViewControllerDidCancel(viewController)

        // Then the persisted selection reverts to card A
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardA.stripeId))
    }

    func testCancel_doesNotRestoreDeletedSavedPaymentMethod() {
        // Given the persisted card is available when PaymentSheet is presented
        let customerID = "cus_ps_cancel_deleted"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let deletedCard = makeCard(id: "pm_deleted", last4: "4242")
        let remainingCard = makeCard(id: "pm_remaining", last4: "0005")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(deletedCard.stripeId), forCustomer: customerID)
        let configuration = makeConfiguration(customerID: customerID)
        let (sheet, _) = makePaymentSheet(
            configuration: configuration,
            savedPaymentMethods: [deletedCard, remainingCard],
            orientation: .vertical
        )

        // When that card is no longer present when the sheet is canceled
        let currentLoadResult = makeLoadResult(savedPaymentMethods: [remainingCard], orientation: .vertical)
        let currentViewController = PaymentSheetVerticalViewController(
            configuration: configuration,
            loadResult: currentLoadResult,
            isFlowController: false,
            analyticsHelper: ._testValue(),
            previousPaymentOption: nil
        )
        sheet.paymentSheetViewControllerDidCancel(currentViewController)

        // Then cancellation does not leave a persisted reference to the deleted card
        XCTAssertNil(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID))
    }

    func testCancel_restoresPersistedSavedPaymentMethodFilteredOutOfSheet() {
        // Given the persisted card exists for the customer but is filtered out of this PaymentSheet
        let customerID = "cus_ps_cancel_filtered"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let hiddenCard = makeCard(id: "pm_hidden", last4: "4242")
        let visibleCard = makeCard(id: "pm_visible", last4: "0005")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(hiddenCard.stripeId), forCustomer: customerID)
        let configuration = makeConfiguration(customerID: customerID)
        let (sheet, paymentSheetViewController) = makePaymentSheet(
            configuration: configuration,
            savedPaymentMethods: [visibleCard],
            orientation: .vertical
        )
        let viewController = paymentSheetViewController as! PaymentSheetVerticalViewController
        viewController.loadViewIfNeeded()

        // When the visible card is selected and the sheet is canceled
        viewController.didTapPaymentMethod(.saved(paymentMethod: visibleCard))
        sheet.paymentSheetViewControllerDidCancel(viewController)

        // Then the filtered persisted card is restored because it was not deleted here
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(hiddenCard.stripeId))
    }

    func testCancel_restoresNonSavedPersistedPaymentOptions() {
        let paymentOptions: [(name: String, option: CustomerPaymentOption?)] = [
            ("none", nil),
            ("apple_pay", .applePay),
            ("link", .link),
        ]

        for paymentOption in paymentOptions {
            // Given a non-saved option is persisted when PaymentSheet is presented
            let customerID = "cus_ps_cancel_\(paymentOption.name)"
            let card = makeCard(id: "pm_\(paymentOption.name)", last4: "4242")
            CustomerPaymentOption.setDefaultPaymentMethod(paymentOption.option, forCustomer: customerID)
            let configuration = makeConfiguration(customerID: customerID)
            let (sheet, paymentSheetViewController) = makePaymentSheet(
                configuration: configuration,
                savedPaymentMethods: [card],
                orientation: .vertical
            )
            let viewController = paymentSheetViewController as! PaymentSheetVerticalViewController
            viewController.loadViewIfNeeded()

            // When the customer selects a saved card and then cancels
            viewController.didTapPaymentMethod(.saved(paymentMethod: card))
            sheet.paymentSheetViewControllerDidCancel(viewController)

            // Then the original option, including no persisted option, is restored
            XCTAssertEqual(
                CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
                paymentOption.option
            )
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID)
        }
    }

    func testCompletedPayment_doesNotRevertPersistedSavedPaymentMethod() {
        // Given card A is persisted when PaymentSheet is presented
        let customerID = "cus_ps_completed"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = makeCard(id: "pm_completed_a", last4: "4242")
        let cardB = makeCard(id: "pm_completed_b", last4: "0005")
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        let configuration = makeConfiguration(customerID: customerID)
        let (sheet, paymentSheetViewController) = makePaymentSheet(
            configuration: configuration,
            savedPaymentMethods: [cardA, cardB],
            orientation: .vertical
        )
        let viewController = paymentSheetViewController as! PaymentSheetVerticalViewController
        viewController.loadViewIfNeeded()

        // When the customer selects card B and completes PaymentSheet
        viewController.didTapPaymentMethod(.saved(paymentMethod: cardB))
        sheet.paymentSheetViewControllerDidFinish(viewController, result: .completed)

        // Then card B remains persisted
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardB.stripeId))
    }
}
