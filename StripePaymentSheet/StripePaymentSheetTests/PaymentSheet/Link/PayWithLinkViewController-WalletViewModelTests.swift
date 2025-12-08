//
//  PayWithLinkViewController-WalletViewModelTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 3/31/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

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
        let sut = try makeSUT(supportedPaymentDetailsTypes: [.bankAccount], linkFundingSources: ["BANK_ACCOUNT"])
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
        let sut = try makeSUT(supportedPaymentDetailsTypes: [.bankAccount], linkFundingSources: ["BANK_ACCOUNT"])

        XCTAssertEqual(
            sut.selectedPaymentMethodIndex,
            LinkStubs.PaymentMethodIndices.card,
            "Selected payment method should be bank account when cards are disabled"
        )
    }

    func test_defaultLogic_whenNotSupportedCardIsOnlyOption() throws {
        let paymentMethods = Array(LinkStubs.paymentMethods()[0..<1])
        let sut = try makeSUT(paymentMethods: paymentMethods,
                              supportedPaymentDetailsTypes: [.bankAccount],
                              linkFundingSources: ["BANK_ACCOUNT"])
        XCTAssertEqual(
            sut.selectedPaymentMethodIndex,
            LinkStubs.PaymentMethodIndices.card,
            "Selected payment method should be bank account when cards are disabled"
        )
    }

    func test_cardBrandFiltering_passThroughEnabled() throws {
        let sut = try makeSUT(supportedPaymentDetailsTypes: [.card],
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
        let sut = try makeSUT(supportedPaymentDetailsTypes: [.card],
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
            supportedPaymentDetailsTypes: [.card, .bankAccount],
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
            supportedPaymentDetailsTypes: [.card, .bankAccount],
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
            supportedPaymentDetailsTypes: [.card, .bankAccount],
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
            supportedPaymentDetailsTypes: [.card, .bankAccount],
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
            supportedPaymentDetailsTypes: [.card, .bankAccount],
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
        let sut = try makeSUT(shouldShowSecondaryCta: true)
        XCTAssertNotNil(sut.cancelButtonConfiguration)
    }

    func testShouldShowSecondaryButtonDisabled() throws {
        let sut = try makeSUT(shouldShowSecondaryCta: false)
        XCTAssertNil(sut.cancelButtonConfiguration)
    }
}

extension PayWithLinkViewController_WalletViewModelTests {

    func makeSUT(
        paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
        supportedPaymentDetailsTypes: Set<ConsumerPaymentDetails.DetailsType> = [.card, .bankAccount],
        linkFundingSources: [String] = ["CARD"],
        cardBrandAcceptance: PaymentSheet.CardBrandAcceptance = .all,
        allowedCardFundingTypes: PaymentSheet.CardFundingType = .all,
        linkPassthroughModeEnabled: Bool? = nil,
        isSettingUp: Bool = false,
        linkPMOSFU: Bool? = nil,
        shouldShowSecondaryCta: Bool = true
    ) throws -> PayWithLinkViewController.WalletViewModel {
        let (intent, elementsSession) = try isSettingUp
        ? PayWithLinkTestHelpers.makeSetupIntentAndElementsSession(
            linkFundingSources: linkFundingSources,
            linkPassthroughModeEnabled: linkPassthroughModeEnabled
        )
        : PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(
            linkFundingSources: linkFundingSources,
            linkPassthroughModeEnabled: linkPassthroughModeEnabled,
            linkPMOSFU: linkPMOSFU
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
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                shouldShowSecondaryCta: shouldShowSecondaryCta,
                canSkipWalletAfterVerification: false,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue()
            ),
            paymentMethods: paymentMethods
        )
    }
}
