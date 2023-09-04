//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentMethodFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Stripe
import StripeCoreTestUtils

class STPPaymentMethodFunctionalTest: XCTestCase {

    func testCreateCardPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let card = STPPaymentMethodCardParams()
        card.number = "4242424242424242"
        card.expMonth = NSNumber(value: 10)
        card.expYear = NSNumber(value: 2028)
        card.cvc = "100"

        let billingAddress = STPPaymentMethodAddress()
        billingAddress.city = "San Francisco"
        billingAddress.country = "US"
        billingAddress.line1 = "150 Townsend St"
        billingAddress.line2 = "4th Floor"
        billingAddress.postalCode = "94103"
        billingAddress.state = "CA"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = billingAddress
        billingDetails.email = "email@email.com"
        billingDetails.name = "Isaac Asimov"
        billingDetails.phone = "555-555-5555"

        let params = STPPaymentMethodParams(
            card: card,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])
        let expectation = self.expectation(description: "Payment Method Card create")
        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertNotNil(paymentMethod?.stripeId)
            XCTAssertNotNil(paymentMethod?.created)
            XCTAssertFalse(paymentMethod!.liveMode)
                XCTAssertEqual(paymentMethod?.type, .card)

            // Billing Details
                XCTAssertEqual(paymentMethod?.billingDetails!.email, "email@email.com")
            XCTAssertEqual(paymentMethod?.billingDetails!.name, "Isaac Asimov")
            XCTAssertEqual(paymentMethod?.billingDetails!.phone, "555-555-5555")

            // Billing Details Address
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.line1, "150 Townsend St")
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.line2, "4th Floor")
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.city, "San Francisco")
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.country, "US")
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.state, "CA")
            XCTAssertEqual(paymentMethod?.billingDetails!.address!.postalCode, "94103")

            // Card
                XCTAssertEqual(paymentMethod?.card!.brand, .visa)
                XCTAssertEqual(paymentMethod?.card!.checks!.cvcCheck, .unknown)
                XCTAssertEqual(paymentMethod?.card!.checks!.addressLine1Check, .unknown)
                XCTAssertEqual(paymentMethod?.card!.checks!.addressPostalCodeCheck, .unknown)
            XCTAssertEqual(paymentMethod?.card!.country, "US")
            XCTAssertEqual(paymentMethod?.card!.expMonth, 10)
            XCTAssertEqual(paymentMethod?.card!.expYear, 2028)
            XCTAssertEqual(paymentMethod?.card!.funding, "credit")
            XCTAssertEqual(paymentMethod?.card!.last4, "4242")
            XCTAssertTrue(paymentMethod!.card!.threeDSecureUsage!.supported)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateBacsPaymentMethod() {
        let client = STPAPIClient(publishableKey: "pk_test_z6Ct4bpx0NUjHii0rsi4XZBf00jmM8qA28")

        let bacs = STPPaymentMethodBacsDebitParams()
        bacs.sortCode = "108800"
        bacs.accountNumber = "00012345"

        let billingAddress = STPPaymentMethodAddress()
        billingAddress.city = "London"
        billingAddress.country = "GB"
        billingAddress.line1 = "Stripe, 7th Floor The Bower Warehouse"
        billingAddress.postalCode = "EC1V 9NR"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = billingAddress
        billingDetails.email = "email@email.com"
        billingDetails.name = "Isaac Asimov"
        billingDetails.phone = "555-555-5555"

        let params = STPPaymentMethodParams(bacsDebit: bacs, billingDetails: billingDetails, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
                XCTAssertEqual(paymentMethod?.type, .bacsDebit)

            // Bacs Debit
            XCTAssertEqual(paymentMethod!.bacsDebit!.fingerprint, "UkSG0HfCGxxrja1H")
            XCTAssertEqual(paymentMethod!.bacsDebit!.last4, "2345")
            XCTAssertEqual(paymentMethod!.bacsDebit!.sortCode, "108800")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateAlipayPaymentMethod() {
        let client = STPAPIClient(publishableKey: "pk_test_JBVAMwnBuzCdmsgN34jfxbU700LRiPqVit")

        let params = STPPaymentMethodParams(alipay: STPPaymentMethodAlipayParams(), billingDetails: nil, metadata: nil)

        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
                XCTAssertEqual(paymentMethod?.type, .alipay)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateBLIKPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        let params = STPPaymentMethodParams(blik: STPPaymentMethodBLIKParams(), billingDetails: nil, metadata: nil)

        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(
            with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
                XCTAssertEqual(paymentMethod?.type, .blik
                )
            XCTAssertNotNil(paymentMethod?.blik)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateMobilePayPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        let params = STPPaymentMethodParams(mobilePay: STPPaymentMethodMobilePayParams(), billingDetails: nil, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertEqual(paymentMethod?.type, .mobilePay)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
