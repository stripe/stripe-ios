//
//  TelemetryInjectionTest.swift
//  StripeApplePayTests
//
//  Created by David Estes on 2/9/22.
//

import Foundation
import OHHTTPStubs
import StripeCoreTestUtils
@_spi(STP) @testable import StripeApplePay
@_spi(STP) @testable import StripeCore
import AVFoundation
import XCTest

class TelemetryInjectionTest: APIStubbedTestCase {
    func testIntentConfirmAddsTelemetry() {
        let apiClient = stubbedAPIClient()
        
        let piTelemetryExpectation = self.expectation(description: "saw pi telemetry")
        let siTelemetryExpectation = self.expectation(description: "saw si telemetry")
        
        // As an implementation detail, OHHTTPStubs will run this block in `canInitWithRequest` in addition to
        // `initWithRequest`. So it could be called more times than we expect.
        // We don't have control over this behavior (CFNetwork drives it), so let's not worry
        // about overfulfillment.
        piTelemetryExpectation.assertForOverFulfill = false
        siTelemetryExpectation.assertForOverFulfill = false
        
        stub { urlRequest in
            if urlRequest.url!.absoluteString.contains("_intent") {
                let ua = urlRequest.queryItems!.first(where: { $0.name == "payment_method_data[payment_user_agent]" })!.value!
                XCTAssertTrue(ua.hasPrefix("stripe-ios/"))
                let muid = urlRequest.queryItems!.first(where: { $0.name == "payment_method_data[muid]" })!.value!
                let guid = urlRequest.queryItems!.first(where: { $0.name == "payment_method_data[guid]" })!.value!
                XCTAssertNotNil(muid)
                XCTAssertNotNil(guid)
                if urlRequest.url!.absoluteString.contains("payment_intent") {
                    piTelemetryExpectation.fulfill()
                }
                if urlRequest.url!.absoluteString.contains("setup_intent") {
                    siTelemetryExpectation.fulfill()
                }
                return true
            }
            return false
        } response: { urlRequest in
            // We don't care about the response
            return HTTPStubsResponse()
        }
        
        let params = StripeAPI.PaymentMethodParams(type: .card)
        var card = StripeAPI.PaymentMethodParams.Card()
        card.number = "4242424242424242"
        card.expYear = 28
        card.expMonth = 12
        card.cvc = "100"

        // Set up telemetry data
        StripeAPI.advancedFraudSignalsEnabled = true
        FraudDetectionData.shared.sid = "sid"
        FraudDetectionData.shared.muid = "muid"
        FraudDetectionData.shared.guid = "guid"
        FraudDetectionData.shared.sidCreationDate = Date()
        
        let piExpectation = self.expectation(description: "PI Confirmed")
        var pip = StripeAPI.PaymentIntentParams(clientSecret: "pi_123_secret_abc")
        pip.paymentMethodData = params
        StripeAPI.PaymentIntent.confirm(apiClient: apiClient, params: pip) { _ in
            piExpectation.fulfill()
        }
        
        let siExpectation = self.expectation(description: "SI Confirmed")
        var sip = StripeAPI.SetupIntentConfirmParams(clientSecret: "seti_123_secret_abc")
        sip.paymentMethodData = params
        StripeAPI.SetupIntent.confirm(apiClient: apiClient, params: sip) { _ in
            siExpectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}


