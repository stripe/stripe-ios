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

/// Covers full PaymentSheet's cancel behavior: an abandoned selection change must not stick as the
/// locally persisted default. Drives the same code paths as the (slow) selection-revert UI tests,
/// headlessly: present-time snapshot → row tap (persists) → cancel delegate → persistence reverted.
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

    private func makeLoadResult(savedPaymentMethods: [STPPaymentMethod]) -> PaymentSheetLoader.LoadResult {
        return PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(paymentMethodTypes: ["card"]),
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical
        )
    }

    func testVerticalCancel_revertsPersistedDefault() throws {
        // Given card A is the persisted default when the sheet is presented
        let customerID = "cus_ps_cancel_vertical"
        defer { CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID) }
        let cardA = STPPaymentMethod._testCard()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(cardA.stripeId), forCustomer: customerID)
        var config = PaymentSheet.Configuration._testValue_MostPermissive(isApplePayEnabled: true)
        config.customer = .init(id: customerID, ephemeralKeySecret: "ek_test")
        let loadResult = makeLoadResult(savedPaymentMethods: [cardA])
        let sheet = PaymentSheet(paymentIntentClientSecret: "pi_123_secret_456", configuration: config)
        let vc = PaymentSheetVerticalViewController(configuration: config, loadResult: loadResult, isFlowController: false, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        vc.loadViewIfNeeded()
        sheet.persistedSelectionSnapshot = .capture(paymentOption: nil, customerID: customerID, savedPaymentMethods: [cardA])

        // When the user selects Apple Pay (which persists it as the default)...
        vc.didTapPaymentMethod(.applePay)
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .applePay)

        // ...and then cancels the sheet
        sheet.paymentSheetViewControllerDidCancel(vc)

        // Then the persisted default reverts to card A
        XCTAssertEqual(CustomerPaymentOption.localDefaultPaymentMethod(for: customerID), .stripeId(cardA.stripeId))

        // And re-presenting derives the original selection
        let freshVC = PaymentSheetVerticalViewController(configuration: config, loadResult: loadResult, isFlowController: false, analyticsHelper: ._testValue(), previousPaymentOption: nil)
        freshVC.loadViewIfNeeded()
        guard case .saved(let selected) = freshVC.paymentMethodListViewController?.currentSelection else {
            return XCTFail("Expected a saved payment method to be selected on re-presentation")
        }
        XCTAssertEqual(selected.stripeId, cardA.stripeId)
    }
}
