//
//  STPPaymentHandlerStubbedMockedFilesTests.swift
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
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentHandlerStubbedMockedFilesTests: APIStubbedTestCase, STPAuthenticationContext {
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
        let paymentHandler = stubbedPaymentHandler(formSpecProvider: formSpecProvider())
        stubConfirm(
            fileMock: .paymentIntentResponse,
            responseCallback: { data in
                self.replaceData(
                    data: data,
                    variables: [
                        "<next_action>": nextActionData,
                        "<payment_method>": paymentMethod,
                        "<status>": "\"requires_action\"",
                    ]
                )
            }
        )

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.returnURL = "payments-example://stripe-redirect"
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            afterpayClearpay: STPPaymentMethodAfterpayClearpayParams(),
            billingDetails: STPPaymentMethodBillingDetails(),
            metadata: nil
        )
        paymentIntentParams.paymentMethodParams?.afterpayClearpay =
            STPPaymentMethodAfterpayClearpayParams()
        let didRedirect = expectation(description: "didRedirect")
        paymentHandler._redirectShim = { redirectTo, returnToURL, isStandardRedirect in
            XCTAssertEqual(
                redirectTo.absoluteString,
                "https://hooks.stripe.com/afterpay_clearpay/acct_123/pa_nonce_321/redirect"
            )
            XCTAssertEqual(returnToURL?.absoluteString, "payments-example://stripe-redirect")
            XCTAssert(isStandardRedirect)
            didRedirect.fulfill()
        }
        let expectConfirmWasCanceled = expectation(description: "didCancel")
        paymentHandler.confirmPayment(paymentIntentParams, with: self) {
            status,
            _,
            _ in
            if case .canceled = status {
                expectConfirmWasCanceled.fulfill()
            }
        }
        guard XCTWaiter.wait(for: [didRedirect], timeout: 2.0) != .timedOut else {
            XCTFail("Unable to redirect")
            return
        }

        // Test the cancel case
        stubRetrievePaymentIntent(
            fileMock: .paymentIntentResponse,
            responseCallback: { data in
                self.replaceData(
                    data: data,
                    variables: [
                        "<next_action>": nextActionData,
                        "<payment_method>": paymentMethod,
                        "<status>": "\"requires_action\"",
                    ]
                )
            }
        )
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
        let paymentMethodData = """
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
        let paymentHandler = stubbedPaymentHandler(formSpecProvider: formSpecProvider())
        stubConfirm(
            fileMock: .paymentIntentResponse,
            responseCallback: { data in
                self.replaceData(
                    data: data,
                    variables: [
                        "<next_action>": nextActionData,
                        "<payment_method>": paymentMethodData,
                        "<status>": "\"requires_action\"",
                    ]
                )
            }
        )

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.returnURL = "payments-example://stripe-redirect"
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            afterpayClearpay: STPPaymentMethodAfterpayClearpayParams(),
            billingDetails: STPPaymentMethodBillingDetails(),
            metadata: nil
        )
        paymentIntentParams.paymentMethodParams?.afterpayClearpay =
            STPPaymentMethodAfterpayClearpayParams()
        let didRedirect = expectation(description: "didRedirect")
        paymentHandler._redirectShim = { redirectTo, returnToURL, isStandardRedirect in
            XCTAssertEqual(
                redirectTo.absoluteString,
                "https://hooks.stripe.com/afterpay_clearpay/acct_123/pa_nonce_321/redirect"
            )
            XCTAssertEqual(returnToURL?.absoluteString, "payments-example://stripe-redirect")
            XCTAssert(isStandardRedirect)
            didRedirect.fulfill()
        }
        confirmPaymentWithSucceed(nextActionData: nextActionData,
                                  paymentMethodData: paymentMethodData,
                                  didRedirect: didRedirect,
                                  paymentHandler: paymentHandler,
                                  paymentIntentParams: paymentIntentParams)
    }

    func testRedirectStrategy_external_browser() {
        let nextActionData = """
              {
                "redirect_to_url": {
                  "return_url": "payments-example://stripe-redirect",
                  "url": "https://hooks.stripe.com/affirm/acct_123/pa_nonce_321/redirect"
                },
                "type": "redirect_to_url"
              }
            """
        let paymentMethodData = """
              {
                "id": "pm_123123123123123",
                "object": "payment_method",
                "affirm": {},
                "created": 1658187899,
                "customer": null,
                "livemode": false,
                "type": "affirm"
              }
            """

        let formSpecProvider = formSpecProvider()
        let paymentHandler = stubbedPaymentHandler(formSpecProvider: formSpecProvider)
        stubConfirm(
            fileMock: .paymentIntentResponse,
            responseCallback: { data in
                self.replaceData(
                    data: data,
                    variables: [
                        "<next_action>": nextActionData,
                        "<payment_method>": paymentMethodData,
                        "<status>": "\"requires_action\"",
                    ]
                )
            }
        )
        XCTAssertTrue(formSpecProvider.loadFrom(affirmSpec(redirectStrategy: "external_browser")))
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.returnURL = "payments-example://stripe-redirect"
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(affirm: STPPaymentMethodAffirmParams(),
                                                                         metadata: nil)
        let didRedirect = expectation(description: "didRedirect")
        paymentHandler._redirectShim = { redirectTo, returnToURL, isStandardRedirect in
            XCTAssertEqual(
                redirectTo.absoluteString,
                "https://hooks.stripe.com/affirm/acct_123/pa_nonce_321/redirect"
            )
            XCTAssertEqual(returnToURL?.absoluteString, "payments-example://stripe-redirect")
            XCTAssertFalse(isStandardRedirect)
            didRedirect.fulfill()
        }
        confirmPaymentWithSucceed(nextActionData: nextActionData,
                                  paymentMethodData: paymentMethodData,
                                  didRedirect: didRedirect,
                                  paymentHandler: paymentHandler,
                                  paymentIntentParams: paymentIntentParams)
    }

    func testRedirectStrategy_follow_redirects() {
        let nextActionData = """
              {
                "redirect_to_url": {
                  "return_url": "payments-example://stripe-redirect",
                  "url": "https://hooks.stripe.com/affirm/acct_123/pa_nonce_321/redirect"
                },
                "type": "redirect_to_url"
              }
            """
        let paymentMethodData = """
              {
                "id": "pm_123123123123123",
                "object": "payment_method",
                "affirm": {},
                "created": 1658187899,
                "customer": null,
                "livemode": false,
                "type": "affirm"
              }
            """
        let formSpecProvider = formSpecProvider()
        let paymentHandler = stubbedPaymentHandler(formSpecProvider: formSpecProvider)
        stubConfirm(
            fileMock: .paymentIntentResponse,
            responseCallback: { data in
                self.replaceData(
                    data: data,
                    variables: [
                        "<next_action>": nextActionData,
                        "<payment_method>": paymentMethodData,
                        "<status>": "\"requires_action\"",
                    ]
                )
            }
        )
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/affirm/acct_123") ?? false
        } response: { _ in
            let data = "<>".data(using: .utf8)!
            return HTTPStubsResponse(data: data, statusCode: 302, headers: ["Location": "https://www.financial-partner.com/"])
        }
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("financial-partner.com") ?? false
        } response: { _ in
            let data = "".data(using: .utf8)!
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }

        XCTAssertTrue(formSpecProvider.loadFrom(affirmSpec(redirectStrategy: "follow_redirects")))
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.returnURL = "payments-example://stripe-redirect"
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(affirm: STPPaymentMethodAffirmParams(),
                                                                         metadata: nil)
        let didRedirect = expectation(description: "didRedirect")
        paymentHandler._redirectShim = { redirectTo, returnToURL, isStandardRedirect in
            XCTAssertEqual(redirectTo.absoluteString, "https://www.financial-partner.com/")
            XCTAssertEqual(returnToURL?.absoluteString, "payments-example://stripe-redirect")
            XCTAssert(isStandardRedirect)
            didRedirect.fulfill()
        }
        confirmPaymentWithSucceed(nextActionData: nextActionData,
                                  paymentMethodData: paymentMethodData,
                                  didRedirect: didRedirect,
                                  paymentHandler: paymentHandler,
                                  paymentIntentParams: paymentIntentParams)
    }

    func testCallConfirmAfterpay_Redirect_thenSucceeded_withoutNextActionSpec() {
        let formSpecProvider = formSpecProvider()
        let paymentHandler = stubbedPaymentHandler(formSpecProvider: formSpecProvider)
        // Validate affirm is read in with next action spec
        guard let affirm = formSpecProvider.formSpec(for: "affirm"),
            affirm.fields.count == 1,
            affirm.fields.first == .affirm_header,
            case .redirect_to_url = affirm.nextActionSpec?.confirmResponseStatusSpecs[
                "requires_action"
            ]?.type,
            case .finished = affirm.nextActionSpec?.postConfirmHandlingPiStatusSpecs?["succeeded"]?
                .type,
            case .canceled = affirm.nextActionSpec?.postConfirmHandlingPiStatusSpecs?[
                "requires_action"
            ]?.type
        else {
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
        XCTAssert(formSpecProvider.loadFrom(formSpec))
        guard let affirmUpdated = formSpecProvider.formSpec(for: "affirm") else {
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
        let paymentMethodData = """
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
        stubConfirm(
            fileMock: .paymentIntentResponse,
            responseCallback: { data in
                self.replaceData(
                    data: data,
                    variables: [
                        "<next_action>": nextActionData,
                        "<payment_method>": paymentMethodData,
                        "<status>": "\"requires_action\"",
                    ]
                )
            }
        )

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "pi_123456_secret_654321")
        paymentIntentParams.returnURL = "payments-example://stripe-redirect"
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            afterpayClearpay: STPPaymentMethodAfterpayClearpayParams(),
            billingDetails: STPPaymentMethodBillingDetails(),
            metadata: nil
        )
        paymentIntentParams.paymentMethodParams?.afterpayClearpay =
            STPPaymentMethodAfterpayClearpayParams()
        let didRedirect = expectation(description: "didRedirect")
        paymentHandler._redirectShim = { redirectTo, returnToURL, isStandardRedirect in
            XCTAssertEqual(
                redirectTo.absoluteString,
                "https://hooks.stripe.com/affirm/acct_123/pa_nonce_321/redirect"
            )
            XCTAssertEqual(returnToURL?.absoluteString, "payments-example://stripe-redirect")
            XCTAssert(isStandardRedirect)
            didRedirect.fulfill()
        }
        confirmPaymentWithSucceed(nextActionData: nextActionData,
                                  paymentMethodData: paymentMethodData,
                                  didRedirect: didRedirect,
                                  paymentHandler: paymentHandler,
                                  paymentIntentParams: paymentIntentParams)
    }
    private func confirmPaymentWithSucceed(
        nextActionData: String,
        paymentMethodData: String,
        didRedirect: XCTestExpectation,
        paymentHandler: STPPaymentHandler,
        paymentIntentParams: STPPaymentIntentParams
    ) {
        let expectConfirmSucceeded = expectation(description: "didSucceed")
        paymentHandler.confirmPayment(paymentIntentParams, with: self) {
            status,
            _,
            _ in
            if case .succeeded = status {
                expectConfirmSucceeded.fulfill()
            }
        }
        guard XCTWaiter.wait(for: [didRedirect], timeout: 2.0) != .timedOut else {
            XCTFail("Unable to redirect")
            return
        }

        // Test status as succeeded
        stubRetrievePaymentIntent(
            fileMock: .paymentIntentResponse,
            responseCallback: { data in
                self.replaceData(
                    data: data,
                    variables: [
                        "<next_action>": nextActionData,
                        "<payment_method>": paymentMethodData,
                        "<status>": "\"succeeded\"",
                    ]
                )
            }
        )
        paymentHandler._retrieveAndCheckIntentForCurrentAction()
        wait(for: [expectConfirmSucceeded], timeout: 2.0)
    }

    private func formSpecProvider() -> FormSpecProvider {
        let expectation = expectation(description: "Load Specs")
        let formSpecProvider = FormSpecProvider()
        formSpecProvider.load { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        return formSpecProvider
    }

    private func stubbedPaymentHandler(formSpecProvider: FormSpecProvider) -> STPPaymentHandler {
        let stubbedAPIClient = stubbedAPIClient()
        let paymentSheetFormSpecHandler = PaymentSheetFormSpecPaymentHandler(urlSession: stubbedAPIClient.urlSession,
                                                                             formSpecProvider: formSpecProvider)
        return STPPaymentHandler(apiClient: stubbedAPIClient,
                                 formSpecPaymentHandler: paymentSheetFormSpecHandler)
    }

    private func replaceData(data: Data, variables: [String: String]) -> Data {
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
        } response: { _ in
            let mockResponseData = try! fileMock.data()
            let data = responseCallback?(mockResponseData) ?? mockResponseData
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
    }
    private func stubRetrievePaymentIntent(
        fileMock: FileMock,
        responseCallback: ((Data) -> Data)? = nil
    ) {
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/payment_intents") ?? false
        } response: { _ in
            let mockResponseData = try! fileMock.data()
            let data = responseCallback?(mockResponseData) ?? mockResponseData
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }
    }
    private func affirmSpec(redirectStrategy: String) -> [NSDictionary] {
        let formSpec =
            """
            [{
                "type": "affirm",
                "async": false,
                "fields": [
                    {
                        "type": "affirm_header"
                    }
                ],
                "next_action_spec": {
                    "confirm_response_status_specs": {
                        "requires_action": {
                            "type": "redirect_to_url",
                            "native_mobile_redirect_strategy": "\(redirectStrategy)"
                        }
                    },
                    "post_confirm_handling_pi_status_specs": {
                        "succeeded": {
                            "type": "finished"
                        }
                    }
                }
            }]
            """.data(using: .utf8)!
        return try! JSONSerialization.jsonObject(with: formSpec) as! [NSDictionary]
    }
}
extension STPPaymentHandlerStubbedMockedFilesTests {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

public class ClassForBundle {}
@_spi(STP) public enum FileMock: String, MockData {
    public typealias ResponseType = StripeFile
    public var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case paymentIntentResponse = "MockFiles/paymentIntentResponse"
}
