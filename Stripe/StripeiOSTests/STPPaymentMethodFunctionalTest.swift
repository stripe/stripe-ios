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
@_spi(STP) import StripePayments
@testable @_spi(CustomerSessionBetaAccess) import StripePaymentSheet
@testable import StripePaymentsTestUtils

class STPPaymentMethodFunctionalTest: STPNetworkStubbingTestCase {
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
        client.createPaymentMethod(with: params) { paymentMethod, error in
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

    func testUpdateCardPaymentMethod() async throws {
         let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)

         // A hardcoded test Customer
         let testCustomerID = "cus_PTf9mhkFv9ZGXl"

         // Create a new EK for the Customer
         let customerAndEphemeralKey = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: testCustomerID, merchantCountry: "fr")

         // Create a new payment method
         let paymentMethod = try await client.createPaymentMethod(with: ._testCardValue(), additionalPaymentUserAgentValues: [])

         // Attach the payment method to the customer
         try await client.attachPaymentMethod(paymentMethod.stripeId,
                                    customerID: customerAndEphemeralKey.customer,
                                    ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

         // Update the expiry year for the card by 1 year
         let card = STPPaymentMethodCardParams()
         card.expYear = (paymentMethod.card!.expYear + 1) as NSNumber

         let params = STPPaymentMethodUpdateParams(card: card, billingDetails: nil)

         let updatedPaymentMethod = try await client.updatePaymentMethod(with: paymentMethod.stripeId,
                                                                         paymentMethodUpdateParams: params,
                                                                         ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

         // Verify
         XCTAssertEqual(updatedPaymentMethod.card!.expYear, (paymentMethod.card!.expYear + 1))

        // Clean up, detach the payment method as a customer can only have 400 payment methods saved
        try await client.detachPaymentMethod(paymentMethod.stripeId,
                                             fromCustomerUsing: customerAndEphemeralKey.ephemeralKeySecret)
     }

    func testMulitpleCardCreationWithCustomerSessionAndMultiDelete() async throws {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        // Create a new customer and new key
        let customerAndEphemeralKey = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil, merchantCountry: nil)

        // Create a new payment method 1
        let paymentMethod1 = try await client.createPaymentMethod(with: ._testCardValue(), additionalPaymentUserAgentValues: [])

        // Attach the payment method 1 to the customer
        try await client.attachPaymentMethod(paymentMethod1.stripeId,
                                   customerID: customerAndEphemeralKey.customer,
                                   ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

        // Create a new payment method 2
        let paymentMethod2 = try await client.createPaymentMethod(with: ._testCardValue(), additionalPaymentUserAgentValues: [])

        // Attach the payment method 2 to the customer
        try await client.attachPaymentMethod(paymentMethod2.stripeId,
                                   customerID: customerAndEphemeralKey.customer,
                                   ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

        // Element/Sessions endpoint should de-dupe payment methods with CustomerSesssion
        let cscs = try await STPTestingAPIClient.shared().fetchCustomerAndCustomerSessionClientSecret(customerID: customerAndEphemeralKey.customer,
                                                                                                      merchantCountry: nil)
        var configuration = PaymentSheet.Configuration()
        configuration.customer = PaymentSheet.CustomerConfiguration(id: cscs.customer, customerSessionClientSecret: cscs.customerSessionClientSecret)
        let elementSession = try await client.retrieveDeferredElementsSession(
            withIntentConfig: .init(mode: .payment(amount: 5000, currency: "usd", setupFutureUsage: .offSession, captureMethod: .automatic),
                                    confirmHandler: { _, _, _ in
                                        // no-op
                                    }),
            clientDefaultPaymentMethod: paymentMethod2.stripeId,
            configuration: configuration)

        // Requires FF: elements_enable_read_allow_redisplay, to return "1", otherwise 0
        XCTAssertEqual(elementSession.customer?.paymentMethods.count, 1)
        XCTAssertEqual(elementSession.customer?.paymentMethods.first?.stripeId, paymentMethod2.stripeId)
        XCTAssertEqual(elementSession.customer?.defaultPaymentMethod, paymentMethod2.stripeId)
        guard let elementsCustomer = elementSession.customer else {
            XCTFail("Failed to get claimed customer session ephemeral key")
            return
        }

        let claimedCustomerSessionAPIKey = elementsCustomer.customerSession.apiKey
        let customerId = elementsCustomer.customerSession.customer

        // Official endpoint should have two payment methods
        let fetchedPaymentMethods = try await fetchPaymentMethods(client: client,
                                                                  types: [.card],
                                                                  customerId: customerId,
                                                                  ephemeralKey: claimedCustomerSessionAPIKey)
        XCTAssertEqual(fetchedPaymentMethods.count, 2)

        // Clean up, detach both payment methods
        try await client.detachPaymentMethodRemoveDuplicates(paymentMethod2.stripeId,
                                                             customerId: customerId,
                                                             fromCustomerUsing: claimedCustomerSessionAPIKey,
                                                             withCustomerSessionClientSecret: claimedCustomerSessionAPIKey)

        let reFetchedPaymentMethods = try await fetchPaymentMethods(client: client,
                                                                    types: [.card],
                                                                    customerId: customerId,
                                                                    ephemeralKey: claimedCustomerSessionAPIKey)
        XCTAssertEqual(reFetchedPaymentMethods.count, 0)
    }

    func testDetachOnPrivateEndpoint() async throws {
        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        var sepaPaymentMethod: STPPaymentMethod?
        let expectation = self.expectation(description: "Payment Method create")

        let createSepaPaymentMethod = {
            let sepaDebitParams = STPPaymentMethodSEPADebitParams()
            sepaDebitParams.iban =  "AT611904300234573201"

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

            let params = STPPaymentMethodParams(sepaDebit: sepaDebitParams, billingDetails: billingDetails, metadata: nil)

            client.createPaymentMethod(
                with: params) { paymentMethod, error in
                    XCTAssertNil(error)
                    XCTAssertNotNil(paymentMethod)
                    XCTAssertEqual(paymentMethod?.type, .SEPADebit)
                    sepaPaymentMethod = paymentMethod
                    expectation.fulfill()
                }
        }
        createSepaPaymentMethod()
        await fulfillment(of: [expectation], timeout: 5)

        guard let sepaPaymentMethod = sepaPaymentMethod else {
            XCTFail("Unable to create payment method")
            return
        }

        // Create a new customer and new key
        let customerAndEphemeralKey = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil, merchantCountry: "fr")

        // Attach the payment method to user
        try await client.attachPaymentMethod(sepaPaymentMethod.stripeId,
                                   customerID: customerAndEphemeralKey.customer,
                                   ephemeralKeySecret: customerAndEphemeralKey.ephemeralKeySecret)

        let fetchedPaymentMethods = try await fetchPaymentMethods(client: client,
                                                                  types: [.SEPADebit],
                                                                  customerId: customerAndEphemeralKey.customer,
                                                                  ephemeralKey: customerAndEphemeralKey.ephemeralKeySecret)
        XCTAssertEqual(fetchedPaymentMethods.count, 1)
        XCTAssertEqual(fetchedPaymentMethods[0].type, .SEPADebit)

        let cscs = try await STPTestingAPIClient.shared().fetchCustomerAndCustomerSessionClientSecret(customerID: customerAndEphemeralKey.customer,
                                                                                                      merchantCountry: "fr")
        var configuration = PaymentSheet.Configuration()
        configuration.customer = PaymentSheet.CustomerConfiguration(id: cscs.customer, customerSessionClientSecret: cscs.customerSessionClientSecret)
        let elementSession = try await client.retrieveDeferredElementsSession(
            withIntentConfig: .init(mode: .payment(amount: 5000, currency: "eur", setupFutureUsage: .offSession, captureMethod: .automatic),
                                    confirmHandler: { _, _, _ in
                                        // no-op
                                    }),
            clientDefaultPaymentMethod: nil,
            configuration: configuration)

        XCTAssertEqual(elementSession.customer?.paymentMethods.count, 1)
        XCTAssertEqual(elementSession.customer?.paymentMethods.first?.stripeId, sepaPaymentMethod.stripeId)
        guard let elementsCustomer = elementSession.customer else {
            XCTFail("Failed to get claimed customer session ephemeral key")
            return
        }

        // Detach using private endpoint and verify
        let claimedCustomerSessionAPIKey = elementsCustomer.customerSession.apiKey
        let customerId = elementsCustomer.customerSession.customer
        try await client.detachPaymentMethod(sepaPaymentMethod.stripeId,
                                             fromCustomerUsing: claimedCustomerSessionAPIKey,
                                             withCustomerSessionClientSecret: cscs.customerSessionClientSecret)

        let reFetchedPaymentMethods = try await fetchPaymentMethods(client: client,
                                                                    types: [.SEPADebit],
                                                                    customerId: customerId,
                                                                    ephemeralKey: claimedCustomerSessionAPIKey)
        XCTAssertEqual(reFetchedPaymentMethods.count, 0)
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

    func testCreateAmazonPayPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let params = STPPaymentMethodParams(amazonPay: STPPaymentMethodAmazonPayParams(), billingDetails: nil, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertEqual(paymentMethod?.type, .amazonPay)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateAlmaPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        let params = STPPaymentMethodParams(alma: STPPaymentMethodAlmaParams(), billingDetails: nil, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertEqual(paymentMethod?.type, .alma)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateSunbitPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let params = STPPaymentMethodParams(sunbit: STPPaymentMethodSunbitParams(), billingDetails: nil, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertEqual(paymentMethod?.type, .sunbit)
            XCTAssertNotNil(paymentMethod?.sunbit, "The `sunbit` property must be populated")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateBilliePaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDEPublishableKey)
        let params = STPPaymentMethodParams(billie: STPPaymentMethodBillieParams(), billingDetails: nil, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertEqual(paymentMethod?.type, .billie)
            XCTAssertNotNil(paymentMethod?.billie, "The `billie` property must be populated")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateSatispayPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingITPublishableKey)
        let params = STPPaymentMethodParams(satispay: STPPaymentMethodSatispayParams(), billingDetails: nil, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertEqual(paymentMethod?.type, .satispay)
            XCTAssertNotNil(paymentMethod?.satispay, "The `satispay` property must be populated")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateCryptoPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let params = STPPaymentMethodParams(crypto: STPPaymentMethodCryptoParams(), billingDetails: nil, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertEqual(paymentMethod?.type, .crypto)
            XCTAssertNotNil(paymentMethod?.crypto, "The `crypto` property must be populated")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateMultibancoPaymentMethod() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "tester@example.com"
        let params = STPPaymentMethodParams(alma: STPPaymentMethodAlmaParams(), billingDetails: billingDetails, metadata: nil)
        let expectation = self.expectation(description: "Payment Method create")
        client.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentMethod)
            XCTAssertEqual(paymentMethod?.type, .alma)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func fetchPaymentMethods(client: STPAPIClient,
                             types: [STPPaymentMethodType],
                             customerId: String,
                             ephemeralKey: String) async throws -> [STPPaymentMethod] {
        try await withCheckedThrowingContinuation { continuation in
            client.listPaymentMethods(forCustomer: customerId,
                                      using: ephemeralKey,
                                      types: types) { paymentMethods, error in
                guard let paymentMethods, error == nil else {
                    continuation.resume(throwing: error!)
                    return
                }
                continuation.resume(returning: paymentMethods)
            }
        }
    }
}
