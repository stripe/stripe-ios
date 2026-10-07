//
//  PaymentSheet+APIMockTest.swift
//  StripePaymentSheet
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore

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
            .init(mode: .payment(amount: 123, currency: "USD"), paymentMethodTypes: ["card"]) { _, _ in return clientSecret }
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

    func testDeferredPaymentMethodCallbackUsesReturnedCredentialsForRetrievalAndConfirmation() async {
        // Given a payment method collected with the original credentials
        var configuration = MockParams.configuration(pk: "pk_test_original")
        configuration.apiClient = stubbedAPIClient()
        configuration.apiClient.publishableKey = "pk_test_original"
        configuration.apiClient.stripeAccount = "acct_original"
        let intentConfig = PaymentSheet.IntentConfiguration.withAPIConfiguration(
            mode: .payment(amount: 2345, currency: "USD"),
            confirmHandler: { _, _ in
                .init(clientSecret: MockParams.paymentIntentClientSecret,
                      apiConfiguration: .init(publishableKey: "pk_test_intent", stripeAccount: "acct_intent"))
            }
        )
        let retrieved = expectation(description: "Intent retrieved with returned credentials")
        let confirmed = expectation(description: "Intent confirmed with returned credentials")

        stub { request in
            request.httpMethod == "GET" && request.url?.path.contains("/payment_intents/") == true
        } response: { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_intent")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Account"), "acct_intent")
            retrieved.fulfill()
            var json = MockJson.paymentIntent
            json["status"] = "requires_confirmation"
            json["capture_method"] = "automatic"
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
        stub { request in
            request.httpMethod == "POST" && request.url?.path.hasSuffix("/confirm") == true
        } response: { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_intent")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Account"), "acct_intent")
            confirmed.fulfill()
            var json = MockJson.paymentIntent
            json["status"] = "succeeded"
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }

        // When the new intent is confirmed
        let result = await PaymentSheet.routeDeferredIntentConfirmation(
            confirmType: .saved(MockParams.cardPaymentMethod, paymentOptions: nil, clientAttributionMetadata: nil, radarOptions: nil),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            isFlowController: false,
            elementsSession: nil
        )

        // Then both intent requests use the returned credentials, without changing the original client
        if case .completed = result.result {} else { XCTFail("Expected completed payment, got \(result.result)") }
        await fulfillment(of: [retrieved, confirmed], timeout: 5)
        XCTAssertEqual(configuration.apiClient.publishableKey, "pk_test_original")
        XCTAssertEqual(configuration.apiClient.stripeAccount, "acct_original")
    }

    func testDeferredConfirmationTokenCallbackClearsOriginalAccountForSetupIntent() async {
        // Given a confirmation token created with the original credentials
        var configuration = MockParams.configuration(pk: "pk_test_original")
        configuration.apiClient = stubbedAPIClient()
        configuration.apiClient.publishableKey = "pk_test_original"
        configuration.apiClient.stripeAccount = "acct_original"
        let intentConfig = PaymentSheet.IntentConfiguration.withConfirmationTokenAPIConfiguration(
            mode: .setup(currency: "USD"),
            confirmHandler: { _ in
                .init(clientSecret: "seti_123456789_secret_123456789",
                      apiConfiguration: .init(publishableKey: "pk_test_intent"))
            }
        )
        let tokenCreated = expectation(description: "Token created with original credentials")
        let retrieved = expectation(description: "SetupIntent retrieved with returned credentials")
        let confirmed = expectation(description: "SetupIntent confirmed with returned credentials")

        stub { request in
            request.httpMethod == "POST" && request.url?.path == "/v1/confirmation_tokens"
        } response: { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_original")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Stripe-Account"), "acct_original")
            tokenCreated.fulfill()
            return HTTPStubsResponse(jsonObject: ["id": "ctoken_test_123", "created": 1_700_000_000], statusCode: 200, headers: nil)
        }
        stub { request in
            request.httpMethod == "GET" && request.url?.path.contains("/setup_intents/") == true
        } response: { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_intent")
            XCTAssertNil(request.value(forHTTPHeaderField: "Stripe-Account"))
            retrieved.fulfill()
            var json = MockJson.setupIntent
            json["status"] = "requires_confirmation"
            json["payment_method"] = NSNull()
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }
        stub { request in
            request.httpMethod == "POST" && request.url?.path.hasSuffix("/confirm") == true
        } response: { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_intent")
            XCTAssertNil(request.value(forHTTPHeaderField: "Stripe-Account"))
            confirmed.fulfill()
            var json = MockJson.setupIntent
            json["status"] = "succeeded"
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }

        // When the new intent is confirmed
        let result = await PaymentSheet.routeDeferredIntentConfirmation(
            confirmType: .saved(MockParams.cardPaymentMethod, paymentOptions: nil, clientAttributionMetadata: nil, radarOptions: nil),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            isFlowController: false,
            elementsSession: .emptyElementsSession
        )

        // Then intent requests use the returned key with no Stripe account
        if case .completed = result.result {} else { XCTFail("Expected completed setup, got \(result.result)") }
        await fulfillment(of: [tokenCreated, retrieved, confirmed], timeout: 5)
        XCTAssertEqual(configuration.apiClient.stripeAccount, "acct_original")
    }

    func testDeferredIntentResultWithoutAPIConfigurationKeepsOriginalClient() async throws {
        // Given a callback result without credentials
        let original = stubbedAPIClient()
        original.publishableKey = "pk_test_original"
        original.stripeAccount = "acct_original"
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _ in "pi_secret" }
        let paymentMethod = MockParams.cardPaymentMethod

        // When the callback result is resolved
        let result = try await intentConfig.createIntent(paymentMethod: paymentMethod, shouldSavePaymentMethod: false)
        let resolved = try intentConfig.apiClient(for: result, original: original)

        // Then the original API client and account are retained
        XCTAssertTrue(resolved === original)
        XCTAssertEqual(resolved.publishableKey, "pk_test_original")
        XCTAssertEqual(resolved.stripeAccount, "acct_original")
    }

    func testDeferredServerConfirmedIntentUsesReturnedCredentials() async {
        // Given an intent that the server has already confirmed
        var configuration = MockParams.configuration(pk: "pk_test_original")
        configuration.apiClient = stubbedAPIClient()
        configuration.apiClient.publishableKey = "pk_test_original"
        let intentConfig = PaymentSheet.IntentConfiguration.withAPIConfiguration(
            mode: .payment(amount: 2345, currency: "USD"),
            confirmHandler: { _, _ in
                .init(clientSecret: MockParams.paymentIntentClientSecret,
                      apiConfiguration: .init(publishableKey: "pk_test_intent"))
            }
        )
        let retrieved = expectation(description: "Server-confirmed intent retrieved with returned credentials")

        stub { request in
            request.httpMethod == "GET" && request.url?.path.contains("/payment_intents/") == true
        } response: { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer pk_test_intent")
            retrieved.fulfill()
            var json = MockJson.paymentIntent
            json["status"] = "succeeded"
            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
        }

        // When PaymentSheet handles the server-confirmed intent
        let result = await PaymentSheet.routeDeferredIntentConfirmation(
            confirmType: .saved(MockParams.cardPaymentMethod, paymentOptions: nil, clientAttributionMetadata: nil, radarOptions: nil),
            configuration: configuration,
            intentConfig: intentConfig,
            authenticationContext: self,
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            isFlowController: false,
            elementsSession: nil
        )

        // Then the callback result is completed through the server path
        if case .completed = result.result {} else { XCTFail("Expected completed payment, got \(result.result)") }
        XCTAssertEqual(result.deferredIntentConfirmationType, .server)
        await fulfillment(of: [retrieved], timeout: 5)
    }

}

extension PaymentSheetAPIMockTest: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

// MARK: - Helpers

private extension PaymentSheetAPIMockTest {
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
        line: UInt = #line
    ) {
        let exp = expectation(description: "share payment method requested")

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
            return pathComponents.last == "share"
        } response: { [self] request in
            let params = bodyParams(from: request, line: line)

            assertParam(params, named: "credentials[consumer_session_client_secret]", is: consumerSessionClientSecret, line: line)
            assertParam(params, named: "request_surface", is: "ios_payment_element", line: line)
            assertParam(params, named: "expand[0]", is: "payment_method", line: line)
            assertParam(params, named: "id", is: paymentMethodID, line: line)

            defer { exp.fulfill() }
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
                    "country" : "COUNTRY_US",
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

    func assertParam(_ params: [String: String], named name: String, is value: String?, line: UInt) {
        XCTAssertEqual(params[name], value, name, line: line)
    }

    func bodyParams(from request: URLRequest, line: UInt) -> [String: String] {
        return RequestBodyTestHelpers.formEncodedBodyParams(from: request, omittingEmptyValues: true, line: line)
    }
}
