//
//  WalletViewControllerTests.swift
//  StripePaymentSheetTests
//
//

@_spi(InternalOnlyAPI) import StripeCore
import XCTest

@testable @_spi(InternalOnlyAPI) import StripePaymentSheet

final class WalletViewControllerTests: XCTestCase {
    @MainActor
    func testDefaultCardActionsIncludeUpdateAndRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.card, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Update card",
            "Remove card",
        ])
        XCTAssertEqual(actions.map(\.style), [.default, .destructive])
    }

    @MainActor
    func testNonDefaultCardActionsIncludeSetDefaultUpdateAndRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.cardWithFailingChecks, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Set as default",
            "Update card",
            "Remove card",
        ])
        XCTAssertEqual(actions.map(\.style), [.default, .default, .destructive])
    }

    @MainActor
    func testNonDefaultBankAccountActionsIncludeSetDefaultAndRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.bankAccount, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Set as default",
            "Remove linked account",
        ])
        XCTAssertEqual(actions.map(\.style), [.default, .destructive])
    }

    @MainActor
    func testDefaultBankAccountActionsOnlyIncludeRemove() throws {
        var paymentMethods = LinkStubs.paymentMethods()
        paymentMethods[LinkStubs.PaymentMethodIndices.bankAccount].isDefault = true
        let sut = makeSUT(paymentMethods: paymentMethods)

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.bankAccount, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Remove linked account",
        ])
        XCTAssertEqual(actions.map(\.style), [.destructive])
    }

    @MainActor
    func testGenericPaymentMethodActionsOnlyIncludeRemove() throws {
        let sut = makeSUT()

        let actions = sut.actions(for: LinkStubs.PaymentMethodIndices.genericWithDisplay, includeCancelAction: false)

        XCTAssertEqual(actions.map(\.title), [
            "Remove payment method"
        ])
        XCTAssertEqual(actions.map(\.style), [.destructive])
    }

    @MainActor
    func test_recordBankAccountConsentIfNeeded_firesForBankAccountWithConsentText() async {
        let consentText = "Rocket Deliveries can access account and ownership details, balances, and transactions."
        let spy = RecordConsentSpyLinkAccount()
        let sut = makeSUT(linkAccount: spy, linkPaymentMethodBankAccountDataConsent: consentText)

        let bankAccount = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
        await sut.recordBankAccountConsentIfNeeded(for: bankAccount)

        XCTAssertEqual(spy.recordedConsentText, consentText)
    }

    @MainActor
    func test_recordBankAccountConsentIfNeeded_doesNotFireForCard() async {
        let consentText = "Rocket Deliveries can access account and ownership details, balances, and transactions."
        let spy = RecordConsentSpyLinkAccount()
        let sut = makeSUT(linkAccount: spy, linkPaymentMethodBankAccountDataConsent: consentText)

        let card = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
        await sut.recordBankAccountConsentIfNeeded(for: card)

        XCTAssertNil(spy.recordedConsentText)
    }

    @MainActor
    func test_recordBankAccountConsentIfNeeded_doesNotFireWhenConsentTextMissing() async {
        let spy = RecordConsentSpyLinkAccount()
        let sut = makeSUT(linkAccount: spy, linkPaymentMethodBankAccountDataConsent: nil)

        let bankAccount = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
        await sut.recordBankAccountConsentIfNeeded(for: bankAccount)

        XCTAssertNil(spy.recordedConsentText)
    }

    @MainActor
    func testAddBankAccount_whenFailed_showsError() {
        // Given a wallet that can only add bank accounts
        let (sut, coordinator) = makeAddBankSUT()

        // When adding a bank account fails
        let error = URLError(.notConnectedToInternet)
        sut.tapAddPaymentMethod()
        coordinator.completeFinancialConnections(with: .failed(error: error))

        // Then the error is shown
        XCTAssertEqual(sut.visibleErrorMessage, error.nonGenericDescription)
    }

    @MainActor
    func testAddBankAccount_whenRetried_clearsPreviousError() {
        // Given a failed attempt to add a bank account
        let (sut, coordinator) = makeAddBankSUT()
        sut.tapAddPaymentMethod()
        coordinator.completeFinancialConnections(with: .failed(error: URLError(.notConnectedToInternet)))

        // When the customer tries again
        sut.tapAddPaymentMethod()

        // Then the previous error is cleared
        XCTAssertNil(sut.visibleErrorMessage)
    }
}

private final class RecordConsentSpyLinkAccount: PaymentSheetLinkAccount {
    private(set) var recordedConsentText: String?

    init() {
        super.init(
            email: "user@example.com",
            session: LinkStubs.consumerSession(),
            publishableKey: nil,
            displayablePaymentDetails: nil,
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )
    }

    override func recordConnectionsConsentAcquired(localizedConsentText: String) async throws -> EmptyResponse {
        recordedConsentText = localizedConsentText
        return try JSONDecoder().decode(EmptyResponse.self, from: Data("{}".utf8))
    }
}

private extension WalletViewControllerTests {
    @MainActor
    func makeSUT(
        paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
        linkAccount: PaymentSheetLinkAccount = LinkStubs.account(),
        linkFundingSources: [String] = ["CARD"],
        linkPaymentMethodBankAccountDataConsent: String? = nil
    ) -> PayWithLinkViewController.WalletViewController {
        let (intent, elementsSession) = try! PayWithLinkTestHelpers.makePaymentIntentAndElementsSession(
            linkFundingSources: linkFundingSources,
            linkPaymentMethodBankAccountDataConsent: linkPaymentMethodBankAccountDataConsent
        )
        let configuration = PaymentSheet.Configuration()

        return PayWithLinkViewController.WalletViewController(
            linkAccount: linkAccount,
            context: .init(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                linkBrand: configuration.resolvedLinkBrand(elementsSession: elementsSession, linkAccount: nil),
                shouldOfferApplePay: false,
                shouldFinishOnClose: false,
                initiallySelectedPaymentDetailsID: nil,
                callToAction: nil,
                analyticsHelper: ._testValue()
            ),
            paymentMethods: paymentMethods
        )
    }

    @MainActor
    func makeAddBankSUT() -> (PayWithLinkViewController.WalletViewController, FinancialConnectionsCoordinatorSpy) {
        let bankAccount = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.bankAccount]
        let linkAccount = LinkStubs.account(
            session: LinkStubs.consumerSession(supportedPaymentDetailsTypes: [ParsedEnum(.bankAccount)])
        )
        let sut = makeSUT(paymentMethods: [bankAccount], linkAccount: linkAccount, linkFundingSources: ["BANK_ACCOUNT"])
        // `coordinator` is weak, so the caller must retain the spy.
        let coordinator = FinancialConnectionsCoordinatorSpy()
        sut.coordinator = coordinator
        sut.loadViewIfNeeded()
        return (sut, coordinator)
    }
}

@MainActor
private final class FinancialConnectionsCoordinatorSpy: PayWithLinkCoordinating {
    private var financialConnectionsCompletion: ((PaymentSheetResult) -> Void)?

    func completeFinancialConnections(with result: PaymentSheetResult) {
        financialConnectionsCompletion?(result)
    }

    func startFinancialConnections(completion: @escaping (PaymentSheetResult) -> Void) {
        financialConnectionsCompletion = completion
    }

    func pushContentViewController(_ contentViewController: PayWithLinkViewController.BaseViewController) {}
    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails,
        confirmationExtras: LinkConfirmationExtras?,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {}
    func confirmWithApplePay() {}
    func startInstantDebits(completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void) {}
    func cancel(shouldReturnToPaymentSheet: Bool) {}
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount) {}
    func finish(withResult result: PaymentSheetResult, deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?) {}
    func handlePaymentDetailsSelected(_ paymentDetails: ConsumerPaymentDetails, confirmationExtras: LinkConfirmationExtras) {}
    func logout(cancel: Bool) {}
    func bailToWebFlow() {}
    func cancel3DS2ChallengeFlow() {}
}

private extension PayWithLinkViewController.WalletViewController {
    func tapAddPaymentMethod() {
        guard let picker = view.descendants(ofType: LinkPaymentMethodPicker.self).first else {
            XCTFail("Payment method picker not found")
            return
        }
        paymentDetailsPickerDidTapOnAddPayment(picker, sourceRect: .zero)
    }

    var visibleErrorMessage: String? {
        view.descendants(ofType: LinkHintMessageView.self).first { !$0.isHidden }?.text
    }
}

private extension UIView {
    func descendants<T: UIView>(ofType type: T.Type) -> [T] {
        subviews.flatMap { subview in
            ((subview as? T).map { [$0] } ?? []) + subview.descendants(ofType: type)
        }
    }
}
