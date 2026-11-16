//
//  CheckoutLinkInlineSignupTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 11/13/26.
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

extension CheckoutTests {

    func testLiveLinkInlineSignupInPassthroughModeSavesCardWhenCustomerOptsIn() async throws {
        // Given a returning customer whose email has no Link account yet
        HTTPStubs.removeAllStubs()
        let linkEmail = "mobile-payments-sdk-ci+\(UUID().uuidString)@stripe.com"
        let keyResponse = try await customerLogicBackendRequest(endpoint: "publishable_key?merchant=US")
        let apiClient = STPAPIClient(publishableKey: try XCTUnwrap(keyResponse["publishable_key"] as? String))
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(email: linkEmail)

        // Link signup and Checkout write process-wide state, so restore it however the test ends
        let previousLinkAccount = LinkAccountContext.shared.account
        let customerHadUsedLink = UserDefaults.standard.customerHasUsedLink
        defer {
            LinkAccountContext.shared.account = previousLinkAccount
            UserDefaults.standard.customerHasUsedLink = customerHadUsedLink
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID)
        }

        // ...on a live card-only session that offers saving new cards to that customer
        let sessionResponse = try await customerLogicBackendRequest(endpoint: "create_checkout_session", parameters: [
            "merchant": "US",
            "stripe_version": STPTestingAPIClient.checkoutMobileElementsAPISettings,
            "request_params": [
                "ui_mode": "mobile_elements",
                "currency": "usd",
                "allowed_payment_method_types": ["card"],
                "customer": customerID,
                "items": [
                    [
                        "type": "one_time_price",
                        "one_time_price": [
                            "items": [
                                [
                                    "price_data": [
                                        "currency": "usd",
                                        "unit_amount": 2000,
                                        "product_data": ["name": "Customer logic repro"],
                                    ],
                                    "quantity": 1,
                                ],
                            ],
                        ],
                    ],
                ],
                "saved_payment_method_options": [
                    "payment_method_save": "enabled",
                    "allow_redisplay_filters": ["always", "limited", "unspecified"],
                ],
            ],
        ])
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: try XCTUnwrap(sessionResponse["client_secret"] as? String),
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = apiClient
        configuration.paymentElement = .init()
        let checkout = try await CheckoutElementsController(configuration: configuration)
        XCTAssertEqual(checkout.session.customerId, customerID, "The session must belong to the new Customer")
        XCTAssertEqual(checkout.session.savedPaymentMethodsOfferSave?.enabled, true, "The session must offer saving new cards")
        XCTAssertTrue(checkout.session.customer?.paymentMethods.isEmpty ?? true, "The new Customer must start without saved cards")

        // ...where Link runs in passthrough mode, so Link shares a card PaymentMethod back to Checkout
        let elementsSession = checkout.session.elementsSession
        XCTAssertTrue(
            elementsSession.linkPassthroughModeEnabled,
            "The playground merchant must use Link passthrough mode; link settings: \(String(describing: elementsSession.linkSettings))"
        )
        // ...the Link signup opt-in experiment, which hides the merchant save checkbox, is off
        XCTAssertFalse(elementsSession.linkSignupOptInFeatureEnabled, "The Link signup opt-in experiment must be off")
        // ...and signup uses the regular consumer endpoints, which work without App Attest in the simulator
        XCTAssertNotEqual(elementsSession.linkSettings?.useAttestationEndpoints, true, "Link must not require attestation endpoints")
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        let signupDisabledReasons = PaymentSheet.linkSignupDisabledReasons(
            elementsSession: elementsSession,
            configuration: embedded.configuration
        )
        XCTAssertTrue(signupDisabledReasons.isEmpty, "Link inline signup must be enabled, but is disabled because \(signupDisabledReasons)")
        // ...and Checkout's load-time Link lookup found the customer's email unregistered
        XCTAssertEqual(
            LinkAccountContext.shared.account?.email.lowercased(),
            linkEmail.lowercased(),
            "Checkout should look up the customer's email in Link while loading"
        )
        XCTAssertEqual(LinkAccountContext.shared.account?.isRegistered, false, "The fresh email must not have a Link account")
        guard elementsSession.linkPassthroughModeEnabled,
              !elementsSession.linkSignupOptInFeatureEnabled,
              elementsSession.linkSettings?.useAttestationEndpoints != true,
              signupDisabledReasons.isEmpty,
              LinkAccountContext.shared.account?.isRegistered == false else {
            return
        }

        // When the customer opens the new card form, enters a card, and checks the merchant's save checkbox
        let presentingViewController = UIViewController()
        embedded.presentingViewController = presentingViewController
        let cardRow = try XCTUnwrap(embedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        }, "The new card row must be shown")
        embedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let form = try XCTUnwrap(embedded.formCache[.stripe(.card)], "Tapping the card row should build the card form")
        let cardDetails = [
            ("Card number", "4242424242424242"),
            ("MM / YY", "1240"),
            ("CVC", "123"),
            ("ZIP", "94107"),
        ]
        for (label, text) in cardDetails {
            let field: TextFieldElement? = form.getTextFieldElement(label)
            try XCTUnwrap(field, "The card form is missing its \(label) field").setText(text)
        }
        let saveCheckbox = try XCTUnwrap(
            form.getCheckboxElement(startingWith: "Save"),
            "The card form must show the merchant's save checkbox"
        )
        saveCheckbox.isSelected = true

        // ...and enters a phone number in Link's inline signup fields, which show beside that checkbox
        let inlineSignupElement = try XCTUnwrap(
            form.getAllUnwrappedSubElements().compactMap { $0 as? LinkInlineSignupElement }.first,
            "The card form must include Link inline signup"
        )
        XCTAssertEqual(
            inlineSignupElement.viewModel.mode,
            .textFieldsOnlyPhoneFirst,
            "With the save checkbox shown and the email prefilled, Link signup should show only text fields"
        )
        func findSignupView(in view: UIView) -> LinkInlineSignupView? {
            (view as? LinkInlineSignupView) ?? view.subviews.lazy.compactMap { findSignupView(in: $0) }.first
        }
        let signupView = try XCTUnwrap(findSignupView(in: inlineSignupElement.view), "The inline signup view must be on screen")
        signupView.phoneNumberElement.setPhoneNumber("3105551234")
        XCTAssertTrue(form.validationState.isValid, "The completed card form should be valid")
        guard form.validationState.isValid else { return }

        // ...and taps Continue, which hands Checkout a Link signup option that carries the save choice
        let formViewController = try XCTUnwrap(embedded.selectedFormViewController, "The card form should be presented")
        formViewController.didTapPrimaryButton()
        // Continue finishes after an async billing sync, then records the option it accepted
        let continueDeadline = Date().addingTimeInterval(15)
        var continuedSignupParams: IntentConfirmParams?
        repeat {
            if case .link(.signUp(_, _, _, _, _, let intentConfirmParams)) = formViewController.paymentOptionToRestoreOnCancellation,
               !checkout.isUpdating {
                continuedSignupParams = intentConfirmParams
            } else {
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        } while continuedSignupParams == nil && Date() < continueDeadline
        let signupParams = try XCTUnwrap(
            continuedSignupParams,
            "Continue should leave a Link signup option selected, got \(String(describing: embedded._paymentOption))"
        )
        XCTAssertEqual(signupParams.saveForFutureUseCheckboxState, .selected, "The Link signup option must record the save choice")

        // ...and the merchant confirms, while a passive observer records the outgoing /confirm parameters.
        // The observer never stubs a response, so every request still reaches the live backend.
        let observedConfirmRequests = ObservedCheckoutConfirmRequests()
        let confirmObserver = HTTPStubs.stubRequests(passingTest: { [sessionID = checkout.session.id] request in
            if request.url?.path == "/v1/checkout_client/\(sessionID)/confirm" {
                observedConfirmRequests.record(request)
            }
            return false
        }, withStubResponse: { _ in HTTPStubsResponse() })
        defer { HTTPStubs.removeStub(confirmObserver) }
        STPAnalyticsClient.sharedClient._testLogHistory = []
        let result = await checkout.confirm(from: presentingViewController)
        guard case .completed = result else {
            return XCTFail("Expected the live confirmation to complete, got \(result)")
        }

        // Then the payment went through Link signup and passthrough sharing, rather than a fallback that sends card details
        let events = STPAnalyticsClient.sharedClient._testLogHistory.compactMap { $0["event"] as? String }
        XCTAssertTrue(events.contains("link.signup.complete"), "Link signup must succeed; events: \(events)")
        let confirmParameters = try XCTUnwrap(observedConfirmRequests.latestParameters, "The /confirm request body must be observed")
        let sharedPaymentMethodID = try XCTUnwrap(
            confirmParameters["payment_method"],
            "Confirm should use the PaymentMethod Link shared back; params: \(confirmParameters.keys.sorted())"
        )
        XCTAssertTrue(sharedPaymentMethodID.hasPrefix("pm_"), "Link should share back a card PaymentMethod")
        XCTAssertNil(confirmParameters["payment_method_data[type]"], "The share-success path must not send raw card details")

        // ...and /confirm carries the customer's choice to save the card to the merchant
        XCTAssertEqual(
            confirmParameters["collected_information[save_payment_method]"],
            "true",
            "The customer checked the save box, but /confirm sent: \(confirmParameters.keys.sorted())"
        )

        // ...so the shared card is attached to the Customer, as a later session for that Customer shows
        let followUpSession = try await STPTestingAPIClient.shared.createCheckoutSession(
            customerID: customerID,
            savedPaymentMethodAllowRedisplayFilters: ["always", "limited", "unspecified"]
        )
        let saveDeadline = Date().addingTimeInterval(15)
        var savedPaymentMethods: [STPPaymentMethod] = []
        repeat {
            savedPaymentMethods = try await apiClient.initCheckoutSession(
                checkoutSessionId: followUpSession.id,
                clientSecret: followUpSession.clientSecret,
                adaptivePricingAllowed: false
            ).customer?.paymentMethods ?? []
            if savedPaymentMethods.isEmpty {
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        } while savedPaymentMethods.isEmpty && Date() < saveDeadline
        XCTAssertEqual(
            savedPaymentMethods.map(\.stripeId),
            [sharedPaymentMethodID],
            "The card the customer chose to save must be attached to their Customer"
        )
    }
}

/// Records Checkout `/confirm` request parameters from an OHHTTPStubs test block, which runs off the main thread.
private final class ObservedCheckoutConfirmRequests: @unchecked Sendable {

    private let lock = NSLock()
    private var parameters: [[String: String]] = []

    var latestParameters: [String: String]? {
        lock.lock()
        defer { lock.unlock() }
        return parameters.last
    }

    func record(_ request: URLRequest) {
        // Read OHHTTPStubs' copy of the body rather than the body stream, which the live request still needs
        guard let url = request.url, let body = request.ohhttpStubs_httpBody else {
            return
        }
        var bodyOnlyRequest = URLRequest(url: url)
        bodyOnlyRequest.httpBody = body
        let requestParameters = RequestBodyTestHelpers.formEncodedBodyParams(from: bodyOnlyRequest)
        lock.lock()
        defer { lock.unlock() }
        parameters.append(requestParameters)
    }
}
