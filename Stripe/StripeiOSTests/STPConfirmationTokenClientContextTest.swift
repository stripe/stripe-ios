//
//  STPConfirmationTokenClientContextTest.swift
//  StripePaymentsTests
//
//  Created by Nick Porter on 9/26/25.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
import XCTest

class STPConfirmationTokenClientContextTest: XCTestCase {

    // MARK: - STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertEqual(STPConfirmationTokenClientContext.rootObjectName(), "client_context")
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let clientContext = STPConfirmationTokenClientContext()
        let mapping = STPConfirmationTokenClientContext.propertyNamesToFormFieldNamesMapping()

        // Verify all property names don't contain colons
        for propertyName in mapping.keys {
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(clientContext.responds(to: NSSelectorFromString(propertyName)))
        }

        // Verify all form field names are non-empty
        for formFieldName in mapping.values {
            XCTAssert(formFieldName.count > 0)
        }

        // Verify all form field names are unique
        XCTAssertEqual(mapping.values.count, Set(mapping.values).count)

        // Verify expected mappings
        XCTAssertEqual(mapping["mode"], "mode")
        XCTAssertEqual(mapping["currency"], "currency")
        XCTAssertEqual(mapping["setupFutureUsage"], "setup_future_usage")
        XCTAssertEqual(mapping["captureMethod"], "capture_method")
        XCTAssertEqual(mapping["paymentMethodTypes"], "payment_method_types")
        XCTAssertEqual(mapping["onBehalfOf"], "on_behalf_of")
        XCTAssertEqual(mapping["paymentMethodConfiguration"], "payment_method_configuration")
        XCTAssertEqual(mapping["customer"], "customer")
        XCTAssertEqual(mapping["paymentMethodOptions"], "payment_method_options")
    }

    // MARK: - Form Encoding Tests

    func testFormEncodingWithAllProperties() {
        let clientContext = STPConfirmationTokenClientContext()
        clientContext.mode = "payment"
        clientContext.currency = "usd"
        clientContext.setupFutureUsage = "off_session"
        clientContext.captureMethod = "automatic_async"
        clientContext.paymentMethodTypes = ["card", "apple_pay"]
        clientContext.onBehalfOf = "acct_123456"
        clientContext.paymentMethodConfiguration = "pmc_123456"
        clientContext.customer = "cus_123456"

        let paymentMethodOptions = [
            "card": ["setup_future_usage": "off_session"],
            "us_bank_account": ["setup_future_usage": "on_session"],
        ]
        clientContext.paymentMethodOptions = paymentMethodOptions

        let encoded = STPFormEncoder.dictionary(forObject: clientContext)

        // Properties should be under "client_context" key due to rootObjectName()
        let clientContextDict = encoded["client_context"] as? [String: Any]
        XCTAssertNotNil(clientContextDict)
        XCTAssertEqual(clientContextDict?["mode"] as? String, "payment")
        XCTAssertEqual(clientContextDict?["currency"] as? String, "usd")
        XCTAssertEqual(clientContextDict?["setup_future_usage"] as? String, "off_session")
        XCTAssertEqual(clientContextDict?["capture_method"] as? String, "automatic_async")
        XCTAssertEqual(clientContextDict?["payment_method_types"] as? [String], ["card", "apple_pay"])
        XCTAssertEqual(clientContextDict?["on_behalf_of"] as? String, "acct_123456")
        XCTAssertEqual(clientContextDict?["payment_method_configuration"] as? String, "pmc_123456")
        XCTAssertEqual(clientContextDict?["customer"] as? String, "cus_123456")
        XCTAssertNotNil(clientContextDict?["payment_method_options"])
    }

    func testFormEncodingWithMinimalProperties() {
        let clientContext = STPConfirmationTokenClientContext()
        clientContext.mode = "setup"
        clientContext.currency = "eur"

        let encoded = STPFormEncoder.dictionary(forObject: clientContext)

        // Properties should be under "client_context" key due to rootObjectName()
        let clientContextDict = encoded["client_context"] as? [String: Any]
        XCTAssertNotNil(clientContextDict)
        XCTAssertEqual(clientContextDict?["mode"] as? String, "setup")
        XCTAssertEqual(clientContextDict?["currency"] as? String, "eur")
        XCTAssertNil(clientContextDict?["setup_future_usage"])
        XCTAssertNil(clientContextDict?["capture_method"])
        XCTAssertNil(clientContextDict?["payment_method_types"])
        XCTAssertNil(clientContextDict?["on_behalf_of"])
        XCTAssertNil(clientContextDict?["payment_method_configuration"])
        XCTAssertNil(clientContextDict?["customer"])
        XCTAssertNil(clientContextDict?["payment_method_options"])
    }

    func testFormEncodingWithNilProperties() {
        let clientContext = STPConfirmationTokenClientContext()

        let encoded = STPFormEncoder.dictionary(forObject: clientContext)

        // When all properties are nil, the client_context key should still be present but empty
        let clientContextDict = encoded["client_context"] as? [String: Any]
        XCTAssertNotNil(clientContextDict)
        XCTAssertNil(clientContextDict?["mode"])
        XCTAssertNil(clientContextDict?["currency"])
        XCTAssertNil(clientContextDict?["setup_future_usage"])
        XCTAssertNil(clientContextDict?["capture_method"])
        XCTAssertNil(clientContextDict?["payment_method_types"])
        XCTAssertNil(clientContextDict?["on_behalf_of"])
        XCTAssertNil(clientContextDict?["payment_method_configuration"])
        XCTAssertNil(clientContextDict?["customer"])
        XCTAssertNil(clientContextDict?["payment_method_options"])
    }

    // MARK: - Additional API Parameters Tests

    func testAdditionalAPIParameters() {
        let clientContext = STPConfirmationTokenClientContext()

        XCTAssertEqual(clientContext.additionalAPIParameters.count, 0)

        clientContext.additionalAPIParameters = ["custom_key": "custom_value"]
        XCTAssertEqual(clientContext.additionalAPIParameters["custom_key"] as? String, "custom_value")
    }

}
