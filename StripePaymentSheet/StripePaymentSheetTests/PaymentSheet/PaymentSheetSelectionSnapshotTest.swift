//
//  PaymentSheetSelectionSnapshotTest.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PaymentSheetSelectionSnapshotTest: XCTestCase {
    private let customerID = "cus_selection_snapshot_test"

    override func tearDown() {
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID)
        super.tearDown()
    }

    func testClearingLinkSelectionDoesNotResurrectPersistedLinkOnRestore() {
        // Given Link is the selection and the persisted default when the sheet is presented
        CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: customerID)
        let snapshot = SelectionSnapshot.capture(
            paymentOption: .link(option: .wallet(brand: .link)),
            customerID: customerID,
            savedPaymentMethods: []
        )

        // When the user drops out of the native Link flow (which deliberately clears the selection)...
        let cleared = snapshot.clearingLinkSelection
        XCTAssertNil(cleared.paymentOption)

        // ...and then cancels the sheet
        cleared.restoreLocalPersistence(customerID: customerID, savedPaymentMethods: [])

        // Then Link must not remain the persisted default while the in-memory selection is nil
        XCTAssertNil(
            CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
            "The persisted default should not remain Link after the Link selection was deliberately cleared"
        )
    }

    func testIsPaymentOptionValid_formBackedLinkedBankSaved_isValidForBothLinkModes() {
        // Instant Debits and Link Card Brand forms create their payment method in the bank-auth flow
        // and return it as `.saved` — it's form-backed, not customer-saved, so it can't be
        // invalidated by deletions even though it never appears in `savedPaymentMethods`
        for (type, linkMode) in [(PaymentSheet.PaymentMethodType.instantDebits, LinkMode.linkPaymentMethod), (.linkCardBrand, .linkCardBrand)] {
            // Given a snapshot of a completed linked-bank form selection
            let paymentMethod = STPPaymentMethod._testUSBankAccount()
            let confirmParams = IntentConfirmParams(type: type)
            confirmParams.instantDebitsLinkedBank = InstantDebitsLinkedBank(
                paymentMethod: LinkBankPaymentMethod(id: paymentMethod.stripeId),
                bankName: "StripeBank",
                last4: "6789",
                linkMode: linkMode,
                incentiveEligible: false,
                linkAccountSessionId: "fcsess_123"
            )
            let snapshot = SelectionSnapshot.capture(
                paymentOption: .saved(paymentMethod: paymentMethod, confirmParams: confirmParams),
                customerID: customerID,
                savedPaymentMethods: []
            )

            // Then it's restorable regardless of the customer's saved payment methods
            guard case .revert(let restored) = snapshot.paymentOptionRestoration(savedPaymentMethods: []) else {
                return XCTFail("A form-backed \(type) selection should be restorable; it isn't a customer-saved payment method")
            }
            if case .saved(let restoredPaymentMethod, _)? = restored {
                XCTAssertEqual(restoredPaymentMethod.stripeId, paymentMethod.stripeId)
            } else {
                XCTFail("Expected the form-backed .saved selection to be restored unchanged")
            }
        }
    }

    func testClearingLinkSelectionPreservesNonLinkPersistedDefault() {
        // Given a saved card is the persisted default, but Link is the in-memory selection
        let paymentMethod = STPPaymentMethod._testCard()
        CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(paymentMethod.stripeId), forCustomer: customerID)
        let snapshot = SelectionSnapshot.capture(
            paymentOption: .link(option: .wallet(brand: .link)),
            customerID: customerID,
            savedPaymentMethods: [paymentMethod]
        )

        // When the user drops out of the native Link flow and then cancels
        let cleared = snapshot.clearingLinkSelection
        cleared.restoreLocalPersistence(customerID: customerID, savedPaymentMethods: [paymentMethod])

        // Then the unrelated persisted default is untouched
        XCTAssertEqual(
            CustomerPaymentOption.localDefaultPaymentMethod(for: customerID),
            .stripeId(paymentMethod.stripeId)
        )
    }
}
