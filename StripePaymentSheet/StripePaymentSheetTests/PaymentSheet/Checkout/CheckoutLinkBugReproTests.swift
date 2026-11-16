//
//  CheckoutLinkBugReproTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 11/16/26.
//

import OHHTTPStubs
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable @_spi(InternalOnlyAPI) import StripeUICore
import UIKit
import XCTest

@MainActor
final class CheckoutLinkBugReproTests: STPNetworkStubbingTestCase {

    // MARK: - Link default opt-in kill switch

    func testLiveCheckoutCardFormHonorsMerchantLinkDefaultOptInKillSwitch() async throws {
        // Given a live guest Checkout Session with card and Link for the US playground merchant
        HTTPStubs.removeAllStubs()
        // Start without a Link account left over from another test, so inline signup is shown.
        LinkAccountContext.shared.account = nil
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(types: ["card", "link"])
        let apiClient = STPAPIClient(publishableKey: checkoutSession.publishableKey)

        // ...and, as a control, the same merchant's Embedded Payment Element loaded from v1/elements/sessions.
        // The SDK's iOS user agent makes the backend apply the merchant's mobile default opt-in kill switch there.
        var embeddedConfiguration = EmbeddedPaymentElement.Configuration()
        embeddedConfiguration.apiClient = apiClient
        let intentConfiguration = EmbeddedPaymentElement.IntentConfiguration(
            mode: .payment(amount: 2000, currency: "USD"),
            paymentMethodTypes: ["card", "link"]
        ) { _, _ in
            XCTFail("This test does not confirm")
            return ""
        }
        let controlEmbedded = try await EmbeddedPaymentElement.create(
            intentConfiguration: intentConfiguration,
            configuration: embeddedConfiguration
        )
        XCTAssertFalse(
            controlEmbedded.elementsSession.allowsLinkDefaultOptIn,
            "Precondition: v1/elements/sessions must report the merchant's default opt-in kill switch as on"
        )
        let (controlFormViewController, controlSignup) = try linkDefaultOptInOpenCardForm(in: controlEmbedded)
        XCTAssertEqual(controlSignup.viewModel.mode, .checkbox)
        XCTAssertFalse(controlSignup.viewModel.saveCheckboxChecked)
        XCTAssertNotNil(controlFormViewController.selectedPaymentOption, "Control: card details alone complete the form")

        // When the Checkout Payment Element for the same merchant opens its card form and card details are entered
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = apiClient
        configuration.paymentElement = .init()
        let checkout = try await CheckoutElementsController(configuration: configuration)
        // The guest has no saved-card checkbox, and the session is in the US, so the Link checkbox mode is chosen
        // purely from the default opt-in setting.
        XCTAssertNil(checkout.session.customerId)
        XCTAssertEqual(checkout.session.elementsSession.countryCode, "US")
        let (formViewController, signup) = try linkDefaultOptInOpenCardForm(
            in: checkout.getPaymentElement().embeddedPaymentElement
        )

        // Then Checkout must honor the same kill switch as the control: the Link box starts unchecked,
        // and the card details alone produce a payment option.
        let checkoutLinkSettingsKeys = checkout.session.elementsSession.linkSettings?.allResponseFields.keys
            .compactMap { $0 as? String }
            .sorted() ?? []
        XCTAssertFalse(
            checkout.session.elementsSession.allowsLinkDefaultOptIn,
            "Checkout init link_settings keys: \(checkoutLinkSettingsKeys)"
        )
        XCTAssertEqual(signup.viewModel.mode, .checkbox)
        XCTAssertFalse(signup.viewModel.saveCheckboxChecked, "Link signup must not be pre-checked")
        XCTAssertNotNil(formViewController.selectedPaymentOption, "Card details alone should complete the form")
    }

    /// Taps the card row, fills in a valid card, and returns the presented form with its Link inline signup element.
    private func linkDefaultOptInOpenCardForm(
        in embedded: EmbeddedPaymentElement
    ) throws -> (EmbeddedFormViewController, LinkInlineSignupElement) {
        embedded.presentingViewController = UIViewController()
        let cardRow = try XCTUnwrap(embedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        })
        embedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let formViewController = try XCTUnwrap(embedded.selectedFormViewController)
        let form = formViewController.form
        let signup = try XCTUnwrap(
            form.getAllUnwrappedSubElements().compactMap { $0 as? LinkInlineSignupElement }.first,
            "The card form should offer Link inline signup"
        )
        // Fill in the card fields shown for a US card, which are enough to pay without Link.
        try XCTUnwrap(form.getTextFieldElement("Card number")).setText("4242424242424242")
        try XCTUnwrap(form.getTextFieldElement("MM / YY")).setText("1232")
        try XCTUnwrap(form.getTextFieldElement("CVC")).setText("123")
        try XCTUnwrap(form.getTextFieldElement("ZIP")).setText("65432")
        return (formViewController, signup)
    }

    // MARK: - Bank linking in $0 Checkout Sessions

    func testLiveZeroAmountCheckoutLinkBankRowCreatesLinkAccountSession() async throws {
        // Given live Checkout Sessions for the US playground merchant, each with a fresh customer email
        // so the Link Bank row is offered and no Link account is signed in
        HTTPStubs.removeAllStubs()
        LinkAccountContext.shared.account = nil
        zeroAmountBankRestoreSharedPublishableKeyOnTeardown()

        // ...and, as a control, a $20 card + Link session, where Continue on the Bank row creates a
        // Link account session and hands it to Financial Connections
        let paidAttempt = try await zeroAmountBankLinkAttempt(
            types: ["card", "link"],
            amount: 2000,
            rowType: .instantDebits
        )
        XCTAssertFalse(paidAttempt.checkout.session.noPaymentRequired)
        zeroAmountBankAssertLinkAccountSessionCreated(paidAttempt, label: "Control: $20 card + Link session")

        // When the same flow runs in $0 sessions, which the backend reports as no_payment_required:
        // one with card + Link (LINK_PAYMENT_METHOD) and one with card only (LINK_CARD_BRAND)
        let linkPaymentMethodAttempt = try await zeroAmountBankLinkAttempt(
            types: ["card", "link"],
            amount: 0,
            rowType: .instantDebits
        )
        let linkCardBrandAttempt = try await zeroAmountBankLinkAttempt(
            types: ["card"],
            amount: 0,
            rowType: .linkCardBrand
        )
        let freeAttempts: [(ZeroAmountBankLinkAttempt, LinkMode)] = [
            (linkPaymentMethodAttempt, .linkPaymentMethod),
            (linkCardBrandAttempt, .linkCardBrand),
        ]
        for (attempt, linkMode) in freeAttempts {
            let session = attempt.checkout.session
            XCTAssertTrue(session.noPaymentRequired, "Precondition: a $0 session should be no_payment_required")
            XCTAssertEqual(session.amount, 0)
            XCTAssertEqual(session.elementsSession.linkSettings?.linkMode, linkMode)
        }

        // ...and, as a control, the backend creates a Link account session for the same $0 session when the
        // amount is left out, which is what the SDK already does for deferred SetupIntents
        let freeSession = linkPaymentMethodAttempt.checkout.session
        let linkAccountSessionWithoutAmount: LinkAccountSession = try await withCheckedThrowingContinuation { continuation in
            STPAPIClient.shared.createLinkAccountSessionForDeferredIntent(
                sessionId: freeSession.elementsSession.sessionID,
                amount: nil,
                currency: freeSession.activePresentmentCurrency,
                onBehalfOf: nil,
                linkMode: freeSession.elementsSession.linkSettings?.linkMode,
                additionalParameters: [
                    "product": "instant_debits",
                    "hosted_surface": "payment_element",
                ]
            ) { linkAccountSession, error in
                if let linkAccountSession {
                    continuation.resume(returning: linkAccountSession)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "CheckoutLinkBugReproTests", code: 0))
                }
            }
        }
        XCTAssertTrue(linkAccountSessionWithoutAmount.stripeID.hasPrefix("fcsess_"))

        // Then the SDK creates a Link account session and opens Financial Connections in both $0 sessions,
        // just as it does at $20
        zeroAmountBankAssertLinkAccountSessionCreated(linkPaymentMethodAttempt, label: "$0 card + Link session")
        zeroAmountBankAssertLinkAccountSessionCreated(linkCardBrandAttempt, label: "$0 card-only session")
    }

    func testLiveZeroAmountCheckoutUSBankAccountRowLinksBank() async throws {
        // Given live Checkout Sessions with card and US bank account for the US playground merchant.
        // Checkout only offers the US bank account row when the session sets a supported verification method.
        HTTPStubs.removeAllStubs()
        LinkAccountContext.shared.account = nil
        zeroAmountBankRestoreSharedPublishableKeyOnTeardown()
        let usBankAccountOptions: [String: Any] = ["us_bank_account": ["verification_method": "automatic"]]
        let linkFailureText = PaymentSheetError.accountLinkFailure.nonGenericDescription

        // ...and, as a control, a $20 session, where Continue on the US bank account row links a bank.
        // Unit tests use the SDK's built-in stand-in for the Financial Connections sheet, which returns
        // a test bank as soon as it is opened.
        let paidAttempt = try await zeroAmountBankLinkAttempt(
            types: ["card", "us_bank_account"],
            amount: 2000,
            paymentMethodOptions: usBankAccountOptions,
            rowType: .stripe(.USBankAccount)
        )
        XCTAssertFalse(paidAttempt.checkout.session.noPaymentRequired)
        XCTAssertFalse(zeroAmountBankLabelTexts(in: paidAttempt.formViewController.view).contains(linkFailureText))
        XCTAssertNotNil(
            paidAttempt.formViewController.selectedPaymentOption,
            "Control: the $20 session should link a bank"
        )

        // When the same flow runs in a $0 session, which the backend reports as no_payment_required
        let freeAttempt = try await zeroAmountBankLinkAttempt(
            types: ["card", "us_bank_account"],
            amount: 0,
            paymentMethodOptions: usBankAccountOptions,
            rowType: .stripe(.USBankAccount)
        )
        XCTAssertTrue(freeAttempt.checkout.session.noPaymentRequired, "Precondition: a $0 session should be no_payment_required")
        XCTAssertEqual(freeAttempt.checkout.session.amount, 0)

        // Then the bank is linked just as it is at $20, and no linking error is shown
        let shownLabels = zeroAmountBankLabelTexts(in: freeAttempt.formViewController.view)
        XCTAssertFalse(
            shownLabels.contains(linkFailureText),
            "The form shows \"\(linkFailureText)\" (\(zeroAmountBankErrorDescription(freeAttempt.finishedEvent)))"
        )
        XCTAssertNotNil(
            freeAttempt.formViewController.selectedPaymentOption,
            "The $0 session should link a bank"
        )
    }

    /// The result of tapping Continue on a bank row in a live Checkout Session's embedded Payment Element.
    private struct ZeroAmountBankLinkAttempt {

        let checkout: CheckoutElementsController
        let formViewController: EmbeddedFormViewController
        /// The `stripeios.bankaccountcollector.finished` analytics payload. It records whether the
        /// Link account session was created, or the API error that stopped it.
        let finishedEvent: [String: Any]
    }

    /// Creates a live Checkout Session, opens the given bank row in its embedded Payment Element, fills in
    /// any empty customer details, and taps Continue. Returns once the bank account collector reports a result.
    private func zeroAmountBankLinkAttempt(
        types: [String],
        amount: Int,
        paymentMethodOptions: [String: Any]? = nil,
        rowType: PaymentSheet.PaymentMethodType
    ) async throws -> ZeroAmountBankLinkAttempt {
        // A fresh email is a new Link consumer, which keeps Link account state out of the flow.
        let email = "link_repro+\(UUID().uuidString)@example.com"
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: types,
            amount: amount,
            customerEmail: email,
            paymentMethodOptions: paymentMethodOptions
        )
        // Use the shared API client, as the Checkout Playground does. The Payment Element's bank forms
        // create their STPBankAccountCollector with `STPAPIClient.shared`, not `Configuration.apiClient`.
        STPAPIClient.shared.publishableKey = checkoutSession.publishableKey
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.paymentElement = .init()
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Open the bank row's form, as a customer tapping the row would.
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        embedded.presentingViewController = UIViewController()
        let rowTypes = embedded.embeddedPaymentMethodsView.rowButtons.map(\.type)
        let bankRow = try XCTUnwrap(
            embedded.embeddedPaymentMethodsView.rowButtons.first { $0.type == .new(paymentMethodType: rowType) },
            "Expected a \(rowType) row for \(types) at amount \(amount); rows: \(rowTypes)"
        )
        embedded.embeddedPaymentMethodsView.didTap(rowButton: bankRow)
        let formViewController = try XCTUnwrap(embedded.selectedFormViewController)

        // Fill in any details the form still needs. The US bank account form asks for a name, and the
        // email field (if shown) may already hold the session's email.
        let form = formViewController.form
        if let nameField = form.getTextFieldElement("Full name"), nameField.text.isEmpty {
            nameField.setText("Jane Doe")
        }
        if let emailField = form.getTextFieldElement("Email"), emailField.text.isEmpty {
            emailField.setText(email)
        }

        // Tap Continue, which the bank forms use to start linking a bank.
        STPAnalyticsClient.sharedClient._testLogHistory = []
        formViewController.didTapPrimaryButton()

        // Wait for the bank account collector to report how linking went.
        let deadline = Date().addingTimeInterval(30)
        var finishedEvent: [String: Any]?
        while finishedEvent == nil, Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
            finishedEvent = STPAnalyticsClient.sharedClient._testLogHistory.first {
                $0["event"] as? String == "stripeios.bankaccountcollector.finished"
            }
        }
        return ZeroAmountBankLinkAttempt(
            checkout: checkout,
            formViewController: formViewController,
            finishedEvent: try XCTUnwrap(finishedEvent, "Timed out waiting for bank linking to finish")
        )
    }

    /// Restores `STPAPIClient.shared.publishableKey` after the test, since the bank linking attempts change it.
    private func zeroAmountBankRestoreSharedPublishableKeyOnTeardown() {
        let originalPublishableKey = STPAPIClient.shared.publishableKey
        addTeardownBlock { @MainActor in
            STPAPIClient.shared.publishableKey = originalPublishableKey
        }
    }

    /// Asserts that tapping Continue created a Link account session, which is what opens Financial Connections.
    ///
    /// The Link Bank form can't be judged by its error label in unit tests: the SDK's stand-in for the
    /// Financial Connections sheet returns a US bank account result, which that form always reports as an error.
    private func zeroAmountBankAssertLinkAccountSessionCreated(
        _ attempt: ZeroAmountBankLinkAttempt,
        label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotNil(
            attempt.finishedEvent["link_account_session_id"],
            "\(label): bank linking failed before Financial Connections opened (\(zeroAmountBankErrorDescription(attempt.finishedEvent)))",
            file: file,
            line: line
        )
    }

    /// Describes the API error recorded by the bank account collector, e.g. "invalid_request_error / parameter_invalid_integer".
    private func zeroAmountBankErrorDescription(_ finishedEvent: [String: Any]) -> String {
        return "\(finishedEvent["error_type"] ?? "no error type") / \(finishedEvent["error_code"] ?? "no error code")"
    }

    /// Returns the text of every label in the given view hierarchy.
    private func zeroAmountBankLabelTexts(in view: UIView) -> [String] {
        let ownText = (view as? UILabel)?.text.map { [$0] } ?? []
        return ownText + view.subviews.flatMap { zeroAmountBankLabelTexts(in: $0) }
    }

    // MARK: - Save consent with Link inline signup in passthrough mode

    func testLivePassthroughLinkSignupKeepsSavePaymentDetailsConsent() async throws {
        // Given live card-only Checkout Sessions, each for a new Customer, that offer to save payment details.
        // Card-only sessions use Link in passthrough mode (LINK_CARD_BRAND): after Link signup, Link shares the
        // card as a PaymentMethod and Checkout confirms with that PaymentMethod's ID.
        HTTPStubs.removeAllStubs()
        LinkAccountContext.shared.account = nil
        addTeardownBlock { @MainActor in
            LinkAccountContext.shared.account = nil
        }
        let requestLog = passthroughSaveConsentRecordRequests()

        // ...and, as a control, a customer who checks "Save payment details" but leaves the Link phone number empty.
        // Checkout confirms the card details directly, sends the consent, and the card is saved to the Customer.
        let control = try await passthroughSaveConsentPayWithCard(enterLinkPhoneNumber: false, requestLog: requestLog)
        XCTAssertNotNil(control.confirmParameters["payment_method_data[type]"], "Control: the card is confirmed directly")
        XCTAssertEqual(
            control.confirmParameters["collected_information[save_payment_method]"],
            "true",
            "Control: /confirm should carry the save consent"
        )
        XCTAssertTrue(control.customerHasSavedCard, "Control: the card should be saved to the Customer")
        XCTAssertTrue(control.nextSessionHasSavedCard, "Control: the next session should offer the saved card")

        // When another customer checks "Save payment details", enters a Link phone number, and pays,
        // so Link signs them up and shares the card as a PaymentMethod
        let linkSignup = try await passthroughSaveConsentPayWithCard(enterLinkPhoneNumber: true, requestLog: requestLog)
        XCTAssertTrue(
            linkSignup.requestPaths.contains { $0.hasSuffix("/consumers/accounts/sign_up") },
            "Precondition: Link signup should run. Requests: \(linkSignup.requestPaths)"
        )
        XCTAssertTrue(
            linkSignup.requestPaths.contains { $0.hasSuffix("/consumers/payment_details/share") },
            "Precondition: Link should share the card. Requests: \(linkSignup.requestPaths)"
        )
        let sharedPaymentMethodID = try XCTUnwrap(linkSignup.confirmParameters["payment_method"])
        XCTAssertTrue(sharedPaymentMethodID.hasPrefix("pm_"), "Precondition: /confirm should use the shared PaymentMethod")

        // Then the customer's consent is still sent to /confirm, and the card is saved to their Customer
        XCTAssertEqual(
            linkSignup.confirmParameters["collected_information[save_payment_method]"],
            "true",
            "/confirm dropped the customer's save consent. Parameters: \(linkSignup.confirmParameters.keys.sorted())"
        )
        XCTAssertTrue(linkSignup.customerHasSavedCard, "The card should be saved to the Customer")
        XCTAssertTrue(linkSignup.nextSessionHasSavedCard, "The next session should offer the saved card")
    }

    /// The outcome of paying with a card in a live card-only Checkout Session that offers saving.
    private struct PassthroughSaveConsentAttempt {

        /// The form parameters sent to `/v1/checkout_client/{id}/confirm`.
        let confirmParameters: [String: String]
        /// The paths of the API requests made while confirming, in order.
        let requestPaths: [String]
        /// Whether the session's Customer has the 4242 card saved once confirmation completes.
        let customerHasSavedCard: Bool
        /// Whether a new Checkout Session for the same Customer offers the 4242 card as a saved payment method.
        let nextSessionHasSavedCard: Bool
    }

    /// Records the path and body of every API request without stubbing it, so requests still reach the live backend.
    private final class PassthroughSaveConsentRequestLog: @unchecked Sendable {

        private let lock = NSLock()
        private var requests: [(path: String, body: Data?)] = []

        func append(path: String, body: Data?) {
            lock.lock()
            defer { lock.unlock() }
            // OHHTTPStubs can ask about the same request more than once. Keep one entry per request.
            if let last = requests.last, last.path == path, last.body == body {
                return
            }
            requests.append((path, body))
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return requests.count
        }

        func requests(from index: Int) -> [(path: String, body: Data?)] {
            lock.lock()
            defer { lock.unlock() }
            return Array(requests.dropFirst(index))
        }
    }

    /// Starts recording API requests. The test block never matches, so nothing is stubbed.
    private func passthroughSaveConsentRecordRequests() -> PassthroughSaveConsentRequestLog {
        let requestLog = PassthroughSaveConsentRequestLog()
        HTTPStubs.stubRequests(passingTest: { request in
            if let url = request.url, url.host == "api.stripe.com" {
                requestLog.append(path: url.path, body: request.ohhttpStubs_httpBody)
            }
            return false
        }, withStubResponse: { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        })
        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
        return requestLog
    }

    /// Creates a new Customer and a card-only Checkout Session that offers saving, fills in the embedded card form,
    /// checks "Save payment details", optionally enters a Link phone number, and confirms.
    private func passthroughSaveConsentPayWithCard(
        enterLinkPhoneNumber: Bool,
        requestLog: PassthroughSaveConsentRequestLog
    ) async throws -> PassthroughSaveConsentAttempt {
        // A fresh email is a new Link consumer, so Link inline signup is offered for it.
        let email = "link_repro+\(UUID().uuidString)@example.com"
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(email: email)
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: ["card"],
            customerID: customerID,
            savedPaymentMethodSaveEnabled: true
        )
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSession.publishableKey)
        configuration.paymentElement = .init()
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Check the session state this flow depends on: Link passthrough mode, a Customer, and the offer to save.
        let elementsSession = checkout.session.elementsSession
        XCTAssertEqual(elementsSession.linkSettings?.linkMode, .linkCardBrand)
        XCTAssertTrue(elementsSession.linkPassthroughModeEnabled)
        XCTAssertFalse(elementsSession.linkSignupOptInFeatureEnabled)
        XCTAssertEqual(checkout.session.customerId, customerID)
        XCTAssertEqual(checkout.session.savedPaymentMethodsOfferSave?.enabled, true)
        XCTAssertEqual(checkout.session.customer?.paymentMethods.count, 0, "The new Customer starts with no saved cards")

        // Open the card form, as a customer tapping the Card row would, and fill in a US card.
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        embedded.presentingViewController = UIViewController()
        let cardRow = try XCTUnwrap(embedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        })
        embedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let formViewController = try XCTUnwrap(embedded.selectedFormViewController)
        let form = formViewController.form
        try XCTUnwrap(form.getTextFieldElement("Card number")).setText("4242424242424242")
        try XCTUnwrap(form.getTextFieldElement("MM / YY")).setText("1240")
        try XCTUnwrap(form.getTextFieldElement("CVC")).setText("123")
        try XCTUnwrap(form.getTextFieldElement("ZIP")).setText("65432")

        // Check "Save payment details", as a customer tapping the checkbox would.
        let saveCheckbox = try XCTUnwrap(
            form.getCheckboxElement(startingWith: "Save"),
            "The card form should offer to save the card"
        )
        if !saveCheckbox.isSelected {
            saveCheckbox.isSelected = true
            saveCheckbox.checkboxButton.sendActions(for: .touchUpInside)
        }

        // Because the save checkbox is shown, Link signup is offered as text fields only, without its own checkbox.
        let signup = try XCTUnwrap(
            form.getAllUnwrappedSubElements().compactMap { $0 as? LinkInlineSignupElement }.first,
            "The card form should offer Link inline signup"
        )
        XCTAssertTrue(
            [.textFieldsOnlyPhoneFirst, .textFieldsOnlyEmailFirst].contains(signup.viewModel.mode),
            "Unexpected Link signup mode \(signup.viewModel.mode)"
        )
        XCTAssertEqual(signup.viewModel.linkAccount?.sessionState, .requiresSignUp)
        if enterLinkPhoneNumber {
            // Entering a phone number opts the customer into Link signup.
            signup.viewModel.phoneNumber = PhoneNumber(number: "2015550123", countryCode: "US")
            guard case .signupAndPay = signup.action else {
                XCTFail("Expected the Link phone number to opt into signup, got \(String(describing: signup.action))")
                throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
            }
        } else {
            // With no phone number, the card is paid for without Link.
            if case .signupAndPay = signup.action {
                XCTFail("Link signup should not run without a phone number")
            }
        }

        // Tap the form's primary button, which hands the payment option to Checkout.
        formViewController.didTapPrimaryButton()
        let deadline = Date().addingTimeInterval(15)
        while checkout.session.paymentOption == nil, Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertNotNil(checkout.session.paymentOption, "The card form should produce a payment option")

        // Confirm, keeping track of the requests made along the way.
        let firstRequestIndex = requestLog.count
        let result = await checkout.confirm(from: UIViewController())
        guard case .completed(let paymentStatus) = result else {
            XCTFail("Expected confirmation to complete, got \(result)")
            throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
        }
        XCTAssertEqual(paymentStatus, .paid)
        let requests = requestLog.requests(from: firstRequestIndex)
        let confirmRequest = try XCTUnwrap(
            requests.last { $0.path.hasSuffix("/checkout_client/\(checkoutSession.id)/confirm") },
            "No /confirm request was recorded. Requests: \(requests.map(\.path))"
        )
        // Decode the form-encoded body by hand. It can contain characters URLComponents rejects in a query.
        let confirmBody = try XCTUnwrap(confirmRequest.body.flatMap { String(data: $0, encoding: .utf8) })
        var confirmParameters: [String: String] = [:]
        for pair in confirmBody.split(separator: "&") {
            let keyAndValue = pair.split(separator: "=", maxSplits: 1).map {
                $0.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String($0)
            }
            if let key = keyAndValue.first {
                confirmParameters[key] = keyAndValue.count > 1 ? keyAndValue[1] : ""
            }
        }

        // The confirmed session's Customer lists the payment methods saved to it.
        let customerHasSavedCard = checkout.session.customer?.paymentMethods.contains { $0.card?.last4 == "4242" } ?? false

        // Load the next Checkout Session for the same Customer, which is where a saved card would be offered again.
        let nextCheckoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: ["card"],
            customerID: customerID,
            savedPaymentMethodSaveEnabled: true
        )
        let nextSessionResponse = try await configuration.apiClient.initCheckoutSession(
            checkoutSessionId: nextCheckoutSession.id,
            clientSecret: nextCheckoutSession.clientSecret,
            adaptivePricingAllowed: false
        )
        let nextSessionHasSavedCard = nextSessionResponse.customer?.paymentMethods.contains { $0.card?.last4 == "4242" } ?? false
        return PassthroughSaveConsentAttempt(
            confirmParameters: confirmParameters,
            requestPaths: requests.map(\.path),
            customerHasSavedCard: customerHasSavedCard,
            nextSessionHasSavedCard: nextSessionHasSavedCard
        )
    }

    // MARK: - Adding a bank inside native Link

    func testLiveNativeLinkWalletAddBankOpensFinancialConnectionsInCheckout() async throws {
        // Given native Link. The US playground merchant reports link_mobile_use_attestation_endpoints=false to
        // unit tests, so turn on the override that the Checkout Playground's native Link mode also uses.
        HTTPStubs.removeAllStubs()
        let originalNativeLinkOverride = PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride
        let originalPublishableKey = STPAPIClient.shared.publishableKey
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
        LinkAccountContext.shared.account = nil
        addTeardownBlock { @MainActor in
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = originalNativeLinkOverride
            STPAPIClient.shared.publishableKey = originalPublishableKey
            LinkAccountContext.shared.account = nil
        }
        let requestLog = nativeLinkAddBankRecordRequests()
        let presenter = try await nativeLinkAddBankMakePresenter()

        // ...and a live card + Link Checkout Session whose email belongs to a new Link consumer
        let email = "link_repro+\(UUID().uuidString)@example.com"
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: ["card", "link"],
            customerEmail: email
        )
        // Native Link creates link account sessions with `STPAPIClient.shared`, so use the shared client
        // everywhere, as the Checkout Playground does.
        STPAPIClient.shared.publishableKey = checkoutSession.publishableKey

        // ...and, for the control, the same merchant's Embedded Payment Element with a deferred intent.
        // Load it before Checkout: it has no email, so loading it clears the shared Link account.
        let intentConfiguration = EmbeddedPaymentElement.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "USD"),
            paymentMethodTypes: ["card", "link"]
        ) { _, _ in
            XCTFail("This test does not confirm")
            return ""
        }
        let controlEmbedded = try await EmbeddedPaymentElement.create(
            intentConfiguration: intentConfiguration,
            configuration: EmbeddedPaymentElement.Configuration()
        )

        // ...and Checkout with an Express Checkout Element, whose Link button opens the Link wallet
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.expressCheckoutElement = .init { _ in }
        let checkout = try await CheckoutElementsController(configuration: configuration)
        let elementsSession = checkout.session.elementsSession
        XCTAssertEqual(elementsSession.linkSettings?.linkMode, .linkPaymentMethod)
        XCTAssertTrue(checkout.session.availableExpressCheckoutPaymentMethods.contains(.link))
        for (label, session) in [("Checkout", elementsSession), ("Control", controlEmbedded.elementsSession)] {
            XCTAssertTrue(
                session.linkFundingSources?.contains(.bankAccount) ?? false,
                "Precondition: \(label) should let customers add a bank to Link"
            )
        }

        // ...and the customer signs up for Link and saves a card, so the wallet lists the card and an Add button
        let linkAccount = try XCTUnwrap(LinkAccountContext.shared.account, "Checkout should look up the session's email in Link")
        XCTAssertEqual(linkAccount.email, email)
        try await nativeLinkAddBankSignUpAndSaveCard(linkAccount)
        XCTAssertEqual(linkAccount.sessionState, .verified)
        let supportedTypes = linkAccount.supportedPaymentDetailsTypes(for: elementsSession)
        XCTAssertTrue(
            supportedTypes.contains(.bankAccount) && supportedTypes.contains(.card),
            "Precondition: Add should offer Bank and Card. Supported types: \(supportedTypes)"
        )

        // ...and, as a control, the customer taps Add, then Bank, in a native Link wallet opened with the Embedded
        // Payment Element's intent, the same way PaymentSheet opens it. That creates a link account session and
        // opens Financial Connections.
        var controlResult: PaymentSheetResult?
        let controlLinkController = PayWithNativeLinkController(
            mode: .full,
            intent: controlEmbedded.intent,
            elementsSession: controlEmbedded.elementsSession,
            configuration: controlEmbedded.configuration,
            paymentHandler: STPPaymentHandler(apiClient: STPAPIClient.shared),
            logPayment: false,
            analyticsHelper: PaymentSheetAnalyticsHelper(integrationShape: .embedded, configuration: controlEmbedded.configuration)
        )
        controlLinkController.presentAsSheet(from: presenter, shouldOfferApplePay: false, shouldFinishOnClose: false) { result, _, _ in
            controlResult = result
        }
        let controlAttempt = try await nativeLinkAddBankTapAddThenBank(presentedFrom: presenter, requestLog: requestLog)
        controlAttempt.coordinator.cancel(shouldReturnToPaymentSheet: false)
        try await nativeLinkAddBankWait(until: "the control Link wallet closes") {
            controlResult != nil && presenter.presentedViewController == nil
        }
        XCTAssertEqual(
            controlAttempt.linkAccountSessionParameters?["intent_token"],
            controlEmbedded.elementsSession.sessionID,
            "Control: the link account session should use the elements session ID. Requests: \(controlAttempt.requestPaths)"
        )
        XCTAssertTrue(
            controlAttempt.openedFinancialConnections,
            "Control: Bank should open Financial Connections. Requests: \(controlAttempt.requestPaths)"
        )

        // When the customer taps Link in Checkout's Express Checkout Element, then Add, then Bank in the native Link wallet
        var checkoutResult: CheckoutElementsController.ConfirmResult?
        let window = try XCTUnwrap(presenter.view.window)
        let confirmation = Task { @MainActor in
            checkoutResult = await checkout.expressCheckoutElementShouldConfirm(.link, presentationWindow: window)
        }
        let checkoutAttempt = try await nativeLinkAddBankTapAddThenBank(presentedFrom: presenter, requestLog: requestLog)
        let linkAccountSessionParameters = try XCTUnwrap(
            checkoutAttempt.linkAccountSessionParameters,
            "Bank should request a link account session. Requests: \(checkoutAttempt.requestPaths)"
        )

        // ...and, if Financial Connections didn't open, ask the wallet's coordinator for a bank again to read the
        // backend's reply, which the wallet doesn't show
        var backendReply = "not needed"
        if !checkoutAttempt.openedFinancialConnections {
            let directResult = await nativeLinkAddBankStartFinancialConnections(checkoutAttempt.coordinator)
            backendReply = nativeLinkAddBankDescribe(directResult)
        }
        let walletShowsError = checkoutAttempt.visibleWalletTexts.contains { $0.contains("merchant_token") }
        checkoutAttempt.coordinator.cancel(shouldReturnToPaymentSheet: false)
        try await nativeLinkAddBankWait(until: "the Checkout Link wallet closes") { checkoutResult != nil }
        await confirmation.value

        // ...and, as a control, the backend creates a link account session for the same customer and Checkout
        // Session when intent_token is the session's elements session ID. That is the fallback native Link
        // already uses when the intent has no Stripe ID.
        let consumerSession = try XCTUnwrap(linkAccount.currentSession)
        let controlLinkAccountSession: LinkAccountSession = try await withCheckedThrowingContinuation { continuation in
            consumerSession.createLinkAccountSession(
                linkMode: elementsSession.linkSettings?.linkMode,
                intentToken: elementsSession.sessionID
            ) { result in
                continuation.resume(with: result)
            }
        }
        XCTAssertTrue(controlLinkAccountSession.stripeID.hasPrefix("fcsess_"))

        // Then Financial Connections opens for the bank, as it does in the control
        XCTAssertTrue(
            checkoutAttempt.openedFinancialConnections,
            """
            Bank did not open Financial Connections. The link account session request sent \
            intent_token=\(linkAccountSessionParameters["intent_token"] ?? "nil") and \
            merchant_token=\(linkAccountSessionParameters["merchant_token"] ?? "nil"). \
            Backend reply: \(backendReply). Wallet shows that error: \(walletShowsError). \
            Requests: \(checkoutAttempt.requestPaths)
            """
        )
    }

    /// The result of tapping Add, then Bank, in a native Link wallet.
    private struct NativeLinkAddBankAttempt {

        /// The native Link coordinator behind the wallet.
        let coordinator: PayWithLinkViewController
        /// The form parameters of the `/v1/consumers/link_account_sessions` request, if one was made.
        let linkAccountSessionParameters: [String: String]?
        /// Whether Financial Connections opened. Unit tests use the SDK's stand-in for the Financial Connections
        /// sheet, which returns a fake bank right away. Native Link then saves that bank to Link with a
        /// `/v1/consumers/payment_details` request, which only happens once the sheet has opened.
        let openedFinancialConnections: Bool
        /// The paths of the API requests made after tapping Add, in order.
        let requestPaths: [String]
        /// The text of every visible label in the wallet once bank linking ends.
        let visibleWalletTexts: [String]
    }

    /// Records the path and body of every API request without stubbing it, so requests still reach the live backend.
    private final class NativeLinkAddBankRequestLog: @unchecked Sendable {

        private let lock = NSLock()
        private var requests: [(path: String, body: Data?)] = []

        func append(path: String, body: Data?) {
            lock.lock()
            defer { lock.unlock() }
            // OHHTTPStubs can ask about the same request more than once. Keep one entry per request.
            if let last = requests.last, last.path == path, last.body == body {
                return
            }
            requests.append((path, body))
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return requests.count
        }

        func requests(from index: Int) -> [(path: String, body: Data?)] {
            lock.lock()
            defer { lock.unlock() }
            return Array(requests.dropFirst(index))
        }
    }

    /// Starts recording API requests. The test block never matches, so nothing is stubbed.
    private func nativeLinkAddBankRecordRequests() -> NativeLinkAddBankRequestLog {
        let requestLog = NativeLinkAddBankRequestLog()
        HTTPStubs.stubRequests(passingTest: { request in
            if let url = request.url, url.host == "api.stripe.com" {
                requestLog.append(path: url.path, body: request.ohhttpStubs_httpBody)
            }
            return false
        }, withStubResponse: { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        })
        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
        return requestLog
    }

    /// Returns a view controller in a visible window, for presenting the Link sheet.
    private func nativeLinkAddBankMakePresenter() async throws -> UIViewController {
        // A cold test-host launch may still be connecting its window scene.
        let sceneConnected = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            UIApplication.shared.connectedScenes.contains { $0 is UIWindowScene }
        }, object: nil)
        await fulfillment(of: [sceneConnected], timeout: 5)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        addTeardownBlock { @MainActor in
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        return presenter
    }

    /// Signs up the looked-up Link account with a phone number and saves a test card to it.
    private func nativeLinkAddBankSignUpAndSaveCard(_ linkAccount: PaymentSheetLinkAccount) async throws {
        XCTAssertEqual(linkAccount.sessionState, .requiresSignUp, "Precondition: the email should be new to Link")
        let phoneNumber = try XCTUnwrap(PhoneNumber(number: "2015550123", countryCode: "US"))
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            linkAccount.signUp(
                with: phoneNumber,
                legalName: nil,
                countryCode: "US",
                consentAction: .checkbox_v0,
                analyticsHelper: LinkAnalyticsHelper()
            ) { result in
                continuation.resume(with: result)
            }
        }

        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 12
        cardParams.expYear = 2040
        cardParams.cvc = "123"
        let billingAddress = STPPaymentMethodAddress()
        billingAddress.country = "US"
        billingAddress.postalCode = "65432"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = billingAddress
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ConsumerPaymentDetails, Error>) in
            linkAccount.createPaymentDetails(with: paymentMethodParams, isDefault: true) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Waits for a native Link wallet presented from `presenter`, then taps Add, chooses Bank, and waits for the
    /// Add button's spinner to stop, which is when the wallet is done linking a bank.
    private func nativeLinkAddBankTapAddThenBank(
        presentedFrom presenter: UIViewController,
        requestLog: NativeLinkAddBankRequestLog
    ) async throws -> NativeLinkAddBankAttempt {
        // Wait for the Link sheet to finish presenting and to load the customer's wallet.
        try await nativeLinkAddBankWait(until: "the Link sheet is presented") {
            presenter.presentedViewController is PaymentSheetContainer
                && presenter.presentedViewController?.isBeingPresented == false
        }
        let sheet = try XCTUnwrap(presenter.presentedViewController as? any PaymentSheetContainer)
        try await nativeLinkAddBankWait(until: "the Link wallet loads", timeout: 30) {
            sheet.contentStack.first is PayWithLinkViewController.WalletViewController
        }
        let wallet = try XCTUnwrap(sheet.contentStack.first as? PayWithLinkViewController.WalletViewController)
        let coordinator = try XCTUnwrap(wallet.coordinator as? PayWithLinkViewController)
        let picker = try XCTUnwrap(nativeLinkAddBankFirstSubview(of: LinkPaymentMethodPicker.self, in: wallet.view))
        let addButton = try XCTUnwrap(nativeLinkAddBankFirstSubview(of: LinkPaymentMethodPicker.AddButton.self, in: picker))

        // Expand the payment picker and tap Add, as the customer would.
        picker.setExpanded(true, animated: false)
        let firstRequestIndex = requestLog.count
        addButton.sendActions(for: .touchUpInside)

        // Add offers Bank and Card in an action sheet. Choose Bank.
        try await nativeLinkAddBankWait(until: "the Add action sheet is presented") {
            (wallet.presentedViewController as? UIAlertController)?.isBeingPresented == false
        }
        let actionSheet = try XCTUnwrap(wallet.presentedViewController as? UIAlertController)
        let bankAction = try XCTUnwrap(
            actionSheet.actions.first { $0.title == "Bank" },
            "Add should offer Bank. Actions: \(actionSheet.actions.compactMap(\.title))"
        )
        // UIAlertController has no API to tap an action, so call the action's handler after dismissing, as UIKit does.
        typealias AlertActionHandler = @convention(block) (UIAlertAction) -> Void
        let handlerObject = try XCTUnwrap(bankAction.value(forKey: "handler"), "The Bank action should have a handler")
        let handler = unsafeBitCast(handlerObject as AnyObject, to: AlertActionHandler.self)
        var didChooseBank = false
        actionSheet.dismiss(animated: false) {
            handler(bankAction)
            didChooseBank = true
        }

        // Choosing Bank shows a spinner on Add until bank linking ends.
        try await nativeLinkAddBankWait(until: "bank linking ends", timeout: 30) {
            didChooseBank && !addButton.isLoading
        }
        let requests = requestLog.requests(from: firstRequestIndex)
        let linkAccountSessionRequest = requests.last { $0.path.hasSuffix("/consumers/link_account_sessions") }
        let openedFinancialConnections = requests.contains {
            $0.path.hasSuffix("/consumers/payment_details")
                && nativeLinkAddBankFormParameters($0.body)["type"] == "bank_account"
        }
        return NativeLinkAddBankAttempt(
            coordinator: coordinator,
            linkAccountSessionParameters: linkAccountSessionRequest.map { nativeLinkAddBankFormParameters($0.body) },
            openedFinancialConnections: openedFinancialConnections,
            requestPaths: requests.map(\.path),
            visibleWalletTexts: nativeLinkAddBankVisibleLabelTexts(in: wallet.view)
        )
    }

    /// Asks native Link to link a bank, the same call the wallet's Bank option makes, and returns its result.
    private func nativeLinkAddBankStartFinancialConnections(_ coordinator: PayWithLinkViewController) async -> PaymentSheetResult {
        return await withCheckedContinuation { continuation in
            coordinator.startFinancialConnections { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// Describes a bank linking result, including the backend's error details when it failed.
    private func nativeLinkAddBankDescribe(_ result: PaymentSheetResult) -> String {
        guard case .failed(let error) = result else {
            return "\(result)"
        }
        let userInfo = (error as NSError).userInfo
        let status = userInfo[STPError.httpStatusCodeKey].map { "\($0)" } ?? "unknown"
        let parameter = userInfo[STPError.errorParameterKey].map { "\($0)" } ?? "none"
        let message = userInfo[STPError.errorMessageKey].map { "\($0)" } ?? error.nonGenericDescription
        return "HTTP \(status), param \(parameter): \(message)"
    }

    /// Decodes a form-encoded request body by hand. It can contain characters URLComponents rejects in a query.
    private func nativeLinkAddBankFormParameters(_ body: Data?) -> [String: String] {
        guard let body, let bodyString = String(data: body, encoding: .utf8) else {
            return [:]
        }
        var parameters: [String: String] = [:]
        for pair in bodyString.split(separator: "&") {
            let keyAndValue = pair.split(separator: "=", maxSplits: 1).map {
                $0.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String($0)
            }
            if let key = keyAndValue.first {
                parameters[key] = keyAndValue.count > 1 ? keyAndValue[1] : ""
            }
        }
        return parameters
    }

    /// Returns the first view of the given type in a view hierarchy, searching breadth first.
    private func nativeLinkAddBankFirstSubview<T: UIView>(of type: T.Type, in view: UIView) -> T? {
        var pending = [view]
        while !pending.isEmpty {
            let current = pending.removeFirst()
            if let match = current as? T {
                return match
            }
            pending.append(contentsOf: current.subviews)
        }
        return nil
    }

    /// Returns the text of every label in a view hierarchy that isn't hidden.
    private func nativeLinkAddBankVisibleLabelTexts(in view: UIView) -> [String] {
        guard !view.isHidden else {
            return []
        }
        let ownText = (view as? UILabel)?.text.map { [$0] } ?? []
        return ownText + view.subviews.flatMap { nativeLinkAddBankVisibleLabelTexts(in: $0) }
    }

    /// Polls until `condition` is true, failing the test if it takes longer than `timeout` seconds.
    private func nativeLinkAddBankWait(
        until description: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for \(description)", file: file, line: line)
                throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    // MARK: - Passive captcha token on Checkout /confirm

    func testLiveCheckoutConfirmSendsPassiveCaptchaTokenAtTopLevel() async throws {
        // Given a visible key window, which the passive hCaptcha needs to run, and a log of every live API request
        HTTPStubs.removeAllStubs()
        LinkAccountContext.shared.account = nil
        addTeardownBlock { @MainActor in
            LinkAccountContext.shared.account = nil
        }
        let presenter = try await passiveCaptchaMakePresenter()
        let requestLog = passiveCaptchaRecordRequests()

        // ...and, as a control, the live CheckoutClient /confirm endpoint: it rejects unknown top-level parameters,
        // but accepts a top-level passive_captcha_token, so that parameter is part of its contract
        let controlSession = try await STPTestingAPIClient.shared.createCheckoutSession(types: ["card"])
        let controlAPIClient = STPAPIClient(publishableKey: controlSession.publishableKey)
        let controlInitResponse = try await controlAPIClient.initCheckoutSession(
            checkoutSessionId: controlSession.id,
            clientSecret: controlSession.clientSecret,
            adaptivePricingAllowed: false
        )
        XCTAssertNotNil(
            controlInitResponse.elementsSession.value.passiveCaptchaData,
            "Precondition: /init should turn on passive captcha"
        )
        // Mint a token the same way Checkout does, from the session's passive captcha settings.
        let controlChallenge = ConfirmationChallenge(
            elementsSession: controlInitResponse.elementsSession.value,
            stripeAttest: controlAPIClient.stripeAttest
        )
        let controlRadarOptions = await controlChallenge.makeRadarOptions(for: .card)
        let controlToken = try XCTUnwrap(
            controlRadarOptions?.hcaptchaToken,
            "Control: the passive hCaptcha should produce a token on this device"
        )
        let controlConfirmParameters: [String: Any] = [
            "client_secret": controlSession.clientSecret,
            "locale": "en-US",
            "expected_amount": 2000,
            "return_url": "stripe-ios-test://checkout-return",
            "payment_method_data": ["type": "card", "card": ["token": "tok_visa"]],
            "expected_payment_method_type": "card",
            "collected_information": ["email": "link_repro+\(UUID().uuidString)@example.com"],
        ]
        let unknownParameterResult = await passiveCaptchaPostConfirm(
            apiClient: controlAPIClient,
            sessionID: controlSession.id,
            parameters: controlConfirmParameters.merging(["passive_captcha_token_unknown": controlToken]) { $1 }
        )
        guard case .failure(StripeError.apiError(let unknownParameterError)) = unknownParameterResult else {
            XCTFail("Control: /confirm should reject an unknown top-level parameter, got \(unknownParameterResult)")
            return
        }
        XCTAssertEqual(unknownParameterError.code, "parameter_unknown")
        let topLevelTokenResult = await passiveCaptchaPostConfirm(
            apiClient: controlAPIClient,
            sessionID: controlSession.id,
            parameters: controlConfirmParameters.merging(["passive_captcha_token": controlToken]) { $1 }
        )
        XCTAssertEqual(
            try? topLevelTokenResult.get().paymentStatus,
            .paid,
            "Control: /confirm should accept a top-level passive_captcha_token, got \(topLevelTokenResult)"
        )

        // When a customer pays with a card in a live card + Link Checkout Session, where Link is in payment method mode
        let cardAttempt = try await passiveCaptchaPayWithCard(
            types: ["card", "link"],
            signUpForLink: false,
            presenter: presenter,
            requestLog: requestLog
        )
        XCTAssertEqual(cardAttempt.confirmParameters["payment_method_data[type]"], "card")

        // ...and another customer pays with a card and signs up for Link inline, so Checkout confirms the
        // new Link payment details as a Link PaymentMethod
        let linkAttempt = try await passiveCaptchaPayWithCard(
            types: ["card", "link"],
            signUpForLink: true,
            presenter: presenter,
            requestLog: requestLog
        )
        XCTAssertTrue(
            linkAttempt.requestPaths.contains { $0.hasSuffix("/consumers/accounts/sign_up") },
            "Precondition: Link signup should run. Requests: \(linkAttempt.requestPaths)"
        )
        XCTAssertEqual(
            linkAttempt.confirmParameters["payment_method_data[type]"],
            "link",
            "Precondition: /confirm should create a Link PaymentMethod"
        )

        for (label, attempt) in [("Card", cardAttempt), ("Link signup", linkAttempt)] {
            let topLevelToken = attempt.confirmParameters["passive_captcha_token"]
            let nestedToken = attempt.confirmParameters["payment_method_data[radar_options][hcaptcha_token]"]
            // ...and, as a control, Checkout minted a passive captcha token for this /confirm and sent it somewhere
            XCTAssertFalse(
                (topLevelToken ?? nestedToken ?? "").isEmpty,
                "Control: \(label) /confirm should carry a passive captcha token"
            )

            // Then /confirm sends that token as the top-level passive_captcha_token, which is where CheckoutClient reads it
            XCTAssertFalse(
                (topLevelToken ?? "").isEmpty,
                """
                \(label) /confirm has no top-level passive_captcha_token. \
                The token was sent only as payment_method_data[radar_options][hcaptcha_token]: \(nestedToken != nil). \
                Captcha parameters: \(passiveCaptchaParameterNames(in: attempt.confirmParameters))
                """
            )
        }
    }

    func testLiveLinkPassthroughConfirmSendsPassiveCaptchaToken() async throws {
        // Given a visible key window, which the passive hCaptcha needs to run, and a log of every live API request
        HTTPStubs.removeAllStubs()
        LinkAccountContext.shared.account = nil
        addTeardownBlock { @MainActor in
            LinkAccountContext.shared.account = nil
        }
        let presenter = try await passiveCaptchaMakePresenter()
        let requestLog = passiveCaptchaRecordRequests()

        // ...and, as a control, a customer in a live card-only Checkout Session, where Link is in passthrough mode,
        // who pays with the card without Link. Checkout confirms the card details and sends a passive captcha token.
        let control = try await passiveCaptchaPayWithCard(
            types: ["card"],
            signUpForLink: false,
            presenter: presenter,
            requestLog: requestLog
        )
        XCTAssertEqual(control.confirmParameters["payment_method_data[type]"], "card")
        XCTAssertFalse(
            (control.confirmParameters["passive_captcha_token"]
                ?? control.confirmParameters["payment_method_data[radar_options][hcaptcha_token]"] ?? "").isEmpty,
            "Control: /confirm for the card should carry a passive captcha token"
        )

        // When another customer pays with a card and signs up for Link inline, so Link shares the card as a
        // PaymentMethod and Checkout confirms with that PaymentMethod's ID
        let linkAttempt = try await passiveCaptchaPayWithCard(
            types: ["card"],
            signUpForLink: true,
            presenter: presenter,
            requestLog: requestLog
        )
        XCTAssertTrue(
            linkAttempt.requestPaths.contains { $0.hasSuffix("/consumers/payment_details/share") },
            "Precondition: Link should share the card. Requests: \(linkAttempt.requestPaths)"
        )
        let sharedPaymentMethodID = try XCTUnwrap(linkAttempt.confirmParameters["payment_method"])
        XCTAssertTrue(sharedPaymentMethodID.hasPrefix("pm_"), "Precondition: /confirm should use the shared PaymentMethod")

        // Then /confirm still sends a passive captcha token, as the top-level passive_captcha_token
        XCTAssertFalse(
            (linkAttempt.confirmParameters["passive_captcha_token"] ?? "").isEmpty,
            """
            /confirm with the Link-shared PaymentMethod has no passive_captcha_token. \
            Captcha parameters: \(passiveCaptchaParameterNames(in: linkAttempt.confirmParameters))
            """
        )
    }

    /// The `/v1/checkout_client/{id}/confirm` request made when paying with a card in a live Checkout Session.
    private struct PassiveCaptchaConfirmAttempt {

        /// The form parameters sent to `/confirm`.
        let confirmParameters: [String: String]
        /// The paths of the API requests made while confirming, in order.
        let requestPaths: [String]
    }

    /// Records the path and body of every API request without stubbing it, so requests still reach the live backend.
    private final class PassiveCaptchaRequestLog: @unchecked Sendable {

        private let lock = NSLock()
        private var requests: [(path: String, body: Data?)] = []

        func append(path: String, body: Data?) {
            lock.lock()
            defer { lock.unlock() }
            // OHHTTPStubs can ask about the same request more than once. Keep one entry per request.
            if let last = requests.last, last.path == path, last.body == body {
                return
            }
            requests.append((path, body))
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return requests.count
        }

        func requests(from index: Int) -> [(path: String, body: Data?)] {
            lock.lock()
            defer { lock.unlock() }
            return Array(requests.dropFirst(index))
        }
    }

    /// Starts recording API requests. The test block never matches, so nothing is stubbed.
    private func passiveCaptchaRecordRequests() -> PassiveCaptchaRequestLog {
        let requestLog = PassiveCaptchaRequestLog()
        HTTPStubs.stubRequests(passingTest: { request in
            if let url = request.url, url.host == "api.stripe.com" {
                requestLog.append(path: url.path, body: request.ohhttpStubs_httpBody)
            }
            return false
        }, withStubResponse: { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        })
        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
        return requestLog
    }

    /// Returns a view controller in a visible key window. The passive hCaptcha web view only runs once it can be
    /// added to a key window, and the presenter is also used for any confirmation UI.
    private func passiveCaptchaMakePresenter() async throws -> UIViewController {
        // A cold test-host launch may still be connecting its window scene.
        let sceneConnected = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            UIApplication.shared.connectedScenes.contains { $0 is UIWindowScene }
        }, object: nil)
        await fulfillment(of: [sceneConnected], timeout: 5)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        addTeardownBlock { @MainActor in
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        return presenter
    }

    /// Creates a live guest Checkout Session for a new Link consumer, fills in the embedded card form, optionally
    /// signs up for Link inline, confirms, and returns the `/confirm` request.
    private func passiveCaptchaPayWithCard(
        types: [String],
        signUpForLink: Bool,
        presenter: UIViewController,
        requestLog: PassiveCaptchaRequestLog
    ) async throws -> PassiveCaptchaConfirmAttempt {
        // A fresh email is a new Link consumer, so Link inline signup is offered for it.
        let email = "link_repro+\(UUID().uuidString)@example.com"
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(types: types, customerEmail: email)
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSession.publishableKey)
        configuration.paymentElement = .init()
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // The session turns on passive captcha, which is what gives Checkout a token to send with /confirm.
        let elementsSession = checkout.session.elementsSession
        XCTAssertNotNil(elementsSession.passiveCaptchaData, "Precondition: /init should turn on passive captcha")
        XCTAssertNotNil(checkout.confirmationChallenge)
        XCTAssertEqual(elementsSession.linkPassthroughModeEnabled, types == ["card"])

        // Open the card form, as a customer tapping the Card row would, and fill in a US card.
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        embedded.presentingViewController = presenter
        let cardRow = try XCTUnwrap(embedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        })
        embedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let formViewController = try XCTUnwrap(embedded.selectedFormViewController)
        let form = formViewController.form
        try XCTUnwrap(form.getTextFieldElement("Card number")).setText("4242424242424242")
        try XCTUnwrap(form.getTextFieldElement("MM / YY")).setText("1240")
        try XCTUnwrap(form.getTextFieldElement("CVC")).setText("123")
        try XCTUnwrap(form.getTextFieldElement("ZIP")).setText("65432")

        // Opt in or out of Link inline signup. The session's email was already looked up in Link at load.
        let signup = try XCTUnwrap(
            form.getAllUnwrappedSubElements().compactMap { $0 as? LinkInlineSignupElement }.first,
            "The card form should offer Link inline signup"
        )
        XCTAssertEqual(signup.viewModel.linkAccount?.sessionState, .requiresSignUp)
        if [.checkbox, .checkboxWithDefaultOptIn].contains(signup.viewModel.mode) {
            // Check or uncheck the Link box, as a customer tapping it would.
            signup.viewModel.saveCheckboxChecked = signUpForLink
        }
        if signUpForLink {
            // Entering a phone number completes the Link signup details.
            signup.viewModel.phoneNumber = PhoneNumber(number: "2015550123", countryCode: "US")
            guard case .signupAndPay = signup.action else {
                XCTFail("Expected the customer to opt into Link signup, got \(String(describing: signup.action))")
                throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
            }
        } else if case .signupAndPay = signup.action {
            XCTFail("Link signup should not run")
        }

        // Tap the form's primary button, which hands the payment option to Checkout.
        formViewController.didTapPrimaryButton()
        let deadline = Date().addingTimeInterval(15)
        while checkout.session.paymentOption == nil, Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertNotNil(checkout.session.paymentOption, "The card form should produce a payment option")

        // Confirm, keeping track of the requests made along the way.
        let firstRequestIndex = requestLog.count
        let result = await checkout.confirm(from: presenter)
        guard case .completed(let paymentStatus) = result else {
            XCTFail("Expected confirmation to complete, got \(result)")
            throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
        }
        XCTAssertEqual(paymentStatus, .paid)
        let requests = requestLog.requests(from: firstRequestIndex)
        let confirmRequest = try XCTUnwrap(
            requests.last { $0.path.hasSuffix("/checkout_client/\(checkoutSession.id)/confirm") },
            "No /confirm request was recorded. Requests: \(requests.map(\.path))"
        )

        // Decode the form-encoded body by hand. It can contain characters URLComponents rejects in a query.
        let confirmBody = try XCTUnwrap(confirmRequest.body.flatMap { String(data: $0, encoding: .utf8) })
        var confirmParameters: [String: String] = [:]
        for pair in confirmBody.split(separator: "&") {
            let keyAndValue = pair.split(separator: "=", maxSplits: 1).map {
                $0.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String($0)
            }
            if let key = keyAndValue.first {
                confirmParameters[key] = keyAndValue.count > 1 ? keyAndValue[1] : ""
            }
        }
        return PassiveCaptchaConfirmAttempt(confirmParameters: confirmParameters, requestPaths: requests.map(\.path))
    }

    /// Posts form parameters to a live CheckoutClient `/confirm`, the same way the SDK does, and returns the result.
    private func passiveCaptchaPostConfirm(
        apiClient: STPAPIClient,
        sessionID: String,
        parameters: [String: Any]
    ) async -> Result<CheckoutClientAPIResponse, Error> {
        return await withCheckedContinuation { continuation in
            apiClient.post(
                resource: "checkout_client/\(sessionID)/confirm",
                parameters: parameters
            ) { (result: Result<CheckoutClientAPIResponse, Error>) in
                continuation.resume(returning: result)
            }
        }
    }

    /// Lists the names of the captcha-related parameters in a `/confirm` request, e.g. for failure messages.
    private func passiveCaptchaParameterNames(in parameters: [String: String]) -> [String] {
        return parameters.keys.filter { $0.contains("captcha") }.sorted()
    }

    // MARK: - Opening native Link replacing the Payment Element's selection

    func testLiveClosingNativeLinkOpenedFromLinkRowKeepsLinkSelected() async throws {
        // Given native Link, a visible window to present it from, and no Apple Pay, so the Payment Element's
        // hidden FlowController starts with nothing selected
        HTTPStubs.removeAllStubs()
        nativeLinkSourceOfTruthUseNativeLink()
        let presenter = try await nativeLinkSourceOfTruthMakePresenter()

        // ...and no remembered guest selection. Tapping the Link row saves Link as every guest's local default, which
        // would make the hidden FlowController start on Link too in later runs and hide the wrong selection.
        let originalLastSelectedPaymentMethods = UserDefaults.standard.customerToLastSelectedPaymentMethod
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        addTeardownBlock {
            UserDefaults.standard.customerToLastSelectedPaymentMethod = originalLastSelectedPaymentMethods
        }

        // ...and a live guest card + Link Checkout Session shown in an embedded Payment Element
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(types: ["card", "link"])
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSession.publishableKey)
        configuration.paymentElement = .init()
        let checkout = try await CheckoutElementsController(configuration: configuration)
        XCTAssertEqual(checkout.session.elementsSession.linkSettings?.linkMode, .linkPaymentMethod)
        let paymentElement = checkout.getPaymentElement()
        let embedded = paymentElement.embeddedPaymentElement
        embedded.presentingViewController = presenter
        XCTAssertNil(
            paymentElement.paymentSheetFlowController.internalPaymentOption,
            "Precondition: the hidden FlowController should start with nothing selected"
        )

        // ...and the customer taps the Link row
        let linkRow = try XCTUnwrap(
            embedded.embeddedPaymentMethodsView.rowButtons.first { $0.type == .link },
            "The embedded Payment Element should show a Link row"
        )
        embedded.embeddedPaymentMethodsView.didTap(rowButton: linkRow)
        XCTAssertEqual(checkout.session.paymentOption?.paymentMethodType, "link", "Precondition: Link should be selected")
        XCTAssertFalse(paymentElement.paymentOptionSourceOfTruthIsFlowController)

        // When the customer taps the merchant's Pay button, which opens the native Link sheet, and closes the
        // sheet without logging in
        let firstAttempt = try await nativeLinkSourceOfTruthConfirm(presenter: presenter) {
            await checkout.confirm(from: presenter)
        }
        XCTAssertTrue(firstAttempt.openedLink, "Precondition: Pay should open native Link. Result: \(firstAttempt.result)")
        guard case .canceled = firstAttempt.result else {
            XCTFail("Closing Link should cancel the confirmation, got \(firstAttempt.result)")
            return
        }

        // Then the embedded Payment Element still shows Link as selected...
        XCTAssertEqual(embedded.embeddedPaymentMethodsView.selectedRowButton?.type, .link)
        XCTAssertEqual(embedded.paymentOption?.paymentMethodType, "link")

        // ...and Checkout still has Link as the payment option, instead of the hidden FlowController's empty selection
        XCTAssertEqual(
            checkout.session.paymentOption?.paymentMethodType,
            "link",
            "After closing Link, session.paymentOption is \(nativeLinkSourceOfTruthDescribe(checkout.session.paymentOption))"
        )
        XCTAssertFalse(
            paymentElement.paymentOptionSourceOfTruthIsFlowController,
            "Opening Link made the hidden FlowController the Payment Element's source of truth"
        )

        // ...and tapping Pay again opens Link again, instead of confirming without a payment method
        let secondAttempt = try await nativeLinkSourceOfTruthConfirm(presenter: presenter) {
            await checkout.confirm(from: presenter)
        }
        XCTAssertTrue(
            secondAttempt.openedLink,
            "Tapping Pay again with Link still selected did not open Link. Result: \(nativeLinkSourceOfTruthDescribe(secondAttempt.result))"
        )
    }

    func testLiveClosingNativeLinkFromExpressCheckoutKeepsEnteredCardSelected() async throws {
        // Given native Link, a visible window to present it from, and a log of every live API request
        HTTPStubs.removeAllStubs()
        nativeLinkSourceOfTruthUseNativeLink()
        let presenter = try await nativeLinkSourceOfTruthMakePresenter()
        let requestLog = nativeLinkSourceOfTruthRecordRequests()

        // ...and a live card + Link Checkout Session for a returning customer with a saved Visa
        let email = "link_repro+\(UUID().uuidString)@example.com"
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(email: email)
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: ["card", "link"],
            customerID: customerID,
            savedPaymentMethodAllowRedisplayFilters: ["always"]
        )
        let apiClient = STPAPIClient(publishableKey: checkoutSession.publishableKey)
        let savedCardParams = STPPaymentMethodCardParams()
        savedCardParams.number = "4242424242424242"
        savedCardParams.expMonth = 12
        savedCardParams.expYear = 2040
        savedCardParams.cvc = "123"
        let savedCard = try await apiClient.createPaymentMethod(with: STPPaymentMethodParams(
            card: savedCardParams,
            billingDetails: nil,
            allowRedisplay: .always,
            metadata: nil
        ))
        try await nativeLinkSourceOfTruthAttach(paymentMethodID: savedCard.stripeId, toCustomer: customerID)

        // ...shown in an embedded Payment Element, next to an Express Checkout Element with a Link button
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = apiClient
        configuration.paymentElement = .init()
        configuration.expressCheckoutElement = .init { _ in }
        let checkout = try await CheckoutElementsController(configuration: configuration)
        XCTAssertTrue(checkout.session.availableExpressCheckoutPaymentMethods.contains(.link))
        let paymentElement = checkout.getPaymentElement()
        let embedded = paymentElement.embeddedPaymentElement
        embedded.presentingViewController = presenter
        guard case .saved(let flowControllerCard, _)? = paymentElement.paymentSheetFlowController.internalPaymentOption else {
            XCTFail("Precondition: the hidden FlowController should select the saved card by default")
            return
        }
        XCTAssertEqual(flowControllerCard.stripeId, savedCard.stripeId)

        // ...and the customer taps the Card row and enters a new Mastercard instead of using the saved Visa
        let cardRow = try XCTUnwrap(embedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        })
        embedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let formViewController = try XCTUnwrap(embedded.selectedFormViewController)
        let form = formViewController.form
        try XCTUnwrap(form.getTextFieldElement("Card number")).setText("5555555555554444")
        try XCTUnwrap(form.getTextFieldElement("MM / YY")).setText("1240")
        try XCTUnwrap(form.getTextFieldElement("CVC")).setText("123")
        try XCTUnwrap(form.getTextFieldElement("ZIP")).setText("65432")
        // Leave Link inline signup off, so paying with the new card doesn't involve Link.
        if let signup = form.getAllUnwrappedSubElements().compactMap({ $0 as? LinkInlineSignupElement }).first,
           [.checkbox, .checkboxWithDefaultOptIn].contains(signup.viewModel.mode) {
            signup.viewModel.saveCheckboxChecked = false
        }
        // Tap the form's primary button, which hands the new card to Checkout, and wait for the form sheet to close.
        formViewController.didTapPrimaryButton()
        try await nativeLinkSourceOfTruthWait(until: "the card form closes") {
            presenter.presentedViewController == nil
        }
        XCTAssertTrue(
            nativeLinkSourceOfTruthDescribe(checkout.session.paymentOption).contains("4444"),
            "Precondition: the new card should be selected, got \(nativeLinkSourceOfTruthDescribe(checkout.session.paymentOption))"
        )
        XCTAssertFalse(paymentElement.paymentOptionSourceOfTruthIsFlowController)

        // When the customer taps the Express Checkout Element's Link button, which opens the native Link sheet, and
        // closes the sheet without logging in
        let window = try XCTUnwrap(presenter.view.window)
        let linkAttempt = try await nativeLinkSourceOfTruthConfirm(presenter: presenter) {
            await checkout.expressCheckoutElementShouldConfirm(.link, presentationWindow: window)
        }
        XCTAssertTrue(linkAttempt.openedLink, "Precondition: the Link button should open native Link. Result: \(linkAttempt.result)")
        guard case .canceled = linkAttempt.result else {
            XCTFail("Closing Link should cancel the confirmation, got \(linkAttempt.result)")
            return
        }

        // Then the embedded Payment Element still has the new card...
        XCTAssertTrue(nativeLinkSourceOfTruthDescribe(embedded.paymentOption.map(CheckoutElementsController.Session.PaymentOptionDisplayData.init)).contains("4444"))

        // ...and Checkout's payment option is still the new card, not the saved Visa the hidden FlowController selected
        XCTAssertTrue(
            nativeLinkSourceOfTruthDescribe(checkout.session.paymentOption).contains("4444"),
            "After closing Link, session.paymentOption is \(nativeLinkSourceOfTruthDescribe(checkout.session.paymentOption))"
        )
        XCTAssertFalse(
            paymentElement.paymentOptionSourceOfTruthIsFlowController,
            "Opening Link made the hidden FlowController the Payment Element's source of truth"
        )

        // ...and when the customer taps the merchant's Pay button, Checkout pays with the new card, not the saved Visa
        let firstRequestIndex = requestLog.count
        let payAttempt = try await nativeLinkSourceOfTruthConfirm(presenter: presenter) {
            await checkout.confirm(from: presenter)
        }
        guard case .completed = payAttempt.result else {
            XCTFail("Expected the payment to complete, got \(nativeLinkSourceOfTruthDescribe(payAttempt.result))")
            return
        }
        let confirmRequest = try XCTUnwrap(
            requestLog.requests(from: firstRequestIndex).last { $0.path.hasSuffix("/checkout_client/\(checkoutSession.id)/confirm") },
            "No /confirm request was recorded"
        )
        let confirmParameters = nativeLinkSourceOfTruthFormParameters(confirmRequest.body)
        XCTAssertNotEqual(
            confirmParameters["payment_method"],
            savedCard.stripeId,
            "/confirm charged the saved Visa instead of the new Mastercard the Payment Element shows"
        )
        XCTAssertEqual(confirmParameters["payment_method_data[type]"], "card")
    }

    /// The result of a confirmation attempt that may open the native Link sheet.
    private struct NativeLinkSourceOfTruthAttempt {

        /// Whether the native Link sheet opened. It's closed right away, as a customer who doesn't log in would.
        let openedLink: Bool
        /// The result of the confirmation attempt.
        let result: CheckoutElementsController.ConfirmResult
    }

    /// Records the path and body of every API request without stubbing it, so requests still reach the live backend.
    private final class NativeLinkSourceOfTruthRequestLog: @unchecked Sendable {

        private let lock = NSLock()
        private var requests: [(path: String, body: Data?)] = []

        func append(path: String, body: Data?) {
            lock.lock()
            defer { lock.unlock() }
            // OHHTTPStubs can ask about the same request more than once. Keep one entry per request.
            if let last = requests.last, last.path == path, last.body == body {
                return
            }
            requests.append((path, body))
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return requests.count
        }

        func requests(from index: Int) -> [(path: String, body: Data?)] {
            lock.lock()
            defer { lock.unlock() }
            return Array(requests.dropFirst(index))
        }
    }

    /// Turns on native Link and restores the shared state this changes when the test ends. The US playground
    /// merchant reports link_mobile_use_attestation_endpoints=false to the unit-test host app, so use the override
    /// that the Checkout Playground's default "Native" Link mode also sets.
    private func nativeLinkSourceOfTruthUseNativeLink() {
        let originalNativeLinkOverride = PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
        // Start without a Link account left over from another test.
        LinkAccountContext.shared.account = nil
        addTeardownBlock { @MainActor in
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = originalNativeLinkOverride
            LinkAccountContext.shared.account = nil
        }
    }

    /// Starts recording API requests. The test block never matches, so nothing is stubbed.
    private func nativeLinkSourceOfTruthRecordRequests() -> NativeLinkSourceOfTruthRequestLog {
        let requestLog = NativeLinkSourceOfTruthRequestLog()
        HTTPStubs.stubRequests(passingTest: { request in
            if let url = request.url, url.host == "api.stripe.com" {
                requestLog.append(path: url.path, body: request.ohhttpStubs_httpBody)
            }
            return false
        }, withStubResponse: { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        })
        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
        return requestLog
    }

    /// Returns a view controller in a visible key window, for presenting the Link sheet and the card form.
    private func nativeLinkSourceOfTruthMakePresenter() async throws -> UIViewController {
        // A cold test-host launch may still be connecting its window scene.
        let sceneConnected = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            UIApplication.shared.connectedScenes.contains { $0 is UIWindowScene }
        }, object: nil)
        await fulfillment(of: [sceneConnected], timeout: 5)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        addTeardownBlock { @MainActor in
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        return presenter
    }

    /// Attaches a payment method to a customer through the playground backend.
    private func nativeLinkSourceOfTruthAttach(paymentMethodID: String, toCustomer customerID: String) async throws {
        let url = try XCTUnwrap(URL(string: STPTestingAPIClient.STPTestingPlaygroundBackendURL + "attach_payment_method"))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "merchant": "US",
            "payment_method_id": paymentMethodID,
            "request_params": ["customer": customerID],
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        XCTAssertTrue(
            (200..<300).contains(statusCode),
            "Attaching the saved card failed: \(String(data: data, encoding: .utf8) ?? "")"
        )
    }

    /// Starts a confirmation and waits for it to finish. If it opens the native Link sheet, closes the sheet with
    /// its close button, as a customer who doesn't want to log in would.
    private func nativeLinkSourceOfTruthConfirm(
        presenter: UIViewController,
        _ confirm: @escaping @MainActor () async -> CheckoutElementsController.ConfirmResult
    ) async throws -> NativeLinkSourceOfTruthAttempt {
        var result: CheckoutElementsController.ConfirmResult?
        let confirmation = Task { @MainActor in
            result = await confirm()
        }
        // The Link sheet's first screen is one of native Link's screens, e.g. sign up for a customer without a Link account.
        func presentedLinkScreen() -> PayWithLinkViewController.BaseViewController? {
            guard let sheet = presenter.presentedViewController as? any PaymentSheetContainer,
                  !sheet.isBeingPresented else {
                return nil
            }
            return sheet.contentStack.first as? PayWithLinkViewController.BaseViewController
        }
        try await nativeLinkSourceOfTruthWait(until: "the confirmation finishes or opens Link", timeout: 30) {
            result != nil || presentedLinkScreen() != nil
        }
        var openedLink = false
        if result == nil, let linkScreen = presentedLinkScreen() {
            openedLink = true
            // Tap the Link sheet's close button.
            linkScreen.navigationBar.delegate?.sheetNavigationBarDidClose(linkScreen.navigationBar)
            try await nativeLinkSourceOfTruthWait(until: "the Link sheet closes") {
                result != nil && presenter.presentedViewController == nil
            }
        }
        await confirmation.value
        return NativeLinkSourceOfTruthAttempt(openedLink: openedLink, result: try XCTUnwrap(result))
    }

    /// Describes a Checkout payment option for assertions and failure messages, e.g. "card •••• 4444 Mastercard".
    private func nativeLinkSourceOfTruthDescribe(_ paymentOption: CheckoutElementsController.Session.PaymentOptionDisplayData?) -> String {
        guard let paymentOption else {
            return "nil"
        }
        return [paymentOption.paymentMethodType, paymentOption.label, paymentOption.sublabel].compactMap { $0 }.joined(separator: " ")
    }

    /// Describes a confirmation result, including the backend's error message when it failed.
    private func nativeLinkSourceOfTruthDescribe(_ result: CheckoutElementsController.ConfirmResult) -> String {
        guard case .failed(let error) = result else {
            return "\(result)"
        }
        let message = (error as NSError).userInfo[STPError.errorMessageKey].map { "\($0)" } ?? error.nonGenericDescription
        return "failed: \(message)"
    }

    /// Decodes a form-encoded request body by hand. It can contain characters URLComponents rejects in a query.
    private func nativeLinkSourceOfTruthFormParameters(_ body: Data?) -> [String: String] {
        guard let body, let bodyString = String(data: body, encoding: .utf8) else {
            return [:]
        }
        var parameters: [String: String] = [:]
        for pair in bodyString.split(separator: "&") {
            let keyAndValue = pair.split(separator: "=", maxSplits: 1).map {
                $0.replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String($0)
            }
            if let key = keyAndValue.first {
                parameters[key] = keyAndValue.count > 1 ? keyAndValue[1] : ""
            }
        }
        return parameters
    }

    /// Polls until `condition` is true, failing the test if it takes longer than `timeout` seconds.
    private func nativeLinkSourceOfTruthWait(
        until description: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for \(description)", file: file, line: line)
                throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    // MARK: - Card with Link signup when the Link button is hidden

    func testLiveWalletButtonHiddenKeepsCardWithLinkSignupAfterShippingUpdate() async throws {
        // Given a live card and Link Checkout Session for a new Link customer, with a Payment Element that hides the
        // Link button but keeps inline signup (`.walletButtonHidden`)
        HTTPStubs.removeAllStubs()
        // ...and a card entered in the embedded card form with Link signup opted in, then Continue tapped
        let (checkout, embedded) = try await walletButtonHiddenSignupEnterCardAndContinue(linkDisplay: .walletButtonHidden)
        // The customer has no Link account, so the Link row is hidden.
        XCTAssertFalse(
            embedded.embeddedPaymentMethodsView.rowButtons.contains { $0.type == .link },
            "Precondition: `.walletButtonHidden` should hide the Link row for a new Link customer"
        )

        // When an unrelated, local-only shipping change updates the session and rebuilds the Payment Element
        try await checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then the card row stays selected, and the entered card is still the payment option
        walletButtonHiddenSignupAssertCardKept(checkout: checkout, embedded: embedded)
    }

    func testLiveAutomaticLinkDisplayKeepsCardWithLinkSignupAfterShippingUpdate() async throws {
        // Given the same flow as above, but with the default Link display (`.automatic`), which shows the Link row
        HTTPStubs.removeAllStubs()
        let (checkout, embedded) = try await walletButtonHiddenSignupEnterCardAndContinue(linkDisplay: .automatic)
        XCTAssertTrue(
            embedded.embeddedPaymentMethodsView.rowButtons.contains { $0.type == .link },
            "Precondition: `.automatic` should show the Link row"
        )

        // When the same local-only shipping change updates the session
        try await checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then, as a control, the card row stays selected, and the entered card is still the payment option
        walletButtonHiddenSignupAssertCardKept(checkout: checkout, embedded: embedded)
    }

    /// Creates a live card and Link Checkout Session for a new Link customer, opens the embedded card form, fills in a
    /// card, opts into Link inline signup, and taps Continue.
    /// Returns once Checkout reports the card with Link signup as its payment option.
    private func walletButtonHiddenSignupEnterCardAndContinue(
        linkDisplay: PaymentElement.Configuration.LinkConfiguration.Display
    ) async throws -> (CheckoutElementsController, EmbeddedPaymentElement) {
        // Start without a Link account left over from another test. A registered account would show the Link row.
        LinkAccountContext.shared.account = nil
        addTeardownBlock { @MainActor in
            LinkAccountContext.shared.account = nil
        }

        // A fresh email is a new Link consumer, so the card form offers Link inline signup for it.
        let email = "link_repro+\(UUID().uuidString)@example.com"
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: ["card", "link"],
            customerEmail: email
        )
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSession.publishableKey)
        // Prefill the Link signup phone number, so opting in is all the customer has to do.
        configuration.defaults.phone = "+12015550123"
        var paymentElementConfiguration = PaymentElement.Configuration()
        paymentElementConfiguration.linkConfiguration = .init(display: linkDisplay)
        configuration.paymentElement = paymentElementConfiguration
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Check the state this flow depends on: Link in payment method mode, and a lookup that found no Link account.
        XCTAssertEqual(checkout.session.elementsSession.linkSettings?.linkMode, .linkPaymentMethod)
        let linkAccount = try XCTUnwrap(LinkAccountContext.shared.account, "Checkout should look up the session's email in Link")
        XCTAssertEqual(linkAccount.email, email)
        XCTAssertFalse(linkAccount.isRegistered, "Precondition: the new email should not have a Link account")

        // Open the card form, as a customer tapping the Card row would, and fill in a US card.
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        embedded.presentingViewController = UIViewController()
        let cardRow = try XCTUnwrap(embedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        })
        embedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let formViewController = try XCTUnwrap(embedded.selectedFormViewController)
        let form = formViewController.form
        try XCTUnwrap(form.getTextFieldElement("Card number")).setText("4242424242424242")
        try XCTUnwrap(form.getTextFieldElement("MM / YY")).setText("1240")
        try XCTUnwrap(form.getTextFieldElement("CVC")).setText("123")
        try XCTUnwrap(form.getTextFieldElement("ZIP")).setText("65432")

        // Opt into Link signup, as a customer checking the Link box would. The email comes from the session and the
        // phone number from the defaults, so this makes the card form sign the customer up for Link.
        let signup = try XCTUnwrap(
            form.getAllUnwrappedSubElements().compactMap { $0 as? LinkInlineSignupElement }.first,
            "The card form should offer Link inline signup"
        )
        XCTAssertTrue([.checkbox, .checkboxWithDefaultOptIn].contains(signup.viewModel.mode), "Unexpected mode \(signup.viewModel.mode)")
        signup.viewModel.saveCheckboxChecked = true
        guard case .signupAndPay = signup.action else {
            XCTFail("Precondition: Link signup should be opted in, got \(String(describing: signup.action))")
            throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
        }

        // Tap Continue, which hands the payment option to Checkout.
        formViewController.didTapPrimaryButton()
        let deadline = Date().addingTimeInterval(15)
        while checkout.session.paymentOption == nil, Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertNotNil(checkout.session.paymentOption, "Precondition: Continue should give Checkout a payment option")
        XCTAssertEqual(
            embedded.embeddedPaymentMethodsView.selectedRowButton?.type,
            .new(paymentMethodType: .stripe(.card)),
            "Precondition: the card row should be selected"
        )
        // The selection is a card with Link signup, not a plain card. Otherwise this flow would not test the bug.
        guard case .link(option: .signUp) = embedded._paymentOption else {
            XCTFail("Precondition: expected a card with Link signup, got \(String(describing: embedded._paymentOption))")
            throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
        }
        return (checkout, embedded)
    }

    /// Asserts that the embedded card row is still selected and that both the Payment Element and Checkout still hold
    /// the entered card as their payment option.
    private func walletButtonHiddenSignupAssertCardKept(
        checkout: CheckoutElementsController,
        embedded: EmbeddedPaymentElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            embedded.embeddedPaymentMethodsView.selectedRowButton?.type,
            .new(paymentMethodType: .stripe(.card)),
            "The card row should stay selected after the update",
            file: file,
            line: line
        )
        XCTAssertNotNil(
            embedded.selectedFormViewController,
            "The card form should be rebuilt with the entered card",
            file: file,
            line: line
        )
        XCTAssertNotNil(
            embedded._paymentOption,
            "The Payment Element should still have the entered card",
            file: file,
            line: line
        )
        XCTAssertNotNil(
            checkout.session.paymentOption,
            "Checkout should still have a payment option, or confirm would go out without a payment method",
            file: file,
            line: line
        )
    }

    // MARK: - Linked bank dropped by Checkout session updates

    func testLiveLinkedBankStaysSelectedAfterLocalShippingUpdate() async throws {
        // Given live Checkout Sessions with a fresh customer email and no automatic tax: one with card and Link,
        // which offers Link's Bank row (Instant Bank Payments), and one with card only, which offers the
        // Link Card Brand bank row
        HTTPStubs.removeAllStubs()
        let variants: [(types: [String], rowType: PaymentSheet.PaymentMethodType, linkMode: LinkMode)] = [
            (["card", "link"], .instantDebits, .linkPaymentMethod),
            (["card"], .linkCardBrand, .linkCardBrand),
        ]
        for variant in variants {
            let label = "\(variant.types) session, \(variant.rowType) row"

            // ...and a bank linked in that row's form, then Continue tapped
            let (checkout, embedded, formViewController) = try await linkedBankDroppedOpenForm(
                types: variant.types,
                automaticTax: false,
                rowType: variant.rowType
            )
            XCTAssertEqual(checkout.session.elementsSession.linkSettings?.linkMode, variant.linkMode, "Precondition (\(label))")
            try linkedBankDroppedLinkBank(in: formViewController, linkMode: variant.linkMode)
            try await linkedBankDroppedTapContinue(formViewController)

            // As a control, Continue itself keeps the bank: no tax sync runs, so the session is not updated yet
            linkedBankDroppedAssertBankSelected(
                checkout: checkout,
                embedded: embedded,
                rowType: variant.rowType,
                context: "\(label), right after Continue"
            )

            // When an unrelated, local-only shipping change updates the session, which rebuilds the Payment Element
            try await checkout.updateShippingAddress(
                name: "Jenny Rosen",
                address: .init(country: "US", line1: "354 Oyster Point Blvd", city: "South San Francisco", state: "CA", postalCode: "94080")
            )

            // Then the linked bank is still selected, and Checkout still has it as the payment option
            linkedBankDroppedAssertBankSelected(
                checkout: checkout,
                embedded: embedded,
                rowType: variant.rowType,
                context: "\(label), after the shipping update"
            )
        }
    }

    func testLiveLinkedBankStaysSelectedAfterContinueWithBillingAutomaticTax() async throws {
        // Given a live card and Link Checkout Session with automatic tax and no shipping collection,
        // so Checkout calculates tax from the billing address, and a default billing address that prefills the forms
        HTTPStubs.removeAllStubs()
        let (checkout, embedded, formViewController) = try await linkedBankDroppedOpenForm(
            types: ["card", "link"],
            automaticTax: true,
            rowType: .instantDebits
        )
        XCTAssertTrue(checkout.session.shouldSendTaxRegion(for: "billing"), "Precondition: tax should come from the billing address")

        // ...and a bank linked in the Bank row's form, which also collects the billing address for tax
        try linkedBankDroppedLinkBank(in: formViewController, linkMode: .linkPaymentMethod)
        XCTAssertEqual(
            formViewController.selectedPaymentOption?.checkoutBillingDetails?.address?.country,
            "US",
            "Precondition: the bank form should have a billing address, so Continue sends it to Checkout for tax"
        )
        let elementsSessionIDBeforeContinue = checkout.session.elementsSession.sessionID

        // When the customer taps Continue, which first sends the billing address to Checkout for tax
        try await linkedBankDroppedTapContinue(formViewController)
        XCTAssertNotEqual(
            checkout.session.elementsSession.sessionID,
            elementsSessionIDBeforeContinue,
            "Precondition: Continue should have updated the session's tax region"
        )

        // Then the linked bank is still selected, and Checkout has it as the payment option
        linkedBankDroppedAssertBankSelected(
            checkout: checkout,
            embedded: embedded,
            rowType: .instantDebits,
            context: "after Continue with billing-based tax"
        )
    }

    func testLiveCardStaysSelectedAfterContinueWithBillingAutomaticTax() async throws {
        // Given the same kind of session as above: card and Link, automatic tax from the billing address
        HTTPStubs.removeAllStubs()
        let (checkout, embedded, formViewController) = try await linkedBankDroppedOpenForm(
            types: ["card", "link"],
            automaticTax: true,
            rowType: .stripe(.card)
        )

        // ...and, as a control, a card entered in the Card row's form instead of a linked bank
        let form = formViewController.form
        try XCTUnwrap(form.getTextFieldElement("Card number")).setText("4242424242424242")
        try XCTUnwrap(form.getTextFieldElement("MM / YY")).setText("1240")
        try XCTUnwrap(form.getTextFieldElement("CVC")).setText("123")
        // Leave Link signup off, so this is a plain card.
        if let signup = form.getAllUnwrappedSubElements().compactMap({ $0 as? LinkInlineSignupElement }).first {
            signup.viewModel.saveCheckboxChecked = false
        }
        guard case .new = formViewController.selectedPaymentOption else {
            XCTFail(
                "Precondition: expected a new card, got \(String(describing: formViewController.selectedPaymentOption)); "
                + "fields: \(linkedBankDroppedFieldLabels(in: form))"
            )
            return
        }
        let elementsSessionIDBeforeContinue = checkout.session.elementsSession.sessionID

        // When the customer taps Continue, which sends the card's billing address to Checkout for tax
        try await linkedBankDroppedTapContinue(formViewController)
        XCTAssertNotEqual(
            checkout.session.elementsSession.sessionID,
            elementsSessionIDBeforeContinue,
            "Precondition: Continue should have updated the session's tax region"
        )

        // Then the card stays selected through the same rebuild
        XCTAssertEqual(embedded.embeddedPaymentMethodsView.selectedRowButton?.type, .new(paymentMethodType: .stripe(.card)))
        XCTAssertEqual(checkout.session.paymentOption?.label, "Visa")
        XCTAssertEqual(checkout.session.paymentOption?.sublabel, "•••• 4242")
    }

    /// Creates a live Checkout Session with a fresh customer email and opens the given row's form in its embedded
    /// Payment Element, as a customer tapping the row would. With `automaticTax`, the forms are also prefilled with a
    /// default US billing address.
    private func linkedBankDroppedOpenForm(
        types: [String],
        automaticTax: Bool,
        rowType: PaymentSheet.PaymentMethodType
    ) async throws -> (CheckoutElementsController, EmbeddedPaymentElement, EmbeddedFormViewController) {
        // Start without a Link account left over from another test.
        LinkAccountContext.shared.account = nil
        // ...and without a guest's last selection (e.g. Link) saved on this device by another test, which the
        // Payment Element would otherwise select by default.
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        addTeardownBlock { @MainActor in
            LinkAccountContext.shared.account = nil
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        }

        // A known email makes the bank rows available. A fresh one is a new Link consumer.
        let email = "link_repro+\(UUID().uuidString)@example.com"
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: types,
            automaticTax: automaticTax,
            customerEmail: email
        )
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSession.publishableKey)
        configuration.paymentElement = .init()
        if automaticTax {
            // Billing-based tax needs a full US address, so prefill one, as the Checkout Playground's
            // "Billing Details" default does. Otherwise the forms would show address autocomplete.
            var billingDetails = CheckoutElementsController.Configuration.Defaults.BillingDetails()
            billingDetails.name = "Jenny Rosen"
            billingDetails.address = .init(
                country: "US",
                line1: "510 Townsend St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94103"
            )
            configuration.defaults.billingDetails = billingDetails
        }
        let checkout = try await CheckoutElementsController(configuration: configuration)

        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        embedded.presentingViewController = UIViewController()
        let rowTypes = embedded.embeddedPaymentMethodsView.rowButtons.map(\.type)
        let row = try XCTUnwrap(
            embedded.embeddedPaymentMethodsView.rowButtons.first { $0.type == .new(paymentMethodType: rowType) },
            "Expected a \(rowType) row for \(types); rows: \(rowTypes)"
        )
        embedded.embeddedPaymentMethodsView.didTap(rowButton: row)
        let formViewController = try XCTUnwrap(embedded.selectedFormViewController)

        // The email field, if shown, may not be prefilled with the session's email.
        if let emailField = formViewController.form.getTextFieldElement("Email"), emailField.text.isEmpty {
            emailField.setText(email)
        }
        return (checkout, embedded, formViewController)
    }

    /// Links a bank in an open Instant Bank Payments or Link Card Brand form.
    ///
    /// This stands in for the Financial Connections sheet, which unit tests can't drive. Its result is the same
    /// shape the sheet returns: a payment method created for this one payment, which is not one of the customer's
    /// saved payment methods.
    private func linkedBankDroppedLinkBank(in formViewController: EmbeddedFormViewController, linkMode: LinkMode) throws {
        let bankForm = try XCTUnwrap(
            formViewController.form.getAllUnwrappedSubElements().compactMap { $0 as? InstantDebitsPaymentMethodElement }.first
                ?? formViewController.form as? InstantDebitsPaymentMethodElement,
            "Expected a Link bank form"
        )
        let paymentMethodID = "pm_linked_bank_\(UUID().uuidString.prefix(8))"
        var linkBankPaymentMethod = LinkBankPaymentMethod(id: paymentMethodID)
        linkBankPaymentMethod._allResponseFieldsStorage = NonEncodableParameters(storage: [
            "id": paymentMethodID,
            "object": "payment_method",
            // Financial Connections creates a `link` payment method in Link payment method mode, and shares the
            // bank as a `card` payment method in Link Card Brand mode.
            "type": linkMode == .linkCardBrand ? "card" : "link",
            "created": Int(Date().timeIntervalSince1970),
            "livemode": false,
        ])
        bankForm.setLinkedBank(
            InstantDebitsLinkedBank(
                paymentMethod: linkBankPaymentMethod,
                bankName: "StripeBank",
                last4: "6789",
                linkMode: linkMode,
                incentiveEligible: false,
                linkAccountSessionId: "fcsess_linked_bank_repro"
            )
        )

        guard case .saved = formViewController.selectedPaymentOption else {
            XCTFail(
                "Precondition: the linked bank should complete the form, got \(String(describing: formViewController.selectedPaymentOption)); "
                + "fields: \(linkedBankDroppedFieldLabels(in: formViewController.form))"
            )
            throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
        }
    }

    /// Lists the form's text and dropdown field labels, to explain an incomplete form.
    private func linkedBankDroppedFieldLabels(in form: Element) -> [String] {
        return form.getAllUnwrappedSubElements().compactMap { element in
            if let textField = element as? TextFieldElement {
                return "\(textField.configuration.label)=\(textField.text)"
            } else if let dropdown = element as? DropdownFieldElement {
                return "\(dropdown.label ?? "dropdown")=\(dropdown.selectedItem.rawData)"
            }
            return nil
        }
    }

    /// Taps the form's Continue button and waits until the form hands its payment option to the Payment Element.
    private func linkedBankDroppedTapContinue(_ formViewController: EmbeddedFormViewController) async throws {
        XCTAssertNil(formViewController.paymentOptionToRestoreOnCancellation)
        formViewController.didTapPrimaryButton()
        // Continue records the accepted payment option right before telling the Payment Element.
        let deadline = Date().addingTimeInterval(30)
        while formViewController.paymentOptionToRestoreOnCancellation == nil, Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertNotNil(formViewController.paymentOptionToRestoreOnCancellation, "Timed out waiting for Continue to finish")
    }

    /// Asserts that the embedded bank row is still selected with its linked bank, and that Checkout's payment option
    /// is that bank.
    private func linkedBankDroppedAssertBankSelected(
        checkout: CheckoutElementsController,
        embedded: EmbeddedPaymentElement,
        rowType: PaymentSheet.PaymentMethodType,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            embedded.embeddedPaymentMethodsView.selectedRowButton?.type,
            .new(paymentMethodType: rowType),
            "The bank row should stay selected (\(context))",
            file: file,
            line: line
        )
        if case .saved(_, let confirmParams) = embedded._paymentOption {
            XCTAssertEqual(confirmParams?.instantDebitsLinkedBank?.last4, "6789", "(\(context))", file: file, line: line)
        } else {
            XCTFail(
                "The Payment Element should still have the linked bank, got \(String(describing: embedded._paymentOption)) (\(context))",
                file: file,
                line: line
            )
        }
        XCTAssertEqual(
            checkout.session.paymentOption?.sublabel,
            "••••6789",
            "Checkout's payment option should be the linked bank, got \(String(describing: checkout.session.paymentOption?.label)) (\(context))",
            file: file,
            line: line
        )
    }

    // MARK: - Native Link card picked in the Payment Element sheet, then a session update

    func testLiveHorizontalSheetKeepsNativeLinkCardAfterLocalShippingUpdate() async throws {
        // Given a live card + Link Checkout Session shown in the Payment Element sheet with its default layout,
        // which is horizontal for two payment method types. Without Apple Pay, Link is a button in the sheet's header.
        HTTPStubs.removeAllStubs()
        // ...and a customer who opens the sheet, taps Link, picks their Mastercard (not their default Visa)
        // in native Link, and taps Continue
        let selection = try await horizontalLinkSelectionPickMastercard(layout: .automatic, applePay: false)
        XCTAssertTrue(
            selection.paymentElement.paymentSheetFlowController.viewController is PaymentSheetFlowControllerViewController,
            "Precondition: the sheet should use the horizontal layout"
        )

        // When an unrelated, local-only shipping change updates the session, which rebuilds the sheet
        try await selection.checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then Checkout still has the Mastercard as its payment option, and confirming pays with it
        try await horizontalLinkSelectionAssertMastercardKeptAndPaid(selection)
    }

    func testLiveHorizontalSheetWithApplePayKeepsNativeLinkCardAfterLocalShippingUpdate() async throws {
        // Given the same flow, but with Apple Pay on, so Link is a cell in the sheet's carousel next to Apple Pay
        HTTPStubs.removeAllStubs()
        let selection = try await horizontalLinkSelectionPickMastercard(layout: .automatic, applePay: true)
        XCTAssertTrue(
            selection.paymentElement.paymentSheetFlowController.viewController is PaymentSheetFlowControllerViewController,
            "Precondition: the sheet should use the horizontal layout"
        )

        // When the same local-only shipping change updates the session
        try await selection.checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then Checkout still has the Mastercard as its payment option, and confirming pays with it
        try await horizontalLinkSelectionAssertMastercardKeptAndPaid(selection)
    }

    func testLiveVerticalSheetKeepsNativeLinkCardAfterLocalShippingUpdate() async throws {
        // Given the same flow as above without Apple Pay, but with the Payment Element sheet in the vertical layout
        HTTPStubs.removeAllStubs()
        let selection = try await horizontalLinkSelectionPickMastercard(layout: .vertical, applePay: false)
        XCTAssertTrue(
            selection.paymentElement.paymentSheetFlowController.viewController is PaymentSheetVerticalViewController,
            "Precondition: the sheet should use the vertical layout"
        )

        // When the same local-only shipping change updates the session
        try await selection.checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then, as a control, the vertical sheet keeps the Mastercard through the rebuild, and confirming pays with it
        try await horizontalLinkSelectionAssertMastercardKeptAndPaid(selection)
    }

    /// The state after a customer picked their Mastercard in native Link from the Payment Element sheet.
    private struct HorizontalLinkSelection {

        let checkout: CheckoutElementsController
        let paymentElement: PaymentElement
        let presenter: UIViewController
        let requestLog: HorizontalLinkSelectionRequestLog
        let checkoutSessionID: String
        /// The Link payment details IDs of the customer's default Visa and of the Mastercard they picked.
        let visaPaymentDetailsID: String
        let mastercardPaymentDetailsID: String
    }

    /// Records the path and body of every API request without stubbing it, so requests still reach the live backend.
    private final class HorizontalLinkSelectionRequestLog: @unchecked Sendable {

        private let lock = NSLock()
        private var requests: [(path: String, body: Data?)] = []

        func append(path: String, body: Data?) {
            lock.lock()
            defer { lock.unlock() }
            // OHHTTPStubs can ask about the same request more than once. Keep one entry per request.
            if let last = requests.last, last.path == path, last.body == body {
                return
            }
            requests.append((path, body))
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return requests.count
        }

        func requests(from index: Int) -> [(path: String, body: Data?)] {
            lock.lock()
            defer { lock.unlock() }
            return Array(requests.dropFirst(index))
        }
    }

    /// Creates a live card + Link Checkout Session for a new Link customer with a default Visa and a Mastercard,
    /// presents the Payment Element sheet, taps Link, picks the Mastercard in native Link, and taps Continue.
    /// Returns once the sheet has closed and Checkout reports the Mastercard as its payment option.
    private func horizontalLinkSelectionPickMastercard(
        layout: PaymentSheet.PaymentMethodLayout,
        applePay: Bool
    ) async throws -> HorizontalLinkSelection {
        // Native Link. The US playground merchant reports link_mobile_use_attestation_endpoints=false to the
        // unit-test host app, so use the override that the Checkout Playground's default "Native" Link mode sets.
        let originalNativeLinkOverride = PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride
        let originalPublishableKey = STPAPIClient.shared.publishableKey
        let originalLastSelectedPaymentMethods = UserDefaults.standard.customerToLastSelectedPaymentMethod
        PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = true
        // Start without a Link account left over from another test, and without a guest's last selection saved on
        // this device. Tapping Link in the carousel saves Link as the guest's local default.
        LinkAccountContext.shared.account = nil
        CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: nil)
        addTeardownBlock { @MainActor in
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = originalNativeLinkOverride
            STPAPIClient.shared.publishableKey = originalPublishableKey
            UserDefaults.standard.customerToLastSelectedPaymentMethod = originalLastSelectedPaymentMethods
            LinkAccountContext.shared.account = nil
        }
        let requestLog = horizontalLinkSelectionRecordRequests()
        let presenter = try await horizontalLinkSelectionMakePresenter()

        // A live card + Link Checkout Session whose email belongs to a new Link consumer
        let email = "link_repro+\(UUID().uuidString)@example.com"
        let checkoutSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            types: ["card", "link"],
            customerEmail: email
        )
        // Use the shared API client everywhere, as the Checkout Playground does.
        STPAPIClient.shared.publishableKey = checkoutSession.publishableKey
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSession.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        if applePay {
            configuration.applePayMerchantId = "merchant.com.stripe.umbrella.test"
        }
        var paymentElementConfiguration = PaymentElement.Configuration()
        paymentElementConfiguration.paymentMethodLayout = layout
        configuration.paymentElement = paymentElementConfiguration
        let checkout = try await CheckoutElementsController(configuration: configuration)
        XCTAssertEqual(checkout.session.elementsSession.linkSettings?.linkMode, .linkPaymentMethod)
        let paymentElement = checkout.getPaymentElement()
        let flowController = paymentElement.paymentSheetFlowController
        if applePay {
            guard case .applePay? = flowController.internalPaymentOption else {
                XCTFail("Precondition: the sheet should offer Apple Pay and select it by default, got \(String(describing: flowController.internalPaymentOption))")
                throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
            }
        } else {
            XCTAssertNil(flowController.internalPaymentOption, "Precondition: the sheet should start with nothing selected")
        }

        // ...and the customer has a Link account with a default Visa and a second card, a Mastercard.
        // Signing up here stands in for logging in to Link with a one-time code: either way, the account is verified.
        let linkAccount = try XCTUnwrap(LinkAccountContext.shared.account, "Checkout should look up the session's email in Link")
        XCTAssertEqual(linkAccount.email, email)
        XCTAssertEqual(linkAccount.sessionState, .requiresSignUp, "Precondition: the email should be new to Link")
        let phoneNumber = try XCTUnwrap(PhoneNumber(number: "2015550123", countryCode: "US"))
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            linkAccount.signUp(
                with: phoneNumber,
                legalName: nil,
                countryCode: "US",
                consentAction: .checkbox_v0,
                analyticsHelper: LinkAnalyticsHelper()
            ) { result in
                continuation.resume(with: result)
            }
        }
        XCTAssertEqual(linkAccount.sessionState, .verified)
        let visa = try await horizontalLinkSelectionSaveCard("4242424242424242", isDefault: true, to: linkAccount)
        let mastercard = try await horizontalLinkSelectionSaveCard("5555555555554444", isDefault: false, to: linkAccount)

        // When the customer opens the Payment Element sheet
        var didCloseSheet = false
        let presentation = Task { @MainActor in
            await paymentElement.present(from: presenter)
            didCloseSheet = true
        }
        let sheetContent = flowController.viewController
        try await horizontalLinkSelectionWait(until: "the Payment Element sheet is presented") {
            presenter.presentedViewController is PaymentSheetContainer
                && presenter.presentedViewController?.isBeingPresented == false
                && sheetContent.viewIfLoaded?.window != nil
        }

        // ...and taps Link: the Link cell in the carousel when Apple Pay is shown, or the Link button in the header
        if applePay {
            let horizontalSheet = try XCTUnwrap(sheetContent as? PaymentSheetFlowControllerViewController)
            let carousel = horizontalSheet.savedPaymentOptionsViewController
            // The carousel shows "+ Add", Apple Pay, and Link, in that order.
            XCTAssertEqual(carousel.collectionView.numberOfItems(inSection: 0), 3, "Precondition: expected + Add, Apple Pay, and Link")
            let linkIndexPath = IndexPath(item: 2, section: 0)
            carousel.collectionView.selectItem(at: linkIndexPath, animated: false, scrollPosition: [])
            carousel.collectionView(carousel.collectionView, didSelectItemAt: linkIndexPath)
        } else {
            let linkButton = try XCTUnwrap(
                horizontalLinkSelectionFirstSubview(of: PayWithLinkButton.self, in: sheetContent.view),
                "The sheet should show a Link button in its header"
            )
            linkButton.sendActions(for: .touchUpInside)
        }

        // ...and, in the native Link wallet, picks the Mastercard and taps Continue
        try await horizontalLinkSelectionWait(until: "the Link wallet loads", timeout: 30) {
            self.horizontalLinkSelectionPresentedWallet(from: presenter)?.viewModel.paymentMethods.count == 2
        }
        let wallet = try XCTUnwrap(horizontalLinkSelectionPresentedWallet(from: presenter))
        XCTAssertEqual(wallet.viewModel.selectedPaymentMethod?.stripeID, visa.stripeID, "Precondition: the wallet should start on the default Visa")
        let mastercardIndex = try XCTUnwrap(wallet.viewModel.paymentMethods.firstIndex { $0.stripeID == mastercard.stripeID })
        let picker = try XCTUnwrap(horizontalLinkSelectionFirstSubview(of: LinkPaymentMethodPicker.self, in: wallet.view))
        wallet.paymentMethodPicker(picker, didSelectIndex: mastercardIndex)
        XCTAssertEqual(wallet.viewModel.selectedPaymentMethod?.stripeID, mastercard.stripeID)
        // A card just saved to Link hasn't had its CVC checked yet, so the wallet asks for it. Type it in.
        if wallet.viewModel.shouldRecollectCardCVC {
            let cvcField = try XCTUnwrap(
                horizontalLinkSelectionAllSubviews(of: UITextField.self, in: wallet.view).first { $0.accessibilityIdentifier == "CVC" },
                "The wallet should show a CVC field"
            )
            cvcField.text = "123"
            cvcField.sendActions(for: .editingChanged)
            XCTAssertEqual(wallet.viewModel.cvc, "123", "Precondition: the wallet should accept the CVC")
        }
        let continueButton = try XCTUnwrap(horizontalLinkSelectionFirstSubview(of: ConfirmButton.self, in: wallet.view))
        continueButton.sendActions(for: .touchUpInside)

        // Continue closes Link and the sheet, and Checkout gets the Mastercard as its payment option.
        let closeDeadline = Date().addingTimeInterval(15)
        while !(didCloseSheet && presenter.presentedViewController == nil), Date() < closeDeadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        guard didCloseSheet && presenter.presentedViewController == nil else {
            // Describe what's on screen, to explain why the sheet didn't close.
            let presented = presenter.presentedViewController
            let contentStack = (presented as? any PaymentSheetContainer)?.contentStack.map { "\(type(of: $0))" } ?? []
            let screenshot = UIGraphicsImageRenderer(bounds: presenter.view.bounds).image { _ in
                presenter.view.window?.drawHierarchy(in: presenter.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: screenshot)
            attachment.name = "Screen after tapping Continue in Link"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTFail(
                """
                The sheet didn't close after Continue. didCloseSheet=\(didCloseSheet), \
                presented=\(presented.map { "\(type(of: $0))" } ?? "nil"), contentStack=\(contentStack), \
                isBeingDismissed=\(presented?.isBeingDismissed ?? false), \
                linkConfirmOption=\(String(describing: flowController.viewController.linkConfirmOption)), \
                walletButton=\(String(describing: continueButton.status)), \
                labels=\(presented.map { horizontalLinkSelectionVisibleLabelTexts(in: $0.view) } ?? [])
                """
            )
            throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
        }
        await presentation.value
        let selection = HorizontalLinkSelection(
            checkout: checkout,
            paymentElement: paymentElement,
            presenter: presenter,
            requestLog: requestLog,
            checkoutSessionID: checkoutSession.id,
            visaPaymentDetailsID: visa.stripeID,
            mastercardPaymentDetailsID: mastercard.stripeID
        )
        XCTAssertTrue(
            horizontalLinkSelectionDescribe(checkout.session.paymentOption).contains("4444"),
            "Precondition: Checkout should have the Mastercard, got \(horizontalLinkSelectionDescribe(checkout.session.paymentOption))"
        )
        XCTAssertEqual(
            horizontalLinkSelectionPickedPaymentDetailsID(in: paymentElement),
            mastercard.stripeID,
            "Precondition: the sheet should hold the Mastercard picked in Link"
        )
        return selection
    }

    /// Asserts that Checkout and the sheet still have the Mastercard, then confirms and asserts that the payment
    /// completes with the Mastercard.
    private func horizontalLinkSelectionAssertMastercardKeptAndPaid(
        _ selection: HorizontalLinkSelection,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let checkout = selection.checkout
        XCTAssertTrue(
            horizontalLinkSelectionDescribe(checkout.session.paymentOption).contains("4444"),
            "After the update, Checkout's payment option is \(horizontalLinkSelectionDescribe(checkout.session.paymentOption)), not the Mastercard",
            file: file,
            line: line
        )
        XCTAssertEqual(
            horizontalLinkSelectionPickedPaymentDetailsID(in: selection.paymentElement),
            selection.mastercardPaymentDetailsID,
            "After the update, the sheet's selection is \(String(describing: selection.paymentElement.paymentSheetFlowController.internalPaymentOption))",
            file: file,
            line: line
        )

        // ...and when the customer taps the merchant's Buy button, Checkout pays with the Mastercard
        let firstRequestIndex = selection.requestLog.count
        var result: CheckoutElementsController.ConfirmResult?
        let confirmation = Task { @MainActor in
            result = await checkout.confirm(from: selection.presenter)
        }
        try await horizontalLinkSelectionWait(until: "the confirmation finishes or opens Link", timeout: 30) {
            result != nil || self.horizontalLinkSelectionPresentedWallet(from: selection.presenter) != nil
        }
        // If confirming opens the Link wallet instead of paying, note which card it offers, then close it,
        // as a customer who expected to pay with the Mastercard would.
        var reopenedWalletCard: String?
        if result == nil, let wallet = horizontalLinkSelectionPresentedWallet(from: selection.presenter) {
            let selectedID = wallet.viewModel.selectedPaymentMethod?.stripeID
            reopenedWalletCard = selectedID == selection.visaPaymentDetailsID ? "the default Visa" : (selectedID ?? "nothing")
            wallet.navigationBar.delegate?.sheetNavigationBarDidClose(wallet.navigationBar)
        }
        try await horizontalLinkSelectionWait(until: "the confirmation finishes", timeout: 30) {
            result != nil && selection.presenter.presentedViewController == nil
        }
        await confirmation.value
        let requests = selection.requestLog.requests(from: firstRequestIndex)
        XCTAssertNil(
            reopenedWalletCard,
            "Buy reopened the Link wallet with \(reopenedWalletCard ?? "") selected instead of paying with the Mastercard",
            file: file,
            line: line
        )
        guard case .completed = try XCTUnwrap(result) else {
            XCTFail(
                "Expected the payment to complete, got \(horizontalLinkSelectionDescribe(result)). Requests: \(requests.map(\.path))",
                file: file,
                line: line
            )
            return
        }
        // The Mastercard's Link payment details ID goes to the backend when paying with it.
        let confirmRequests = requests.filter { $0.path.hasSuffix("/checkout_client/\(selection.checkoutSessionID)/confirm") }
        XCTAssertFalse(confirmRequests.isEmpty, "No /confirm request was recorded", file: file, line: line)
        XCTAssertTrue(
            requests.contains { request in
                request.body.flatMap { String(data: $0, encoding: .utf8) }?.contains(selection.mastercardPaymentDetailsID) ?? false
            },
            "The payment didn't use the Mastercard's Link payment details. Requests: \(requests.map(\.path))",
            file: file,
            line: line
        )
    }

    /// Starts recording API requests. The test block never matches, so nothing is stubbed.
    private func horizontalLinkSelectionRecordRequests() -> HorizontalLinkSelectionRequestLog {
        let requestLog = HorizontalLinkSelectionRequestLog()
        HTTPStubs.stubRequests(passingTest: { request in
            if let url = request.url, url.host == "api.stripe.com" {
                requestLog.append(path: url.path, body: request.ohhttpStubs_httpBody)
            }
            return false
        }, withStubResponse: { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        })
        addTeardownBlock {
            HTTPStubs.removeAllStubs()
        }
        return requestLog
    }

    /// Returns a view controller in a visible key window, for presenting the sheets and running the passive captcha.
    private func horizontalLinkSelectionMakePresenter() async throws -> UIViewController {
        // A cold test-host launch may still be connecting its window scene.
        let sceneConnected = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            UIApplication.shared.connectedScenes.contains { $0 is UIWindowScene }
        }, object: nil)
        await fulfillment(of: [sceneConnected], timeout: 5)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let presenter = UIViewController()
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        addTeardownBlock { @MainActor in
            presenter.dismiss(animated: false)
            window.isHidden = true
        }
        return presenter
    }

    /// Saves a test card to the verified Link account and returns its Link payment details.
    private func horizontalLinkSelectionSaveCard(
        _ number: String,
        isDefault: Bool,
        to linkAccount: PaymentSheetLinkAccount
    ) async throws -> ConsumerPaymentDetails {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = number
        cardParams.expMonth = 12
        cardParams.expYear = 2040
        cardParams.cvc = "123"
        let billingAddress = STPPaymentMethodAddress()
        billingAddress.country = "US"
        billingAddress.postalCode = "65432"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = billingAddress
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        return try await withCheckedThrowingContinuation { continuation in
            linkAccount.createPaymentDetails(with: paymentMethodParams, isDefault: isDefault) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Returns the native Link wallet if it's presented from `presenter` and done presenting.
    private func horizontalLinkSelectionPresentedWallet(from presenter: UIViewController) -> PayWithLinkViewController.WalletViewController? {
        guard let sheet = presenter.presentedViewController as? any PaymentSheetContainer, !sheet.isBeingPresented else {
            return nil
        }
        return sheet.contentStack.first as? PayWithLinkViewController.WalletViewController
    }

    /// Returns the Link payment details ID in the sheet's selection, if it's a card picked in native Link.
    private func horizontalLinkSelectionPickedPaymentDetailsID(in paymentElement: PaymentElement) -> String? {
        guard case .link(.withPaymentDetails(_, _, let paymentDetails, _, _))? = paymentElement.paymentSheetFlowController.internalPaymentOption else {
            return nil
        }
        return paymentDetails.stripeID
    }

    /// Describes a Checkout payment option for assertions and failure messages, e.g. "link Link Mastercard •••• 4444".
    private func horizontalLinkSelectionDescribe(_ paymentOption: CheckoutElementsController.Session.PaymentOptionDisplayData?) -> String {
        guard let paymentOption else {
            return "nil"
        }
        return [paymentOption.paymentMethodType, paymentOption.label, paymentOption.sublabel].compactMap { $0 }.joined(separator: " ")
    }

    /// Describes a confirmation result, including the backend's error message when it failed.
    private func horizontalLinkSelectionDescribe(_ result: CheckoutElementsController.ConfirmResult?) -> String {
        guard let result else {
            return "nil"
        }
        guard case .failed(let error) = result else {
            return "\(result)"
        }
        let message = (error as NSError).userInfo[STPError.errorMessageKey].map { "\($0)" } ?? error.nonGenericDescription
        return "failed: \(message)"
    }

    /// Returns the text of every label in a view hierarchy that isn't hidden.
    private func horizontalLinkSelectionVisibleLabelTexts(in view: UIView) -> [String] {
        guard !view.isHidden else {
            return []
        }
        let ownText = (view as? UILabel)?.text.map { [$0] } ?? []
        return ownText + view.subviews.flatMap { horizontalLinkSelectionVisibleLabelTexts(in: $0) }
    }

    /// Returns every view of the given type in a view hierarchy.
    private func horizontalLinkSelectionAllSubviews<T: UIView>(of type: T.Type, in view: UIView) -> [T] {
        let ownMatch = (view as? T).map { [$0] } ?? []
        return ownMatch + view.subviews.flatMap { horizontalLinkSelectionAllSubviews(of: type, in: $0) }
    }

    /// Returns the first view of the given type in a view hierarchy, searching breadth first.
    private func horizontalLinkSelectionFirstSubview<T: UIView>(of type: T.Type, in view: UIView) -> T? {
        var pending = [view]
        while !pending.isEmpty {
            let current = pending.removeFirst()
            if let match = current as? T {
                return match
            }
            pending.append(contentsOf: current.subviews)
        }
        return nil
    }

    /// Polls until `condition` is true, failing the test if it takes longer than `timeout` seconds.
    private func horizontalLinkSelectionWait(
        until description: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for \(description)", file: file, line: line)
                throw NSError(domain: "CheckoutLinkBugReproTests", code: 0)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
