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
        XCTAssertNil(params.setAsDefaultPM)
        XCTAssertNil(params.clientAttributionMetadata)
        XCTAssertNil(params.clientContext)
        XCTAssertNotNil(params.additionalAPIParameters)
        XCTAssertEqual(params.additionalAPIParameters.count, 0)
    }

    func testConvenienceInitWithPaymentMethodData() {
        let paymentMethodData = STPPaymentMethodParams()
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
        params.paymentMethodData = paymentMethodParams
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
        XCTAssertTrue(description.contains("setAsDefaultPM"))
        XCTAssertTrue(description.contains("clientAttributionMetadata"))
        XCTAssertTrue(description.contains("clientContext"))
    }

    func testDescriptionWithPopulatedProperties() {
        let params = STPConfirmationTokenParams()
        params.paymentMethod = "pm_test_123"
        params.returnURL = "https://example.com"

        let mandateData = STPMandateDataParams.makeWithInferredValues()
        params.mandateData = mandateData

        let paymentMethodOptions = STPConfirmPaymentMethodOptions()
        params.paymentMethodOptions = paymentMethodOptions

        let description = params.description
        XCTAssertTrue(description.contains("pm_test_123"))
        XCTAssertTrue(description.contains("https://example.com"))
        XCTAssertTrue(description.contains("STPMandateDataParams"))
        XCTAssertTrue(description.contains("STPConfirmPaymentMethodOptions"))
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
        XCTAssertEqual(mapping["setAsDefaultPM"], "set_as_default_payment_method")
        XCTAssertEqual(mapping["clientAttributionMetadata"], "client_attribution_metadata")
        XCTAssertEqual(mapping["clientContext"], "client_context")
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
        let paymentMethodData = STPPaymentMethodParams()

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

    func testSetAsDefaultPMProperty() {
        let params = STPConfirmationTokenParams()

        XCTAssertNil(params.setAsDefaultPM)

        params.setAsDefaultPM = NSNumber(value: true)
        XCTAssertEqual(params.setAsDefaultPM, NSNumber(value: true))

        params.setAsDefaultPM = NSNumber(value: false)
        XCTAssertEqual(params.setAsDefaultPM, NSNumber(value: false))

        params.setAsDefaultPM = nil
        XCTAssertNil(params.setAsDefaultPM)
    }

    func testPaymentMethodOptionsProperty() {
        let params = STPConfirmationTokenParams()

        XCTAssertNil(params.paymentMethodOptions)

        let paymentMethodOptions = STPConfirmPaymentMethodOptions()
        params.paymentMethodOptions = paymentMethodOptions
        XCTAssertEqual(params.paymentMethodOptions, paymentMethodOptions)

        params.paymentMethodOptions = nil
        XCTAssertNil(params.paymentMethodOptions)
    }

    func testClientAttributionMetadataProperty() {
        let params = STPConfirmationTokenParams()

        XCTAssertNil(params.clientAttributionMetadata)

        let clientMetadata = STPClientAttributionMetadata()
        params.clientAttributionMetadata = clientMetadata
        XCTAssertEqual(params.clientAttributionMetadata, clientMetadata)

        params.clientAttributionMetadata = nil
        XCTAssertNil(params.clientAttributionMetadata)
    }

    func testClientContextProperty() {
        let params = STPConfirmationTokenParams()

        XCTAssertNil(params.clientContext)

        let clientContext = STPConfirmationTokenClientContext()
        clientContext.mode = "payment"
        clientContext.currency = "usd"

        params.clientContext = clientContext
        XCTAssertEqual(params.clientContext, clientContext)
        XCTAssertEqual(params.clientContext?.mode, "payment")
        XCTAssertEqual(params.clientContext?.currency, "usd")

        params.clientContext = nil
        XCTAssertNil(params.clientContext)
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

    func testAdditionalAPIParametersWithSetAsDefaultPM() {
        let params = STPConfirmationTokenParams()
        params.setAsDefaultPM = NSNumber(value: true)

        let apiParams = params.additionalAPIParameters
        XCTAssertEqual(apiParams["set_as_default_payment_method"] as? NSNumber, NSNumber(value: true))
    }

    func testAdditionalAPIParametersWithoutSetAsDefaultPM() {
        let params = STPConfirmationTokenParams()

        let apiParams = params.additionalAPIParameters
        XCTAssertNil(apiParams["set_as_default_payment_method"])
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

    func testFormEncodingWithPaymentMethodOptions() {
        let params = STPConfirmationTokenParams()
        let paymentMethodOptions = STPConfirmPaymentMethodOptions()

        // Add card options to make the encoding more meaningful
        let cardOptions = STPConfirmCardOptions()
        paymentMethodOptions.cardOptions = cardOptions
        params.paymentMethodOptions = paymentMethodOptions

        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNotNil(encoded["payment_method_options"])
    }

    func testFormEncodingWithoutPaymentMethodOptions() {
        let params = STPConfirmationTokenParams()

        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNil(encoded["payment_method_options"])
    }

    func testCompleteFormEncoding() {
        let params = STPConfirmationTokenParams()
        params.paymentMethod = "pm_test_123"
        params.returnURL = "https://example.com/return"
        params.setupFutureUsage = STPPaymentIntentSetupFutureUsage.onSession

        let mandateData = STPMandateDataParams.makeWithInferredValues()
        params.mandateData = mandateData

        let paymentMethodOptions = STPConfirmPaymentMethodOptions()
        let cardOptions = STPConfirmCardOptions()
        paymentMethodOptions.cardOptions = cardOptions
        params.paymentMethodOptions = paymentMethodOptions

        let encoded = STPFormEncoder.dictionary(forObject: params)

        XCTAssertEqual(encoded["payment_method"] as? String, "pm_test_123")
        XCTAssertEqual(encoded["return_url"] as? String, "https://example.com/return")
        XCTAssertEqual(encoded["setup_future_usage"] as? String, "on_session")
        XCTAssertNotNil(encoded["mandate_data"])
        XCTAssertNotNil(encoded["payment_method_options"])

        // Test with setAsDefaultPM
        params.setAsDefaultPM = NSNumber(value: true)
        let encodedWithDefault = STPFormEncoder.dictionary(forObject: params)
        XCTAssertEqual(encodedWithDefault["set_as_default_payment_method"] as? NSNumber, NSNumber(value: true))
        XCTAssertNotNil(encodedWithDefault["payment_method_options"])
    }

    // MARK: - Real-World Usage Pattern Tests

    func testCompleteObjectCreation() {
        let paymentMethodData = STPPaymentMethodParams()
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

        // Add client attribution metadata
        let clientMetadata = STPClientAttributionMetadata()
        params.clientAttributionMetadata = clientMetadata

        // Verify all properties are set
        XCTAssertNotNil(params.paymentMethodData)
        XCTAssertEqual(params.returnURL, "https://example.com/return")
        XCTAssertNotNil(params.mandateData)
        XCTAssertNotNil(params.shipping)
        XCTAssertEqual(params.setupFutureUsage, STPPaymentIntentSetupFutureUsage.offSession)
        XCTAssertNotNil(params.clientAttributionMetadata)

        // Add setAsDefaultPM
        params.setAsDefaultPM = NSNumber(value: true)
        XCTAssertNotNil(params.setAsDefaultPM)

        // Verify form encoding works
        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNotNil(encoded["payment_method_data"])
        XCTAssertNotNil(encoded["mandate_data"])
        XCTAssertNotNil(encoded["shipping"])
        XCTAssertEqual(encoded["setup_future_usage"] as? String, "off_session")
        XCTAssertEqual(encoded["set_as_default_payment_method"] as? NSNumber, NSNumber(value: true))
        XCTAssertNotNil(encoded["client_attribution_metadata"])
    }

    func testFormEncodingWithClientContext() {
        let params = STPConfirmationTokenParams()
        let clientContext = STPConfirmationTokenClientContext()
        clientContext.mode = "payment"
        clientContext.currency = "usd"
        clientContext.setupFutureUsage = "off_session"
        clientContext.captureMethod = "automatic"
        clientContext.paymentMethodTypes = ["card", "apple_pay"]
        clientContext.onBehalfOf = "acct_123"
        clientContext.paymentMethodConfiguration = "pmc_123"
        clientContext.customer = "cus_123"

        params.clientContext = clientContext

        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNotNil(encoded["client_context"])

        let clientContextDict = encoded["client_context"] as? [String: Any]
        XCTAssertNotNil(clientContextDict)
        XCTAssertEqual(clientContextDict?["mode"] as? String, "payment")
        XCTAssertEqual(clientContextDict?["currency"] as? String, "usd")
        XCTAssertEqual(clientContextDict?["setup_future_usage"] as? String, "off_session")
        XCTAssertEqual(clientContextDict?["capture_method"] as? String, "automatic")
        XCTAssertEqual(clientContextDict?["payment_method_types"] as? [String], ["card", "apple_pay"])
        XCTAssertEqual(clientContextDict?["on_behalf_of"] as? String, "acct_123")
        XCTAssertEqual(clientContextDict?["payment_method_configuration"] as? String, "pmc_123")
        XCTAssertEqual(clientContextDict?["customer"] as? String, "cus_123")
    }

    func testFormEncodingWithoutClientContext() {
        let params = STPConfirmationTokenParams()

        let encoded = STPFormEncoder.dictionary(forObject: params)
        XCTAssertNil(encoded["client_context"])
    }

    func testPropertyMutationAfterInit() {
        let params = STPConfirmationTokenParams()

        // Start with basic setup
        params.paymentMethod = "pm_initial"
        XCTAssertEqual(params.paymentMethod, "pm_initial")

        // Change to payment method data
        params.paymentMethod = nil
        params.paymentMethodData = STPPaymentMethodParams()
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
        XCTAssertNil(encoded["client_attribution_metadata"])
        XCTAssertNil(encoded["client_context"])

        // setup_future_usage should not be present when .none
        XCTAssertNil(encoded["setup_future_usage"])

        // set_as_default_payment_method should not be present when nil
        XCTAssertNil(encoded["set_as_default_payment_method"])
    }
}
