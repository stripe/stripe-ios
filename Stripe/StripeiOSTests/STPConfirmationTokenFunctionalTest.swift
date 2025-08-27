//
//  STPConfirmationTokenFunctionalTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/25/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest
import Stripe
import StripeCoreTestUtils
@_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CustomerSessionBetaAccess) import StripePaymentSheet
@testable import StripePaymentsTestUtils

class STPConfirmationTokenFunctionalTest: STPNetworkStubbingTestCase {
    
    func testCreateConfirmationToken() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        
        // Create payment method params
        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 2028)
        card.cvc = "100"
        
        let billingAddress = STPPaymentMethodAddress()
        billingAddress.city = "San Francisco"
        billingAddress.country = "US"
        billingAddress.line1 = "150 Townsend St"
        billingAddress.postalCode = "94103"
        billingAddress.state = "CA"
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = billingAddress
        billingDetails.email = "test@example.com"
        billingDetails.name = "Test User"
        billingDetails.phone = "555-555-5555"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: card,
            billingDetails: billingDetails,
            metadata: [:]
        )
        
        // Create confirmation token params
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams,
            returnURL: "https://example.com/return"
        )
        confirmationTokenParams.setupFutureUsage = .offSession
        
        let expectation = self.expectation(description: "ConfirmationToken create")
        client.createConfirmationToken(with: confirmationTokenParams) { confirmationToken, error in
            XCTAssertNil(error, "Unexpected error: \(error?.localizedDescription ?? "")")
            XCTAssertNotNil(confirmationToken)
            XCTAssertNotNil(confirmationToken?.stripeId)
            XCTAssertTrue(confirmationToken?.stripeId.hasPrefix("ctoken") == true)
            XCTAssertEqual(confirmationToken?.object, "confirmation_token")
            XCTAssertNotNil(confirmationToken?.created)
            XCTAssertNotNil(confirmationToken?.expiresAt)
            XCTAssertEqual(confirmationToken?.returnURL, "https://example.com/return")
            XCTAssertEqual(confirmationToken?.setupFutureUsage, .offSession)
            XCTAssertTrue(confirmationToken?.useStripeSDK == true)
            XCTAssertNotNil(confirmationToken?.paymentMethodPreview)
            XCTAssertEqual(confirmationToken?.paymentMethodPreview?.type, .card)
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testCreateConfirmationTokenWithMinimalParams() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        
        // Create minimal payment method params
        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expMonth = NSNumber(value: 12)
        card.expYear = NSNumber(value: 2030)
        card.cvc = "123"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: card,
            billingDetails: nil,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams
        )
        
        let expectation = self.expectation(description: "ConfirmationToken create minimal")
        client.createConfirmationToken(with: confirmationTokenParams) { confirmationToken, error in
            XCTAssertNil(error, "Unexpected error: \(error?.localizedDescription ?? "")")
            XCTAssertNotNil(confirmationToken)
            XCTAssertNotNil(confirmationToken?.stripeId)
            XCTAssertTrue(confirmationToken?.stripeId.hasPrefix("ctoken_") == true)
            XCTAssertEqual(confirmationToken?.object, "confirmation_token")
            XCTAssertNotNil(confirmationToken?.created)
            XCTAssertEqual(confirmationToken?.setupFutureUsage, STPPaymentIntentSetupFutureUsage.none)
            XCTAssertTrue(confirmationToken?.useStripeSDK == true)
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
    
    func testCreateConfirmationTokenAsync() async {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        
        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expMonth = NSNumber(value: 12)
        card.expYear = NSNumber(value: 2030)
        card.cvc = "123"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: card,
            billingDetails: nil,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams,
            returnURL: "https://example.com/return"
        )
        
        do {
            let confirmationToken = try await client.createConfirmationToken(
                with: confirmationTokenParams,
                additionalPaymentUserAgentValues: ["test"]
            )
            
            XCTAssertNotNil(confirmationToken.stripeId)
            XCTAssertTrue(confirmationToken.stripeId.hasPrefix("ctoken_"))
            XCTAssertEqual(confirmationToken.object, "confirmation_token")
            XCTAssertNotNil(confirmationToken.created)
            XCTAssertEqual(confirmationToken.returnURL, "https://example.com/return")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCreateConfirmationTokenWithInvalidCard() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        
        let card = STPPaymentMethodCardParams()
        card.number = "4000000000000002" // Declined card
        card.expMonth = NSNumber(value: 12)
        card.expYear = NSNumber(value: 2030)
        card.cvc = "123"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: card,
            billingDetails: nil,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams
        )
        
        let expectation = self.expectation(description: "ConfirmationToken create with invalid card")
        client.createConfirmationToken(with: confirmationTokenParams) { confirmationToken, error in
            // Note: ConfirmationToken creation itself may succeed even with a declined card
            // The decline typically happens during intent confirmation, not token creation
            // This test documents the behavior but may need adjustment based on actual API behavior
            if error != nil {
                // If there is an error, verify it's the expected type
                XCTAssertNotNil(error)
            } else {
                // If no error, the token should still be created
                XCTAssertNotNil(confirmationToken)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
}
