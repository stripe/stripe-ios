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
    func testCreateSource_bancontact() {
        let params = STPSourceParams.bancontactParams(
            withAmount: 1099,
            name: "Jenny Rosen",
            returnURL: "https://shop.example.com/crtABC",
            statementDescriptor: "ORDER AT123")
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.bancontact)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.owner?.name, params.owner?["name"] as? String)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

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

    func testCreateSource_ideal() {
        let params = STPSourceParams.idealParams(
            withAmount: 1099,
            name: "Jenny Rosen",
            returnURL: "https://shop.example.com/crtABC",
            statementDescriptor: "ORDER AT123",
            bank: "ing")
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.iDEAL)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.owner?.name, params.owner?["name"] as? String)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertEqual(source?.details?["bank"] as? String, "ing")
            XCTAssertEqual(source?.details?["statement_descriptor"] as? String, "ORDER AT123")
            // #pragma clang diagnostic push
            // #pragma clang diagnostic ignored "-Wdeprecated"
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")
            // #pragma clang diagnostic pop

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_ideal_missingOptionalFields() {
        let params = STPSourceParams.idealParams(
            withAmount: 1099,
            name: nil,
            returnURL: "https://shop.example.com/crtABC",
            statementDescriptor: nil,
            bank: nil)

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.iDEAL)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertNil(source?.owner?.name)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.details?["bank"])
            XCTAssertNil(source?.details?["statement_descriptor"])
            // #pragma clang diagnostic push
            // #pragma clang diagnostic ignored "-Wdeprecated"
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")
            // #pragma clang diagnostic pop

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_ideal_emptyOptionalFields() {
        let params = STPSourceParams.idealParams(
            withAmount: 1099,
            name: "",
            returnURL: "https://shop.example.com/crtABC",
            statementDescriptor: "",
            bank: "")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.iDEAL)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertNil(source?.owner?.name)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.details?["bank"])
            XCTAssertNil(source?.details?["statement_descriptor"])
            // #pragma clang diagnostic push
            // #pragma clang diagnostic ignored "-Wdeprecated"
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")
            // #pragma clang diagnostic pop

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_sepaDebit() {
        let params = STPSourceParams.sepaDebitParams(
            withName: "Jenny Rosen",
            iban: "DE89370400440532013000",
            addressLine1: "Nollendorfstraße 27",
            city: "Berlin",
            postalCode: "10777",
            country: "DE")
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.SEPADebit)
            XCTAssertNil(source?.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.owner?.name, params.owner?["name"] as? String)
            XCTAssertEqual(source?.owner?.address?.city, "Berlin")
            XCTAssertEqual(source?.owner?.address?.line1, "Nollendorfstraße 27")
            XCTAssertEqual(source?.owner?.address?.country, "DE")
            XCTAssertEqual(source?.sepaDebitDetails?.country, "DE")
            XCTAssertEqual(source?.sepaDebitDetails?.last4, "3000")
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_sepaDebit_NoAddress() {
        let params = STPSourceParams.sepaDebitParams(
            withName: "Jenny Rosen",
            iban: "DE89370400440532013000",
            addressLine1: nil,
            city: nil,
            postalCode: nil,
            country: nil)
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.SEPADebit)
            XCTAssertNil(source?.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.owner?.name, params.owner?["name"] as? String)
            XCTAssertNil(source?.owner?.address?.city)
            XCTAssertNil(source?.owner?.address?.line1)
            XCTAssertNil(source?.owner?.address?.country)
            XCTAssertEqual(source?.sepaDebitDetails?.country, "DE") // German IBAN so sepa tells us country here even though we didnt pass it up as owner info
            XCTAssertEqual(source?.sepaDebitDetails?.last4, "3000")
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_sofort() {
        let params = STPSourceParams.sofortParams(
            withAmount: 1099,
            returnURL: "https://shop.example.com/crtABC",
            country: "DE",
            statementDescriptor: "ORDER AT11990")
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.sofort)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")
            XCTAssertEqual(source?.details?["country"] as? String, "DE")

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

    func testCreateSource_alipay() {
        let params = STPSourceParams.alipayParams(
            withAmount: 1099,
            currency: "usd",
            returnURL: "https://shop.example.com/crtABC")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Alipay Source creation")

        params.metadata = [
            "foo": "bar",
        ]
        client.createSource(with: params) { source, error2 in
            XCTAssertNil(error2)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.alipay)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_p24() {
        let params = STPSourceParams.p24Params(
            withAmount: 1099,
            currency: "eur",
            email: "user@example.com",
            name: "Jenny Rosen",
            returnURL: "https://shop.example.com/crtABC")

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "P24 Source creation")

        params.metadata = [
            "foo": "bar",
        ]
        client.createSource(with: params) { source, error2 in
            XCTAssertNil(error2)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.P24)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.owner?.email, params.owner?["email"] as? String)
            XCTAssertEqual(source?.owner?.name, params.owner?["name"] as? String)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")
            expectation.fulfill()
        }

        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testRetrieveSource_sofort() {
        let client = STPAPIClient(publishableKey: "pk_test_vOo1umqsYxSrP5UXfOeL3ecm")
        let params = STPSourceParams()
        params.type = STPSourceType.sofort
        params.amount = NSNumber(value: 1099)
        params.currency = "eur"
        params.redirect = [
            "return_url": "https://shop.example.com/crtA6B28E1",
        ]
        params.metadata = [
            "foo": "bar",
        ]
        params.additionalAPIParameters = [
            "sofort": [
            "country": "DE",
        ],
        ]
        let createExp = expectation(description: "Source creation")
        let retrieveExp = expectation(description: "Source retrieval")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            guard let source else { XCTFail(); return }
            createExp.fulfill()
            client.retrieveSource(
                withId: source.stripeID,
                clientSecret: source.clientSecret!) { source2, error2 in
                XCTAssertNil(error2)
                XCTAssertNotNil(source2)
                XCTAssertEqual(source, source2)
                retrieveExp.fulfill()
            }
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_eps() {
        let params = STPSourceParams.epsParams(
            withAmount: 1099,
            name: "Jenny Rosen",
            returnURL: "https://shop.example.com/crtABC",
            statementDescriptor: "ORDER AT123")
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.EPS)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.owner?.name, params.owner?["name"] as? String)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")
            XCTAssertEqual(source?.allResponseFields["statement_descriptor"] as! String, "ORDER AT123")

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_eps_no_statement_descriptor() {
        let params = STPSourceParams.epsParams(
            withAmount: 1099,
            name: "Jenny Rosen",
            returnURL: "https://shop.example.com/crtABC",
            statementDescriptor: nil)
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.EPS)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.currency, params.currency)
            XCTAssertEqual(source?.owner?.name, params.owner?["name"] as? String)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")
            XCTAssertNil(source?.allResponseFields["statement_descriptor"])

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_multibanco() {
        let params = STPSourceParams.multibancoParams(
            withAmount: 1099,
            returnURL: "https://shop.example.com/crtABC",
            email: "user@example.com")
        params.metadata = [
            "foo": "bar",
        ]

        let client = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.multibanco)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/crtABC?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)
            XCTAssertNil(source?.perform(NSSelectorFromString("metadata")), "Metadata is not returned.")

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_klarna() {
        let lineItems = [
            STPKlarnaLineItem(itemType: STPKlarnaLineItemType.SKU, itemDescription: "Test Item", quantity: NSNumber(value: 2), totalAmount: NSNumber(value: 500)),
            STPKlarnaLineItem(itemType: STPKlarnaLineItemType.tax, itemDescription: "Tax", quantity: NSNumber(value: 1), totalAmount: NSNumber(value: 100)),
        ]
        let address = STPAddress()
        address.line1 = "29 Arlington Avenue"
        address.email = "test@example.com"
        address.city = "London"
        address.postalCode = "N1 7BE"
        address.country = "GB"
        address.phone = "02012267709"
        let dob = STPDateOfBirth()
        dob.day = 11
        dob.month = 3
        dob.year = 1952
        let params = STPSourceParams.klarnaParams(withReturnURL: "https://shop.example.com/return", currency: "GBP", purchaseCountry: "GB", items: lineItems, customPaymentMethods: [STPKlarnaPaymentMethods.none], billingAddress: address, billingFirstName: "Arthur", billingLastName: "Dent", billingDOB: dob)

        let client = STPAPIClient(publishableKey: STPTestingGBPublishableKey)
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.klarna)
            XCTAssertEqual(source?.amount, NSNumber(value: 600))
            XCTAssertEqual(source?.owner?.address?.line1, address.line1)
            XCTAssertEqual(source?.klarnaDetails?.purchaseCountry, "GB")
            XCTAssertEqual(source?.redirect?.status, STPSourceRedirectStatus.pending)
            XCTAssertEqual(source?.redirect?.returnURL, URL(string: "https://shop.example.com/return?redirect_merchant_name=xctest"))
            XCTAssertNotNil(source?.redirect?.url)

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    // 7/5/2023:
    // Previously, we were allowed to use live keys and test w/ wechat on sources would generated "ios_native_url"
    // however, this is no longer possible.  Therefore, to get ample test coverage, we will have two tests:
    // - testCreateSource_wechatPay_testMode - run in test mode, to ensure we can still call sources
    // - testCreateSource_wechatPay_mocked - run a mocked version which is what we would expect in live mode
    func testCreateSource_wechatPay_testMode() {
        let params = STPSourceParams.wechatPay(
            withAmount: 1010,
            currency: "usd",
            appId: "wxa0df51ec63e578ce",
            statementDescriptor: nil)
        let client = STPAPIClient(publishableKey: "pk_test_h0JFD5q63mLThM5JVSbrREmR")
        let expectation = self.expectation(description: "Source creation")
        client.createSource(with: params) { source, error in
            XCTAssertNil(error)
            XCTAssertNotNil(source)
            XCTAssertEqual(source?.type, STPSourceType.weChatPay)
            XCTAssertEqual(source?.status, STPSourceStatus.pending)
            XCTAssertEqual(source?.amount, params.amount)
            XCTAssertNil(source?.redirect)

            let wechat = source?.weChatPayDetails
            XCTAssertNotNil(wechat)
            // Will not be generated in test mode
            // XCTAssertNotNil(wechat.weChatAppURL);

            expectation.fulfill()
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout, handler: nil)
    }

    func testCreateSource_wechatPay_mocked() {
        let params = STPSourceParams.wechatPay(
            withAmount: 1010,
            currency: "usd",
            appId: "wxa0df51ec63e578ce",
            statementDescriptor: nil)

        let source = STPFixtures.weChatPaySource()
        XCTAssertEqual(source.type, STPSourceType.weChatPay)
        XCTAssertEqual(source.status, STPSourceStatus.pending)
        XCTAssertEqual(source.amount, params.amount)
        XCTAssertNil(source.redirect)

        let wechat = source.weChatPayDetails
        XCTAssertNotNil(wechat)
        XCTAssertNotNil(wechat?.weChatAppURL)
    }
}
