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
@testable@_spi(STP) import StripePaymentSheet
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
        XCTAssertFalse(sut.context.intent.isSettingUp)

        // Card
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.card
        XCTAssertNil(sut.mandate)

        // Bank account
        sut.selectedPaymentMethodIndex = LinkStubs.PaymentMethodIndices.bankAccount
        XCTAssertEqual(sut.mandate?.string, "By continuing, you agree to authorize payments pursuant to these terms.")
    }

    func test_showCorrectMandateForPaymentWithLinkPMOSFUPaymentMethodMode() throws {
        let sut = try makeSUT(linkPassthroughModeEnabled: false, isSettingUp: false, linkPMOSFU: true)
        XCTAssertFalse(sut.context.intent.isSettingUp)
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
        XCTAssertFalse(sut.context.intent.isSettingUp)
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
        XCTAssertTrue(sut.context.intent.isSettingUp)

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
}

extension PayWithLinkViewController_WalletViewModelTests {

    func makeSUT(
        paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
        supportedPaymentDetailsTypes: Set<ConsumerPaymentDetails.DetailsType> = [.card, .bankAccount],
        linkFundingSources: [String] = ["CARD"],
        cardBrandAcceptance: PaymentSheet.CardBrandAcceptance = .all,
        linkPassthroughModeEnabled: Bool? = nil,
        isSettingUp: Bool = false,
        linkPMOSFU: Bool? = nil
    ) throws -> PayWithLinkViewController.WalletViewModel {
        let (intent, elementsSession) = try isSettingUp
        ? makeSetupIntentAndElementsSession(linkFundingSources: linkFundingSources, linkPassthroughModeEnabled: linkPassthroughModeEnabled)
            : makePaymentIntentAndElementsSession(linkFundingSources: linkFundingSources, linkPassthroughModeEnabled: linkPassthroughModeEnabled, linkPMOSFU: linkPMOSFU)

        var paymentSheetConfiguration = PaymentSheet.Configuration()
        if let linkPMOSFU {
            paymentSheetConfiguration.shouldReadPaymentMethodOptionsSetupFutureUsage = true
        }

        paymentSheetConfiguration.cardBrandAcceptance = cardBrandAcceptance

        return PayWithLinkViewController.WalletViewModel(
            // TODO(link): Fully mock `PaymentSheetLinkAccount and remove this.
            linkAccount: .init(
                email: "user@example.com",
                session: LinkStubs.consumerSession(supportedPaymentDetailsTypes: supportedPaymentDetailsTypes),
                publishableKey: nil,
                useMobileEndpoints: false
            ),
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: paymentSheetConfiguration,
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                callToAction: nil,
                analyticsHelper: ._testValue()
            ),
            paymentMethods: paymentMethods
        )
    }

    private func makePaymentIntentAndElementsSession(
        linkFundingSources: [String] = ["CARD"],
        linkPassthroughModeEnabled: Bool? = nil,
        linkPMOSFU: Bool? = nil
    ) throws -> (Intent, STPElementsSession) {
        // Link settings don't live in the PaymentIntent object itself, but in the /elements/sessions API response
        // So we construct a minimal response (see STPPaymentIntentTest.testDecodedObjectFromAPIResponseMapping) to parse them
        var paymentIntentJson = try XCTUnwrap(STPTestUtils.jsonNamed(STPTestJSONPaymentIntent))
        if let linkPMOSFU {
            paymentIntentJson["payment_method_options"] = [(linkPassthroughModeEnabled ?? false ? "card" : "link"): ["setup_future_usage": "off_session"]]
        }
        let orderedPaymentJson = ["card", "link"]
        let paymentIntentResponse = [
            "payment_intent": paymentIntentJson,
            "ordered_payment_method_types": orderedPaymentJson,
        ] as [String: Any]

        var linkSettingsJson: [String: Any] = ["link_funding_sources": linkFundingSources]

        if let linkPassthroughModeEnabled {
            linkSettingsJson["link_passthrough_mode_enabled"] = linkPassthroughModeEnabled
        }

        let response = [
            "payment_method_preference": paymentIntentResponse,
            "link_settings": linkSettingsJson,
            "session_id": "abc123",
        ] as [String: Any]
        let elementsSession = try XCTUnwrap(
            STPElementsSession.decodedObject(fromAPIResponse: response)
        )
        let paymentIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "payment_intent"]
        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJSON)!

        return (Intent.paymentIntent(paymentIntent), elementsSession)
    }

    private func makeSetupIntentAndElementsSession(
        linkFundingSources: [String] = ["CARD"],
        linkPassthroughModeEnabled: Bool? = nil
    ) throws -> (Intent, STPElementsSession) {
        // Link settings don't live in the PaymentIntent object itself, but in the /elements/sessions API response
        // So we construct a minimal response (see STPPaymentIntentTest.testDecodedObjectFromAPIResponseMapping) to parse them
        let setupIntentJson = try XCTUnwrap(STPTestUtils.jsonNamed(STPTestJSONSetupIntent))
        let orderedSetupJson = ["card", "link"]
        let setupIntentResponse = [
            "setup_intent": setupIntentJson,
            "ordered_payment_method_types": orderedSetupJson,
        ] as [String: Any]

        var linkSettingsJson: [String: Any] = ["link_funding_sources": linkFundingSources]

        if let linkPassthroughModeEnabled {
            linkSettingsJson["link_passthrough_mode_enabled"] = linkPassthroughModeEnabled
        }

        let response = [
            "payment_method_preference": setupIntentResponse,
            "link_settings": linkSettingsJson,
            "session_id": "abc123",
        ] as [String: Any]
        let elementsSession = try XCTUnwrap(
            STPElementsSession.decodedObject(fromAPIResponse: response)
        )
        let setupIntentJSON = elementsSession.allResponseFields[jsonDict: "payment_method_preference"]?[jsonDict: "setup_intent"]
        let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: setupIntentJSON)!

        return (Intent.setupIntent(setupIntent), elementsSession)
    }
}
