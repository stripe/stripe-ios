//
//  STPPaymentHandlerStubbedMockedFilesTests.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeApplePay

import StripeCoreTestUtils
import OHHTTPStubs

class STPPaymentHandlerStubbedMockedFilesTests: APIStubbedTestCase, STPAuthenticationContext {
    override func setUp() {
        let expectation = expectation(description: "Load Specs")
        FormSpecProvider.shared.load { success in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testCallConfirmAfterpay_Redirect_thenCanceled() {
        let nextActionData = """
          {
            "redirect_to_url": {
              "return_url": "payments-example://stripe-redirect",
              "url": "https://hooks.stripe.com/afterpay_clearpay/acct_123/pa_nonce_321/redirect"
            },
            "type": "redirect_to_url"
          }
        """
        let paymentMethod = """
          {
            "id": "pm_123123123123123",
            "object": "payment_method",
            "afterpay_clearpay": {},
            "billing_details": {
              "address": {
                "city": "San Francisco",
                "country": "AT",
                "line1": "510 Townsend St.",
                "line2": "",
                "postal_code": "94102",
                "state": null
              },
              "email": "foo@bar.com",
              "name": "Jane Doe",
              "phone": null
            },
            "created": 1658187899,
            "customer": null,
            "livemode": false,
            "type": "afterpay_clearpay"
          }
        """
        stubConfirm(fileMock: .paymentIntentResponse, responseCallback: { data in
            self.replaceData(data: data, variables: ["<next_action>": nextActionData,
                                                     "<payment_method>": paymentMethod,
                                                     "<status>" : "\"requires_action\""])
        })

        let paymentHandler = STPPaymentHandler(apiClient: stubbedAPIClient())
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.returnURL = "payments-example://stripe-redirect"
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(afterpayClearpay: STPPaymentMethodAfterpayClearpayParams(),
                                                                         billingDetails: STPPaymentMethodBillingDetails(),
                                                                         metadata: nil)
        paymentIntentParams.paymentMethodParams?.afterpayClearpay = STPPaymentMethodAfterpayClearpayParams()
        let didRedirect = expectation(description: "didRedirect")
        paymentHandler._redirectShim = { redirectTo, returnToURL in
            XCTAssertEqual(redirectTo.absoluteString, "https://hooks.stripe.com/afterpay_clearpay/acct_123/pa_nonce_321/redirect")
            XCTAssertEqual(returnToURL?.absoluteString, "payments-example://stripe-redirect")
            didRedirect.fulfill()
        }
        let expectConfirmWasCanceled = expectation(description: "didCancel")
        paymentHandler.confirmPayment(paymentIntentParams, with: self) { status, paymentIntent, error in
            if case .canceled = status {
                expectConfirmWasCanceled.fulfill()
            }
        }
        guard XCTWaiter.wait(for: [didRedirect], timeout: 2.0) != .timedOut else {
            XCTFail("Unable to redirect")
            return
        }

        //Test the cancel case
        stubRetrievePaymentIntent(fileMock: .paymentIntentResponse, responseCallback: {data in
            self.replaceData(data: data, variables: ["<next_action>": nextActionData,
                                                     "<payment_method>": paymentMethod,
                                                     "<status>" : "\"requires_action\""])
        })
        paymentHandler._retrieveAndCheckIntentForCurrentAction()
        wait(for: [expectConfirmWasCanceled], timeout: 2.0)
    }

    func testCallConfirmAfterpay_Redirect_thenSucceeded() {
        let nextActionData = """
          {
            "redirect_to_url": {
              "return_url": "payments-example://stripe-redirect",
              "url": "https://hooks.stripe.com/afterpay_clearpay/acct_123/pa_nonce_321/redirect"
            },
            "type": "redirect_to_url"
          }
        """
        let paymentMethod = """
          {
            "id": "pm_123123123123123",
            "object": "payment_method",
            "afterpay_clearpay": {},
            "billing_details": {
              "address": {
                "city": "San Francisco",
                "country": "AT",
                "line1": "510 Townsend St.",
                "line2": "",
                "postal_code": "94102",
                "state": null
              },
              "email": "foo@bar.com",
              "name": "Jane Doe",
              "phone": null
            },
            "created": 1658187899,
            "customer": null,
            "livemode": false,
            "type": "afterpay_clearpay"
          }
        """
        stubConfirm(fileMock: .paymentIntentResponse, responseCallback: { data in
            self.replaceData(data: data, variables: ["<next_action>": nextActionData,
                                                     "<payment_method>": paymentMethod,
                                                     "<status>" : "\"requires_action\""])
        })

        let paymentHandler = STPPaymentHandler(apiClient: stubbedAPIClient())
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.returnURL = "payments-example://stripe-redirect"
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(afterpayClearpay: STPPaymentMethodAfterpayClearpayParams(),
                                                                         billingDetails: STPPaymentMethodBillingDetails(),
                                                                         metadata: nil)
        paymentIntentParams.paymentMethodParams?.afterpayClearpay = STPPaymentMethodAfterpayClearpayParams()
        let didRedirect = expectation(description: "didRedirect")
        paymentHandler._redirectShim = { redirectTo, returnToURL in
            XCTAssertEqual(redirectTo.absoluteString, "https://hooks.stripe.com/afterpay_clearpay/acct_123/pa_nonce_321/redirect")
            XCTAssertEqual(returnToURL?.absoluteString, "payments-example://stripe-redirect")
            didRedirect.fulfill()
        }
        let expectConfirmSucceeded = expectation(description: "didSucceed")
        paymentHandler.confirmPayment(paymentIntentParams, with: self) { status, paymentIntent, error in
            if case .succeeded = status {
                expectConfirmSucceeded.fulfill()
            }
        }
        guard XCTWaiter.wait(for: [didRedirect], timeout: 2.0) != .timedOut else {
            XCTFail("Unable to redirect")
            return
        }

        // Test status as succeeded
        stubRetrievePaymentIntent(fileMock: .paymentIntentResponse, responseCallback: {data in
            self.replaceData(data: data, variables: ["<next_action>": nextActionData,
                                                     "<payment_method>": paymentMethod,
                                                     "<status>" : "\"succeeded\""])
        })
        paymentHandler._retrieveAndCheckIntentForCurrentAction()
        wait(for: [expectConfirmSucceeded], timeout: 2.0)
    }

    func testCallConfirmAfterpay_Redirect_thenSucceeded_withoutNextActionSpec() {
        // Validate affirm is read in with next action spec
        guard let affirm = FormSpecProvider.shared.formSpec(for: "affirm"),
              affirm.fields.count == 1,
              affirm.fields.first == .affirm_header,
              case .redirect_to_url = affirm.nextActionSpec?.confirmResponseStatusSpecs["requires_action"]?.type,
              case .finished = affirm.nextActionSpec?.postConfirmHandlingPiStatusSpecs?["succeeded"]?.type,
              case .canceled = affirm.nextActionSpec?.postConfirmHandlingPiStatusSpecs?["requires_action"]?.type else {
            XCTFail()
            return
        }

        // Override it with a spec that doesn't define a next action so that we force the SDK to default behavior
        let updatedSpecJson =
        """
        [{
            "type": "affirm",
            "async": false,
            "fields": [
                {
                    "type": "name"
                }
            ]
        }]
        """.data(using: .utf8)!
        let formSpec = try! JSONSerialization.jsonObject(with: updatedSpecJson) as! [NSDictionary]
        FormSpecProvider.shared.load(from: formSpec)
        guard let affirmUpdated = FormSpecProvider.shared.formSpec(for: "affirm") else {
            XCTFail()
            return
        }
        XCTAssertNil(affirmUpdated.nextActionSpec)


        let nextActionData = """
          {
            "redirect_to_url": {
              "return_url": "payments-example://stripe-redirect",
              "url": "https://hooks.stripe.com/affirm/acct_123/pa_nonce_321/redirect"
            },
            "type": "redirect_to_url"
          }
        """
        let paymentMethod = """
          {
            "id": "pm_123123123123123",
            "object": "payment_method",
            "afterpay_clearpay": {},
            "billing_details": {
              "address": {
                "city": "San Francisco",
                "country": "AT",
                "line1": "510 Townsend St.",
                "line2": "",
                "postal_code": "94102",
                "state": null
              },
              "email": "foo@bar.com",
              "name": "Jane Doe",
              "phone": null
            },
            "created": 1658187899,
            "customer": null,
            "livemode": false,
            "type": "afterpay_clearpay"
          }
        """
        stubConfirm(fileMock: .paymentIntentResponse, responseCallback: { data in
            self.replaceData(data: data, variables: ["<next_action>": nextActionData,
                                                     "<payment_method>": paymentMethod,
                                                     "<status>" : "\"requires_action\""])
        })

        let paymentHandler = STPPaymentHandler(apiClient: stubbedAPIClient())
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.returnURL = "payments-example://stripe-redirect"
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(afterpayClearpay: STPPaymentMethodAfterpayClearpayParams(),
                                                                         billingDetails: STPPaymentMethodBillingDetails(),
                                                                         metadata: nil)
        paymentIntentParams.paymentMethodParams?.afterpayClearpay = STPPaymentMethodAfterpayClearpayParams()
        let didRedirect = expectation(description: "didRedirect")
        paymentHandler._redirectShim = { redirectTo, returnToURL in
            XCTAssertEqual(redirectTo.absoluteString, "https://hooks.stripe.com/affirm/acct_123/pa_nonce_321/redirect")
            XCTAssertEqual(returnToURL?.absoluteString, "payments-example://stripe-redirect")
            didRedirect.fulfill()
        }
        let expectConfirmSucceeded = expectation(description: "didSucceed")
        paymentHandler.confirmPayment(paymentIntentParams, with: self) { status, paymentIntent, error in
            if case .succeeded = status {
                expectConfirmSucceeded.fulfill()
            }
        }
        guard XCTWaiter.wait(for: [didRedirect], timeout: 2.0) != .timedOut else {
            XCTFail("Unable to redirect")
            return
        }

        // Test status as succeeded
        stubRetrievePaymentIntent(fileMock: .paymentIntentResponse, responseCallback: {data in
            self.replaceData(data: data, variables: ["<next_action>": nextActionData,
                                                     "<payment_method>": paymentMethod,
                                                     "<status>" : "\"succeeded\""])
        })
        paymentHandler._retrieveAndCheckIntentForCurrentAction()
        wait(for: [expectConfirmSucceeded], timeout: 2.0)
    }

    private func replaceData(data: Data, variables: [String:String]) -> Data {
        var template = String(data: data, encoding: .utf8)!
        for (templateKey, templateValue) in variables {
            let translated = template.replacingOccurrences(of: templateKey, with: templateValue)
            template = translated
        }
        return template.data(using: .utf8)!
    }

    private func stubConfirm(fileMock: FileMock, responseCallback: ((Data) -> Data)? = nil) {
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/confirm") ?? false
        } response: { urlRequest in
            let mockResponseData = try! fileMock.data()
            let data = responseCallback?(mockResponseData) ?? mockResponseData
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
    }
    private func stubRetrievePaymentIntent(fileMock: FileMock, responseCallback: ((Data) -> Data)? = nil) {
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/payment_intents") ?? false
        } response: { urlRequest in
            let mockResponseData = try! fileMock.data()
            let data = responseCallback?(mockResponseData) ?? mockResponseData
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
    }
}
extension STPPaymentHandlerStubbedMockedFilesTests {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

public class ClassForBundle { }
@_spi(STP) public enum FileMock: String, MockData {
    public typealias ResponseType = StripeFile
    public var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case paymentIntentResponse = "MockFiles/paymentIntentResponse"
}
