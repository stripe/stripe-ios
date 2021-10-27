//
//  STPAddCardViewControllerTest.swift
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
@testable import Stripe
@_spi(STP) @testable import StripeCore
import OHHTTPStubs

class MockDelegate: NSObject, STPAddCardViewControllerDelegate {
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {

    }

    var addCardViewControllerDidCreatePaymentMethodBlock:
        (STPAddCardViewController, STPPaymentMethod, STPErrorBlock) -> Void = { _, _, _ in }
    func addCardViewController(
        _ addCardViewController: STPAddCardViewController,
        didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock
    ) {
        addCardViewControllerDidCreatePaymentMethodBlock(
            addCardViewController, paymentMethod, completion)
    }
}

class STPAddCardViewControllerTest: APIStubbedTestCase {
    
    func paymentMethodAPIFilter(expectedCardParams: STPPaymentMethodCardParams, urlRequest: URLRequest) -> Bool {
        if urlRequest.url?.absoluteString.contains("payment_methods") ?? false {
            let cardNumber = urlRequest.queryItems?.first(where: { item in
                item.name == "card[number]"
            })
            XCTAssertEqual(cardNumber!.value, expectedCardParams.number)
            return true
        }
        return false
    }
    
    func buildAddCardViewController() -> STPAddCardViewController? {
        let config = STPFixtures.paymentConfiguration()
        let theme = STPTheme.defaultTheme
        let vc = STPAddCardViewController(
            configuration: config,
            theme: theme)
        XCTAssertNotNil(vc.view)
        return vc
    }

    func testPrefilledBillingAddress_removeAddress() {
        let config = STPFixtures.paymentConfiguration()
        config.requiredBillingAddressFields = .postalCode
        let sut = STPAddCardViewController(
            configuration: config,
            theme: STPTheme.defaultTheme)
        let address = STPAddress()
        address.name = "John Smith Doe"
        address.phone = "8885551212"
        address.email = "foo@example.com"
        address.line1 = "55 John St"
        address.city = "Harare"
        address.postalCode = "10002"
        address.country = "ZW"  // Zimbabwe does not require zip codes, while the default locale for tests (US) does
        // Sanity checks
        XCTAssertFalse(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "ZW"))
        XCTAssertTrue(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "US"))

        let prefilledInfo = STPUserInformation()
        prefilledInfo.billingAddress = address
        sut.prefilledInformation = prefilledInfo

        XCTAssertNoThrow(sut.loadView())
        XCTAssertNoThrow(sut.viewDidLoad())
    }

    func testPrefilledBillingAddress_addAddress() {
        // Zimbabwe does not require zip codes, while the default locale for tests (US) does
        NSLocale.stp_withLocale(as: NSLocale(localeIdentifier: "en_ZW") as Locale) {
            // Sanity checks
            XCTAssertFalse(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "ZW"))
            XCTAssertTrue(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "US"))
            let config = STPFixtures.paymentConfiguration()
            config.requiredBillingAddressFields = .postalCode
            let sut = STPAddCardViewController(
                configuration: config,
                theme: STPTheme.defaultTheme)
            let address = STPAddress()
            address.name = "John Smith Doe"
            address.phone = "8885551212"
            address.email = "foo@example.com"
            address.line1 = "55 John St"
            address.city = "New York"
            address.state = "NY"
            address.postalCode = "10002"
            address.country = "US"

            let prefilledInfo = STPUserInformation()
            prefilledInfo.billingAddress = address
            sut.prefilledInformation = prefilledInfo

            XCTAssertNoThrow(sut.loadView())
            XCTAssertNoThrow(sut.viewDidLoad())
        }
    }

    //#pragma clang diagnostic push
    //#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    func testNextWithCreatePaymentMethodError() {
        let sut = buildAddCardViewController()!
        let expectedCardParams = STPFixtures.paymentMethodCardParams()
        sut.paymentCell?.paymentField!.cardParams = expectedCardParams

        let exp = expectation(description: "createPaymentMethodWithCard network request")
        stub { urlRequest in
            return self.paymentMethodAPIFilter(expectedCardParams: expectedCardParams, urlRequest: urlRequest)
        } response: { urlRequest in
            XCTAssertTrue(sut.loading)
            let paymentMethod = ["error": "intentionally_invalid"]
            defer {
                exp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: paymentMethod, statusCode: 200, headers: nil)
        }
        sut.apiClient = stubbedAPIClient()
        // tap next button
        let nextButton = sut.navigationItem.rightBarButtonItem
        _ = nextButton?.target?.perform(nextButton?.action, with: nextButton)

        waitForExpectations(timeout: 2, handler: nil)
        
        // It takes a few more spins on the runloop before we get a response from
        // the HTTP stubs, so we'll wait 0.5 seconds before checking the loading indicator.
        let loadExp = expectation(description: "loading has stopped")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(sut.loading)
            loadExp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testNextWithCreatePaymentMethodSuccessAndDidCreatePaymentMethodError() {
        let sut = buildAddCardViewController()!
        let createPaymentMethodExp = expectation(description: "createPaymentMethodWithCard")

        let expectedCardParams = STPFixtures.paymentMethodCardParams()
        let expectedPaymentMethod = STPFixtures.paymentMethod()
        let expectedPaymentMethodData = STPFixtures.paymentMethodJSON()
        
        stub { urlRequest in
            return self.paymentMethodAPIFilter(expectedCardParams: expectedCardParams, urlRequest: urlRequest)
        } response: { urlRequest in
            XCTAssertTrue(sut.loading)
            defer {
                createPaymentMethodExp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: expectedPaymentMethodData, statusCode: 200, headers: nil)
        }

        let mockDelegate = MockDelegate()
        sut.apiClient = stubbedAPIClient()
        sut.delegate = mockDelegate
        sut.paymentCell?.paymentField!.cardParams = expectedCardParams
        
        let didCreatePaymentMethodExp = expectation(description: "didCreatePaymentMethod")

        mockDelegate.addCardViewControllerDidCreatePaymentMethodBlock = {
            (addCardViewController, paymentMethod, completion) in
            XCTAssertTrue(sut.loading)
            let error = NSError.stp_genericFailedToParseResponseError()
            XCTAssertEqual(paymentMethod.stripeId, expectedPaymentMethod.stripeId)
            completion(error)
            XCTAssertFalse(sut.loading)
            didCreatePaymentMethodExp.fulfill()
        }

        // tap next button
        let nextButton = sut.navigationItem.rightBarButtonItem
        _ = nextButton?.target?.perform(nextButton?.action, with: nextButton)

        waitForExpectations(timeout: 2, handler: nil)
    }

    
    func testNextWithCreateTokenSuccessAndDidCreateTokenSuccess() {
        let sut = buildAddCardViewController()!

        let createPaymentMethodExp = expectation(description: "createPaymentMethodWithCard")
        
        let expectedCardParams = STPFixtures.paymentMethodCardParams()
        let expectedPaymentMethod = STPFixtures.paymentMethod()
        let expectedPaymentMethodData = STPFixtures.paymentMethodJSON()
        
        stub { urlRequest in
            return self.paymentMethodAPIFilter(expectedCardParams: expectedCardParams, urlRequest: urlRequest)
        } response: { urlRequest in
            XCTAssertTrue(sut.loading)
            defer {
                createPaymentMethodExp.fulfill()
            }
            return HTTPStubsResponse(jsonObject: expectedPaymentMethodData, statusCode: 200, headers: nil)
        }

        
        let mockDelegate = MockDelegate()
        sut.apiClient = stubbedAPIClient()
        sut.delegate = mockDelegate
        sut.paymentCell?.paymentField!.cardParams = expectedCardParams


        let didCreatePaymentMethodExp = expectation(description: "didCreatePaymentMethod")
        mockDelegate.addCardViewControllerDidCreatePaymentMethodBlock = {
            (addCardViewController, paymentMethod, completion) in
            XCTAssertTrue(sut.loading)
            XCTAssertEqual(paymentMethod.stripeId, expectedPaymentMethod.stripeId)
            completion(nil)
            XCTAssertFalse(sut.loading)
            didCreatePaymentMethodExp.fulfill()
        }

        // tap next button
        let nextButton = sut.navigationItem.rightBarButtonItem
        _ = nextButton?.target?.perform(nextButton?.action, with: nextButton)

        waitForExpectations(timeout: 2, handler: nil)
    }
}
