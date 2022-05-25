//
//  ServerErrorMapperTest.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 9/13/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe
@testable import StripeCore

class ServerErrorMapperTest: XCTestCase {

    func testFromMissingPublishableKey() {
        let serverErrorMessage = "You did not provide an API key. You need to provide your API key in the Authorization header, using Bearer auth (e.g. \'Authorization: Bearer YOUR_SECRET_KEY\'). See https://stripe.com/docs/api#authentication for details, or we can help at https://support.stripe.com/."
        
        XCTAssertTrue(ServerErrorMapper.mobileErrorMessage(from: serverErrorMessage, httpResponse: HTTPURLResponse())!.hasPrefix("No valid API key provided. Set `STPAPIClient.shared()"))
    }
    
    func testFromInvalidPublishableKey() {
        let serverErrorMessage = "Invalid API Key provided: pk_test"
        
        XCTAssertTrue(ServerErrorMapper.mobileErrorMessage(from: serverErrorMessage, httpResponse: HTTPURLResponse())!.hasPrefix("No valid API key provided. Set `STPAPIClient.shared()"))
    }
    
    func testFromInvalidCustEphKey() {
        let serverErrorMessage = "Invalid API Key provided: badCustEphKey"
        
        let url = URL(string: "https://api.stripe.com/v1/payment_methods?customer=")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)
        XCTAssertTrue(ServerErrorMapper.mobileErrorMessage(from: serverErrorMessage, httpResponse: httpResponse)!.hasPrefix("Invalid customer ephemeral key secret."))
    }
    
    func testFromNoSuchPaymentIntent() {
        let serverErrorMessage = "No such payment_intent: pi_123"
        
        XCTAssertTrue(ServerErrorMapper.mobileErrorMessage(from: serverErrorMessage, httpResponse: HTTPURLResponse())!.hasPrefix("No matching PaymentIntent could"))
    }
    
    func testFromNoSuchSetupIntent() {
        let serverErrorMessage = "No such setup_intent: si_123"
        
        XCTAssertTrue(ServerErrorMapper.mobileErrorMessage(from: serverErrorMessage, httpResponse: HTTPURLResponse())!.hasPrefix("No matching SetupIntent could"))
    }
    
    func testFromUnknownErrorMessage() {
        let serverErrorMessage = "This error message is not known to ServerErrorMapper, should return nil."
        
        XCTAssertNil(ServerErrorMapper.mobileErrorMessage(from: serverErrorMessage, httpResponse: HTTPURLResponse()))
    }

}
