//
//  EmbeddedBankRowLinkWalletTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@_spi(InternalOnlyAPI) import StripeUICore
import XCTest

/// When native Link can pay with bank accounts, Embedded's Bank row opens the Link wallet, showing only bank accounts, instead of the bank form.
@MainActor
final class EmbeddedBankRowLinkWalletTests: XCTestCase {
    private let analyticsClient = STPTestingAnalyticsClient()

    override func setUp() async throws {
        try await super.setUp()
        // The card form's country field needs address specs.
        await AddressSpecProvider.shared.loadAddressSpecs()
        EmbeddedLinkInlineAuthRegistry.reset()
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

    func testTheBankRowOpensTheLinkWalletInsteadOfTheBankForm() throws {
        // Given native Link can pay with bank accounts
        let element = makeElement()
        let delegate = EmbeddedBankRowDelegateSpy()
        element.delegate = delegate

        // Then the Bank row has no form
        XCTAssertTrue(element.isBankRowOpeningLinkWallet(.new(paymentMethodType: .instantDebits)))
        XCTAssertFalse(element.willDisplayForm(for: .new(paymentMethodType: .instantDebits)))

        // When the customer taps it, and the wallet can't be presented
        element.embeddedPaymentMethodsView.didTap(rowButton: try bankRow(of: element))

        // Then no form opens, and the tap is undone without telling the merchant about a payment option
        XCTAssertNil(element.selectedFormViewController)
        XCTAssertNil(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertNil(element.paymentOption)
        XCTAssertEqual(delegate.paymentOptionUpdates, 0)
    }

    func testTheBankRowShowsTheBankFormWhenLinkCantPayWithBankAccounts() {
        let cases: [(name: String, nativeLink: Bool, linkFundingSources: Set<ParsedEnum<LinkSettings.FundingSource>>, linkDisplay: PaymentSheet.LinkConfiguration.Display)] = [
            ("native Link unavailable", false, [ParsedEnum(.card), ParsedEnum(.bankAccount)], .automatic),
            ("no bank account funding source", true, [ParsedEnum(.card)], .automatic),
            ("Link row hidden", true, [ParsedEnum(.card), ParsedEnum(.bankAccount)], .never),
        ]
        for testCase in cases {
            // Given Link can't pay with bank accounts from the Bank row
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = testCase.nativeLink
            var configuration = makeConfiguration()
            configuration.link = PaymentSheet.LinkConfiguration(display: testCase.linkDisplay)
            let element = makeElement(configuration: configuration, linkFundingSources: testCase.linkFundingSources)

            // Then the Bank row shows the bank form
            XCTAssertFalse(element.isBankRowOpeningLinkWallet(.new(paymentMethodType: .instantDebits)), testCase.name)
            XCTAssertTrue(element.willDisplayForm(for: .new(paymentMethodType: .instantDebits)), testCase.name)
        }
    }

    func testPickingABankAccountShowsOnlyLink() throws {
        // Given a customer who tapped the Bank row
        let element = makeElement()
        let linkAccount = makeVerifiedLinkAccount()
        let delegate = EmbeddedBankRowDelegateSpy()
        element.delegate = delegate

        // When they pick a bank account in the Link wallet
        let bankAccount = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
        element.linkWalletDidFinish(with: confirmOption(bankAccount, linkAccount: linkAccount), revertsSelectionOnClose: true, opensFromBankRow: true)

        // Then Link is the only row, selected with that bank account
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        let linkRow = try XCTUnwrap(element.embeddedPaymentMethodsView.selectedRowButton)
        XCTAssertEqual(linkRow.label.text, bankAccount.paymentSheetLabel)
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, bankAccount.stripeID)
        XCTAssertEqual(element.paymentOption?.paymentMethodType, "link")
        XCTAssertEqual(delegate.paymentOptionUpdates, 1)
        // ...and "Change" opens the Link wallet again
        XCTAssertTrue(element.linkRowSelectionOpensWallet(linkWasSelected: true))
        // ...and it isn't logged as part of inline verification
        XCTAssertFalse(analyticsClient.events.contains { $0.event == .linkEmbeddedInlineAuthWalletSelected })
    }

    func testClosingTheWalletKeepsThePreviousSelection() throws {
        // Given Link is selected
        let element = makeElement()
        _ = makeVerifiedLinkAccount()
        element.embeddedPaymentMethodsView.selectLinkRow()

        // When the wallet that the Bank row opened is closed
        element.linkWalletDidFinish(with: nil, revertsSelectionOnClose: true, opensFromBankRow: true)

        // Then Link stays selected, and every payment method still shows
        XCTAssertEqual(element.embeddedPaymentMethodsView.selectedRowButton?.type, .link)
        XCTAssertFalse(element.showsOnlyLink)
        XCTAssertFalse(analyticsClient.events.contains { $0.event == .linkEmbeddedInlineAuthWalletClosed })
    }

    func testAnUpdateKeepsOnlyLinkAfterPickingABankAccount() {
        // Given a customer who picked a bank account in the wallet the Bank row opened
        let configuration = makeConfiguration()
        let element = makeElement(configuration: configuration)
        let linkAccount = makeVerifiedLinkAccount()
        let bankAccount = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
        element.linkWalletDidFinish(with: confirmOption(bankAccount, linkAccount: linkAccount), revertsSelectionOnClose: true, opensFromBankRow: true)

        // When the merchant updates the element
        element.applyLoadResult(makeLoadResult(), confirmationChallenge: nil, configuration: configuration)

        // Then Link is still the only row, selected with the same bank account
        XCTAssertTrue(element.showsOnlyLink)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.map(\.type), [.link])
        XCTAssertEqual(element._paymentOption?.currentLinkPaymentMethod, bankAccount.stripeID)
    }

    func testVerifyingInTheWalletReplacesTheInlineVerificationCardWithTheLinkRow() throws {
        // Given a returning Link customer who sees the inline verification card
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = true
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
        var configuration = makeConfiguration()
        configuration.allowsLinkInlineVerification = true
        let element = makeElement(configuration: configuration)
        XCTAssertNotNil(element.embeddedPaymentMethodsView.linkInlineVerificationView)

        // When they tap the Bank row, verify in the Link wallet, and pick a bank account
        linkAccount.applyAuthResponse(.init(consumerSession: makeVerifiedSession()))
        let bankAccount = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
        element.linkWalletDidFinish(with: confirmOption(bankAccount, linkAccount: linkAccount), revertsSelectionOnClose: true, opensFromBankRow: true)
        // ...then tap "Change" and continue another way
        element.linkWalletDidFinish(with: nil, shouldReturnToPaymentSheet: true, revertsSelectionOnClose: false)

        // Then every payment method shows, with the regular Link row at the top instead of the card
        XCTAssertFalse(element.showsOnlyLink)
        XCTAssertNil(element.embeddedPaymentMethodsView.linkInlineVerificationView)
        XCTAssertEqual(element.embeddedPaymentMethodsView.rowButtons.first?.type, .link)
        XCTAssertEqual(element.linkInlineAuth?.phase ?? .finished, .finished)
    }

    // MARK: - Helpers

    private func bankRow(of element: EmbeddedPaymentElement) throws -> RowButton {
        try XCTUnwrap(element.embeddedPaymentMethodsView.rowButtons.first { $0.type == .new(paymentMethodType: .instantDebits) })
    }

    private func confirmOption(_ paymentDetails: ConsumerPaymentDetails, linkAccount: PaymentSheetLinkAccount) -> PaymentSheet.LinkConfirmOption {
        .withPaymentDetails(brand: .link, account: linkAccount, paymentDetails: paymentDetails, confirmationExtras: nil, shippingAddress: nil)
    }

    private func makeElement(
        configuration: EmbeddedPaymentElement.Configuration? = nil,
        linkFundingSources: Set<ParsedEnum<LinkSettings.FundingSource>> = [ParsedEnum(.card), ParsedEnum(.bankAccount)]
    ) -> EmbeddedPaymentElement {
        let element = EmbeddedPaymentElement(
            configuration: configuration ?? makeConfiguration(),
            loadResult: makeLoadResult(linkFundingSources: linkFundingSources),
            analyticsHelper: ._testValue(integrationShape: .embedded, analyticsClient: analyticsClient)
        )
        element.view.autosizeHeight(width: 320)
        return element
    }

    /// A Link customer who's already verified, e.g. in the Link wallet.
    private func makeVerifiedLinkAccount() -> PaymentSheetLinkAccount {
        let linkAccount = PaymentSheetLinkAccount(
            email: "jane.diaz@example.com",
            session: makeVerifiedSession(),
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )
        LinkAccountContext.shared.account = linkAccount
        return linkAccount
    }

    private func makeVerifiedSession() -> ConsumerSession {
        ConsumerSession.make(
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
    }

    private func makeLoadResult(
        linkFundingSources: Set<ParsedEnum<LinkSettings.FundingSource>> = [ParsedEnum(.card), ParsedEnum(.bankAccount)]
    ) -> PaymentSheetLoader.LoadResult {
        PaymentSheetLoader.LoadResult(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: ._testValue(
                paymentMethodTypes: ["card", "link"],
                linkFundingSources: linkFundingSources
            ),
            savedPaymentMethods: [],
            paymentMethodTypes: [.stripe(.card), .instantDebits],
            paymentMethodMessagingPromotionsHelper: ._testValue(),
            paymentMethodOrientation: .vertical,
            customerProvider: CustomerProvider(customer: nil)
        )
    }

    private func makeConfiguration() -> EmbeddedPaymentElement.Configuration {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.merchantDisplayName = "Example Merchant"
        configuration.defaultBillingDetails.email = "test@example.com"
        return configuration
    }
}

@MainActor
private final class EmbeddedBankRowDelegateSpy: EmbeddedPaymentElementDelegate {
    var paymentOptionUpdates = 0

    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {}
    func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        paymentOptionUpdates += 1
    }
}
