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
        static let dashboardClientSecret = "pi_xxx"
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
        } response: { _ in
            return HTTPStubsResponse(jsonObject: MockJson.setupIntent, statusCode: 200, headers: nil)
        }
    }

    // MARK: - Dashboard PaymentIntent

    func testDashboard_PaymentIntent_saved() {
        stubConfirmPaymentExpecting(
            paymentMethodId: MockParams.cardPaymentMethod.stripeId,
            shippingAddressLine1: "Line 1",
            shippingAddressCountry: "US",
            shippingName: "Jane Doe",
            shippingPhone: "5551234567",
            cardMoto: true
        )

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.dashboardPublicKey)

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .paymentIntent(elementsSession: .emptyElementsSession, paymentIntent: MockParams.paymentIntent),
            paymentOption: .saved(paymentMethod: MockParams.cardPaymentMethod),
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            completion: { _, _ in }
        )

        waitForExpectations(timeout: 10)
    }

    func testDashboard_PaymentIntent_new_saveUnchecked() {
        stubConfirmPaymentExpecting(
            paymentMethodData: MockParams.paymentMethodCardParams,
            shippingAddressLine1: "Line 1",
            shippingAddressCountry: "US",
            shippingName: "Jane Doe",
            shippingPhone: "5551234567",
            cardMoto: true
        )

        let configuration = MockParams.configuration(pk: MockParams.dashboardPublicKey)

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .paymentIntent(elementsSession: .emptyElementsSession, paymentIntent: MockParams.paymentIntent),
            paymentOption: .new(confirmParams: MockParams.intentConfirmParams),
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            completion: { _, _ in }
        )

        waitForExpectations(timeout: 10)
    }

    func testDashboard_PaymentIntent_new_saveChecked() {
        let intentConfirmParams = MockParams.intentConfirmParams
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        stubConfirmPaymentExpecting(
            paymentMethodData: MockParams.paymentMethodCardParams,
            setupFutureUsage: "off_session",
            shippingAddressLine1: "Line 1",
            shippingAddressCountry: "US",
            shippingName: "Jane Doe",
            shippingPhone: "5551234567",
            cardMoto: true
        )

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.dashboardPublicKey)

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .paymentIntent(elementsSession: .emptyElementsSession, paymentIntent: MockParams.paymentIntent),
            paymentOption: .new(confirmParams: intentConfirmParams),
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            completion: { _, _ in }
        )

        waitForExpectations(timeout: 10)
    }

    // MARK: - Dashboard Deferred PaymentIntent

    func testDashboard_DeferredPaymentIntent_saved() {
        stubConfirmPaymentExpecting(
            paymentMethodId: MockParams.cardPaymentMethod.stripeId,
            shippingAddressLine1: "Line 1",
            shippingAddressCountry: "US",
            shippingName: "Jane Doe",
            shippingPhone: "5551234567",
            cardMoto: true
        )

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.dashboardPublicKey)

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(elementsSession: .emptyElementsSession, intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.dashboardClientSecret)),
            paymentOption: .saved(paymentMethod: MockParams.cardPaymentMethod),
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            completion: { _, _ in }
        )

        waitForExpectations(timeout: 10)
    }

    func testDashboard_DeferredPaymentIntent_new_saveUnchecked() {
        stubConfirmPaymentExpecting(
            paymentMethodId: MockParams.cardPaymentMethod.stripeId,
            shippingAddressLine1: "Line 1",
            shippingAddressCountry: "US",
            shippingName: "Jane Doe",
            shippingPhone: "5551234567",
            cardMoto: true
        )

        let configuration = MockParams.configuration(pk: MockParams.dashboardPublicKey)

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(elementsSession: .emptyElementsSession, intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.dashboardClientSecret)),
            paymentOption: .new(confirmParams: MockParams.intentConfirmParams),
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            completion: { _, _ in }
        )

        waitForExpectations(timeout: 10)
    }

    func testDashboard_DeferredPaymentIntent_new_saveChecked() {
        let intentConfirmParams = MockParams.intentConfirmParams
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        stubConfirmPaymentExpecting(
            paymentMethodId: MockParams.cardPaymentMethod.stripeId,
            setupFutureUsage: "off_session",
            shippingAddressLine1: "Line 1",
            shippingAddressCountry: "US",
            shippingName: "Jane Doe",
            shippingPhone: "5551234567",
            cardMoto: true
        )

        let configuration = MockParams.configurationWithCustomer(pk: MockParams.dashboardPublicKey)

        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: .deferredIntent(elementsSession: .emptyElementsSession, intentConfig: MockParams.deferredPaymentIntentConfiguration(clientSecret: MockParams.dashboardClientSecret)),
            paymentOption: .new(confirmParams: intentConfirmParams),
            paymentHandler: STPPaymentHandler(apiClient: configuration.apiClient),
            completion: { _, _ in }
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
        paymentMethodId: String? = nil,
        paymentMethodData: STPPaymentMethodCardParams? = nil,
        setupFutureUsage: String? = nil,
        shippingAddressLine1: String? = nil,
        shippingAddressCountry: String? = nil,
        shippingName: String? = nil,
        shippingPhone: String? = nil,
        cardMoto: Bool? = nil,
        line: UInt = #line
    ) {
        let exp = expectation(description: "confirm payment requested")

        stub { urlRequest in
            guard let pathComponents = urlRequest.url?.pathComponents else { return false }
            return pathComponents[2] == "payment_intents" && pathComponents.last == "confirm"
        } response: { [self] request in
            let params = bodyParams(from: request, line: line)

            assertParam(params, named: "payment_method", is: paymentMethodId, line: line)

            // Payment Method Card
            assertParam(params, named: "payment_method_data[type]", is: paymentMethodData.map { _ in "card" }, line: line)
            assertParam(params, named: "payment_method_data[card][number]", is: paymentMethodData?.number, line: line)
            assertParam(params, named: "payment_method_data[card][cvc]", is: paymentMethodData?.cvc, line: line)
            assertParam(params, named: "payment_method_data[card][exp_year]", is: paymentMethodData?.expYear.map { "\($0)" }, line: line)
            assertParam(params, named: "payment_method_data[card][exp_month]", is: paymentMethodData?.expMonth.map { "\($0)" }, line: line)

            // Payment Method Options
            assertParam(params, named: "payment_method_options[card][setup_future_usage]", is: setupFutureUsage, line: line)
            assertParam(params, named: "payment_method_options[card][moto]", is: cardMoto.map { "\($0)" }, line: line)

            // Shipping
            assertParam(params, named: "shipping[name]", is: shippingName, line: line)
            assertParam(params, named: "shipping[phone]", is: shippingPhone, line: line)
            assertParam(params, named: "shipping[address][line1]", is: shippingAddressLine1, line: line)
            assertParam(params, named: "shipping[address][country]", is: shippingAddressCountry, line: line)

            defer { exp.fulfill() }

            return HTTPStubsResponse(jsonObject: MockJson.paymentIntent, statusCode: 200, headers: nil)
        }
    }

    func assertParam(_ params: [String: String], named name: String, is value: String?, line: UInt) {
        XCTAssertEqual(params[name], value, name, line: line)
    }

    func bodyParams(from request: URLRequest, line: UInt) -> [String: String] {
        guard let httpBody = request.httpBodyOrBodyStream,
              let query = String(data: httpBody, encoding: .utf8),
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
