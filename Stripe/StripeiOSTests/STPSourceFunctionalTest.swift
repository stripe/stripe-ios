//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPSourceFunctionalTest.m
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

@_spi(STP) @testable import StripeCore
@testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
import StripePaymentsTestUtils
import XCTest

class STPSourceFunctionalTest: STPNetworkStubbingTestCase {

    func testCreateSource_card() {
        let card = STPCardParams()
        card.number = "4242 4242 4242 4242"
        card.expMonth = 6
        card.expYear = 2050
        card.currency = "usd"
        card.name = "Jenny Rosen"
        card.address.line1 = "123 Fake Street"
        card.address.line2 = "Apartment 4"
        card.address.city = "New York"
        card.address.state = "NY"
        card.address.country = "USA"
        card.address.postalCode = "10002"
        let params = STPSourceParams.cardParams(withCard: card)
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.card)
            XCTAssertEqual(source?.cardDetails?.last4, "4242")
            XCTAssertEqual(source?.cardDetails?.expMonth, card.expMonth)
            XCTAssertEqual(source?.cardDetails?.expYear, card.expYear)
            XCTAssertEqual(source?.owner?.name, card.name)
            let address = source?.owner?.address
            XCTAssertEqual(address?.line1, card.address.line1)
            XCTAssertEqual(address?.line2, card.address.line2)
            XCTAssertEqual(address?.city, card.address.city)
            XCTAssertEqual(address?.state, card.address.state)
            XCTAssertEqual(address?.country, card.address.country)
            XCTAssertEqual(address?.postalCode, card.address.postalCode)
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func skip_testCreateSourceVisaCheckout() {
        // The SDK does not have a means of generating Visa Checkout params for testing. Supply your own
        // callId, and the correct publishable key, and you can run this test case
        // manually after removing the `skip_` prefix. It'll log the source's stripeID, and that
        // can be verified in dashboard.
        let params = STPSourceParams.visaCheckoutParams(withCallId: "")
        let client = STPAPIClient(publishableKey: "pk_")
        client.apiURL = URL(string: "https://api.stripe.com/v1")

        let sourceExp = expectation(description: "VCO source created")
        client.createSource(with: params) { source, error in
            sourceExp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.card)
            XCTAssertEqual(source?.flow, STPSourceFlow.none)
            XCTAssertEqual(source?.status, STPSourceStatus.chargeable)
            XCTAssertEqual(source?.usage, STPSourceUsage.reusable)
            XCTAssertTrue(source!.stripeID.hasPrefix("src_"))
            if let stripeID = source?.stripeID {
                print("Created a VCO source \(stripeID)")
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func skip_testCreateSourceMasterpass() {
        // The SDK does not have a means of generating Masterpass params for testing. Supply your own
        // cartId & transactionId, and the correct publishable key, and you can run this test case
        // manually after removing the `skip_` prefix. It'll log the source's stripeID, and that
        // can be verified in dashboard.
        let params = STPSourceParams.masterpassParams(withCartId: "", transactionId: "")
        let client = STPAPIClient(publishableKey: "pk_")
        client.apiURL = URL(string: "https://api.stripe.com/v1")

        let sourceExp = expectation(description: "Masterpass source created")
        client.createSource(with: params) { source, error in
            sourceExp.fulfill()

            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.card)
            XCTAssertEqual(source?.flow, STPSourceFlow.none)
            XCTAssertEqual(source?.status, STPSourceStatus.chargeable)
            XCTAssertEqual(source?.usage, STPSourceUsage.singleUse)
            XCTAssertTrue(source!.stripeID.hasPrefix("src_"))
            if let stripeID = source?.stripeID {
                print("Created a Masterpass source \(stripeID)")
            }
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }
}
