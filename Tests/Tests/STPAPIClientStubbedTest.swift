//
//  STPAPIClientStubbedTest.swift
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

class STPAPIClientStubbedTest: APIStubbedTestCase {
    
    func testSetupIntent_LinkAccountSessionForUSBankAccount() {
        let sut = stubbedAPIClient()
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/setup_intents/seti_12345/link_account_sessions") ?? false
        } response: { urlRequest in
            guard let data = urlRequest.httpBodyOrBodyStream,
                  let body = String(data: data, encoding: .utf8) else {
                      return HTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 400, headers: nil)
                  }
            XCTAssert(body.contains("client_secret=si_client_secret_123"))
            XCTAssert(body.contains("payment_method_data%5Bbilling_details%5D%5Bemail%5D=test%40example.com"))
            XCTAssert(body.contains("payment_method_data%5Bbilling_details%5D%5Bname%5D=Test%20Tester"))
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
            return HTTPStubsResponse(data: jsonText.data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        
        let expectCallback = expectation(description: "bindings serialize/deserialize")
        sut.createLinkAccountSession(setupIntentID: "seti_12345",
                                     clientSecret: "si_client_secret_123",
                                     paymentMethodType: .USBankAccount,
                                     customerName: "Test Tester",
                                     customerEmailAddress: "test@example.com") { intent, error in
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
            return urlRequest.url?.absoluteString.contains("/payment_intents/pi_12345/link_account_sessions") ?? false
        } response: { urlRequest in
            guard let data = urlRequest.httpBodyOrBodyStream,
                  let body = String(data: data, encoding: .utf8) else {
                      return HTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 400, headers: nil)
                  }
            XCTAssert(body.contains("client_secret=si_client_secret_123"))
            XCTAssert(body.contains("payment_method_data%5Bbilling_details%5D%5Bemail%5D=test%40example.com"))
            XCTAssert(body.contains("payment_method_data%5Bbilling_details%5D%5Bname%5D=Test%20Tester"))
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
            return HTTPStubsResponse(data: jsonText.data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        
        let expectCallback = expectation(description: "bindings serialize/deserialize")
        sut.createLinkAccountSession(paymentIntentID: "pi_12345",
                                     clientSecret: "si_client_secret_123",
                                     paymentMethodType: .USBankAccount,
                                     customerName: "Test Tester",
                                     customerEmailAddress: "test@example.com") { intent, error in
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
            return urlRequest.url?.absoluteString.contains("/setup_intents/seti_12345/link_account_sessions/las_123456/attach") ?? false
        } response: { urlRequest in
            guard let data = urlRequest.httpBodyOrBodyStream,
                  let body = String(data: data, encoding: .utf8) else {
                      return HTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 400, headers: nil)
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
            return HTTPStubsResponse(data: jsonText.data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        
        let expectCallback = expectation(description: "bindings serialize/deserialize")
        sut.attachLinkAccountSession(setupIntentID: "seti_12345",
                                     linkAccountSessionID: "las_123456",
                                     clientSecret: "si_client_secret_123") { intent, error in
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
            return urlRequest.url?.absoluteString.contains("/payment_intents/pi_12345/link_account_sessions/las_123456/attach") ?? false
        } response: { urlRequest in
            guard let data = urlRequest.httpBodyOrBodyStream,
                  let body = String(data: data, encoding: .utf8) else {
                      return HTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 400, headers: nil)
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
            return HTTPStubsResponse(data: jsonText.data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        
        let expectCallback = expectation(description: "bindings serialize/deserialize")
        sut.attachLinkAccountSession(paymentIntentID: "pi_12345",
                                     linkAccountSessionID: "las_123456",
                                     clientSecret: "pi_client_secret_123") { intent, error in
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
