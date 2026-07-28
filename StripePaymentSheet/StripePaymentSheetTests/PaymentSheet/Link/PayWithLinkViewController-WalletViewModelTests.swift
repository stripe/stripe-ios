//
//  PayWithLinkViewController-WalletViewModelTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) @_spi(CardFundingFilteringPrivatePreview) import StripePaymentSheet
import StripePaymentsTestUtils
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

    func test_showCorrectMandateForPayment() throws {
        let sut = try makeSUT(isSettingUp: false)
        XCTAssertFalse(sut.context.intent.isSetupFutureUsageSet(for: .link))

        // Card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertNil(sut.mandate)

        // Bank account
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertEqual(sut.mandate?.string, "By continuing, you agree to authorize payments pursuant to these terms.")
    }

    func test_showCorrectMandateForPaymentWithLinkPMOSFUPaymentMethodMode() throws {
        let sut = try makeSUT(linkPassthroughModeEnabled: false, isSettingUp: false, linkPMOSFU: true)
        XCTAssertTrue(sut.context.intent.isSetupFutureUsageSet(for: .link))

        // Card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertEqual(sut.mandate?.string, "By providing your card information, you allow StripePaymentSheetTestHostApp to charge your card for future payments in accordance with their terms.")

        // Bank account
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertEqual(sut.mandate?.string, "By continuing, you agree to authorize payments pursuant to these terms.")
    }

    func test_showCorrectMandateForPaymentWithLinkPMOSFUPassthroughMode() throws {
        let sut = try makeSUT(linkPassthroughModeEnabled: true, isSettingUp: false, linkPMOSFU: true)
        XCTAssertTrue(sut.context.intent.isSetupFutureUsageSet(for: .card))

        // Card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertEqual(sut.mandate?.string, "By providing your card information, you allow StripePaymentSheetTestHostApp to charge your card for future payments in accordance with their terms.")

        // Bank account
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertEqual(sut.mandate?.string, "By continuing, you agree to authorize payments pursuant to these terms.")
    }

    func test_showCorrectMandateForSetup() throws {
        let sut = try makeSUT(isSettingUp: true)
        XCTAssertTrue(sut.context.intent.isSetupFutureUsageSet(for: .link))

        // Card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertEqual(sut.mandate?.string, "By providing your card information, you allow StripePaymentSheetTestHostApp to charge your card for future payments in accordance with their terms.")

        // Bank account
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertEqual(sut.mandate?.string, "By continuing, you agree to authorize payments pursuant to these terms.")
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

    func test_confirmButtonStatus_whenSelectedCardIsNotSupported() throws {
        let sut = try makeSUT(supportedPaymentDetailsTypes: [ParsedEnum(.bankAccount)], linkFundingSources: ["BANK_ACCOUNT"])
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertEqual(
            sut.confirmButtonStatus,
            .disabled,
            "Button should be disabled if the current payment method is not supported"
        )
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertEqual(
            sut.confirmButtonStatus,
            .enabled,
            "Button should be disabled if the current payment method is not supported"
        )
    }

    func test_defaultLogic_whenDefaultCardIsNotSupportedItShouldStillBeSelected() throws {
        let sut = try makeSUT(supportedPaymentDetailsTypes: [ParsedEnum(.bankAccount)], linkFundingSources: ["BANK_ACCOUNT"])

        XCTAssertEqual(
            sut.selectedPaymentMethodIndex,
            LinkStubs.PaymentMethodIndices.card,
            "Selected payment method should be bank account when cards are disabled"
        )
    }

    func test_defaultLogic_whenNotSupportedCardIsOnlyOption() throws {
        let paymentMethods = Array(LinkStubs.paymentMethods()[0..<1])
        let sut = try makeSUT(paymentMethods: paymentMethods,
                              supportedPaymentDetailsTypes: [ParsedEnum(.bankAccount)],
                              linkFundingSources: ["BANK_ACCOUNT"])
        XCTAssertEqual(
            sut.selectedPaymentMethodIndex,
            LinkStubs.PaymentMethodIndices.card,
            "Selected payment method should be bank account when cards are disabled"
        )
    }

    func test_supportedPaymentMethodTypes_whenFilterIsNil_usesAllCasesAtIntersection() throws {
        let sut = try makeSUT(
            supportedPaymentDetailsTypes: [ParsedEnum(.bankAccount)],
            supportedPaymentMethodTypes: nil,
            linkFundingSources: ["BANK_ACCOUNT"]
        )

        XCTAssertEqual(sut.supportedPaymentMethodTypes, [ParsedEnum(.bankAccount)])
    }

    func test_supportedPaymentMethodTypes_whenFilterIsEmpty_usesAllCasesAtIntersection() throws {
        let sut = try makeSUT(
            supportedPaymentDetailsTypes: [ParsedEnum(.bankAccount)],
            supportedPaymentMethodTypes: [],
            linkFundingSources: ["BANK_ACCOUNT"]
        )

        XCTAssertEqual(sut.supportedPaymentMethodTypes, [ParsedEnum(.bankAccount)])
    }

    func test_supportedPaymentMethodTypes_whenFilterIsCard_returnsCardOnly() throws {
        let sut = try makeSUT(
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            supportedPaymentMethodTypes: [.card],
            linkFundingSources: ["CARD", "BANK_ACCOUNT"]
        )

        XCTAssertEqual(sut.supportedPaymentMethodTypes, [ParsedEnum(.card)])
    }

    func test_cardBrandFiltering_passThroughEnabled() throws {
        let sut = try makeSUT(supportedPaymentDetailsTypes: [ParsedEnum(.card)],
                              linkFundingSources: ["CARD"],
                              cardBrandAcceptance: .disallowed(brands: [.visa]),
                              linkPassthroughModeEnabled: true)
        XCTAssertFalse(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.card]),
            "Selected payment method should be bank account when cards are disabled"
        )

        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.cardWithFailingChecks]),
            "Selected payment method should be bank account when cards are disabled"
        )

        XCTAssertEqual(
            sut.selectedPaymentMethodIndex,
            LinkStubs.PaymentMethodIndices.card,
            "Selected payment method should be bank account when cards are disabled"
        )
    }

    func test_cardBrandFiltering_ignoredWhenPassThroughDisabled() throws {
        let sut = try makeSUT(supportedPaymentDetailsTypes: [ParsedEnum(.card)],
                              linkFundingSources: ["CARD"],
                              cardBrandAcceptance: .disallowed(brands: [.visa]),
                              linkPassthroughModeEnabled: false)
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.card]),
            "Selected payment method should be bank account when cards are disabled"
        )

        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.cardWithFailingChecks]),
            "Selected payment method should be bank account when cards are disabled"
        )

        XCTAssertEqual(
            sut.selectedPaymentMethodIndex,
            LinkStubs.PaymentMethodIndices.card,
            "Selected payment method should be bank account when cards are disabled"
        )
    }

    // MARK: - Card Funding Filtering Tests

    func test_cardFundingFiltering_debitOnly() throws {
        let sut = try makeSUT(
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkFundingSources: ["CARD", "BANK_ACCOUNT"],
            allowedCardFundingTypes: .debit
        )

        // Debit card should be supported
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.card]),
            "Debit card should be supported when only debit is allowed"
        )

        // Credit card should NOT be supported
        XCTAssertFalse(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.cardWithFailingChecks]),
            "Credit card should not be supported when only debit is allowed"
        )

        // Prepaid card (expired card index) should NOT be supported
        XCTAssertFalse(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.expiredCard]),
            "Prepaid card should not be supported when only debit is allowed"
        )

        // Bank account should still be supported (not affected by card funding filter)
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.bankAccount]),
            "Bank account should be supported regardless of card funding filter"
        )
    }

    func test_cardFundingFiltering_creditOnly() throws {
        let sut = try makeSUT(
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkFundingSources: ["CARD", "BANK_ACCOUNT"],
            allowedCardFundingTypes: .credit
        )

        // Debit card should NOT be supported
        XCTAssertFalse(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.card]),
            "Debit card should not be supported when only credit is allowed"
        )

        // Credit card should be supported
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.cardWithFailingChecks]),
            "Credit card should be supported when only credit is allowed"
        )
    }

    func test_cardFundingFiltering_prepaidOnly() throws {
        let sut = try makeSUT(
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkFundingSources: ["CARD", "BANK_ACCOUNT"],
            allowedCardFundingTypes: .prepaid
        )

        // Debit card should NOT be supported
        XCTAssertFalse(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.card]),
            "Debit card should not be supported when only prepaid is allowed"
        )

        // Credit card should NOT be supported
        XCTAssertFalse(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.cardWithFailingChecks]),
            "Credit card should not be supported when only prepaid is allowed"
        )

        // Prepaid card should be supported
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.expiredCard]),
            "Prepaid card should be supported when only prepaid is allowed"
        )
    }

    func test_cardFundingFiltering_debitAndCredit() throws {
        let sut = try makeSUT(
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkFundingSources: ["CARD", "BANK_ACCOUNT"],
            allowedCardFundingTypes: [.debit, .credit]
        )

        // Debit card should be supported
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.card]),
            "Debit card should be supported when debit and credit are allowed"
        )

        // Credit card should be supported
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.cardWithFailingChecks]),
            "Credit card should be supported when debit and credit are allowed"
        )

        // Prepaid card should NOT be supported
        XCTAssertFalse(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.expiredCard]),
            "Prepaid card should not be supported when only debit and credit are allowed"
        )
    }

    func test_cardFundingFiltering_allFundingTypes() throws {
        let sut = try makeSUT(
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkFundingSources: ["CARD", "BANK_ACCOUNT"],
            allowedCardFundingTypes: .all
        )

        // All cards should be supported
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.card]),
            "All cards should be supported when all funding types are allowed"
        )
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.cardWithFailingChecks]),
            "All cards should be supported when all funding types are allowed"
        )
        XCTAssertTrue(
            sut.isPaymentMethodSupported(paymentMethod: sut.paymentMethods[LinkStubs.PaymentMethodIndices.expiredCard]),
            "All cards should be supported when all funding types are allowed"
        )
    }

    func testShouldShowSecondaryButtonEnabled() throws {
        let sut = try makeSUT(canContinueWithoutLink: true)
        XCTAssertNotNil(sut.cancelButtonConfiguration)
    }

    func testShouldShowSecondaryButtonDisabled() throws {
        let sut = try makeSUT(canContinueWithoutLink: false)
        XCTAssertNil(sut.cancelButtonConfiguration)
    }
}

// MARK: - Tax Sync Tests

extension PayWithLinkViewController_WalletViewModelTests {

    // MARK: Helpers

    @MainActor
    private func makeSUTWithCheckout(
        automaticTaxEnabled: Bool,
        automaticTaxAddressSource: String? = "billing",
        amount: Int = 1000,
        paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
        checkout: CheckoutSessionBillingAddressUpdater? = nil
    ) throws -> PayWithLinkViewController.WalletViewModel {
        let intent = Intent._testCheckoutSession(
            amount: amount,
            currency: "USD",
            automaticTaxEnabled: automaticTaxEnabled,
            automaticTaxAddressSource: automaticTaxAddressSource
        )
        let (_, elementsSession) = try PayWithLinkTestHelpers.makePaymentIntentAndElementsSession()

        return PayWithLinkViewController.WalletViewModel(
            linkAccount: .init(
                email: "user@example.com",
                session: LinkStubs.consumerSession(),
                publishableKey: nil,
                displayablePaymentDetails: nil,
                useMobileEndpoints: false,
                canSyncAttestationState: false
            ),
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: PaymentSheet.Configuration(),
                linkBrand: .link,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue(),
                checkout: checkout
            ),
            paymentMethods: paymentMethods
        )
    }

    static func makePaymentMethodWithBillingAddress(
        stripeID: String = "pm_1",
        countryCode: String = "US",
        postalCode: String = "10001",
        isDefault: Bool = true
    ) -> ConsumerPaymentDetails {
        ConsumerPaymentDetails(
            stripeID: stripeID,
            details: .card(card: .init(
                expiryYear: 30,
                expiryMonth: 10,
                brand: "visa",
                networks: ["visa"],
                last4: "4242",
                funding: .debit,
                checks: nil
            )),
            billingAddress: BillingAddress(
                name: nil,
                line1: nil,
                line2: nil,
                city: nil,
                state: nil,
                postalCode: postalCode,
                countryCode: countryCode
            ),
            billingEmailAddress: nil,
            nickname: nil,
            isDefault: isDefault
        )
    }

    // MARK: No-op cases

    @MainActor
    func test_syncBillingAddressForTax_noOp_whenNotCheckoutSession() throws {
        // Given a payment intent (not a checkout session)
        let sut = try makeSUT()
        let mockCheckout = MockCheckoutSessionBillingAddressUpdater()
        sut.context.checkout = mockCheckout

        // When selecting a payment method
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount

        // Then no sync is attempted
        XCTAssertEqual(mockCheckout.callCount, 0)
        XCTAssertEqual(sut.taxSyncState, .idle)
    }

    @MainActor
    func test_syncBillingAddressForTax_noOp_whenAutomaticTaxDisabled() throws {
        // Given a checkout session with automatic tax disabled
        let sut = try makeSUTWithCheckout(
            automaticTaxEnabled: false,
            paymentMethods: [Self.makePaymentMethodWithBillingAddress()]
        )
        let mockCheckout = MockCheckoutSessionBillingAddressUpdater()
        sut.context.checkout = mockCheckout

        // When sync is called
        sut.syncBillingAddressForTax()

        // Then no network call is made
        XCTAssertEqual(mockCheckout.callCount, 0)
        XCTAssertEqual(sut.taxSyncState, .idle)
    }

    @MainActor
    func test_syncBillingAddressForTax_noOp_whenTaxSourceIsNotBilling() throws {
        // Given a checkout session using shipping as the tax source
        let sut = try makeSUTWithCheckout(
            automaticTaxEnabled: true,
            automaticTaxAddressSource: "shipping",
            paymentMethods: [Self.makePaymentMethodWithBillingAddress()]
        )
        let mockCheckout = MockCheckoutSessionBillingAddressUpdater()
        sut.context.checkout = mockCheckout

        // When sync is called
        sut.syncBillingAddressForTax()

        // Then no network call is made
        XCTAssertEqual(mockCheckout.callCount, 0)
        XCTAssertEqual(sut.taxSyncState, .idle)
    }

    @MainActor
    func test_syncBillingAddressForTax_noOp_whenPaymentMethodHasNoBillingAddress() throws {
        // Given a checkout session with automatic tax, but the selected PM has no billing address
        let pmWithoutAddress = ConsumerPaymentDetails(
            stripeID: "pm_no_address",
            details: .card(card: .init(expiryYear: 30, expiryMonth: 10, brand: "visa", networks: ["visa"], last4: "4242", funding: .debit, checks: nil)),
            billingAddress: nil,
            billingEmailAddress: nil,
            nickname: nil,
            isDefault: true
        )
        let sut = try makeSUTWithCheckout(
            automaticTaxEnabled: true,
            paymentMethods: [pmWithoutAddress]
        )
        let mockCheckout = MockCheckoutSessionBillingAddressUpdater()
        sut.context.checkout = mockCheckout

        // When sync is called
        sut.syncBillingAddressForTax()

        // Then no network call is made
        XCTAssertEqual(mockCheckout.callCount, 0)
        XCTAssertEqual(sut.taxSyncState, .idle)
    }

    @MainActor
    func test_syncBillingAddressForTax_noOp_whenNoCheckoutReference() throws {
        // Given a checkout session with automatic tax but no checkout reference
        let sut = try makeSUTWithCheckout(
            automaticTaxEnabled: true,
            paymentMethods: [Self.makePaymentMethodWithBillingAddress()],
            checkout: nil
        )

        // When sync is called
        sut.syncBillingAddressForTax()

        // Then state remains idle
        XCTAssertEqual(sut.taxSyncState, .idle)
    }

    // MARK: Successful sync

    @MainActor
    func test_syncBillingAddressForTax_updatesCallToAction_onSuccess() async throws {
        // Given a checkout session with automatic tax and an updated amount on success
        let updatedAmount = 1200
        let mockCheckout = MockCheckoutSessionBillingAddressUpdater(updatedAmount: updatedAmount)
        let sut = try makeSUTWithCheckout(
            automaticTaxEnabled: true,
            amount: 1000,
            paymentMethods: [Self.makePaymentMethodWithBillingAddress()],
            checkout: mockCheckout
        )

        // When sync is triggered
        sut.syncBillingAddressForTax()

        // Then the state goes to syncing and the CTA shows "Calculating tax..."
        XCTAssertEqual(sut.taxSyncState, .syncing)
        XCTAssertEqual(sut.confirmButtonStatus, .spinnerWithInteractionDisabled)
        if case .custom(let title) = sut.confirmButtonCallToAction {
            XCTAssertEqual(title, String.Localized.calculating_tax)
        } else {
            XCTFail("Expected .custom CTA while syncing, got \(sut.confirmButtonCallToAction)")
        }

        // ...and eventually the amount updates and state returns to idle
        await mockCheckout.waitForCompletion()
        XCTAssertEqual(sut.taxSyncState, .idle)
        XCTAssertEqual(sut.confirmButtonStatus, .enabled)
        if case .pay(let amount, _, _) = sut.confirmButtonCallToAction {
            XCTAssertEqual(amount, updatedAmount)
        } else {
            XCTFail("Expected .pay CTA after sync, got \(sut.confirmButtonCallToAction)")
        }
    }

    @MainActor
    func test_syncBillingAddressForTax_deduplicates_sameAddress() async throws {
        // Given a checkout with one payment method with a billing address
        let mockCheckout = MockCheckoutSessionBillingAddressUpdater(updatedAmount: 1200)
        let pm = Self.makePaymentMethodWithBillingAddress()
        let sut = try makeSUTWithCheckout(
            automaticTaxEnabled: true,
            paymentMethods: [pm],
            checkout: mockCheckout
        )

        // When sync is triggered once and completes
        sut.syncBillingAddressForTax()
        await mockCheckout.waitForCompletion()
        XCTAssertEqual(mockCheckout.callCount, 1)

        // When sync is triggered again for the same address
        sut.syncBillingAddressForTax()

        // Then no additional network call is made (address hasn't changed)
        XCTAssertEqual(mockCheckout.callCount, 1, "Should not re-sync the same address")
    }

    @MainActor
    func test_syncBillingAddressForTax_triggeredOnPaymentMethodSelection() async throws {
        // Given two payment methods with different billing addresses
        let pm1 = Self.makePaymentMethodWithBillingAddress(stripeID: "pm_1", countryCode: "US", postalCode: "10001", isDefault: true)
        let pm2 = Self.makePaymentMethodWithBillingAddress(stripeID: "pm_2", countryCode: "GB", postalCode: "SW1A 1AA", isDefault: false)
        let mockCheckout = MockCheckoutSessionBillingAddressUpdater(updatedAmount: 1100)
        let sut = try makeSUTWithCheckout(
            automaticTaxEnabled: true,
            paymentMethods: [pm1, pm2],
            checkout: mockCheckout
        )
        // pm1 is selected by default (no sync triggered during init)
        XCTAssertEqual(mockCheckout.callCount, 0)

        // When selecting the second payment method (different address)
        sut.selectedPaymentMethodIndex = 1

        // Then a sync is triggered and completes
        await mockCheckout.waitForCompletion()
        XCTAssertEqual(mockCheckout.callCount, 1)
    }

    // MARK: Failed sync

    @MainActor
    func test_syncBillingAddressForTax_setsFailedState_onError() async throws {
        // Given a checkout that will fail
        let mockCheckout = MockCheckoutSessionBillingAddressUpdater(shouldFail: true)
        let sut = try makeSUTWithCheckout(
            automaticTaxEnabled: true,
            paymentMethods: [Self.makePaymentMethodWithBillingAddress()],
            checkout: mockCheckout
        )

        // When sync is triggered
        sut.syncBillingAddressForTax()
        await mockCheckout.waitForCompletion()

        // Then state reflects the failure
        if case .failed = sut.taxSyncState {
            // Expected
        } else {
            XCTFail("Expected .failed state, got \(sut.taxSyncState)")
        }
        // And button is re-enabled so the user can retry
        XCTAssertEqual(sut.confirmButtonStatus, .enabled)
    }
}

// MARK: - MockCheckoutSessionBillingAddressUpdater

@MainActor
final class MockCheckoutSessionBillingAddressUpdater: CheckoutSessionBillingAddressUpdater {

    private(set) var callCount = 0
    private(set) var lastAddress: Checkout.Address?

    private let updatedAmount: Int
    private let shouldFail: Bool
    private var continuation: CheckedContinuation<Void, Never>?

    init(updatedAmount: Int = 1000, shouldFail: Bool = false) {
        self.updatedAmount = updatedAmount
        self.shouldFail = shouldFail
    }

    func reset() {
        callCount = 0
        lastAddress = nil
        continuation = nil
    }

    func waitForCompletion() async {
        await withCheckedContinuation { cont in
            continuation = cont
        }
    }

    func commitSession(
        _ apiResponse: PaymentPagesAPIResponse?,
        applying localMutation: (@MainActor @Sendable (Checkout.Session) -> Checkout.Session)?
    ) async throws { }

    func updateBillingTaxRegionIfNecessaryForPaymentSheet(
        address: Checkout.Address,
        canUpdateWhileSheetPresented: Bool
    ) async throws -> Checkout.Session {
        callCount += 1
        lastAddress = address
        defer { continuation?.resume(); continuation = nil }

        if shouldFail {
            throw NSError(domain: "TestError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Tax sync failed"])
        }

        let response = CheckoutTestHelpers.makeSession([
            "currency": "usd",
            "total_summary": [
                "due": updatedAmount,
                "subtotal": updatedAmount,
                "total": updatedAmount,
            ],
        ])
        return response.makePublicSession()
    }
}

// MARK: - Existing helpers

extension PayWithLinkViewController_WalletViewModelTests {

    func makeSUT(
        paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
        supportedPaymentDetailsTypes: Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>> = [ParsedEnum(.card), ParsedEnum(.bankAccount)],
        supportedPaymentMethodTypes: [LinkPaymentMethodType]? = nil,
        linkFundingSources: [String] = ["CARD"],
        cardBrandAcceptance: PaymentSheet.CardBrandAcceptance = .all,
        allowedCardFundingTypes: PaymentSheet.CardFundingType = .all,
        linkPassthroughModeEnabled: Bool? = nil,
        isSettingUp: Bool = false,
        linkPMOSFU: Bool? = nil,
        canContinueWithoutLink: Bool = true
    ) throws -> PayWithLinkViewController.WalletViewModel {
        // Enable card funding filtering when allowedCardFundingTypes is not .all
        let cardFundingFilteringEnabled = allowedCardFundingTypes != .all
        let (intent, elementsSession) = try isSettingUp
        ? PayWithLinkTestHelpers.makeSetupIntentAndElementsSession(
            linkFundingSources: linkFundingSources,
            linkPassthroughModeEnabled: linkPassthroughModeEnabled,
            cardFundingFilteringEnabled: cardFundingFilteringEnabled
        )
        : PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(
            linkFundingSources: linkFundingSources,
            linkPassthroughModeEnabled: linkPassthroughModeEnabled,
            linkPMOSFU: linkPMOSFU,
            cardFundingFilteringEnabled: cardFundingFilteringEnabled
        )

        var paymentSheetConfiguration = PaymentSheet.Configuration()

        paymentSheetConfiguration.cardBrandAcceptance = cardBrandAcceptance
        paymentSheetConfiguration.allowedCardFundingTypes = allowedCardFundingTypes

        return PayWithLinkViewController.WalletViewModel(
            // TODO(link): Fully mock `PaymentSheetLinkAccount and remove this.
            linkAccount: .init(
                email: "user@example.com",
                session: LinkStubs.consumerSession(supportedPaymentDetailsTypes: supportedPaymentDetailsTypes),
                publishableKey: nil,
                displayablePaymentDetails: nil,
                useMobileEndpoints: false,
                canSyncAttestationState: false
            ),
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: paymentSheetConfiguration,
                linkBrand: .link,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                canContinueWithoutLink: canContinueWithoutLink,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                supportedPaymentMethodTypes: supportedPaymentMethodTypes,
                analyticsHelper: ._testValue()
            ),
            paymentMethods: paymentMethods
        )
    }
}
