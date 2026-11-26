//
//  EmbeddedLinkPreselectionTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@_spi(InternalOnlyAPI) import StripeUICore
import XCTest

/// After a customer verifies inline, Embedded selects Link with the payment details the Link wallet would select first, instead of opening the wallet.
@MainActor
final class EmbeddedLinkPreselectionTests: XCTestCase {
    private let analyticsClient = STPTestingAnalyticsClient()
    private let bankAccountDataConsent = "Example Merchant can access account details. [Learn more](https://stripe.com)"

    override func setUp() async throws {
        try await super.setUp()
        EmbeddedLinkInlineAuthRegistry.reset()
        // The card form's country field needs address specs.
        await AddressSpecProvider.shared.loadAddressSpecs()
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = true
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
    }

    override func tearDown() {
        EmbeddedLinkInlineAuthRegistry.reset()
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = nil
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        LinkAccountContext.shared.account = nil
        // Selecting Link saves it as the default for customer-less sessions.
        CustomerPaymentOption.setLocalDefaultPaymentMethod(nil, forCustomer: nil)
        super.tearDown()
    }

    func testVerifyingSelectsLinkWithTheDefaultPaymentDetails() async throws {
        // Given a customer who verified inline, whose default card isn't their first payment method
        let (element, linkAccount) = makeVerifiedElement()
        let delegate = EmbeddedPreselectionDelegateSpy()
        element.delegate = delegate
        let defaultCard = paymentMethod(LinkStubs.PaymentMethodIndices.card)
        let bankAccount = paymentMethod(LinkStubs.PaymentMethodIndices.bankAccount)

        // When their Link payment details load
        await preselect(element, linkAccount: linkAccount, from: [bankAccount, defaultCard])

        // Then Link is the only row, selected with the default card, which the row shows next to the Link logo
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertEqual(linkRow.type, .link)
        XCTAssertTrue(linkRow.isDisplayingAccessoryView)
        XCTAssertEqual(linkRow.label.text, defaultCard.paymentSheetLabel)
        XCTAssertEqual(sublabelText(of: linkRow), defaultCard.paymentSheetSublabel)
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, defaultCard.stripeID)
        XCTAssertEqual(element.paymentOption?.paymentMethodType, "link")
        XCTAssertNil(element.paymentOption?.mandateText)
        XCTAssertEqual(delegate.paymentOptionUpdates, 1)
        // ...and it's logged as preselected, not as falling back to the wallet
        let preselected = analyticsClient.events.filter { $0.event == .linkEmbeddedInlineAuthPreselected }
        XCTAssertEqual(preselected.map { $0.params["payment_details_type"] as? String }, [defaultCard.type.rawValue])
        XCTAssertFalse(analyticsClient.events.contains { $0.event == .linkEmbeddedInlineAuthPreselectionFellBack })
    }

    func testWithoutADefaultTheFirstPaymentDetailsAreSelected() async throws {
        // Given a customer who verified inline, with no default payment method
        let (element, linkAccount) = makeVerifiedElement()
        let bankAccount = paymentMethod(LinkStubs.PaymentMethodIndices.bankAccount)
        let card = paymentMethod(LinkStubs.PaymentMethodIndices.card)
        card.isDefault = false

        // When their Link payment details load
        await preselect(element, linkAccount: linkAccount, from: [bankAccount, card])

        // Then Link is selected with the first one
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, bankAccount.stripeID)
    }

    func testPaymentDetailsThatNeedTheWalletFallBackToIt() async throws {
        let cases: [(name: String, paymentDetails: [ConsumerPaymentDetails], reason: EmbeddedPaymentElement.LinkPreselectionFallbackReason)] = [
            ("no payment details", [], .noPaymentDetails),
            ("a failed CVC check", [paymentMethod(LinkStubs.PaymentMethodIndices.cardWithFailingChecks)], .needsCardDetails),
            ("an expired card", [paymentMethod(LinkStubs.PaymentMethodIndices.expiredCard)], .needsCardDetails),
            ("an unsupported type", [paymentMethod(LinkStubs.PaymentMethodIndices.genericWithDisplay)], .unsupported),
        ]
        for testCase in cases {
            // Given a customer who verified inline
            let (element, linkAccount) = makeVerifiedElement()

            // When their Link payment details load
            let result = await element.defaultLinkConfirmOption(in: testCase.paymentDetails, linkAccount: linkAccount, shippingAddress: nil)

            // Then nothing is preselected
            XCTAssertEqual(failureReason(of: result), testCase.reason, testCase.name)
        }
    }

    func testImmediateActionWithAMandateFallsBackToTheWallet() async throws {
        // Given a merchant that acts as soon as a row is selected, and a customer whose default is a bank account
        var configuration = makeConfiguration()
        configuration.rowSelectionBehavior = .immediateAction {}
        let (element, linkAccount) = makeVerifiedElement(configuration: configuration)
        let bankAccount = paymentMethod(LinkStubs.PaymentMethodIndices.bankAccount)
        bankAccount.isDefault = true

        // When their Link payment details load
        let result = await element.defaultLinkConfirmOption(in: [bankAccount], linkAccount: linkAccount, shippingAddress: nil)

        // Then nothing is preselected, since the customer wouldn't see the mandate below the list
        XCTAssertEqual(failureReason(of: result), .mandateNotVisible)

        // When the merchant shows the mandate itself
        configuration.embeddedViewDisplaysMandateText = false
        let (merchantMandateElement, merchantMandateAccount) = makeVerifiedElement(configuration: configuration)
        let merchantMandateResult = await merchantMandateElement.defaultLinkConfirmOption(in: [bankAccount], linkAccount: merchantMandateAccount, shippingAddress: nil)

        // Then the bank account is preselected
        XCTAssertNil(failureReason(of: merchantMandateResult))
    }

    func testAFailedLoadFallsBackToTheWallet() {
        // Given a customer who verified inline
        let (element, linkAccount) = makeVerifiedElement()

        // When their Link payment details fail to load
        element.finishPreselectingLinkPaymentMethod(.failure(.loadFailed), linkAccount: linkAccount, selectionBeforePreselecting: nil)

        // Then Link isn't selected, and the fallback is logged
        XCTAssertNil(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertNil(element.linkConfirmOption)
        let fellBack = analyticsClient.events.filter { $0.event == .linkEmbeddedInlineAuthPreselectionFellBack }
        XCTAssertEqual(fellBack.map { $0.params["reason"] as? String }, ["load_failed"])
    }

    func testAResultForAnAccountThatChangedIsDropped() async {
        // Given a customer who verified inline
        let (element, linkAccount) = makeVerifiedElement()
        let result = await element.defaultLinkConfirmOption(in: LinkStubs.paymentMethods(), linkAccount: linkAccount, shippingAddress: nil)

        // When another surface logs them out before their payment details are applied
        LinkAccountContext.shared.account = nil
        element.finishPreselectingLinkPaymentMethod(result, linkAccount: linkAccount, selectionBeforePreselecting: nil)

        // Then nothing is selected
        XCTAssertNil(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertNil(element.linkConfirmOption)
    }

    func testAPreselectedBankAccountShowsItsMandateAndDataConsent() async throws {
        for displaysMandateText in [true, false] {
            // Given a customer who verified inline, whose default is a bank account
            var configuration = makeConfiguration()
            configuration.embeddedViewDisplaysMandateText = displaysMandateText
            let (element, linkAccount) = makeVerifiedElement(configuration: configuration)
            let bankAccount = paymentMethod(LinkStubs.PaymentMethodIndices.bankAccount)
            bankAccount.isDefault = true

            // When their Link payment details load
            await preselect(element, linkAccount: linkAccount, from: [bankAccount])

            // Then the payment option carries the bank mandate and the data-sharing consent, whether the element or the merchant shows them
            let mandateText = try XCTUnwrap(element.paymentOption?.mandateText?.string)
            let bankMandate = try XCTUnwrap(PayWithLinkViewController.WalletViewModel.mandate(for: bankAccount, context: element.makeLinkContext(linkAccount: linkAccount))?.string)
            XCTAssertTrue(mandateText.hasPrefix(bankMandate), "displaysMandateText: \(displaysMandateText)")
            XCTAssertTrue(mandateText.hasSuffix("Example Merchant can access account details. Learn more"), "displaysMandateText: \(displaysMandateText)")
        }
    }

    func testABankAccountPickedInTheWalletDoesNotShowItsMandateAgain() async throws {
        // Given a customer who verified inline, whose default bank account was preselected, so its mandate shows below the list
        let (element, linkAccount) = makeVerifiedElement()
        let bankAccount = paymentMethod(LinkStubs.PaymentMethodIndices.bankAccount)
        bankAccount.isDefault = true
        await preselect(element, linkAccount: linkAccount, from: [bankAccount])
        XCTAssertNotNil(element.paymentOption?.mandateText)

        // When they open the wallet, which shows the mandate itself, and pick the same bank account
        let confirmOption = PaymentSheet.LinkConfirmOption.withPaymentDetails(brand: .link, account: linkAccount, paymentDetails: bankAccount, confirmationExtras: nil, shippingAddress: nil)
        element.linkWalletDidFinish(with: confirmOption, revertsSelectionOnClose: false)

        // Then the mandate doesn't show again below the list
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, bankAccount.stripeID)
        XCTAssertNil(element.paymentOption?.mandateText)
        XCTAssertNil(element.preselectedLinkPaymentDetailsID)
    }

    func testTappingTheLinkOnlyRowOpensTheWallet() async throws {
        // Given Link is preselected with the customer's default card
        let (element, linkAccount) = makeVerifiedElement()
        await preselect(element, linkAccount: linkAccount, from: [paymentMethod(LinkStubs.PaymentMethodIndices.card)])

        // Then tapping the Link-only row, which is already selected, opens the wallet to change the card
        XCTAssertTrue(element.linkRowSelectionOpensWallet(linkWasSelected: true))
    }

    func testTappingTheLinkOnlyRowOpensTheWalletAfterTheSessionExpires() async throws {
        // Given Link is the only row, preselected with the customer's default card
        let (element, linkAccount) = makeVerifiedElement()
        await preselect(element, linkAccount: linkAccount, from: [paymentMethod(LinkStubs.PaymentMethodIndices.card)])

        // When their Link session expires, so they need to verify again
        linkAccount.applyAuthResponse(.init(consumerSession: LinkAuthStubs.session()))
        XCTAssertEqual(linkAccount.sessionState, .requiresVerification)

        // Then tapping the row still opens Link, which asks them to verify before showing the wallet
        XCTAssertTrue(element.linkRowSelectionOpensWallet(linkWasSelected: true))
        // ...while Link pays through the wallet until they pick something again
        XCTAssertNil(element.linkPaymentDetails)
    }

    func testPayingAnotherWayShowsEveryPaymentMethod() async throws {
        // Given Link is the only row, preselected with the customer's default card
        let (element, linkAccount) = makeVerifiedElement(paymentMethodTypes: [.stripe(.card), .stripe(.cashApp)])
        let delegate = EmbeddedPreselectionDelegateSpy()
        element.delegate = delegate
        await preselect(element, linkAccount: linkAccount, from: [paymentMethod(LinkStubs.PaymentMethodIndices.card)])
        XCTAssertEqual(delegate.paymentOptionUpdates, 1)

        // When the customer taps "Pay another way" in the Link wallet
        element.linkWalletDidFinish(with: nil, shouldReturnToPaymentSheet: true, revertsSelectionOnClose: false)

        // Then every payment method shows again, with none selected
        XCTAssertFalse(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link, .new(paymentMethodType: .stripe(.card)), .new(paymentMethodType: .stripe(.cashApp))])
        XCTAssertNil(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertNil(element.linkConfirmOption)
        XCTAssertNil(element.paymentOption)
        XCTAssertEqual(delegate.paymentOptionUpdates, 2)
        // ...and the Link row shows the customer's email again
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.rowButtons.first)
        XCTAssertEqual(sublabelText(of: linkRow), linkAccount.email)
        // ...and it's logged as paying another way, not closing the wallet
        XCTAssertTrue(analyticsClient.events.contains { $0.event == .linkEmbeddedInlineAuthPaidAnotherWay })
        XCTAssertFalse(analyticsClient.events.contains { $0.event == .linkEmbeddedInlineAuthWalletClosed })
    }

    func testClosingTheWalletKeepsOnlyLink() async throws {
        // Given Link is the only row, preselected with the customer's default card
        let (element, linkAccount) = makeVerifiedElement()
        let defaultCard = paymentMethod(LinkStubs.PaymentMethodIndices.card)
        await preselect(element, linkAccount: linkAccount, from: [defaultCard])

        // When the customer opens the wallet and closes it
        element.linkWalletDidFinish(with: nil, shouldReturnToPaymentSheet: false, revertsSelectionOnClose: false)

        // Then Link is still the only row, selected with the same card
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        XCTAssertEqual(element.embeddedPaymentMethodsView.selectedRowButton?.type, .link)
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, defaultCard.stripeID)
    }

    func testPickingOtherPaymentDetailsKeepsOnlyLink() async throws {
        // Given Link is the only row, preselected with the customer's default card
        let (element, linkAccount) = makeVerifiedElement()
        await preselect(element, linkAccount: linkAccount, from: [paymentMethod(LinkStubs.PaymentMethodIndices.card)])

        // When the customer picks their bank account in the wallet
        let bankAccount = paymentMethod(LinkStubs.PaymentMethodIndices.bankAccount)
        element.linkWalletDidFinish(with: confirmOption(bankAccount, linkAccount: linkAccount), revertsSelectionOnClose: false)

        // Then Link is still the only row, now showing the bank account
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertEqual(linkRow.label.text, bankAccount.paymentSheetLabel)
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, bankAccount.stripeID)
    }

    func testPickingInTheWalletAfterFallingBackShowsOnlyLink() {
        // Given a customer whose default couldn't be preselected, so the wallet opened
        let (element, linkAccount) = makeVerifiedElement()
        XCTAssertFalse(element.showsOnlyLink)

        // When they pick a card in it
        let card = paymentMethod(LinkStubs.PaymentMethodIndices.card)
        element.linkWalletDidFinish(with: confirmOption(card, linkAccount: linkAccount), revertsSelectionOnClose: false)

        // Then Link is the only row, selected with that card
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, card.stripeID)
    }

    func testPickingLinkFromTheFullListShowsOnlyLinkAgain() async throws {
        // Given a customer who paid another way after Link was preselected
        let (element, linkAccount) = makeVerifiedElement()
        await preselect(element, linkAccount: linkAccount, from: [paymentMethod(LinkStubs.PaymentMethodIndices.card)])
        element.linkWalletDidFinish(with: nil, shouldReturnToPaymentSheet: true, revertsSelectionOnClose: false)

        // When they tap Link again and pick a card in the wallet
        let card = paymentMethod(LinkStubs.PaymentMethodIndices.card)
        element.linkWalletDidFinish(with: confirmOption(card, linkAccount: linkAccount), revertsSelectionOnClose: true)

        // Then Link is the only row again, selected with that card and showing it
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertEqual(linkRow.label.text, card.paymentSheetLabel)
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, card.stripeID)
    }

    func testPickingWithoutPaymentDetailsShowsEveryPaymentMethod() async throws {
        // Given Link is the only row, preselected with the customer's default card
        let (element, linkAccount) = makeVerifiedElement()
        await preselect(element, linkAccount: linkAccount, from: [paymentMethod(LinkStubs.PaymentMethodIndices.card)])

        // When the wallet can't hand back payment details, so Link pays through it
        element.linkWalletDidFinish(with: .wallet(brand: .link), revertsSelectionOnClose: false)

        // Then every payment method shows, with Link still selected
        XCTAssertFalse(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link, .new(paymentMethodType: .stripe(.card))])
        XCTAssertEqual(element.embeddedPaymentMethodsView.selectedRowButton?.type, .link)
        XCTAssertNil(element.linkConfirmOption)
    }

    func testClearingThePaymentOptionShowsEveryPaymentMethod() async throws {
        // Given Link is the only row, preselected with the customer's default card
        let (element, linkAccount) = makeVerifiedElement()
        await preselect(element, linkAccount: linkAccount, from: [paymentMethod(LinkStubs.PaymentMethodIndices.card)])

        // When the merchant clears the payment option
        element.clearPaymentOption()

        // Then every payment method shows, with none selected
        XCTAssertFalse(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link, .new(paymentMethodType: .stripe(.card))])
        XCTAssertNil(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertNil(element.paymentOption)
    }

    func testAnUpdateKeepsOnlyLinkWhileLinkIsShown() async throws {
        // Given Link is the only row, preselected with the customer's default card
        let configuration = makeConfiguration()
        let (element, linkAccount) = makeVerifiedElement(configuration: configuration)
        let defaultCard = paymentMethod(LinkStubs.PaymentMethodIndices.card)
        await preselect(element, linkAccount: linkAccount, from: [defaultCard])

        // When the merchant updates the element
        element.applyLoadResult(makeLoadResult(paymentMethodTypes: [.stripe(.card)]), confirmationChallenge: nil, configuration: configuration)

        // Then Link is still the only row, selected with the same card
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, defaultCard.stripeID)

        // When an update stops showing Link
        element.applyLoadResult(makeLoadResult(paymentMethodTypes: [.stripe(.card)], showsLink: false), confirmationChallenge: nil, configuration: configuration)

        // Then the other payment methods show
        XCTAssertFalse(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.new(paymentMethodType: .stripe(.card))])
    }

    func testChangeOpensTheWalletWhenConfirmingFromTheFormSheet() async throws {
        // Given a merchant whose form sheets confirm, and Link preselected with the customer's default card
        var configuration = makeConfiguration()
        configuration.formSheetAction = .confirm { _ in }
        let (element, linkAccount) = makeVerifiedElement(configuration: configuration)
        await preselect(element, linkAccount: linkAccount, from: [paymentMethod(LinkStubs.PaymentMethodIndices.card)])

        // Then Link is selected inline, and "Change" opens the wallet to pick something else
        XCTAssertEqual(element.embeddedPaymentMethodsView.selectedRowButton?.type, .link)
        XCTAssertTrue(element.linkRowSelectionOpensWallet(linkWasSelected: true))
        // ...but newly selecting Link without picked details keeps paying in the wallet at confirm time
        element.linkConfirmOption = nil
        XCTAssertFalse(element.linkRowSelectionOpensWallet(linkWasSelected: false))
    }

    // MARK: - Helpers

    private func preselect(_ element: EmbeddedPaymentElement, linkAccount: PaymentSheetLinkAccount, from paymentDetails: [ConsumerPaymentDetails]) async {
        let result = await element.defaultLinkConfirmOption(in: paymentDetails, linkAccount: linkAccount, shippingAddress: nil)
        element.finishPreselectingLinkPaymentMethod(result, linkAccount: linkAccount, selectionBeforePreselecting: element.embeddedPaymentMethodsView.selectedRowButton?.type)
    }

    private func failureReason(of result: Result<PaymentSheet.LinkConfirmOption, EmbeddedPaymentElement.LinkPreselectionFallbackReason>) -> EmbeddedPaymentElement.LinkPreselectionFallbackReason? {
        guard case .failure(let reason) = result else { return nil }
        return reason
    }

    private func paymentMethod(_ index: Int) -> ConsumerPaymentDetails {
        LinkStubs.paymentMethods()[index]
    }

    private func confirmOption(_ paymentDetails: ConsumerPaymentDetails, linkAccount: PaymentSheetLinkAccount) -> PaymentSheet.LinkConfirmOption {
        .withPaymentDetails(brand: .link, account: linkAccount, paymentDetails: paymentDetails, confirmationExtras: nil, shippingAddress: nil)
    }

    /// An element whose inline verification card was shown and verified, which leaves the regular Link row at the top.
    private func makeVerifiedElement(
        configuration: EmbeddedPaymentElement.Configuration? = nil,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType] = [.stripe(.card)]
    ) -> (EmbeddedPaymentElement, PaymentSheetLinkAccount) {
        let linkAccount = PaymentSheetLinkAccount(
            email: "jane.diaz@example.com",
            session: LinkAuthStubs.session(),
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false,
            supportedVerificationTypes: [.sms, .email]
        )
        LinkAccountContext.shared.account = linkAccount
        let element = EmbeddedPaymentElement(
            configuration: configuration ?? makeConfiguration(),
            loadResult: makeLoadResult(paymentMethodTypes: paymentMethodTypes),
            analyticsHelper: ._testValue(integrationShape: .embedded, analyticsClient: analyticsClient)
        )
        XCTAssertTrue(element.placesLinkFirst)
        let verifiedSession = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "jane.diaz@example.com",
            redactedFormattedPhoneNumber: "(***) *** **23",
            unredactedPhoneNumber: nil,
            phoneNumberCountry: "US",
            verificationSessions: [],
            supportedPaymentDetailsTypes: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            mobileFallbackWebviewParams: nil,
            currentAuthenticationLevel: .oneFactorAuth,
            minimumAuthenticationLevel: .oneFactorAuth
        )
        linkAccount.applyAuthResponse(.init(consumerSession: verifiedSession))
        element.linkInlineAuth?.invalidate()
        return (element, linkAccount)
    }

    private func makeLoadResult(paymentMethodTypes: [PaymentSheet.PaymentMethodType], showsLink: Bool = true) -> PaymentSheetLoader.LoadResult {
        let stripeTypes = paymentMethodTypes.compactMap { type -> STPPaymentMethodType? in
            guard case .stripe(let stripeType) = type else { return nil }
            return stripeType
        }
        return PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: stripeTypes),
            elementsSession: ._testValue(
                paymentMethodTypes: stripeTypes.map(\.identifier) + (showsLink ? ["link"] : []),
                linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
                linkPaymentMethodBankAccountDataConsent: bankAccountDataConsent
            ),
            savedPaymentMethods: [],
            paymentMethodTypes: paymentMethodTypes,
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical,
            customerProvider: CustomerProvider(customer: nil)
        )
    }

    private func makeConfiguration() -> EmbeddedPaymentElement.Configuration {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.allowsLinkInlineVerification = true
        configuration.merchantDisplayName = "Example Merchant"
        return configuration
    }

    private func sublabelText(of rowButton: RowButton) -> String? {
        (rowButton.sublabel as? RowButton.PlainSublabelView)?.textLabel.text
    }
}

@MainActor
private final class EmbeddedPreselectionDelegateSpy: EmbeddedPaymentElementDelegate {
    var paymentOptionUpdates = 0

    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {}
    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        paymentOptionUpdates += 1
    }
}
