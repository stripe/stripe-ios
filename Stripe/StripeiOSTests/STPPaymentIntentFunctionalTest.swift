//
//  STPPaymentIntentFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentIntentFunctionalTest: STPNetworkStubbingTestCase {
    func testCreatePaymentIntentWithTestingServer() {
        let expectation = self.expectation(description: "PaymentIntent create.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: nil) { clientSecret, error in
            XCTAssertNotNil(clientSecret)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreatePaymentIntentWithInvalidCurrency() {
        let expectation = self.expectation(description: "PaymentIntent create.")
        STPTestingAPIClient.shared.createPaymentIntent(withParams: [
            "payment_method_types": ["bancontact"],
        ]) { clientSecret, error in
            XCTAssertNil(clientSecret)
            XCTAssertNotNil(error)
            let errorString = (error! as NSError).userInfo[STPError.errorMessageKey] as! String
            XCTAssertTrue(errorString.hasPrefix("Error creating PaymentIntent: The currency provided (usd) is invalid. Payments with bancontact support the following currencies: eur."))
            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testRetrievePreviousCreatedPaymentIntent() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent retrieve")

        client.retrievePaymentIntent(
            withClientSecret: "pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe") { paymentIntent, error in
            XCTAssertNil(error)

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, "pi_1GGCGfFY0qyl6XeWbSAsh2hn")
            XCTAssertEqual(paymentIntent?.amount, 100)
            XCTAssertEqual(paymentIntent?.currency, "usd")
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNil(paymentIntent?.sourceId)
            XCTAssertNil(paymentIntent?.paymentMethodId)
                XCTAssertEqual(paymentIntent?.status, .canceled)
                XCTAssertEqual(paymentIntent?.setupFutureUsage, STPPaymentIntentSetupFutureUsage.none)
            XCTAssertNil(paymentIntent?.perform(NSSelectorFromString("nextSourceAction")))
            // #pragma clang diagnostic pop
            XCTAssertNil(paymentIntent!.nextAction)

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testRetrieveWithWrongSecret() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent retrieve")

        client.retrievePaymentIntent(
            withClientSecret: "pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_bad-secret") { paymentIntent, error in
            XCTAssertNil(paymentIntent)

            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain)
                XCTAssertEqual((error as NSError?)?.code, STPErrorCode.invalidRequestError.rawValue)
            XCTAssertEqual(
                (error as NSError?)?.userInfo[STPError.errorParameterKey] as! String,
                "clientSecret")

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testRetrieveMismatchedPublishableKey() {
        // Given an API Client with a publishable key for a test account A...
        let client = STPAPIClient(publishableKey: "pk_test_51JtgfQKG6vc7r7YCU0qQNOkDaaHrEgeHgGKrJMNfuWwaKgXMLzPUA1f8ZlCNPonIROLOnzpUnJK1C1xFH3M3Mz8X00Q6O4GfUt")
        let expectation = self.expectation(description: "Payment Intent retrieve")

        // ...retrieving a PI attached to a *different* account
        client.retrievePaymentIntent(
            withClientSecret: "pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe") { paymentIntent, error in
            // ...should fail.
            XCTAssertNil(paymentIntent)

            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain)
                XCTAssertEqual((error as NSError?)?.code, STPErrorCode.invalidRequestError.rawValue)
            XCTAssertEqual(
                (error as NSError?)?.userInfo[STPError.errorParameterKey] as! String,
                "intent")

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmCanceledPaymentIntentFails() {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let params = STPPaymentIntentParams(clientSecret: "pi_1GGCGfFY0qyl6XeWbSAsh2hn_secret_jbhwsI0DGWhKreJs3CCrluUGe")
        params.sourceParams = cardSourceParams()
        client.confirmPaymentIntent(
            with: params) { paymentIntent, error in
            XCTAssertNil(paymentIntent)

            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError?)?.domain, STPError.stripeDomain)
                XCTAssertEqual((error as NSError?)?.code, STPErrorCode.invalidRequestError.rawValue)
                let errorString = (error! as NSError).userInfo[STPError.errorMessageKey] as! String
                XCTAssertTrue(errorString.hasPrefix("This PaymentIntent's source could not be updated because it has a status of canceled. You may only update the source of a PaymentIntent with one of the following statuses: requires_payment_method, requires_confirmation, requires_action."),
                    "Expected error message to complain about status being canceled. Actual msg: \(errorString)"
                )

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmPaymentIntentWith3DSCardSucceeds() {

        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let params = STPPaymentIntentParams(clientSecret: clientSecret!)
        params.sourceParams = cardSourceParams()
        // returnURL must be passed in while confirming (not creation time)
        params.returnURL = "example-app-scheme://authorized"
        client.confirmPaymentIntent(
            with: params) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, params.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)

            // sourceParams is the 3DS-required test card
                XCTAssertEqual(paymentIntent?.status, .requiresAction)

            // STPRedirectContext is relying on receiving returnURL
            XCTAssertNotNil(paymentIntent!.nextAction!.redirectToURL!.returnURL)
            XCTAssertEqual(
                paymentIntent!.nextAction!.redirectToURL!.returnURL,
                URL(string: "example-app-scheme://authorized"))

            // Test deprecated property still works too
            // #pragma clang diagnostic push
            // #pragma clang diagnostic ignored "-Wdeprecated"
                XCTAssertNotNil(paymentIntent?.nextSourceAction?.authorizeWithURL?.returnURL)
            XCTAssertEqual(
                paymentIntent?.nextSourceAction?.authorizeWithURL?.returnURL,
                URL(string: "example-app-scheme://authorized"))
            // #pragma clang diagnostic pop

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmPaymentIntentWith3DSCardPaymentMethodSucceeds() {

        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let params = STPPaymentIntentParams(clientSecret: clientSecret!)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4000000000003220"
        cardParams.expMonth = NSNumber(value: 7)
        cardParams.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        cardParams.cvc = "123"

        let billingDetails = STPPaymentMethodBillingDetails()

        params.paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil)
        // returnURL must be passed in while confirming (not creation time)
        params.returnURL = "example-app-scheme://authorized"
        client.confirmPaymentIntent(
            with: params) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, params.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // sourceParams is the 3DS-required test card
            XCTAssertEqual(paymentIntent?.status, .requiresAction)

            // STPRedirectContext is relying on receiving returnURL

            XCTAssertNotNil(paymentIntent!.nextAction!.redirectToURL!.returnURL)
            XCTAssertEqual(
                paymentIntent!.nextAction!.redirectToURL!.returnURL,
                URL(string: "example-app-scheme://authorized"))

            // Going to log all the fields so that you, the developer manually running this test, can inspect them
            if let allResponseFields = paymentIntent?.allResponseFields {
                print("Confirmed PaymentIntent: \(allResponseFields)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmPaymentIntentWithShippingDetailsSucceeds() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let params = STPPaymentIntentParams(clientSecret: clientSecret!)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 7)
        cardParams.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        cardParams.cvc = "123"

        let billingDetails = STPPaymentMethodBillingDetails()

        params.paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil)

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: "123 Main St")
        addressParams.line2 = "Apt 2"
        addressParams.city = "San Francisco"
        addressParams.state = "CA"
        addressParams.country = "US"
        addressParams.postalCode = "94106"
        params.shipping = STPPaymentIntentShippingDetailsParams(address: addressParams, name: "Jane")
        params.shipping?.carrier = "UPS"
        params.shipping?.phone = "555-555-5555"
        params.shipping?.trackingNumber = "123abc"

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")
        client.confirmPaymentIntent(
            with: params) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, params.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // Address
            XCTAssertEqual(paymentIntent?.shipping!.address!.line1, "123 Main St")
            XCTAssertEqual(paymentIntent?.shipping!.address!.line2, "Apt 2")
            XCTAssertEqual(paymentIntent?.shipping!.address!.city, "San Francisco")
            XCTAssertEqual(paymentIntent?.shipping!.address!.state, "CA")
            XCTAssertEqual(paymentIntent?.shipping!.address!.country, "US")
            XCTAssertEqual(paymentIntent?.shipping!.address!.postalCode, "94106")

            XCTAssertEqual(paymentIntent?.shipping!.name, "Jane")
            XCTAssertEqual(paymentIntent?.shipping!.carrier, "UPS")
            XCTAssertEqual(paymentIntent?.shipping!.phone, "555-555-5555")
            XCTAssertEqual(paymentIntent?.shipping!.trackingNumber, "123abc")

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmCardWithoutNetworkParam() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let params = STPPaymentIntentParams(clientSecret: clientSecret!)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 7)
        cardParams.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        cardParams.cvc = "123"

        let billingDetails = STPPaymentMethodBillingDetails()

        params.paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil)

        client.confirmPaymentIntent(
            with: params) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, params.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

                XCTAssertEqual(paymentIntent?.status, .succeeded)

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmCardWithNetworkParam() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let params = STPPaymentIntentParams(clientSecret: clientSecret!)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 7)
        cardParams.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)
        cardParams.cvc = "123"

        let billingDetails = STPPaymentMethodBillingDetails()

        params.paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil)

        let cardOptions = STPConfirmCardOptions()
        cardOptions.network = "visa"
        let paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentMethodOptions.cardOptions = cardOptions
        params.paymentMethodOptions = paymentMethodOptions

        client.confirmPaymentIntent(
            with: params) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, params.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

                XCTAssertEqual(paymentIntent?.status, .succeeded)

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testConfirmCardWithInvalidNetworkParam() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(withParams: nil) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let params = STPPaymentIntentParams(clientSecret: clientSecret!)
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 7)
        cardParams.expYear = NSNumber(value: Calendar.current.component(.year, from: Date()) + 5)

        let billingDetails = STPPaymentMethodBillingDetails()

        params.paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil)

        let cardOptions = STPConfirmCardOptions()
        cardOptions.network = "fake_network"
        let paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentMethodOptions.cardOptions = cardOptions
        params.paymentMethodOptions = paymentMethodOptions

        client.confirmPaymentIntent(
            with: params) { paymentIntent, error in
            XCTAssertNotNil(error, "Confirming with invalid network should result in an error")

            XCTAssertNil(paymentIntent)

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - AU BECS Debit

    func testConfirmAUBECSDebitPaymentIntent() {

        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "currency": "aud",
                "amount": NSNumber(value: 2000),
                "payment_method_types": ["au_becs_debit"],
            ],
            account: "au") { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let becsParams = STPPaymentMethodAUBECSDebitParams()
        becsParams.bsbNumber = "000000" // Stripe test bank
        becsParams.accountNumber = "000123456" // test account

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"
        billingDetails.email = "jrosen@example.com"

        let params = STPPaymentMethodParams(
            aubecsDebit: becsParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = params

        let client = STPAPIClient(publishableKey: STPTestingAUPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // AU BECS Debit should be in Processing
            XCTAssertEqual(paymentIntent?.status, .processing)

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Przelewy24

    func testConfirmPaymentIntentWithPrzelewy24() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["p24"],
                "currency": "eur",
            ]) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        let przelewy24Params = STPPaymentMethodPrzelewy24Params()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "email@email.com"

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            przelewy24: przelewy24Params,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])
        paymentIntentParams.returnURL = "example-app-scheme://authorized"
        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // Przelewy24 requires a redirect
            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertNotNil(paymentIntent!.nextAction!.redirectToURL!.returnURL)
            XCTAssertEqual(
                paymentIntent!.nextAction!.redirectToURL!.returnURL,
                URL(string: "example-app-scheme://authorized"))

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Bancontact

    func testConfirmPaymentIntentWithBancontact() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["bancontact"],
                "currency": "eur",
            ]) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        let bancontact = STPPaymentMethodBancontactParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            bancontact: bancontact,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])
        paymentIntentParams.returnURL = "example-app-scheme://authorized"
        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // Bancontact requires a redirect
            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertNotNil(paymentIntent!.nextAction!.redirectToURL!.returnURL)
            XCTAssertEqual(
                paymentIntent!.nextAction!.redirectToURL!.returnURL,
                URL(string: "example-app-scheme://authorized"))

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - OXXO

    func testConfirmPaymentIntentWithOXXO() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["oxxo"],
                "amount": NSNumber(value: 2000),
                "currency": "mxn",
            ],
            account: "mex") { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingMEXPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        let oxxo = STPPaymentMethodOXXOParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "email@email.com"

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            oxxo: oxxo,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])
        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // OXXO requires display the voucher as next step
            let oxxoDisplayDetails = paymentIntent!.nextAction!.allResponseFields["oxxo_display_details"] as? [AnyHashable: Any]
            XCTAssertNotNil(oxxoDisplayDetails?["expires_after"])
            XCTAssertNotNil(oxxoDisplayDetails?["number"])
            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - EPS

    func testConfirmPaymentIntentWithEPS() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["eps"],
                "currency": "eur",
            ]) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        let epsParams = STPPaymentMethodEPSParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            eps: epsParams,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])
        paymentIntentParams.returnURL = "example-app-scheme://authorized"

        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)

            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // EPS requires a redirect
            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertNotNil(paymentIntent!.nextAction!.redirectToURL!.returnURL)
            XCTAssertEqual(
                paymentIntent!.nextAction!.redirectToURL!.returnURL,
                URL(string: "example-app-scheme://authorized"))

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Alipay

    func testConfirmAlipayPaymentIntent() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "currency": "usd",
                "amount": NSNumber(value: 2000),
                "payment_method_types": ["alipay"],
            ]) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let params = STPPaymentMethodParams(alipay: STPPaymentMethodAlipayParams(), billingDetails: nil, metadata: nil)
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = params
        paymentIntentParams.returnURL = "foo://bar"
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions!.alipayOptions = STPConfirmAlipayOptions()

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            XCTAssertEqual(paymentIntent?.status, .requiresAction)
                XCTAssertEqual(paymentIntent!.nextAction?.type, .alipayHandleRedirect)
            XCTAssertNotNil(paymentIntent!.nextAction)

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - GrabPay

    func testConfirmPaymentIntentWithGrabPay() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["grabpay"],
                "currency": "sgd",
            ],
            account: "sg") { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingSGPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        let grabpay = STPPaymentMethodGrabPayParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jenny Rosen"

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            grabPay: grabpay,
            billingDetails: billingDetails,
            metadata: nil)
        paymentIntentParams.returnURL = "example-app-scheme://authorized"

        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)

            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // GrabPay requires a redirect
                XCTAssertEqual(paymentIntent?.status, .requiresAction)
                XCTAssertNotNil(paymentIntent!.nextAction?.redirectToURL?.returnURL)
            XCTAssertEqual(
                paymentIntent!.nextAction!.redirectToURL!.returnURL,
                URL(string: "example-app-scheme://authorized"))

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - PayPal

    func testConfirmPaymentIntentWithPayPal() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["paypal"],
                "currency": "eur",
            ],
            account: "be") { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingBEPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        let payPal = STPPaymentMethodPayPalParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            payPal: payPal,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])
        paymentIntentParams.returnURL = "example-app-scheme://authorized"
        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // PayPal requires a redirect
                XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertNotNil(paymentIntent!.nextAction!.redirectToURL!.returnURL)
            XCTAssertEqual(
                paymentIntent!.nextAction!.redirectToURL!.returnURL,
                URL(string: "example-app-scheme://authorized"))

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - BLIK

    func testConfirmPaymentIntentWithBLIK() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["blik"],
                "currency": "pln",
                "amount": NSNumber(value: 1000),
            ],
            account: "be") { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingBEPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        let blik = STPPaymentMethodBLIKParams()

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            blik: blik,
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ])
        let options = STPConfirmPaymentMethodOptions()
        options.blikOptions = STPConfirmBLIKOptions(code: "123456")
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            // Blik transitions to requires_action until the customer authorizes the transaction or 1 minute passes
                XCTAssertEqual(paymentIntent?.status, .requiresAction)
                XCTAssertEqual(paymentIntent!.nextAction?.type, .BLIKAuthorize)

            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Affirm

    func testConfirmPaymentIntentWithAffirm() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["affirm"],
                "currency": "usd",
                "amount": NSNumber(value: 6000),
            ]) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        let affirm = STPPaymentMethodAffirmParams()

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            affirm: affirm,
            metadata: [
                "test_key": "test_value",
            ])

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: "123 Main St")
        addressParams.line2 = "Apt 2"
        addressParams.city = "San Francisco"
        addressParams.state = "CA"
        addressParams.country = "US"
        addressParams.postalCode = "94106"
        paymentIntentParams.shipping = STPPaymentIntentShippingDetailsParams(address: addressParams, name: "Jane Doe")

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(
            with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

                XCTAssertEqual(paymentIntent?.status, .requiresAction)
                XCTAssertEqual(paymentIntent!.nextAction?.type, .redirectToURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - MobilePay

    func testConfirmPaymentIntentWithMobilePay() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["mobilepay"],
                "currency": "dkk",
                "amount": NSNumber(value: 6000),
            ],
            account: "fr"
        ) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            mobilePay: STPPaymentMethodMobilePayParams(),
            billingDetails: nil,
            metadata: [
                "test_key": "test_value",
            ]
        )

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent!.nextAction?.type, .redirectToURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Amazon Pay

    func testConfirmPaymentIntentWithAmazonPay() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["amazon_pay"],
                "currency": "usd",
                "amount": NSNumber(value: 6000),
            ],
            account: "us"
        ) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            amazonPay: STPPaymentMethodAmazonPayParams(),
            billingDetails: nil,
            metadata: [
                "test_key": "test_value",
            ]
        )

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent!.nextAction?.type, .redirectToURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Alma

    func testConfirmPaymentIntentWithAlma() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["alma"],
                "currency": "eur",
                "amount": NSNumber(value: 6000),
            ],
            account: "fr"
        ) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingFRPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            alma: STPPaymentMethodAlmaParams(),
            billingDetails: nil,
            metadata: [
                "test_key": "test_value",
            ]
        )

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")

            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent!.nextAction?.type, .redirectToURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Sunbit

    func testConfirmPaymentIntentWithSunbit() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["sunbit"],
                "currency": "usd",
                "amount": NSNumber(value: 6000),
            ],
            account: "us"
        ) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            sunbit: STPPaymentMethodSunbitParams(),
            billingDetails: nil,
            metadata: [
                "test_key": "test_value",
            ]
        )

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")
            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)
            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent!.nextAction?.type, .redirectToURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Billie

    func testConfirmPaymentIntentWithBillie() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["billie"],
                "currency": "eur",
                "amount": NSNumber(value: 6000),
            ],
            account: "de"
        ) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDEPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            billie: STPPaymentMethodBillieParams(),
            billingDetails: nil,
            metadata: [
                "test_key": "test_value",
            ]
        )

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")
            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent!.nextAction?.type, .redirectToURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Satispay

    func testConfirmPaymentIntentWithSatispay() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["satispay"],
                "currency": "eur",
                "amount": NSNumber(value: 6000),
            ],
            account: "it"
        ) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingITPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            satispay: STPPaymentMethodSatispayParams(),
            billingDetails: nil,
            metadata: [
                "test_key": "test_value",
            ]
        )

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")
            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent!.nextAction?.type, .redirectToURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Crypto

    func testConfirmPaymentIntentWithCrypto() {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["crypto"],
                "currency": "usd",
                "amount": NSNumber(value: 100),
            ],
            account: "us"
        ) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            createExpectation.fulfill()
            clientSecret = createdClientSecret
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret!)
        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            crypto: STPPaymentMethodCryptoParams(),
            billingDetails: nil,
            metadata: [
                "test_key": "test_value",
            ]
        )

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")
            XCTAssertNotNil(paymentIntent)
            XCTAssertEqual(paymentIntent?.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent!.livemode)
            XCTAssertNotNil(paymentIntent?.paymentMethodId)

            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent!.nextAction?.type, .redirectToURL)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - Multibanco

    func testConfirmPaymentIntentWithMultibanco() throws {
        var clientSecret: String?
        let createExpectation = self.expectation(description: "Create PaymentIntent.")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["multibanco"],
                "currency": "eur",
                "amount": NSNumber(value: 6000),
            ],
            account: "us"
        ) { createdClientSecret, creationError in
            XCTAssertNotNil(createdClientSecret)
            XCTAssertNil(creationError)
            clientSecret = createdClientSecret
            createExpectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
        XCTAssertNotNil(clientSecret)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Payment Intent confirm")

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: try XCTUnwrap(clientSecret))

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "tester@example.com"

        paymentIntentParams.paymentMethodParams = STPPaymentMethodParams(
            multibanco: STPPaymentMethodMultibancoParams(),
            billingDetails: billingDetails,
            metadata: [
                "test_key": "test_value",
            ]
        )

        let options = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions = options
        paymentIntentParams.returnURL = "example-app-scheme://unused"
        client.confirmPaymentIntent(with: paymentIntentParams) { paymentIntent, error in
            guard let paymentIntent = paymentIntent else {
                XCTFail()
                return
            }
            XCTAssertNil(error, "With valid key + secret, should be able to confirm the intent")
            XCTAssertEqual(paymentIntent.stripeId, paymentIntentParams.stripeId)
            XCTAssertFalse(paymentIntent.livemode)
            XCTAssertNotNil(paymentIntent.paymentMethodId)

            XCTAssertEqual(paymentIntent.status, .requiresAction)
            XCTAssertEqual(paymentIntent.nextAction?.type, .multibancoDisplayDetails)
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // MARK: - US Bank Account
    func createAndConfirmPaymentIntentWithUSBankAccount(
        paymentMethodOptions: STPConfirmUSBankAccountOptions? = nil,
        completion: @escaping (String?) -> Void
    ) {
        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

        var clientSecret: String?
        let createPIExpectation = expectation(description: "Create PaymentIntent")
        STPTestingAPIClient.shared.createPaymentIntent(
            withParams: [
                "payment_method_types": ["us_bank_account"],
                "currency": "usd",
                "amount": 1000,
            ],
            account: nil
        ) { intentClientSecret, error in
            XCTAssertNil(error)
            XCTAssertNotNil(intentClientSecret)
            clientSecret = intentClientSecret
            createPIExpectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        guard let clientSecret = clientSecret else {
            XCTFail("Failed to create PaymentIntent")
            return
        }

        let usBankAccountParams = STPPaymentMethodUSBankAccountParams()
        usBankAccountParams.accountType = .checking
        usBankAccountParams.accountHolderType = .individual
        usBankAccountParams.accountNumber = "000123456789"
        usBankAccountParams.routingNumber = "110000000"

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "iOS CI Tester"
        billingDetails.email = "tester@example.com"

        let paymentMethodParams = STPPaymentMethodParams(
            usBankAccount: usBankAccountParams,
            billingDetails: billingDetails,
            metadata: nil
        )

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        if let paymentMethodOptions = paymentMethodOptions {
            let pmo = STPConfirmPaymentMethodOptions()
            pmo.usBankAccountOptions = paymentMethodOptions
            paymentIntentParams.paymentMethodOptions = pmo
        }

        let confirmPIExpectation = expectation(description: "Confirm PaymentIntent")
        client.confirmPaymentIntent(with: paymentIntentParams, expand: ["payment_method"]) {
            paymentIntent,
            error in
            XCTAssertNil(error)
            XCTAssertNotNil(paymentIntent)
            XCTAssertNotNil(paymentIntent?.paymentMethod)
            XCTAssertNotNil(paymentIntent?.paymentMethod?.usBankAccount)
            XCTAssertEqual(paymentIntent?.paymentMethod?.usBankAccount?.last4, "6789")
            XCTAssertEqual(paymentIntent?.status, .requiresAction)
            XCTAssertEqual(paymentIntent?.nextAction?.type, .verifyWithMicrodeposits)
            if let paymentMethodOptions = paymentMethodOptions {
                XCTAssertEqual(
                    paymentIntent?.paymentMethodOptions?.usBankAccount?.setupFutureUsage,
                    paymentMethodOptions.setupFutureUsage
                )
            }
            confirmPIExpectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        completion(clientSecret)
    }

    func testConfirmPaymentIntentWithUSBankAccount_verifyWithAmounts() {
        createAndConfirmPaymentIntentWithUSBankAccount { [self] clientSecret in
            guard let clientSecret = clientSecret else {
                XCTFail("Failed to create PaymentIntent")
                return
            }

            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

            let verificationExpectation = expectation(description: "Verify with microdeposits")
            client.verifyPaymentIntentWithMicrodeposits(
                clientSecret: clientSecret,
                firstAmount: 32,
                secondAmount: 45
            ) { paymentIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(paymentIntent)
                XCTAssertEqual(paymentIntent?.status, .processing)
                verificationExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }
    }

    func testConfirmPaymentIntentWithUSBankAccount_verifyWithDescriptorCode() {
        createAndConfirmPaymentIntentWithUSBankAccount { [self] clientSecret in
            guard let clientSecret = clientSecret else {
                XCTFail("Failed to create PaymentIntent")
                return
            }

            let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

            let verificationExpectation = expectation(description: "Verify with microdeposits")
            client.verifyPaymentIntentWithMicrodeposits(
                clientSecret: clientSecret,
                descriptorCode: "SM11AA"
            ) { paymentIntent, error in
                XCTAssertNil(error)
                XCTAssertNotNil(paymentIntent)
                XCTAssertEqual(paymentIntent?.status, .processing)
                verificationExpectation.fulfill()
            }
            waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
        }
    }

    func testConfirmUSBankAccountWithPaymentMethodOptions() {
        createAndConfirmPaymentIntentWithUSBankAccount(
            paymentMethodOptions: STPConfirmUSBankAccountOptions(setupFutureUsage: .offSession)
        ) { clientSecret in
            XCTAssertNotNil(clientSecret)
        }
    }

    // MARK: - Helpers

    func cardSourceParams() -> STPSourceParams {
        let card = STPCardParams()
        card.number = "4000 0000 0000 3220" // Test 3DS required card
        card.expMonth = 7
        card.expYear = UInt(Calendar.current.component(.year, from: Date()) + 5)
        card.currency = "usd"
        card.cvc = "123"

        return .cardParams(withCard: card)
    }
}
