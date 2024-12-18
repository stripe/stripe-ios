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

final class PaymentSheetAPIMockTest: APIStubbedTestCase {
    enum MockJson {
        static let cardPaymentMethod = STPTestUtils.jsonNamed("CardPaymentMethod")!
        static let paymentIntent = STPTestUtils.jsonNamed("PaymentIntent")!
        static let setupIntent = STPTestUtils.jsonNamed("SetupIntent")!
    }

    enum MockParams {
        static let paymentIntentClientSecret = "pi_xxx_secret_xxx"
        static let setupIntentClientSecret = "seti_xxx_secret_xxx"
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

        static let paymentMethodCardParams: STPPaymentMethodCardParams = {
            let cardParams = STPPaymentMethodCardParams()
            cardParams.number = "4242424242424242"
            cardParams.cvc = "123"
            cardParams.expYear = 32
            cardParams.expMonth = 12
            return cardParams
        }()

        static var intentConfirmParams: IntentConfirmParams {
            .init(
                params: .init(
                    card: paymentMethodCardParams,
                    billingDetails: .init(),
                    metadata: nil
                ),
                type: .stripe(.card)
            )
        }

        static var linkPaymentOption: PaymentSheet.PaymentOption {
            let exampleBillingEmail = "test@example.com"
            return .link(option: .withPaymentDetails(
                account: .init(
                    email: exampleBillingEmail,
                    session: .init(
                        clientSecret: "cs_xxx",
                        emailAddress: exampleBillingEmail,
                        redactedPhoneNumber: "+1-555-xxx-xxxx",
                        verificationSessions: [.init(type: .sms, state: .verified)],
                        supportedPaymentDetailsTypes: [.card]
                    ),
                    publishableKey: "pk_xxx_for_link_account_xxx",
                    useMobileEndpoints: false,
                    elementsSessionID: "abc123"
                ),
                paymentDetails: .init(
                    stripeID: "pd1",
                    details: .card(card:
                            .init(expiryYear: 2055,
                                  expiryMonth: 12,
                                  brand: "visa",
                                  last4: "1234",
                                  checks: nil)
                    ),
                    billingAddress: nil,
                    billingEmailAddress: exampleBillingEmail,
                    isDefault: true)
            )
            )
        }

        static let cardPaymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: MockJson.cardPaymentMethod)!

        static let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: MockJson.paymentIntent)!

        static let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: MockJson.setupIntent)!

        static func deferredPaymentIntentConfiguration(clientSecret: String) -> PaymentSheet.IntentConfiguration {
            .init(mode: .payment(amount: 123, currency: "USD"), paymentMethodTypes: ["card"]) { _, _, c in c(.success(clientSecret)) }
        }

        static func deferredSetupIntentConfiguration(clientSecret: String) -> PaymentSheet.IntentConfiguration {
            .init(mode: .setup(currency: "USD", setupFutureUsage: .offSession), confirmHandler: { _, _, c in c(.success(clientSecret)) })
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
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
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
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
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
                    account: .init(
                        email: "test@example.com",
                        session: .init(clientSecret: "cs_xxx", emailAddress: "test@example.com", redactedPhoneNumber: "+1-555-xxx-xxxx", verificationSessions: [.init(type: .sms, state: .verified)], supportedPaymentDetailsTypes: [.card]),
                        publishableKey: MockParams.publicKey,
                        useMobileEndpoints: false,
                        elementsSessionID: "abc123"),
                    paymentDetails: .init(
                        stripeID: "pd1",
                        details: .card(card: .init(expiryYear: 2055, expiryMonth: 12, brand: "visa", last4: "1234", checks: nil)),
                        billingAddress: nil,
                        billingEmailAddress: nil,
                        isDefault: true)
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

    func stubLinkLogout(
        consumerSessionClientSecret: String,
        line: UInt = #line
    ) {
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
    }

    func assertParam(_ params: [String: String], named name: String, is value: String?, line: UInt) {
        XCTAssertEqual(params[name], value, name, line: line)
    }

    func bodyParams(from request: URLRequest, line: UInt) -> [String: String] {
        guard let httpBody = request.httpBodyOrBodyStream,
              let query = String(decoding: httpBody, as: UTF8.self).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let components = URLComponents(string: "http://someurl.com?\(query)") else {
            XCTFail("Request body empty", line: line)
            return [:]
        }

        return components.queryItems?.reduce(into: [:], { partialResult, item in
            guard item.value != "" else { return }
            partialResult[item.name] = item.value?.removingPercentEncoding
        }) ?? [:]
    }
}
