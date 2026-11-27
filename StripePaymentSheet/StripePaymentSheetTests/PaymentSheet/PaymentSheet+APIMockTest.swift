//
//  PaymentSheet+APIMockTest.swift
//  StripePaymentSheet
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable@_spi(InternalOnlyAPI) import StripeUICore

import OHHTTPStubs
import OHHTTPStubsSwift

@MainActor
final class PaymentSheetAPIMockTest: APIStubbedTestCase {
    enum MockJson {
        static let cardPaymentMethod = STPTestUtils.jsonNamed("CardPaymentMethod")!
        static let paymentIntent = STPTestUtils.jsonNamed("PaymentIntent")!
        static let setupIntent = STPTestUtils.jsonNamed("SetupIntent")!
    }

    enum MockParams {
        static let paymentIntentClientSecret = "pi_xxx_secret_xxx"
        static let publicKey = "pk_xxx"

        static func configuration(pk: String) -> PaymentSheet.Configuration {
            var config = PaymentSheet.Configuration()
            config.apiClient = STPAPIClient(publishableKey: pk)
            config.allowsDelayedPaymentMethods = true
            config.shippingDetails = {
                return .init(
                    address: .init(
                        country: "US",
                        line1: "Line 1"
                    ),
                    name: "Jane Doe",
                    phone: "5551234567"
                )
            }
            config.savePaymentMethodOptInBehavior = .requiresOptOut
            return config
        }

        static func configurationWithCustomer(pk: String) -> PaymentSheet.Configuration {
            var configuration = self.configuration(pk: pk)
            configuration.customer = .init(id: "id", ephemeralKeySecret: "ek")
            return configuration
        }

        static let cardPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: MockJson.cardPaymentMethod)!

        static func deferredPaymentIntentConfiguration(clientSecret: String) -> PaymentSheet.IntentConfiguration {
            .init(mode: .payment(amount: 123, currency: "USD", captureMethod: .automatic), paymentMethodTypes: ["card"]) { _, _ in return clientSecret }
        }
    }

    override func setUp() {
        super.setUp()

        stub { urlRequest in
            urlRequest.url?.absoluteString.contains("payment_methods") ?? false
        } response: { _ in
            return HTTPStubsResponse(jsonObject: MockJson.cardPaymentMethod, statusCode: 200, headers: nil)
        }

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents, pathComponents.count >= 3 else { return false }
            return pathComponents[2] == "payment_intents" && pathComponents.last != "confirm"
        } response: { request in
            var json = MockJson.paymentIntent

            // Mock that the PI requires confirmation if it's being fetched for a deferred PI
            if request.httpMethod == "GET" {
                json["status"] = "requires_confirmation"
                json["capture_method"] = "automatic"
            }

            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents, pathComponents.count >= 3 else { return false }
            return pathComponents[2] == "setup_intents" && pathComponents.last != "confirm"
        } response: { request in
            var json = MockJson.setupIntent
            // Mock that the PI requires confirmation if it's being fetched for a deferred PI
            if request.httpMethod == "GET" {
                json["status"] = "requires_confirmation"
            }

            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
    }

    func testIndiaCardPreservesOnSessionCardSetupOptions() {
        var json = MockJson.paymentIntent
        json["payment_method_options"] = [
            "card": ["setup_future_usage": "on_session"],
            "link": ["setup_future_usage": "off_session"],
        ]
        let intent = Intent.paymentIntent(STPPaymentIntent.decodedObject(fromAPIResponse: json)!)
        stubConfirmPaymentExpecting(isPaymentIntent: true, paymentMethodId: MockParams.cardPaymentMethod.stripeId, setupFutureUsage: "on_session")
        confirmReturningIndiaCard(intent: intent)
    }

    func testIndiaCardConfirmsSetupIntentWithSharedCard() {
        stubConfirmPaymentExpecting(isPaymentIntent: false, paymentMethodId: MockParams.cardPaymentMethod.stripeId)
        confirmReturningIndiaCard(intent: .setupIntent(STPSetupIntent.decodedObject(fromAPIResponse: MockJson.setupIntent)!))
    }

    private func confirmReturningIndiaCard(intent: Intent) {
        stubUnexpectedPaymentMethodCreation()
        stubLinkShareExpecting(consumerSessionClientSecret: "cs_xxx", paymentMethodID: "pd_india", expectedType: "card")
        stubLinkLogout(consumerSessionClientSecret: "cs_xxx")
        let configuration = MockParams.configurationWithCustomer(pk: MockParams.publicKey)
        let account = PaymentSheetLinkAccount(
            email: "test@example.com", session: .make(
                clientSecret: "cs_xxx", emailAddress: "test@example.com",
                redactedFormattedPhoneNumber: "(***) *** **55", unredactedPhoneNumber: "(555) 555-5555",
                phoneNumberCountry: "US", verificationSessions: [.init(type: .sms, state: .verified)],
                supportedPaymentDetailsTypes: [ParsedEnum(.card)], mobileFallbackWebviewParams: nil
            ), publishableKey: MockParams.publicKey, displayablePaymentDetails: nil,
            useMobileEndpoints: false, canSyncAttestationState: false
        )
        let details = ConsumerPaymentDetails(
            stripeID: "pd_india", details: .card(card: .init(
                expiryYear: 2055, expiryMonth: 12, brand: "visa", networks: ["visa"],
                last4: "4242", funding: .credit, checks: nil, country: "IN"
            )), billingAddress: nil, billingEmailAddress: nil, nickname: nil, isDefault: true
        )
        let completed = expectation(description: "shared card confirmed")
        PaymentSheet.confirm(
            configuration: configuration, authenticationContext: self, intent: intent,
            elementsSession: .indiaCardElementsSession(),
            paymentOption: .link(option: .withPaymentDetails(
                brand: .link, account: account, paymentDetails: details, confirmationExtras: nil, shippingAddress: nil
            )), paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient), analyticsHelper: ._testValue()
        ) { result, _ in
            guard case .completed = result else {
                XCTFail("Expected shared card confirmation to complete")
                completed.fulfill()
                return
            }
            completed.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testLinkControllerIndiaCardCreationSharesAndUsesOverrideKey() {
        stubUnexpectedPaymentMethodCreation()
        let configuration = MockParams.configuration(pk: MockParams.publicKey)
        let account = PaymentSheetLinkAccount(
            email: "test@example.com",
            session: .make(
                clientSecret: "cs_xxx", emailAddress: "test@example.com",
                redactedFormattedPhoneNumber: "(***) *** **55", unredactedPhoneNumber: "(555) 555-5555",
                phoneNumberCountry: "US", verificationSessions: [.init(type: .sms, state: .verified)],
                supportedPaymentDetailsTypes: [ParsedEnum(.card)], mobileFallbackWebviewParams: nil
            ),
            publishableKey: MockParams.publicKey, displayablePaymentDetails: nil,
            useMobileEndpoints: false, canSyncAttestationState: false
        )
        let previousAccount = LinkAccountContext.shared.account
        LinkAccountContext.shared.account = account
        defer { LinkAccountContext.shared.account = previousAccount }
        let details = ConsumerPaymentDetails(
            stripeID: "pd_india", details: .card(card: .init(
                expiryYear: 2055, expiryMonth: 12, brand: "visa", networks: ["visa"],
                last4: "4242", funding: .credit, checks: nil, country: "IN"
            )), billingAddress: nil, billingEmailAddress: nil, nickname: nil, isDefault: true
        )
        let controller = LinkController(
            apiClient: configuration.apiClient, mode: .payment,
            elementsSession: .indiaCardElementsSession(),
            intent: .deferredIntent(intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.paymentIntentClientSecret)),
            paymentElementConfiguration: configuration, linkBrand: .link, appearance: nil,
            configuration: nil, analyticsHelper: ._testValue(), requestSurface: .default
        )
        controller.internalPaymentOption = .link(option: .withPaymentDetails(
            brand: .link, account: account, paymentDetails: details, confirmationExtras: nil, shippingAddress: nil
        ))
        let share = expectation(description: "standalone India card shared once")
        share.assertForOverFulfill = true
        stub { $0.url?.pathComponents.last == "share" } response: { [self] request in
            let params = bodyParams(from: request)
            assertParam(params, named: "id", is: "pd_india")
            assertParam(params, named: "expected_payment_method_type", is: "card")
            XCTAssertTrue(request.value(forHTTPHeaderField: "Authorization")?.contains("pk_override") == true)
            share.fulfill()
            return HTTPStubsResponse(jsonObject: ["payment_method": MockJson.cardPaymentMethod], statusCode: 200, headers: nil)
        }
        let completed = expectation(description: "card PaymentMethod returned")
        controller.createPaymentMethod(overridePublishableKey: "pk_override") { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.stripeId, MockParams.cardPaymentMethod.stripeId)
                XCTAssertEqual(paymentMethod.type, .card)
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
            completed.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testWebFallbackCardIsConfirmedDirectly() {
        stubUnexpectedPaymentMethodCreation()
        stubConfirmPaymentExpecting(isPaymentIntent: true, paymentMethodId: MockParams.cardPaymentMethod.stripeId)
        let configuration = MockParams.configuration(pk: MockParams.publicKey)
        let completed = expectation(description: "web card confirmed")
        PaymentSheet.confirm(
            configuration: configuration, authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.paymentIntentClientSecret)),
            elementsSession: .indiaCardElementsSession(),
            paymentOption: .link(option: .withPaymentMethod(brand: .link, paymentMethod: MockParams.cardPaymentMethod)),
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient), analyticsHelper: ._testValue()
        ) { _, _ in completed.fulfill() }
        waitForExpectations(timeout: 10)
    }

    func testIndiaCardShareFailureDoesNotConfirmLinkOrRawCard() {
        stubUnexpectedConfirmation()
        stubUnexpectedPaymentMethodCreation()
        stubLinkShareExpecting(consumerSessionClientSecret: "cs_xxx", paymentMethodID: "pd1", expectedType: "card", fail: true)

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.publicKey)
        let exp = expectation(description: "confirm completed")
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        let elementsSession = STPElementsSession.indiaCardElementsSession()
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.paymentIntentClientSecret)),
            elementsSession: elementsSession,
            paymentOption: .link(
                option: .withPaymentDetails(
                    brand: .link,
                    account: .init(
                        email: "test@example.com",
                        session: .make(
                            clientSecret: "cs_xxx",
                            emailAddress: "test@example.com",
                            redactedFormattedPhoneNumber: "(***) *** **55",
                            unredactedPhoneNumber: "(555) 555-5555",
                            phoneNumberCountry: "US",
                            verificationSessions: [.init(type: .sms, state: .verified)],
                            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
                            mobileFallbackWebviewParams: nil
                        ),
                        publishableKey: MockParams.publicKey,
                        displayablePaymentDetails: nil,
                        useMobileEndpoints: false,
                        canSyncAttestationState: false
                    ),
                    paymentDetails: .init(
                        stripeID: "pd1",
                        details: .card(card: .init(
                            expiryYear: 2055,
                            expiryMonth: 12,
                            brand: "visa",
                            networks: ["visa"],
                            last4: "1234",
                            funding: .credit,
                            checks: nil,
                            country: "COUNTRY_IN"
                        )),
                        billingAddress: nil,
                        billingEmailAddress: nil,
                        nickname: nil,
                        isDefault: true
                    ),
                    confirmationExtras: nil,
                    shippingAddress: nil
                )
            ),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { result, _ in
                guard case .failed = result else {
                    XCTFail("A failed India share must fail confirmation")
                    exp.fulfill()
                    return
                }
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

    func testIndiaCardInPaymentMethodModeCallsShareOnce() {
        stubUnexpectedPaymentMethodCreation()
        stubConfirmPaymentExpecting(isPaymentIntent: true, paymentMethodId: MockParams.cardPaymentMethod.stripeId)
        stubLinkShareExpecting(consumerSessionClientSecret: "cs_xxx", paymentMethodID: "pd1", expectedType: "card")
        stubLinkLogout(consumerSessionClientSecret: "cs_xxx")

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.publicKey)
        let exp = expectation(description: "confirm completed")
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        let elementsSession = STPElementsSession.indiaCardElementsSession()
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.paymentIntentClientSecret)),
            elementsSession: elementsSession,
            paymentOption: .link(
                option: .withPaymentDetails(
                    brand: .link,
                    account: .init(
                        email: "test@example.com",
                        session: .make(
                            clientSecret: "cs_xxx",
                            emailAddress: "test@example.com",
                            redactedFormattedPhoneNumber: "(***) *** **55",
                            unredactedPhoneNumber: "(555) 555-5555",
                            phoneNumberCountry: "US",
                            verificationSessions: [.init(type: .sms, state: .verified)],
                            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
                            mobileFallbackWebviewParams: nil
                        ),
                        publishableKey: MockParams.publicKey,
                        displayablePaymentDetails: nil,
                        useMobileEndpoints: false,
                        canSyncAttestationState: false
                    ),
                    paymentDetails: .init(
                        stripeID: "pd1",
                        details: .card(card: .init(
                            expiryYear: 2055,
                            expiryMonth: 12,
                            brand: "visa",
                            networks: ["visa"],
                            last4: "1234",
                            funding: .credit,
                            checks: nil,
                            country: "COUNTRY_IN"
                        )),
                        billingAddress: nil,
                        billingEmailAddress: nil,
                        nickname: nil,
                        isDefault: true
                    ),
                    confirmationExtras: nil,
                    shippingAddress: nil
                )
            ),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

    func testPassthroughModeCallsSharePaymentDetails() {
        stubConfirmPaymentExpecting(isPaymentIntent: true, paymentMethodId: MockParams.cardPaymentMethod.stripeId)
        stubLinkShareExpecting(consumerSessionClientSecret: "cs_xxx", paymentMethodID: "pd1")
        stubLinkLogout(consumerSessionClientSecret: "cs_xxx")

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.publicKey)
        let exp = expectation(description: "confirm completed")
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        let elementsSession = STPElementsSession.linkPassthroughElementsSession
        PaymentSheet.confirm(
            configuration: configuration,
            customerProvider: CustomerProvider(customer: configuration.customer),
            authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.paymentIntentClientSecret)),
            elementsSession: elementsSession,
            paymentOption: .link(
                option: .withPaymentDetails(
                    brand: .link,
                    account: .init(
                        email: "test@example.com",
                        session: .make(
                            clientSecret: "cs_xxx",
                            emailAddress: "test@example.com",
                            redactedFormattedPhoneNumber: "(***) *** **55",
                            unredactedPhoneNumber: "(555) 555-5555",
                            phoneNumberCountry: "US",
                            verificationSessions: [.init(type: .sms, state: .verified)],
                            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
                            mobileFallbackWebviewParams: nil
                        ),
                        publishableKey: MockParams.publicKey,
                        displayablePaymentDetails: nil,
                        useMobileEndpoints: false,
                        canSyncAttestationState: false
                    ),
                    paymentDetails: .init(
                        stripeID: "pd1",
                        details: .card(card: .init(
                            expiryYear: 2055,
                            expiryMonth: 12,
                            brand: "visa",
                            networks: ["visa"],
                            last4: "1234",
                            funding: .credit,
                            checks: nil
                        )),
                        billingAddress: nil,
                        billingEmailAddress: nil,
                        nickname: nil,
                        isDefault: true
                    ),
                    confirmationExtras: nil,
                    shippingAddress: nil
                )
            ),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

    func testIndiaCardInlineShareFailureDoesNotUseRawCardFallback() {
        stubUnexpectedConfirmation()
        stubUnexpectedPaymentMethodCreation()
        stubLinkSignup()
        stubLinkCreatePaymentDetails(country: "COUNTRY_IN")
        stubLinkShareExpecting(consumerSessionClientSecret: "pscs_abc123", paymentMethodID: "csmrpd_test_61QrpvXKaugSBvBsB41C40Oy4de1NQS8", expectedType: "card", allowRedisplay: "always", cvc: "123", fail: true)

        let exp = expectation(description: "confirm completed")

        var configuration = MockParams.configuration(pk: MockParams.publicKey)
        configuration.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123")

        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        let elementsSession = STPElementsSession.linkElementsSessionWithCustomerSessionAndIndiaOverride

        var paymentIntentJSON = MockJson.paymentIntent
        paymentIntentJSON["payment_method_types"] = ["card", "link"]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJSON)!

        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"

        // User selected to save the payment method
        confirmParams.saveForFutureUseCheckboxState = .selected

        // We're in payment method mode, so the PaymentOption is Link
        let paymentOption: PaymentOption = .link(
            option: .signUp(
                brand: .link,
                account: .init(
                    email: "email@email.com",
                    session: nil,
                    publishableKey: "pk_123",
                    displayablePaymentDetails: nil,
                    useMobileEndpoints: false,
                    canSyncAttestationState: false
                ),
                phoneNumber: PhoneNumber(number: "5555555555", countryCode: "US")!,
                consentAction: .implied_v0_0,
                legalName: nil,
                intentConfirmParams: confirmParams
            )
        )

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .paymentIntent(paymentIntent),
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { result, _ in
                guard case .failed = result else {
                    XCTFail("A failed India share must fail confirmation")
                    exp.fulfill()
                    return
                }
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

    func testIndiaCardInlineSignupSharesReturnedDetails() {
        stubUnexpectedPaymentMethodCreation()
        stubLinkSignup()
        stubLinkCreatePaymentDetails(country: "COUNTRY_IN")
        stubLinkShareExpecting(consumerSessionClientSecret: "pscs_abc123", paymentMethodID: "csmrpd_test_61QrpvXKaugSBvBsB41C40Oy4de1NQS8", expectedType: "card", allowRedisplay: "always", cvc: "123")
        stubConfirmPaymentExpecting(isPaymentIntent: true, paymentMethodId: MockParams.cardPaymentMethod.stripeId, setupFutureUsage: "off_session")
        stubLinkLogout(consumerSessionClientSecret: "pscs_abc123")

        let exp = expectation(description: "confirm completed")

        var configuration = MockParams.configuration(pk: MockParams.publicKey)
        configuration.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123")

        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        let elementsSession = STPElementsSession.linkElementsSessionWithCustomerSessionAndIndiaOverride

        var paymentIntentJSON = MockJson.paymentIntent
        paymentIntentJSON["payment_method_types"] = ["card", "link"]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJSON)!

        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"

        // User selected to save the payment method
        confirmParams.saveForFutureUseCheckboxState = .selected

        // We're in payment method mode, so the PaymentOption is Link
        let paymentOption: PaymentOption = .link(
            option: .signUp(
                brand: .link,
                account: .init(
                    email: "email@email.com",
                    session: nil,
                    publishableKey: "pk_123",
                    displayablePaymentDetails: nil,
                    useMobileEndpoints: false,
                    canSyncAttestationState: false
                ),
                phoneNumber: PhoneNumber(number: "5555555555", countryCode: "US")!,
                consentAction: .implied_v0_0,
                legalName: nil,
                intentConfirmParams: confirmParams
            )
        )

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .paymentIntent(paymentIntent),
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

    func testLinkInlineSignupInPaymentMethodModePassesCorrectAllowRedisplay() {
        stubLinkSignup()
        stubLinkCreatePaymentDetails()
        stubConfirmPaymentExpecting(isPaymentIntent: true, type: "link", setupFutureUsage: "off_session", allowRedisplay: "always")
        stubLinkLogout(consumerSessionClientSecret: "pscs_abc123")

        let exp = expectation(description: "confirm completed")

        var configuration = MockParams.configuration(pk: MockParams.publicKey)
        configuration.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123")

        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        let elementsSession = STPElementsSession.linkElementsSessionWithCustomerSession

        var paymentIntentJSON = MockJson.paymentIntent
        paymentIntentJSON["payment_method_types"] = ["card", "link"]

        let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentJSON)!

        let confirmParams = IntentConfirmParams(type: .stripe(.card))
        confirmParams.paymentMethodParams.card = STPPaymentMethodCardParams()
        confirmParams.paymentMethodParams.card?.number = "4242424242424242"
        confirmParams.paymentMethodParams.card?.expMonth = NSNumber(value: 12)
        confirmParams.paymentMethodParams.card?.expYear = 2040
        confirmParams.paymentMethodParams.card?.cvc = "123"

        // User selected to save the payment method
        confirmParams.saveForFutureUseCheckboxState = .selected

        // We're in payment method mode, so the PaymentOption is Link
        let paymentOption: PaymentOption = .link(
            option: .signUp(
                brand: .link,
                account: .init(
                    email: "email@email.com",
                    session: nil,
                    publishableKey: "pk_123",
                    displayablePaymentDetails: nil,
                    useMobileEndpoints: false,
                    canSyncAttestationState: false
                ),
                phoneNumber: PhoneNumber(number: "5555555555", countryCode: "US")!,
                consentAction: .implied_v0_0,
                legalName: nil,
                intentConfirmParams: confirmParams
            )
        )

        PaymentSheet.confirm(
            configuration: configuration,
            customerProvider: CustomerProvider(customer: configuration.customer),
            authenticationContext: self,
            intent: .paymentIntent(paymentIntent),
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

}

extension PaymentSheetAPIMockTest: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

// MARK: - Helpers

private extension PaymentSheetAPIMockTest {
    func stubUnexpectedPaymentMethodCreation(line: UInt = #line) {
        stub { $0.httpMethod == "POST" && $0.url?.pathComponents.last == "payment_methods" } response: { _ in
            XCTFail("Shared or web-returned card must be consumed directly", line: line)
            return HTTPStubsResponse(jsonObject: ["error": ["message": "Unexpected PaymentMethod creation"]], statusCode: 400, headers: nil)
        }
    }

    func stubUnexpectedConfirmation(line: UInt = #line) {
        stub { $0.url?.pathComponents.last == "confirm" } response: { _ in
            XCTFail("A failed India share must not attempt confirmation", line: line)
            return HTTPStubsResponse(jsonObject: ["error": ["message": "Unexpected confirmation"]], statusCode: 400, headers: nil)
        }
    }


    func stubConfirmPaymentExpecting(
        isPaymentIntent: Bool,
        paymentMethodId: String,
        setupFutureUsage: String? = nil,
        line: UInt = #line
    ) {
        let exp = expectation(description: "confirm payment requested")

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
            return pathComponents.last == "confirm"
        } response: { [self] request in
            let params = bodyParams(from: request, line: line)

            assertParam(params, named: "payment_method_data[type]", is: nil, line: line)
            assertParam(params, named: "payment_method_data[card][number]", is: nil, line: line)
            assertParam(params, named: "payment_method", is: paymentMethodId, line: line)

            // Payment Method Options
            assertParam(params, named: "payment_method_options[card][setup_future_usage]", is: setupFutureUsage, line: line)

            defer { exp.fulfill() }
            var json = isPaymentIntent ? MockJson.paymentIntent : MockJson.setupIntent
            json["status"] = "succeeded"

            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
    }

    func stubConfirmPaymentExpecting(
        isPaymentIntent: Bool,
        type: String,
        setupFutureUsage: String? = nil,
        allowRedisplay: String? = nil,
        line: UInt = #line
    ) {
        let exp = expectation(description: "confirm payment requested")

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
            return pathComponents.last == "confirm"
        } response: { [self] request in
            let params = bodyParams(from: request, line: line)

            assertParam(params, named: "payment_method_data[type]", is: type, line: line)
            assertParam(params, named: "payment_method_data[allow_redisplay]", is: allowRedisplay, line: line)

            // Payment Method Options
            assertParam(params, named: "payment_method_options[link][setup_future_usage]", is: setupFutureUsage, line: line)

            defer { exp.fulfill() }
            var json = isPaymentIntent ? MockJson.paymentIntent : MockJson.setupIntent
            json["status"] = "succeeded"

            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
    }

    func stubLinkShareExpecting(
        consumerSessionClientSecret: String,
        paymentMethodID: String,
        expectedType: String? = nil,
        allowRedisplay: String? = nil,
        cvc: String? = nil,
        fail: Bool = false,
        line: UInt = #line
    ) {
        let exp = expectation(description: "share payment method requested")
        exp.assertForOverFulfill = true

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
            return pathComponents.last == "share"
        } response: { [self] request in
            let params = bodyParams(from: request, line: line)

            assertParam(params, named: "credentials[consumer_session_client_secret]", is: consumerSessionClientSecret, line: line)
            assertParam(params, named: "request_surface", is: "ios_payment_element", line: line)
            assertParam(params, named: "expand[0]", is: "payment_method", line: line)
            assertParam(params, named: "id", is: paymentMethodID, line: line)
            if let expectedType {
                assertParam(params, named: "expected_payment_method_type", is: expectedType, line: line)
            }
            if let allowRedisplay {
                assertParam(params, named: "allow_redisplay", is: allowRedisplay, line: line)
            }
            if let cvc {
                assertParam(params, named: "payment_method_options[card][cvc]", is: cvc, line: line)
            }

            defer { exp.fulfill() }
            if fail {
                return HTTPStubsResponse(jsonObject: ["error": ["message": "share failed", "type": "api_error"]], statusCode: 400, headers: nil)
            }
            let json = ["payment_method": MockJson.cardPaymentMethod]

            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
    }

    @discardableResult
    func stubLinkLogout(
        consumerSessionClientSecret: String,
        line: UInt = #line
    ) -> XCTestExpectation {
        let exp = expectation(description: "Link logout")

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
            return pathComponents.last == "log_out"
        } response: { [self] request in
            let params = bodyParams(from: request, line: line)

            assertParam(params, named: "credentials[consumer_session_client_secret]", is: consumerSessionClientSecret, line: line)
            assertParam(params, named: "request_surface", is: "ios_payment_element", line: line)

            defer { exp.fulfill() }

            return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: nil)
        }
        return exp
    }

    func stubLinkSignup(
        line: UInt = #line
    ) {
        let exp = expectation(description: "Link signup")

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
            return pathComponents.last == "sign_up"
        } response: {_ in
            defer { exp.fulfill() }

            let responseJSON = """
              {
                "publishable_key" : "pk_123",
                "consumer_session": {
                  "client_secret": "pscs_abc123",
                  "email_address": "foo@bar.com",
                  "redacted_formatted_phone_number": "(***) *** **12",
                  "verification_sessions": [
                    {
                      "state" : "STARTED",
                      "type" : "SIGNUP"
                    }
                  ],
                  "support_paymnet_details_types": ["CARD"],
                }
              }
            """

            let response = try! JSONSerialization.jsonObject(
                with: responseJSON.data(using: .utf8)!,
                options: []
            ) as! [AnyHashable: Any]

            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }

    func stubLinkCreatePaymentDetails(
        country: String = "COUNTRY_US",
        line: UInt = #line
    ) {
        let exp = expectation(description: "Link signup")

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
            return pathComponents.last == "payment_details"
        } response: { _ in
            defer { exp.fulfill() }

            let responseJSON = """
              {
                "redacted_payment_details" : {
                  "card_details" : {
                    "brand_enum" : "visa",
                    "checks" : {
                      "address_postal_code_check" : "STATE_INVALID",
                      "cvc_check" : "STATE_INVALID",
                      "address_line1_check" : "STATE_INVALID"
                    },
                    "country" : "\(country)",
                    "exp_month" : 12,
                    "funding" : "CREDIT",
                    "preferred_network" : null,
                    "program_details" : {
                      "card_art_network_id" : "",
                      "height" : 0,
                      "program_name" : "",
                      "width" : 0,
                      "background_color" : "",
                      "foreground_color" : "",
                      "card_art_url" : ""
                    },
                    "brand" : "VISA",
                    "last4" : "4242",
                    "networks" : [
                      "VISA"
                    ],
                    "exp_year" : 2030
                  },
                  "is_default" : false,
                  "id" : "csmrpd_test_61QrpvXKaugSBvBsB41C40Oy4de1NQS8",
                  "backup_ids" : [

                  ],
                  "is_us_debit_prepaid_or_bank_payment" : false,
                  "billing_address" : {
                    "line_1" : null,
                    "line_2" : null,
                    "locality" : null,
                    "postal_code" : "55555",
                    "sorting_code" : null,
                    "country_code" : "US",
                    "dependent_locality" : null,
                    "administrative_area" : null,
                    "name" : "Payments SDK CI"
                  },
                  "nickname" : "",
                  "bank_account_details" : null,
                  "type" : "CARD",
                  "billing_email_address" : "mobile-payments-sdk-ci+874e9b29-df47-4a14-be39-be257a89dccb@stripe.com"
                }
              }
            """

            let response = try! JSONSerialization.jsonObject(
                with: responseJSON.data(using: .utf8)!,
                options: []
            ) as! [AnyHashable: Any]

            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil)
        }
    }

    func assertParam(_ params: [String: String], named name: String, is value: String?, line: UInt = #line) {
        XCTAssertEqual(params[name], value, name, line: line)
    }

    func bodyParams(from request: URLRequest, line: UInt = #line) -> [String: String] {
        return RequestBodyTestHelpers.formEncodedBodyParams(from: request, omittingEmptyValues: true, line: line)
    }
}
