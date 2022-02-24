//
//  STPPaymentMethodFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 8/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest
@_spi(STP) import StripeCore // for StripeError
@_spi(STP) @testable import StripeApplePay

let STPTestingDefaultPublishableKey = "pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6"
public let STPTestingNetworkRequestTimeout: TimeInterval = 8

class STPPaymentMethodModernTest: XCTestCase {
    func testCreateCardPaymentMethod() {
        let expectation = self.expectation(description: "Created")
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        var params = StripeAPI.PaymentMethodParams(type: .card)
        var card = StripeAPI.PaymentMethodParams.Card()
        card.number = "4242424242424242"
        card.expYear = 28
        card.expMonth = 12
        card.cvc = "100"
        var billingAddress = StripeAPI.BillingDetails.Address()
        billingAddress.city = "San Francisco"
        billingAddress.country = "US"
        billingAddress.line1 = "150 Townsend St"
        billingAddress.line2 = "4th Floor"
        billingAddress.postalCode = "94103"
        billingAddress.state = "CA"
        
        var billingDetails = StripeAPI.BillingDetails()
        billingDetails.address = billingAddress
        billingDetails.email = "email@email.com"
        billingDetails.name = "Isaac Asimov"
        billingDetails.phone = "555-555-5555"

        params.card = card
        params.billingDetails = billingDetails
        
        StripeAPI.PaymentMethod.create(apiClient: apiClient, params: params) { result in
            let paymentMethod = try! result.get()
            XCTAssertEqual(paymentMethod.card?.last4, "4242")
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
    
    func testCreateCardPaymentMethodWithAdditionalAPIStuff() {
        let expectation = self.expectation(description: "Created")
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        var params = StripeAPI.PaymentMethodParams(type: .card)
        var card = StripeAPI.PaymentMethodParams.Card()
        card.number = "4242424242424242"
        card.expYear = 28
        card.expMonth = 12
        card.cvc = "100"
        var billingAddress = StripeAPI.BillingDetails.Address()
        billingAddress.city = "San Francisco"
        billingAddress.country = "US"
        billingAddress.line1 = "150 Townsend St"
        billingAddress.line2 = "4th Floor"
        billingAddress.postalCode = "94103"
        billingAddress.state = "CA"
        billingAddress.additionalParameters = ["invalid_thing": "yes"]
        
        var billingDetails = StripeAPI.BillingDetails()
        billingDetails.address = billingAddress
        billingDetails.email = "email@email.com"
        billingDetails.name = "Isaac Asimov"
        billingDetails.phone = "555-555-5555"

        params.card = card
        params.billingDetails = billingDetails
        
        StripeAPI.PaymentMethod.create(apiClient: apiClient, params: params) { result in
            do {
                _ = try result.get()
            }
            catch {
                let stripeError = error as? StripeError
                if case .apiError(let apiError) = stripeError {
                    XCTAssertEqual(apiError.code, "parameter_unknown")
                    XCTAssertEqual(apiError.param, "billing_details[address][invalid_thing]")
                    expectation.fulfill()
                }
            }
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
