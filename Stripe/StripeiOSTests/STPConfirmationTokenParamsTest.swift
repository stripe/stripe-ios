//
//  STPConfirmationTokenParamsTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 8/25/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable @_spi(STP) import Stripe
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments

class STPConfirmationTokenParamsTest: XCTestCase {
    
    // MARK: - Initialization Tests
    func testInit() {
        let confirmationTokenParams = STPConfirmationTokenParams()
        
        XCTAssertNotNil(confirmationTokenParams)
        XCTAssertNil(confirmationTokenParams.paymentMethodData)
        XCTAssertNil(confirmationTokenParams.returnURL)
        XCTAssertEqual(confirmationTokenParams.setupFutureUsage, .none)
        XCTAssertNil(confirmationTokenParams.shipping)
        XCTAssertTrue(confirmationTokenParams.useStripeSDK)
    }
    
    func testInitWithPaymentMethodData() {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams,
            returnURL: "https://example.com/return"
        )
        
        XCTAssertNotNil(confirmationTokenParams.paymentMethodData)
        XCTAssertEqual(confirmationTokenParams.returnURL, "https://example.com/return")
        XCTAssertEqual(confirmationTokenParams.setupFutureUsage, .none)
        XCTAssertTrue(confirmationTokenParams.useStripeSDK)
    }
    
    // MARK: - Description Test
    func testDescription() {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams,
            returnURL: "https://example.com/return"
        )
        
        let description = confirmationTokenParams.description
        XCTAssertTrue(description.contains("STPConfirmationTokenParams"))
        XCTAssertTrue(description.contains("https://example.com/return"))
    }
    
    // MARK: - STPFormEncodable Tests
    func testRootObjectName() {
        XCTAssertNil(STPConfirmationTokenParams.rootObjectName())
    }
    
    func testPropertyNamesToFormFieldNamesMapping() {
        let mapping = STPConfirmationTokenParams.propertyNamesToFormFieldNamesMapping()
        
        XCTAssertEqual(mapping["paymentMethodData"], "payment_method_data")
        XCTAssertEqual(mapping["returnURL"], "return_url")
        XCTAssertEqual(mapping["setupFutureUsage"], "setup_future_usage")
        XCTAssertEqual(mapping["shipping"], "shipping")
        XCTAssertEqual(mapping["useStripeSDK"], "use_stripe_sdk")
    }
    
    // MARK: - Form Encoding Tests
    func testFormEncoding() {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 12)
        cardParams.expYear = NSNumber(value: 2030)
        cardParams.cvc = "123"
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = "test@example.com"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams()
        confirmationTokenParams.paymentMethodData = paymentMethodParams
        confirmationTokenParams.returnURL = "https://example.com/return"
        confirmationTokenParams.setupFutureUsage = .offSession
        confirmationTokenParams.useStripeSDK = false
        
        let formDict = STPFormEncoder.dictionary(forObject: confirmationTokenParams)
        
        XCTAssertNotNil(formDict["payment_method_data"])
        XCTAssertEqual(formDict["return_url"] as? String, "https://example.com/return")
        XCTAssertEqual(formDict["setup_future_usage"] as? String, "off_session")
        XCTAssertEqual(formDict["use_stripe_sdk"] as? Bool, false)
        
        // Verify nested payment method data encoding
        let paymentMethodDataDict = formDict["payment_method_data"] as? [String: Any]
        XCTAssertNotNil(paymentMethodDataDict)
        XCTAssertEqual(paymentMethodDataDict?["type"] as? String, "card")
        
        let cardDict = paymentMethodDataDict?["card"] as? [String: Any]
        XCTAssertNotNil(cardDict)
        XCTAssertEqual(cardDict?["number"] as? String, "4242424242424242")
        XCTAssertEqual(cardDict?["exp_month"] as? NSNumber, 12)
        XCTAssertEqual(cardDict?["exp_year"] as? NSNumber, 2030)
        XCTAssertEqual(cardDict?["cvc"] as? String, "123")
        
        let billingDetailsDict = paymentMethodDataDict?["billing_details"] as? [String: Any]
        XCTAssertNotNil(billingDetailsDict)
        XCTAssertEqual(billingDetailsDict?["email"] as? String, "test@example.com")
    }
    
    // MARK: - Validation Tests
    func testValidateValidParams() {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 12)
        cardParams.expYear = NSNumber(value: 2030)
        cardParams.cvc = "123"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams
        )
        
        let error = confirmationTokenParams.validate()
        XCTAssertNil(error)
    }
    
    func testValidateMissingPaymentMethodData() {
        let confirmationTokenParams = STPConfirmationTokenParams()
        
        let error = confirmationTokenParams.validate()
        XCTAssertNotNil(error)
    }
    
    func testValidateUnsupportedPaymentMethodType() {
        let paymentMethodParams = STPPaymentMethodParams()
        paymentMethodParams.rawTypeString = nil // This will result in .unknown type
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams
        )
        
        let error = confirmationTokenParams.validate()
        XCTAssertNotNil(error)
        XCTAssertTrue(error!.localizedDescription.contains("payment method type is not supported"))
    }
    
    func testValidateInvalidReturnURL() {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 12)
        cardParams.expYear = NSNumber(value: 2030)
        cardParams.cvc = "123"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams,
            returnURL: "invalid-url"
        )
        
        let error = confirmationTokenParams.validate()
        XCTAssertNotNil(error)
        XCTAssertTrue(error!.localizedDescription.contains("return URL format is invalid"))
    }
    
    func testValidateValidReturnURL() {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 12)
        cardParams.expYear = NSNumber(value: 2030)
        cardParams.cvc = "123"
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )
        
        let confirmationTokenParams = STPConfirmationTokenParams(
            paymentMethodData: paymentMethodParams,
            returnURL: "https://example.com/return"
        )
        
        let error = confirmationTokenParams.validate()
        XCTAssertNil(error)
    }
    
    // MARK: - Property Tests
    func testSetupFutureUsage() {
        let confirmationTokenParams = STPConfirmationTokenParams()
        
        // Test default value
        XCTAssertEqual(confirmationTokenParams.setupFutureUsage, .none)
        
        // Test setting values
        confirmationTokenParams.setupFutureUsage = .offSession
        XCTAssertEqual(confirmationTokenParams.setupFutureUsage, .offSession)
        
        confirmationTokenParams.setupFutureUsage = .onSession
        XCTAssertEqual(confirmationTokenParams.setupFutureUsage, .onSession)
    }
    
    func testUseStripeSDK() {
        let confirmationTokenParams = STPConfirmationTokenParams()
        
        // Test default value
        XCTAssertTrue(confirmationTokenParams.useStripeSDK)
        
        // Test setting value
        confirmationTokenParams.useStripeSDK = false
        XCTAssertFalse(confirmationTokenParams.useStripeSDK)
    }
    
    func testReturnURL() {
        let confirmationTokenParams = STPConfirmationTokenParams()
        
        // Test default value
        XCTAssertNil(confirmationTokenParams.returnURL)
        
        // Test setting value
        confirmationTokenParams.returnURL = "https://example.com/return"
        XCTAssertEqual(confirmationTokenParams.returnURL, "https://example.com/return")
    }
    
    // MARK: - Additional API Parameters Tests
    func testAdditionalAPIParameters() {
        let confirmationTokenParams = STPConfirmationTokenParams()
        
        // Test default empty
        XCTAssertTrue(confirmationTokenParams.additionalAPIParameters.isEmpty)
        
        // Test setting additional parameters
        confirmationTokenParams.additionalAPIParameters = ["custom_param": "custom_value"]
        XCTAssertEqual(confirmationTokenParams.additionalAPIParameters["custom_param"] as? String, "custom_value")
        
        // Verify they are included in form encoding
        let formDict = STPFormEncoder.dictionary(forObject: confirmationTokenParams)
        XCTAssertEqual(formDict["custom_param"] as? String, "custom_value")
    }
}
