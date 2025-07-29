//
//  STPAPIClientStubbedTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeApplePay
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet

class STPAPIClientStubbedTest: APIStubbedTestCase {
    func testCreatePaymentMethodWithAdditionalPaymentUserAgentValues() {
        let sut = stubbedAPIClient()
        stub { urlRequest in
            guard let queryItems = urlRequest.queryItems else {
                return false
            }
            XCTAssertTrue(queryItems.contains(where: { item in
                // The additional payment user agent values "foo" and "bar" should be in the payment_user_agent field
                item.name == "payment_user_agent" && item.value!.hasSuffix("%3B%20foo%3B%20bar")
            }))
            return true
        } response: { _ in
            return .init()
        }
        let e = expectation(description: "")
        sut.createPaymentMethod(with: ._testValidCardValue(), additionalPaymentUserAgentValues: ["foo", "bar"]) { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    private func stubClientAttributionMetadata(base: String? = nil, shouldContainClientAttributionMetadata: Bool = true, additionalClientAttributionMetadata: [String: String] = [:], urlPattern: String? = nil) {
            stub { urlRequest in
                // If urlPattern is specified, only validate requests that match the pattern
                if let urlPattern {
                    guard urlRequest.url?.absoluteString.contains(urlPattern) == true else {
                        return false
                    }
                }
                guard let queryItems = urlRequest.queryItems else {
                    return false
                }
                XCTAssertEqual(queryItems.contains(where: { item in
                    if let base {
                        return item.name == "\(base)[client_attribution_metadata][client_session_id]" && item.value == AnalyticsHelper.shared.sessionID
                    }
                    return item.name == "client_attribution_metadata[client_session_id]" && item.value == AnalyticsHelper.shared.sessionID
                }), shouldContainClientAttributionMetadata)
                XCTAssertEqual(queryItems.contains(where: { item in
                    if let base {
                        return item.name == "\(base)[client_attribution_metadata][merchant_integration_source]" && item.value == "elements"
                    }
                    return item.name == "client_attribution_metadata[merchant_integration_source]" && item.value == "elements"
                }), shouldContainClientAttributionMetadata)
                XCTAssertEqual(queryItems.contains(where: { item in
                    if let base {
                        return item.name == "\(base)[client_attribution_metadata][merchant_integration_subtype]" && item.value == "mobile"
                    }
                    return item.name == "client_attribution_metadata[merchant_integration_subtype]" && item.value == "mobile"
                }), shouldContainClientAttributionMetadata)
                XCTAssertEqual(queryItems.contains(where: { item in
                    if let base {
                        return item.name == "\(base)[client_attribution_metadata][merchant_integration_version]" && item.value == "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion)"
                    }
                    return item.name == "client_attribution_metadata[merchant_integration_version]" && item.value == "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion)"
                }), shouldContainClientAttributionMetadata)
                additionalClientAttributionMetadata.forEach { key, value in
                    XCTAssertEqual(queryItems.contains(where: { item in
                        if let base {
                            return item.name == "\(base)[client_attribution_metadata][\(key)]" && item.value == value
                        }
                        return item.name == "client_attribution_metadata[\(key)]" && item.value == value
                    }), shouldContainClientAttributionMetadata)
                }
                return true
            } response: { _ in
                return .init()
            }
        }

    func testCreatePaymentMethodWithClientAttributionMetadata() {
        let sut = stubbedAPIClient()
        AnalyticsHelper.shared.generateSessionID()
        let additionalClientAttributionMetadata = ["elements_session_config_id": "elements_session_config_id", "payment_intent_creation_flow": "deferred", "payment_method_selection_flow": "automatic"]
        stubClientAttributionMetadata(additionalClientAttributionMetadata: additionalClientAttributionMetadata)
        let e = expectation(description: "")
        sut.createPaymentMethod(with: ._testValidCardValue(), additionalClientAttributionMetadata: additionalClientAttributionMetadata) { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testCreateApplePayPaymentMethodWithClientAttributionMetadata() {
        let sut = stubbedAPIClient()
        AnalyticsHelper.shared.generateSessionID()
        let additionalClientAttributionMetadata = ["elements_session_config_id": "elements_session_config_id", "payment_intent_creation_flow": "deferred", "payment_method_selection_flow": "automatic"]
        
        // Stub token creation call
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/tokens") ?? false
        } response: { _ in
            let tokenResponse = """
                {
                    "id": "tok_test_123",
                    "object": "token",
                    "used": false,
                    "livemode": false,
                    "created": 1234567890,
                    "type": "card"
                }
                """
            return HTTPStubsResponse(
                data: Data(tokenResponse.utf8),
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        // Stub payment method creation call
        stubClientAttributionMetadata(additionalClientAttributionMetadata: additionalClientAttributionMetadata, urlPattern: "/payment_methods")
        let e = expectation(description: "")
        StripeAPI.PaymentMethod.create(apiClient: sut, payment: .init(), additionalClientAttributionMetadata: additionalClientAttributionMetadata) { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testConfirmPaymentIntentWithClientAttributionMetadata() {
        let sut = stubbedAPIClient()
        AnalyticsHelper.shared.generateSessionID()
        let additionalClientAttributionMetadata = ["elements_session_config_id": "elements_session_config_id", "payment_intent_creation_flow": "deferred", "payment_method_selection_flow": "automatic"]
        stubClientAttributionMetadata(base: "payment_method_data", additionalClientAttributionMetadata: additionalClientAttributionMetadata)
        let e = expectation(description: "")
        let paymentMethodParams = STPPaymentMethodParams()
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        sut.confirmPaymentIntent(with: paymentIntentParams, expand: nil, additionalClientAttributionMetadata: additionalClientAttributionMetadata) { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testConfirmPaymentIntentWithoutClientAttributionMetadata() {
        let sut = stubbedAPIClient()
        AnalyticsHelper.shared.generateSessionID()
        // We only want to include client_attribution_metadata on tokenization with payment method params
        stubClientAttributionMetadata(base: "payment_method_data", shouldContainClientAttributionMetadata: false)
        let e = expectation(description: "")
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        sut.confirmPaymentIntent(with: paymentIntentParams) { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testConfirmSetupIntentWithClientAttributionMetadata() {
        let sut = stubbedAPIClient()
        AnalyticsHelper.shared.generateSessionID()
        let additionalClientAttributionMetadata = ["elements_session_config_id": "elements_session_config_id", "payment_intent_creation_flow": "deferred", "payment_method_selection_flow": "automatic"]
        stubClientAttributionMetadata(base: "payment_method_data", shouldContainClientAttributionMetadata: true, additionalClientAttributionMetadata: additionalClientAttributionMetadata)
        let e = expectation(description: "")
        let paymentMethodParams = STPPaymentMethodParams()
        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: "seti_123456_secret_654321")
        setupIntentParams.paymentMethodParams = paymentMethodParams
        sut.confirmSetupIntent(with: setupIntentParams, expand: nil, additionalClientAttributionMetadata: additionalClientAttributionMetadata) { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testConfirmSetupIntentWithoutClientAttributionMetadata() {
        let sut = stubbedAPIClient()
        AnalyticsHelper.shared.generateSessionID()
        // We only want to include client_attribution_metadata on tokenization with payment method params
        stubClientAttributionMetadata(base: "payment_method_data", shouldContainClientAttributionMetadata: false)
        let e = expectation(description: "")
        let setupIntentParams = STPSetupIntentConfirmParams(clientSecret: "seti_123456_secret_654321")
        sut.confirmSetupIntent(with: setupIntentParams) { _, _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testSharePaymentDetailsWithClientAttributionMetadata() {
        let sut = stubbedAPIClient()
        AnalyticsHelper.shared.generateSessionID()
        stubClientAttributionMetadata(base: "payment_method_options")
        let e = expectation(description: "")
        sut.sharePaymentDetails(for: "consumer_session_client_secret", id: "id", consumerAccountPublishableKey: nil, allowRedisplay: nil, cvc: nil, expectedPaymentMethodType: nil, billingPhoneNumber: nil) { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testSetupIntent_LinkAccountSessionForUSBankAccount() {
        let sut = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains(
                "/setup_intents/seti_12345/link_account_sessions"
            ) ?? false
        } response: { urlRequest in
            guard let data = urlRequest.httpBodyOrBodyStream,
                let body = String(data: data, encoding: .utf8)
            else {
                return HTTPStubsResponse(
                    data: Data("".utf8),
                    statusCode: 400,
                    headers: nil
                )
            }
            XCTAssert(body.contains("client_secret=si_client_secret_123"))
            XCTAssert(
                body.contains(
                    "payment_method_data%5Bbilling_details%5D%5Bemail%5D=test%40example.com"
                )
            )
            XCTAssert(
                body.contains("payment_method_data%5Bbilling_details%5D%5Bname%5D=Test%20Tester")
            )
            XCTAssert(body.contains("payment_method_data%5Btype%5D=us_bank_account"))

            let jsonText = """
                {
                  "id": "xxxxx",
                  "object": "link_account_session",
                  "client_secret": "las_client_secret_123456",
                  "linked_accounts": {
                    "object": "list",
                    "data": [],
                    "has_more": false,
                    "total_count": 0,
                    "url": "/v1/linked_accounts"
                  },
                  "livemode": false
                }
                """
            return HTTPStubsResponse(
                data: jsonText.data(using: .utf8)!,
                statusCode: 200,
                headers: nil
            )
        }

        let expectCallback = expectation(description: "bindings serialize/deserialize")
        sut.createLinkAccountSession(
            setupIntentID: "seti_12345",
            clientSecret: "si_client_secret_123",
            paymentMethodType: .USBankAccount,
            customerName: "Test Tester",
            customerEmailAddress: "test@example.com",
            linkMode: nil
        ) { intent, _ in
            guard let intent = intent else {
                XCTFail("Intent was null")
                return
            }
            XCTAssertEqual(intent.clientSecret, "las_client_secret_123456")
            expectCallback.fulfill()
        }

        wait(for: [expectCallback], timeout: 2.0)
    }

    func testPaymentIntent_LinkAccountSessionForUSBankAccount() {
        let sut = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains(
                "/payment_intents/pi_12345/link_account_sessions"
            ) ?? false
        } response: { urlRequest in
            guard let data = urlRequest.httpBodyOrBodyStream,
                let body = String(data: data, encoding: .utf8)
            else {
                return HTTPStubsResponse(
                    data: Data("".utf8),
                    statusCode: 400,
                    headers: nil
                )
            }
            XCTAssert(body.contains("client_secret=si_client_secret_123"))
            XCTAssert(
                body.contains(
                    "payment_method_data%5Bbilling_details%5D%5Bemail%5D=test%40example.com"
                )
            )
            XCTAssert(
                body.contains("payment_method_data%5Bbilling_details%5D%5Bname%5D=Test%20Tester")
            )
            XCTAssert(body.contains("payment_method_data%5Btype%5D=us_bank_account"))

            let jsonText = """
                {
                  "id": "las_12345",
                  "object": "link_account_session",
                  "client_secret": "las_client_secret_654321",
                  "linked_accounts": {
                    "object": "list",
                    "data": [

                    ],
                    "has_more": false,
                    "total_count": 0,
                    "url": "/v1/linked_accounts"
                  },
                  "livemode": false
                }
                """
            return HTTPStubsResponse(
                data: Data(jsonText.utf8),
                statusCode: 200,
                headers: nil
            )
        }

        let expectCallback = expectation(description: "bindings serialize/deserialize")
        sut.createLinkAccountSession(
            paymentIntentID: "pi_12345",
            clientSecret: "si_client_secret_123",
            paymentMethodType: .USBankAccount,
            customerName: "Test Tester",
            customerEmailAddress: "test@example.com",
            linkMode: nil
        ) { intent, _ in
            guard let intent = intent else {
                XCTFail("Intent was null")
                return
            }
            XCTAssertEqual(intent.clientSecret, "las_client_secret_654321")
            expectCallback.fulfill()
        }

        wait(for: [expectCallback], timeout: 2.0)
    }

    func testSetupIntent_LinkAccountSessionAttach() {
        let sut = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains(
                "/setup_intents/seti_12345/link_account_sessions/las_123456/attach"
            ) ?? false
        } response: { urlRequest in
            guard let data = urlRequest.httpBodyOrBodyStream,
                let body = String(data: data, encoding: .utf8)
            else {
                return HTTPStubsResponse(
                    data: Data("".utf8),
                    statusCode: 400,
                    headers: nil
                )
            }
            XCTAssert(body.contains("client_secret=si_client_secret_123"))

            let jsonText = """
                {
                  "id": "seti_12345",
                  "object": "setup_intent",
                  "cancellation_reason": null,
                  "client_secret": "seti_abc_secret_def",
                  "created": 1647000000,
                  "description": null,
                  "last_setup_error": null,
                  "livemode": false,
                  "next_action": null,
                  "payment_method": "pm_abcdefg",
                  "payment_method_options": {
                    "us_bank_account": {
                      "verification_method": "instant"
                    }
                  },
                  "payment_method_types": [
                    "us_bank_account"
                  ],
                  "status": "requires_confirmation",
                  "usage": "off_session"
                }
                """
            return HTTPStubsResponse(
                data: Data(jsonText.utf8),
                statusCode: 200,
                headers: nil
            )
        }

        let expectCallback = expectation(description: "bindings serialize/deserialize")
        sut.attachLinkAccountSession(
            setupIntentID: "seti_12345",
            linkAccountSessionID: "las_123456",
            clientSecret: "si_client_secret_123"
        ) { intent, _ in
            guard let intent = intent else {
                XCTFail("Intent was null")
                return
            }
            XCTAssertEqual(intent.paymentMethodID, "pm_abcdefg")
            expectCallback.fulfill()
        }

        wait(for: [expectCallback], timeout: 2.0)
    }

    func testPaymentIntent_LinkAccountSessionAttach() {
        let sut = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains(
                "/payment_intents/pi_12345/link_account_sessions/las_123456/attach"
            ) ?? false
        } response: { urlRequest in
            guard let data = urlRequest.httpBodyOrBodyStream,
                let body = String(data: data, encoding: .utf8)
            else {
                return HTTPStubsResponse(
                    data: Data("".utf8),
                    statusCode: 400,
                    headers: nil
                )
            }
            XCTAssert(body.contains("client_secret=pi_client_secret_123"))

            let jsonText = """
                {
                  "id": "pi_12345",
                  "object": "payment_intent",
                  "amount": 100,
                  "currency": "usd",
                  "cancellation_reason": null,
                  "client_secret": "seti_abc_secret_def",
                  "created": 1647000000,
                  "description": null,
                  "last_setup_error": null,
                  "livemode": false,
                  "next_action": null,
                  "payment_method": "pm_abcdefg",
                  "payment_method_options": {
                    "us_bank_account": {
                      "verification_method": "instant"
                    }
                  },
                  "payment_method_types": [
                    "us_bank_account"
                  ],
                  "status": "requires_payment_method"
                }
                """
            return HTTPStubsResponse(
                data: Data(jsonText.utf8),
                statusCode: 200,
                headers: nil
            )
        }

        let expectCallback = expectation(description: "bindings serialize/deserialize")
        sut.attachLinkAccountSession(
            paymentIntentID: "pi_12345",
            linkAccountSessionID: "las_123456",
            clientSecret: "pi_client_secret_123"
        ) { intent, _ in
            guard let intent = intent else {
                XCTFail("Intent was null")
                return
            }
            XCTAssertEqual(intent.paymentMethodId, "pm_abcdefg")
            expectCallback.fulfill()
        }

        wait(for: [expectCallback], timeout: 2.0)
    }
}
