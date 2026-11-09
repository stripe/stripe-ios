//
//  LinkWalletButtonTests.swift
//  StripePaymentSheetTests
//

import Combine
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet
import UIKit
import XCTest

@MainActor
final class LinkWalletButtonTests: XCTestCase {
    private let email = "jane.diaz@example.com"

    // MARK: - Display state

    func testShowsLoggedOutStateWithoutAccount() {
        // Given a controller without a Link account
        let controller = MockLinkWalletButtonController()

        // When the button is created
        let button = makeButton(controller: controller)

        // Then it doesn't display any account details
        XCTAssertNil(button.displayedLinkAccount)
        XCTAssertNil(button.displayedPaymentMethodPreview)
    }

    func testShowsEmailForAccountWithoutPaymentMethod() {
        // Given a registered account without a default payment method
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email)

        // When the button is created
        let button = makeButton(controller: controller)

        // Then it displays the account without a payment method
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
        XCTAssertNil(button.displayedPaymentMethodPreview)
    }

    func testShowsDefaultPaymentMethod() {
        // Given an account with a default card
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email, paymentMethodType: .card)

        // When the button is created
        let button = makeButton(controller: controller)

        // Then it displays the default card
        XCTAssertEqual(button.displayedPaymentMethodPreview?.last4, "4242")
    }

    func testSelectedPaymentMethodTakesPriorityOverDefault() {
        // Given an account with a default card
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email, paymentMethodType: .card)
        let button = makeButton(controller: controller)

        // When the customer selects a different card in this session
        controller.selectedPaymentDetails = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
        waitForMainQueue()

        // Then the selected card is displayed
        XCTAssertEqual(button.displayedPaymentMethodPreview?.last4, "1234")
    }

    func testFallsBackToDefaultPaymentMethodWhenSelectedOneCantBeDisplayed() {
        // Given an account with a default card, and a selected payment method without a preview
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email, paymentMethodType: .card)
        controller.selectedPaymentDetails = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.genericWithDisplay]

        // When the button is created
        let button = makeButton(controller: controller)

        // Then the default card is displayed
        XCTAssertEqual(button.displayedPaymentMethodPreview?.last4, "4242")
    }

    func testShowsEmailWhenPaymentMethodPreviewIsDisabled() {
        // Given an account with a default card
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email, paymentMethodType: .card)
        controller.selectedPaymentDetails = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
        let button = makeButton(controller: controller)
        XCTAssertNotNil(button.displayedPaymentMethodPreview)

        // When the payment method preview is disabled
        button.showsPaymentMethodPreview = false

        // Then the button shows the email instead
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
        XCTAssertNil(button.displayedPaymentMethodPreview)

        // When it's enabled again
        button.showsPaymentMethodPreview = true

        // Then the payment method is shown again
        XCTAssertEqual(button.displayedPaymentMethodPreview?.last4, "1234")
    }

    func testHidesAccountDetailsWhenEmailDoesNotMatch() {
        // Given an account for a different customer
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: "someone.else@example.com", paymentMethodType: .card)

        // When the button is created
        let button = makeButton(controller: controller)

        // Then it doesn't display the other customer's details
        XCTAssertNil(button.displayedLinkAccount)
        XCTAssertNil(button.displayedPaymentMethodPreview)
    }

    func testEmailMatchingIsCaseInsensitive() {
        // Given an account whose email differs only by case
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email)

        // When the button is created
        let button = makeButton(controller: controller, email: email.uppercased())

        // Then it displays the account
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
    }

    func testUpdatesWhenControllerStateChanges() {
        // Given a button without an account
        let controller = MockLinkWalletButtonController()
        let button = makeButton(controller: controller)
        XCTAssertNil(button.displayedLinkAccount)

        // When the controller finds the customer's account
        controller.linkAccount = Stubs.linkAccount(email: email, paymentMethodType: .card)
        waitForMainQueue()

        // Then the button displays it
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
        XCTAssertEqual(button.displayedPaymentMethodPreview?.last4, "4242")

        // When the customer logs out
        controller.linkAccount = nil
        waitForMainQueue()

        // Then the button returns to the logged out state
        XCTAssertNil(button.displayedLinkAccount)
        XCTAssertNil(button.displayedPaymentMethodPreview)
    }

    func testUpdatesWhenEmailChanges() {
        // Given a button showing the customer's account
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email)
        let button = makeButton(controller: controller)
        XCTAssertNotNil(button.displayedLinkAccount)

        // When the merchant changes the email
        button.email = "someone.else@example.com"

        // Then the previous customer's details are hidden
        XCTAssertNil(button.displayedLinkAccount)
    }

    // MARK: - Lookup

    func testLooksUpCustomerOnInit() {
        // Given a controller without an account
        let controller = MockLinkWalletButtonController()

        // When the button is created
        _ = makeButton(controller: controller)

        // Then it looks up the customer
        XCTAssertEqual(controller.lookupEmails, [email])
    }

    func testSkipsLookupWhenAccountAlreadyMatchesEmail() {
        // Given a controller that already has the customer's account
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email)

        // When the button is created
        _ = makeButton(controller: controller)

        // Then it doesn't look up the customer again
        XCTAssertEqual(controller.lookupEmails, [])
    }

    func testSkipsLookupForEmptyEmail() {
        // When the button is created without an email
        let controller = MockLinkWalletButtonController()
        _ = makeButton(controller: controller, email: "")

        // Then it doesn't look up a customer
        XCTAssertEqual(controller.lookupEmails, [])
    }

    func testWithoutEmailShowsCustomerWhoSignedInWithNativeLink() {
        // Given a button without an email
        let controller = MockLinkWalletButtonController()
        let button = LinkWalletButton(controller: controller, email: nil, phoneNumber: nil)
        button.presentingViewController = UIViewController()

        // When the customer signs in with native Link and selects a payment method
        button.didTap()
        controller.linkAccount = verifiedLinkAccount(email: email)
        controller.completePresent(at: 0, with: .success(.completed(._testCard())))

        // Then the button shows their account
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
    }

    func testWithoutEmailShowsCustomerWhoSignedInButCanceled() {
        // Given a button without an email
        let controller = MockLinkWalletButtonController()
        let button = LinkWalletButton(controller: controller, email: nil, phoneNumber: nil)
        button.presentingViewController = UIViewController()

        // When the customer signs in with native Link, then closes it without selecting a payment method
        button.didTap()
        controller.linkAccount = verifiedLinkAccount(email: email)
        controller.completePresent(at: 0, with: .success(.canceled))

        // Then the button still shows their account
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
    }

    func testWithoutEmailLooksUpCustomerFromWebPopupPaymentMethod() {
        // Given a button without an email, and no native Link session
        let controller = MockLinkWalletButtonController()
        let button = LinkWalletButton(controller: controller, email: nil, phoneNumber: nil)
        button.presentingViewController = UIViewController()

        // When the Link web popup returns a payment method with the customer's email
        button.didTap()
        controller.completePresent(at: 0, with: .success(.completed(paymentMethod(withBillingEmail: email))))

        // Then the button looks up the customer
        XCTAssertEqual(controller.lookupEmails, [email])

        // When the lookup finds their account
        controller.linkAccount = Stubs.linkAccount(email: email)
        controller.completeLookup(at: 0, with: .success(true))
        waitForMainQueue()

        // Then the button shows it
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
    }

    func testWithoutEmailDoesNotShowUnverifiedAccountAfterCanceling() {
        // Given a button without an email, and an unverified Link account on the device
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email)
        let button = LinkWalletButton(controller: controller, email: nil, phoneNumber: nil)
        button.presentingViewController = UIViewController()

        // When the customer closes Link without signing in
        button.didTap()
        controller.completePresent(at: 0, with: .success(.canceled))

        // Then the button doesn't show the account
        XCTAssertNil(button.displayedLinkAccount)
    }

    func testMerchantEmailReplacesCustomerWhoSignedIn() {
        // Given a button showing a customer who signed in through it
        let controller = MockLinkWalletButtonController()
        let button = LinkWalletButton(controller: controller, email: nil, phoneNumber: nil)
        button.presentingViewController = UIViewController()
        button.didTap()
        controller.linkAccount = verifiedLinkAccount(email: email)
        controller.completePresent(at: 0, with: .success(.canceled))
        XCTAssertEqual(button.displayedLinkAccount?.email, email)

        // When the merchant provides a different email
        let merchantEmail = "someone.else@example.com"
        button.email = merchantEmail

        // Then the button stops showing the signed-in customer, and looks up the merchant's customer
        XCTAssertNil(button.displayedLinkAccount)
        XCTAssertEqual(controller.lookupEmails, [merchantEmail])
    }

    func testShowsBankAccountSelectedInWebPopupInsteadOfDefaultCard() {
        // Given an account whose default payment method is a card
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email, paymentMethodType: .card)
        let button = makeButton(controller: controller)

        // When the customer selects a bank account in the Link web popup
        controller.selectedWebPaymentMethod = Self.bankAccountPaymentMethod()
        waitForMainQueue()

        // Then the button shows the bank account, not the default card
        XCTAssertEqual(button.displayedPaymentMethodPreview?.last4, "6789")
        XCTAssertEqual(button.displayedPaymentMethodPreview?.accessibilityName, "STRIPE TEST BANK")
    }

    func testDoesNotShowDefaultPaymentMethodForLinkCardBrandTokenFromWebPopup() {
        // Given an account whose default payment method is a card
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email, paymentMethodType: .card)
        let button = makeButton(controller: controller)

        // When the Link web popup returns a card-brand token, which doesn't describe the selected payment method
        controller.selectedWebPaymentMethod = Self.linkCardBrandTokenPaymentMethod()
        waitForMainQueue()

        // Then the button shows the customer's email, not the default card they may not have selected
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
        XCTAssertNil(button.displayedPaymentMethodPreview)
    }

    func testWithoutEmailSkipsLookupAndHidesAccountDetails() {
        // Given a signed-in Link account
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email)

        // When the button is created without an email
        let button = LinkWalletButton(controller: controller, email: nil, phoneNumber: nil)

        // Then it doesn't look up a customer
        XCTAssertEqual(controller.lookupEmails, [])
        // ...and doesn't display any account details, since the merchant didn't identify the customer
        XCTAssertNil(button.displayedLinkAccount)
        XCTAssertNil(button.displayedPaymentMethodPreview)
    }

    func testTapWithoutEmailPresentsLink() {
        // Given a button without an email
        let controller = MockLinkWalletButtonController()
        let button = LinkWalletButton(controller: controller, email: nil, phoneNumber: nil)
        button.presentingViewController = UIViewController()

        // When the button is tapped
        button.didTap()

        // Then Link is presented without an email, so the customer can sign in or sign up
        XCTAssertEqual(controller.presentCalls.count, 1)
        XCTAssertNil(controller.presentCalls.first?.email)
    }

    func testSettingEmailLooksUpCustomer() {
        // Given a button created without an email
        let controller = MockLinkWalletButtonController()
        let button = LinkWalletButton(controller: controller, email: nil, phoneNumber: nil)

        // When the merchant provides an email
        button.email = email

        // Then the customer is looked up
        XCTAssertEqual(controller.lookupEmails, [email])
    }

    func testLooksUpNewEmailAfterInFlightLookupCompletes() {
        // Given a lookup in flight
        let controller = MockLinkWalletButtonController()
        let button = makeButton(controller: controller)
        XCTAssertEqual(controller.lookupEmails, [email])

        // When the email changes before the lookup completes
        button.email = "someone.else@example.com"

        // Then a second lookup isn't started yet
        XCTAssertEqual(controller.lookupEmails, [email])

        // When the first lookup completes
        controller.completeLookup(at: 0)

        // Then the new email is looked up
        XCTAssertEqual(controller.lookupEmails, [email, "someone.else@example.com"])
    }

    func testDoesNotRepeatLookupAfterItCompletesForSameEmail() {
        // Given a lookup in flight
        let controller = MockLinkWalletButtonController()
        _ = makeButton(controller: controller)

        // When the lookup fails
        controller.completeLookup(at: 0, with: .failure(NSError(domain: "test", code: 0)))

        // Then it isn't retried
        XCTAssertEqual(controller.lookupEmails, [email])
    }

    // MARK: - Presentation

    func testTapPresentsLinkAndReportsResult() {
        // Given a button with a delegate and presenting view controller
        let controller = MockLinkWalletButtonController()
        let button = makeButton(controller: controller)
        let delegate = MockLinkWalletButtonDelegate()
        button.delegate = delegate
        let presentingViewController = UIViewController()
        button.presentingViewController = presentingViewController

        // When the button is tapped
        button.didTap()

        // Then Link is presented with the customer's details
        XCTAssertEqual(controller.presentCalls.count, 1)
        XCTAssertEqual(controller.presentCalls.first?.email, email)
        XCTAssertEqual(controller.presentCalls.first?.phoneNumber, "+15555555555")
        XCTAssertTrue(controller.presentCalls.first?.presentingViewController === presentingViewController)
        XCTAssertEqual(delegate.willPresentCount, 1)

        // When the Link flow is canceled
        controller.completePresent(at: 0, with: .success(.canceled))

        // Then the delegate receives the result
        XCTAssertEqual(delegate.results.count, 1)
        guard case .success(.canceled) = delegate.results.first else {
            return XCTFail("Expected a canceled result, got \(String(describing: delegate.results.first))")
        }
    }

    func testShowsLoadingIndicatorWhileLinkFlowIsInProgress() {
        // Given a button with a signed-in customer
        let controller = MockLinkWalletButtonController()
        controller.linkAccount = Stubs.linkAccount(email: email)
        let button = makeButton(controller: controller)
        button.presentingViewController = UIViewController()
        XCTAssertFalse(button.isDisplayingLoadingIndicator)

        // When the button is tapped
        button.didTap()

        // Then it shows a loading indicator while the Link flow is in progress
        XCTAssertTrue(button.isDisplayingLoadingIndicator)

        // When the Link flow finishes
        controller.completePresent(at: 0, with: .success(.canceled))

        // Then it shows the customer's account again
        XCTAssertFalse(button.isDisplayingLoadingIndicator)
        XCTAssertEqual(button.displayedLinkAccount?.email, email)
    }

    func testTapWhilePresentingDoesNotPresentAgain() {
        // Given Link is being presented
        let controller = MockLinkWalletButtonController()
        let button = makeButton(controller: controller)
        button.presentingViewController = UIViewController()
        button.didTap()

        // When the button is tapped again
        button.didTap()

        // Then Link isn't presented a second time
        XCTAssertEqual(controller.presentCalls.count, 1)

        // When the Link flow completes and the button is tapped again
        controller.completePresent(at: 0, with: .success(.canceled))
        button.didTap()

        // Then Link is presented again
        XCTAssertEqual(controller.presentCalls.count, 2)
    }

    // MARK: - Helpers

    private func makeButton(
        controller: MockLinkWalletButtonController,
        email: String? = nil
    ) -> LinkWalletButton {
        LinkWalletButton(controller: controller, email: email ?? self.email, phoneNumber: "+15555555555")
    }

    private func verifiedLinkAccount(email: String) -> PaymentSheetLinkAccount {
        PaymentSheetLinkAccount(
            email: email,
            session: .make(
                clientSecret: "cs_123",
                emailAddress: email,
                redactedFormattedPhoneNumber: "(•••) ••• ••70",
                unredactedPhoneNumber: "+17070707070",
                phoneNumberCountry: "US",
                verificationSessions: [.init(type: .sms, state: .verified)],
                supportedPaymentDetailsTypes: [ParsedEnum(.card)],
                mobileFallbackWebviewParams: nil,
                currentAuthenticationLevel: .twoFactorAuth,
                minimumAuthenticationLevel: .oneFactorAuth
            ),
            publishableKey: "pk_test_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )
    }

    /// A card-brand token as returned by the Link web popup, e.g. for a bank account selected in Link.
    static func linkCardBrandTokenPaymentMethod() -> STPPaymentMethod {
        STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_789",
            "created": 1_700_000_000,
            "type": "card",
            "billing_details": ["email": NSNull()],
            "card": [
                "brand": "link",
                "display_brand": "other",
                "funding": "credit",
                "last4": "0000",
                "exp_month": 12,
                "exp_year": 2040,
                "networks": ["available": ["link"]],
                "wallet": ["type": "link", "link": [String: Any]()],
            ],
        ])!
    }

    static func bankAccountPaymentMethod() -> STPPaymentMethod {
        STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_456",
            "created": 1_700_000_000,
            "type": "us_bank_account",
            "us_bank_account": [
                "account_holder_type": "individual",
                "account_type": "checking",
                "bank_name": "STRIPE TEST BANK",
                "fingerprint": "fp_123",
                "last4": "6789",
                "routing_number": "110000000",
            ],
        ])!
    }

    private func paymentMethod(withBillingEmail email: String) -> STPPaymentMethod {
        STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123",
            "created": 1_700_000_000,
            "type": "card",
            "billing_details": ["email": email],
            "card": ["brand": "visa", "last4": "4242", "exp_month": 12, "exp_year": 2040],
        ])!
    }

    /// Waits for state changes delivered on the main queue to be applied.
    private func waitForMainQueue() {
        let expectation = expectation(description: "main queue")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}

@MainActor
private final class MockLinkWalletButtonController: LinkWalletButtonControlling {
    struct PresentCall {
        let email: String?
        let phoneNumber: String?
        let presentingViewController: UIViewController
        let completion: (Result<LinkController.PaymentMethodResult, Error>) -> Void
    }

    var linkAccount: PaymentSheetLinkAccount? {
        didSet { stateSubject.send() }
    }
    var selectedPaymentDetails: ConsumerPaymentDetails? {
        didSet { stateSubject.send() }
    }
    var selectedWebPaymentMethod: STPPaymentMethod? {
        didSet { stateSubject.send() }
    }
    var resolvedLinkBrand: LinkBrand = .link
    var stateDidChange: AnyPublisher<Void, Never> { stateSubject.eraseToAnyPublisher() }

    private(set) var lookupEmails: [String] = []
    private var lookupCompletions: [(Result<Bool, Error>) -> Void] = []
    private(set) var presentCalls: [PresentCall] = []
    private let stateSubject = PassthroughSubject<Void, Never>()

    func lookupConsumer(with email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        lookupEmails.append(email)
        lookupCompletions.append(completion)
    }

    func present(
        email: String?,
        phoneNumber: String?,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<LinkController.PaymentMethodResult, Error>) -> Void
    ) {
        presentCalls.append(.init(
            email: email,
            phoneNumber: phoneNumber,
            presentingViewController: presentingViewController,
            completion: completion
        ))
    }

    func completeLookup(at index: Int, with result: Result<Bool, Error> = .success(false)) {
        lookupCompletions[index](result)
    }

    func completePresent(at index: Int, with result: Result<LinkController.PaymentMethodResult, Error>) {
        presentCalls[index].completion(result)
    }
}

@MainActor
private final class MockLinkWalletButtonDelegate: LinkWalletButtonDelegate {
    private(set) var willPresentCount = 0
    private(set) var results: [Result<LinkController.PaymentMethodResult, Error>] = []

    func linkWalletButtonWillPresent(_ button: LinkWalletButton) {
        willPresentCount += 1
    }

    func linkWalletButton(
        _ button: LinkWalletButton,
        didCompleteWith result: Result<LinkController.PaymentMethodResult, Error>
    ) {
        results.append(result)
    }
}
