//
//  PaymentSheet+ConfirmParamsTest.swift
//  StripePaymentSheetTests
//
//  Created by Mel Ludowise on 12/14/23.
//

import Foundation

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore

import OHHTTPStubs
import OHHTTPStubsSwift

final class PaymentSheet_ConfirmParamsTest: APIStubbedTestCase {
    enum MockJson {
        static let cardPaymentMethod = STPTestUtils.jsonNamed("CardPaymentMethod")!
        static let paymentIntent = STPTestUtils.jsonNamed("PaymentIntent")!
        static let setupIntent = STPTestUtils.jsonNamed("SetupIntent")!
    }

    enum MockParams {
        // Note Dashboard's uk requires it to pass PaymentSheet intent identifiers as the "client secret". Seealso: https://github.com/stripe-ios/stripe-ios-private/pull/59
        static let dashboardPaymentIntentClientSecret = "pi_xxx"
        static let dashboardSetupIntentClientSecret = "seti_xxx"
        static let dashboardPublicKey = "uk_xxx"

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

        // Stub all API calls that can be made

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

    // MARK: - Dashboard Deferred PaymentIntent

    func testDashboard_DeferredPaymentIntent_saved() {
        stubConfirmPaymentExpecting(isPaymentIntent: true, paymentMethodId: MockParams.cardPaymentMethod.stripeId)

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.dashboardPublicKey)
        let exp = expectation(description: "confirm completed")
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.dashboardPaymentIntentClientSecret)),
            elementsSession: .emptyElementsSession,
            paymentOption: .saved(paymentMethod: MockParams.cardPaymentMethod, confirmParams: nil),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

    func testDashboard_DeferredPaymentIntent_new_saveUnchecked() {
        stubConfirmPaymentExpecting(
            isPaymentIntent: true,
            paymentMethodId: MockParams.cardPaymentMethod.stripeId
        )

        let configuration = MockParams.configuration(pk: MockParams.dashboardPublicKey)

        let exp = expectation(description: "confirm completed")
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.dashboardPaymentIntentClientSecret)),
            elementsSession: .emptyElementsSession,
            paymentOption: .new(confirmParams: MockParams.intentConfirmParams),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

    func testDashboard_DeferredPaymentIntent_new_saveChecked() {
        let intentConfirmParams = MockParams.intentConfirmParams
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        stubConfirmPaymentExpecting(
            isPaymentIntent: true,
            paymentMethodId: MockParams.cardPaymentMethod.stripeId,
            setupFutureUsage: "off_session"
        )

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.dashboardPublicKey)

        let exp = expectation(description: "confirm completed")
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.dashboardPaymentIntentClientSecret)),
            elementsSession: .emptyElementsSession,
            paymentOption: .new(confirmParams: intentConfirmParams),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )
        waitForExpectations(timeout: 10)
    }

    // MARK: - Dashboard Deferred SetupIntent

    func testDashboard_DeferredSetupIntent_saved() {
        stubConfirmPaymentExpecting(
            isPaymentIntent: false,
            paymentMethodId: MockParams.cardPaymentMethod.stripeId
        )

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.dashboardPublicKey)

        let exp = expectation(description: "confirm completed")
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredSetupIntentConfiguration(clientSecret: MockParams.dashboardSetupIntentClientSecret)),
            elementsSession: .emptyElementsSession,
            paymentOption: .saved(paymentMethod: MockParams.cardPaymentMethod, confirmParams: nil),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }

    func testDashboard_DeferredSetupIntent_new() {
        stubConfirmPaymentExpecting(
            isPaymentIntent: false,
            paymentMethodId: MockParams.cardPaymentMethod.stripeId
        )

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.dashboardPublicKey)

        let exp = expectation(description: "confirm completed")
        let paymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(intentConfig: MockParams.deferredSetupIntentConfiguration(clientSecret: MockParams.dashboardSetupIntentClientSecret)),
            elementsSession: .emptyElementsSession,
            paymentOption: .new(confirmParams: MockParams.intentConfirmParams),
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue(),
            completion: { _, _ in
                exp.fulfill()
            }
        )

        waitForExpectations(timeout: 10)
    }
}

extension PaymentSheet_ConfirmParamsTest: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

// MARK: - Helpers

private extension PaymentSheet_ConfirmParamsTest {
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
            XCTAssertFalse(request.url!.absoluteString.contains("secret")) // Sanity check that the request /confirm URL doesn't contain a client secret
            let params = bodyParams(from: request, line: line)

            // The API doesn't allow Dashboard `uk_` keys to pass raw PANs
            // see card_raw_pan_validator.rb
            assertParam(params, named: "payment_method_data[type]", is: nil, line: line)
            assertParam(params, named: "payment_method_data[card][number]", is: nil, line: line)
            assertParam(params, named: "payment_method", is: paymentMethodId, line: line)
            // The API also doesn't allow Dashboard `uk_` key to pass client_secret here
            assertParam(params, named: "client_secret", is: nil, line: line)

            // Payment Method Options
            assertParam(params, named: "payment_method_options[card][setup_future_usage]", is: setupFutureUsage, line: line)
            // Dashboard should always set `moto`
            assertParam(params, named: "payment_method_options[card][moto]", is: "true", line: line)

            defer { exp.fulfill() }
            var json = isPaymentIntent ? MockJson.paymentIntent : MockJson.setupIntent
            json["status"] = "succeeded"

            return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: nil)
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
