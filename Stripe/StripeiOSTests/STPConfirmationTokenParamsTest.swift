//
//  STPConfirmationTokenParamsTest.swift
//  StripePaymentsTests
//
//  Created by Nick Porter on 9/3/25.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP)@_spi(ConfirmationTokensPublicPreview) import StripePayments
import XCTest

class STPConfirmationTokenParamsTest: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testDefaultInit() {
        let params = STPConfirmationTokenParams()
        
        XCTAssertNotNil(params)
        XCTAssertNil(params.paymentMethod)
        XCTAssertNil(params.paymentMethodData)
        XCTAssertNil(params.paymentMethodOptions)
        XCTAssertNil(params.returnURL)
        XCTAssertEqual(params.setupFutureUsage, STPPaymentIntentSetupFutureUsage.none)
        XCTAssertNil(params.shipping)
        XCTAssertNil(params.mandateData)
        XCTAssertNotNil(params.additionalAPIParameters)
        XCTAssertEqual(params.additionalAPIParameters.count, 0)
    }
    
    func testConvenienceInitWithPaymentMethodData() {
        let paymentMethodData = STPPaymentMethodData()
        let returnURL = "https://example.com/return"
        
        let params = STPConfirmationTokenParams()
        params.paymentMethodData = paymentMethodData
        params.returnURL = returnURL
        
        XCTAssertNotNil(params)
        XCTAssertEqual(params.paymentMethodData, paymentMethodData)
        XCTAssertEqual(params.returnURL, returnURL)
        XCTAssertNil(params.paymentMethod)
        XCTAssertNil(params.mandateData)
    }
    
    func testConvenienceInitWithPaymentMethodParams() {
        let paymentMethodParams = STPPaymentMethodParams()
        let returnURL = "https://example.com/return"
        
        let params = STPConfirmationTokenParams()
        params.paymentMethodData = STPPaymentMethodData(from: paymentMethodParams)
        params.returnURL = returnURL
        
        XCTAssertNotNil(params)
        XCTAssertNotNil(params.paymentMethodData)
        XCTAssertEqual(params.returnURL, returnURL)
        XCTAssertNil(params.paymentMethod)
        XCTAssertNil(params.mandateData)
    }
    
    // MARK: - Description Tests
    
    func testDescription() {
        let params = STPConfirmationTokenParams()
        let description = params.description
        
        XCTAssertTrue(description.contains("STPConfirmationTokenParams"))
        XCTAssertTrue(description.contains("paymentMethod"))
        XCTAssertTrue(description.contains("paymentMethodData"))
        XCTAssertTrue(description.contains("paymentMethodOptions"))
        XCTAssertTrue(description.contains("returnURL"))
        XCTAssertTrue(description.contains("setupFutureUsage"))
        XCTAssertTrue(description.contains("shipping"))
        XCTAssertTrue(description.contains("mandateData"))
    }
    
    func testDescriptionWithPopulatedProperties() {
        let params = STPConfirmationTokenParams()
        params.paymentMethod = "pm_test_123"
        params.returnURL = "https://example.com"
        
        let mandateData = STPMandateDataParams.makeWithInferredValues()
        params.mandateData = mandateData
        
        let description = params.description
        XCTAssertTrue(description.contains("pm_test_123"))
        XCTAssertTrue(description.contains("https://example.com"))
        XCTAssertTrue(description.contains("STPMandateDataParams"))
    }
    
    // MARK: - STPFormEncodable Tests
    
    func testRootObjectName() {
        XCTAssertNil(STPConfirmationTokenParams.rootObjectName())
    }
    
    func testPropertyNamesToFormFieldNamesMapping() {
        let params = STPConfirmationTokenParams()
        let mapping = STPConfirmationTokenParams.propertyNamesToFormFieldNamesMapping()
        
        // Verify all property names don't contain colons
        for propertyName in mapping.keys {
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(params.responds(to: NSSelectorFromString(propertyName)))
        }
        
        // Verify all form field names are non-empty
        for formFieldName in mapping.values {
            XCTAssert(formFieldName.count > 0)
        }
        
        // Verify all form field names are unique
        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)
        
        // Verify expected mappings
        XCTAssertEqual(mapping["paymentMethod"], "payment_method")
        XCTAssertEqual(mapping["paymentMethodData"], "payment_method_data")
        XCTAssertEqual(mapping["paymentMethodOptions"], "payment_method_options")
        XCTAssertEqual(mapping["returnURL"], "return_url")
        XCTAssertEqual(mapping["shipping"], "shipping")
        XCTAssertEqual(mapping["mandateData"], "mandate_data")
    }
    
    // MARK: - Individual Property Tests
    
    func testPaymentMethodProperty() {
        let params = STPConfirmationTokenParams()
        
        XCTAssertNil(params.paymentMethod)
        
        params.paymentMethod = "pm_test_123"
        XCTAssertEqual(params.paymentMethod, "pm_test_123")
        
        params.paymentMethod = nil
        XCTAssertNil(params.paymentMethod)
    }
    
    func testPaymentMethodDataProperty() {
        let params = STPConfirmationTokenParams()
        let paymentMethodData = STPPaymentMethodData()
        
        XCTAssertNil(params.paymentMethodData)
        
        params.paymentMethodData = paymentMethodData
        XCTAssertEqual(params.paymentMethodData, paymentMethodData)
        
        params.paymentMethodData = nil
        XCTAssertNil(params.paymentMethodData)
    }
    
    func testReturnURLProperty() {
        let params = STPConfirmationTokenParams()
        
        XCTAssertNil(params.returnURL)
        
        params.returnURL = "https://example.com/return"
        XCTAssertEqual(params.returnURL, "https://example.com/return")
        
        params.returnURL = ""
        XCTAssertEqual(params.returnURL, "")
        
        params.returnURL = nil
        XCTAssertNil(params.returnURL)
    }
    
    func testSetupFutureUsageProperty() {
        let params = STPConfirmationTokenParams()
        
        XCTAssertEqual(params.setupFutureUsage, STPPaymentIntentSetupFutureUsage.none)
        
        params.setupFutureUsage = STPPaymentIntentSetupFutureUsage.onSession
        XCTAssertEqual(params.setupFutureUsage, STPPaymentIntentSetupFutureUsage.onSession)
        
        params.setupFutureUsage = STPPaymentIntentSetupFutureUsage.offSession
        XCTAssertEqual(params.setupFutureUsage, STPPaymentIntentSetupFutureUsage.offSession)
    }
    
    func testMandateDataProperty() {
        let params = STPConfirmationTokenParams()
        
        XCTAssertNil(params.mandateData)
        
        let mandateData = STPMandateDataParams.makeWithInferredValues()
        params.mandateData = mandateData
        XCTAssertEqual(params.mandateData, mandateData)
        
        params.mandateData = nil
        XCTAssertNil(params.mandateData)
    }
    
    // MARK: - Additional API Parameters Tests
    
    func testAdditionalAPIParameters() {
        let params = STPConfirmationTokenParams()
        
        XCTAssertEqual(params.additionalAPIParameters.count, 0)
        
        params.additionalAPIParameters = ["custom_key": "custom_value"]
        XCTAssertEqual(params.additionalAPIParameters["custom_key"] as? String, "custom_value")
    }
    
    func testAdditionalAPIParametersWithSetupFutureUsage() {
        let params = STPConfirmationTokenParams()
        params.setupFutureUsage = STPPaymentIntentSetupFutureUsage.onSession
        
        let apiParams = params.additionalAPIParameters
        XCTAssertEqual(apiParams["setup_future_usage"] as? String, "on_session")
    }
    
    func testAdditionalAPIParametersWithNoneSetupFutureUsage() {
        let params = STPConfirmationTokenParams()
        params.setupFutureUsage = .none
        
        let apiParams = params.additionalAPIParameters
        XCTAssertNil(apiParams["setup_future_usage"])
    }
    
    // MARK: - Form Encoding Integration Tests
    
    func testFormEncodingWithMandateData() {
        let params = STPConfirmationTokenParams()
        let mandateData = STPMandateDataParams.makeWithInferredValues()
        params.mandateData = mandateData
        
        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNotNil(encoded["mandate_data"])
    }
    
    func testFormEncodingWithoutMandateData() {
        let params = STPConfirmationTokenParams()
        
        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNil(encoded["mandate_data"])
    }
    
    func testCompleteFormEncoding() {
        let params = STPConfirmationTokenParams()
        params.paymentMethod = "pm_test_123"
        params.returnURL = "https://example.com/return"
        params.setupFutureUsage = STPPaymentIntentSetupFutureUsage.onSession
        
        let mandateData = STPMandateDataParams.makeWithInferredValues()
        params.mandateData = mandateData
        
        let encoded = STPFormEncoder.dictionary(forObject: params)
        
        XCTAssertEqual(encoded["payment_method"] as? String, "pm_test_123")
        XCTAssertEqual(encoded["return_url"] as? String, "https://example.com/return")
        XCTAssertEqual(encoded["setup_future_usage"] as? String, "on_session")
        XCTAssertNotNil(encoded["mandate_data"])
    }
    
    // MARK: - Real-World Usage Pattern Tests
    
    func testCompleteObjectCreation() {
        let paymentMethodData = STPPaymentMethodData()
        let params = STPConfirmationTokenParams()
        params.paymentMethodData = paymentMethodData
        params.returnURL = "https://example.com/return"
        
        // Add mandate data
        let mandateData = STPMandateDataParams.makeWithInferredValues()
        params.mandateData = mandateData
        
        // Add shipping
        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: "123 Test St")
        let shipping = STPPaymentIntentShippingDetailsParams(address: addressParams, name: "Test User")
        params.shipping = shipping
        
        // Set setup future usage
        params.setupFutureUsage = STPPaymentIntentSetupFutureUsage.offSession
        
        // Verify all properties are set
        XCTAssertNotNil(params.paymentMethodData)
        XCTAssertEqual(params.returnURL, "https://example.com/return")
        XCTAssertNotNil(params.mandateData)
        XCTAssertNotNil(params.shipping)
        XCTAssertEqual(params.setupFutureUsage, STPPaymentIntentSetupFutureUsage.offSession)
        
        // Verify form encoding works
        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNotNil(encoded["payment_method_data"])
        XCTAssertNotNil(encoded["mandate_data"])
        XCTAssertNotNil(encoded["shipping"])
        XCTAssertEqual(encoded["setup_future_usage"] as? String, "off_session")
    }
    
    func testPropertyMutationAfterInit() {
        let params = STPConfirmationTokenParams()
        
        // Start with basic setup
        params.paymentMethod = "pm_initial"
        XCTAssertEqual(params.paymentMethod, "pm_initial")
        
        // Change to payment method data
        params.paymentMethod = nil
        params.paymentMethodData = STPPaymentMethodData()
        XCTAssertNil(params.paymentMethod)
        XCTAssertNotNil(params.paymentMethodData)
        
        // Add mandate data later
        params.mandateData = STPMandateDataParams.makeWithInferredValues()
        XCTAssertNotNil(params.mandateData)
        
        // Verify encoding still works
        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNil(encoded["payment_method"])
        XCTAssertNotNil(encoded["payment_method_data"])
        XCTAssertNotNil(encoded["mandate_data"])
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyStringProperties() {
        let params = STPConfirmationTokenParams()
        
        params.paymentMethod = ""
        params.returnURL = ""
        
        XCTAssertEqual(params.paymentMethod, "")
        XCTAssertEqual(params.returnURL, "")
        
        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertEqual(encoded["payment_method"] as? String, "")
        XCTAssertEqual(encoded["return_url"] as? String, "")
    }
    
    func testNilPropertiesInEncoding() {
        let params = STPConfirmationTokenParams()
        
        // All properties should be nil by default
        let encoded = STPFormEncoder.dictionary(forObject: params)
        
        XCTAssertNil(encoded["payment_method"])
        XCTAssertNil(encoded["payment_method_data"])
        XCTAssertNil(encoded["payment_method_options"])
        XCTAssertNil(encoded["return_url"])
        XCTAssertNil(encoded["shipping"])
        XCTAssertNil(encoded["mandate_data"])
        
        // setup_future_usage should not be present when .none
        XCTAssertNil(encoded["setup_future_usage"])
    }
}
