//
//  LinkWalletButtonTests.swift
//  StripePaymentSheetTests
//

import Combine
@_spi(STP) @testable import StripePaymentSheet
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
        let email: String
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
        email: String,
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
