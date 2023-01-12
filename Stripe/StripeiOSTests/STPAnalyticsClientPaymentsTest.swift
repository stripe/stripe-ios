//
//  STPAnalyticsClientPaymentsTest.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 5/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeApplePay
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet

class STPAnalyticsClientPaymentsTest: XCTestCase {
    private var client: STPAnalyticsClient!

    override func setUp() {
        super.setUp()
        client = STPAnalyticsClient()
    }

    func testAdditionalInfo() {
        XCTAssertEqual(client.additionalInfo(), [])

        // Add some info
        client.addAdditionalInfo("hello")
        client.addAdditionalInfo("i'm additional info")
        client.addAdditionalInfo("how are you?")

        XCTAssertEqual(client.additionalInfo(), ["hello", "how are you?", "i'm additional info"])

        // Clear it
        client.clearAdditionalInfo()
        XCTAssertEqual(client.additionalInfo(), [])
    }

    func testPayloadFromAnalytic() throws {
        client.addAdditionalInfo("test_additional_info")

        let mockAnalytic = MockAnalytic()
        let payload = client.payload(from: mockAnalytic)

        XCTAssertEqual(payload.count, 13)

        // Verify event name is included
        XCTAssertEqual(payload["event"] as? String, mockAnalytic.event.rawValue)

        // Verify additionalInfo is included
        XCTAssertEqual(payload["additional_info"] as? [String], ["test_additional_info"])

        // Verify all the analytic params are in the payload
        XCTAssertEqual(payload["test_param1"] as? Int, 1)
        XCTAssertEqual(payload["test_param2"] as? String, "two")

        // Verify productUsage is included
        XCTAssertNotNil(payload["product_usage"])

        // Verify install method is Xcode
        XCTAssertEqual(payload["install"] as? String, "X")
    }

    func testPayloadFromErrorAnalytic() throws {
        client.addAdditionalInfo("test_additional_info")

        let mockAnalytic = MockErrorAnalytic()
        let payload = client.payload(from: mockAnalytic)

        // Verify event name is included
        XCTAssertEqual(payload["event"] as? String, mockAnalytic.event.rawValue)

        // Verify additionalInfo is included
        XCTAssertEqual(payload["additional_info"] as? [String], ["test_additional_info"])

        // Verify all the analytic params are in the payload
        XCTAssertEqual(payload["test_param1"] as? Int, 1)
        XCTAssertEqual(payload["test_param2"] as? String, "two")

        // Verify productUsage is included
        XCTAssertNotNil(payload["product_usage"])

        // Verify error_dictionary is included
        let errorDict = try XCTUnwrap(payload["error_dictionary"] as? [String: Any])
        XCTAssertTrue(
            NSDictionary(dictionary: errorDict).isEqual(
                to: mockAnalytic.error.serializeForLogging()
            )
        )
    }

    func testTokenTypeFromParameters() {
        let card = STPFixtures.cardParams()
        let cardDict = buildTokenParams(card)
        XCTAssertEqual(STPAnalyticsClient.tokenType(fromParameters: cardDict), "card")

        let account = STPFixtures.accountParams()
        let accountDict = buildTokenParams(account)
        XCTAssertEqual(STPAnalyticsClient.tokenType(fromParameters: accountDict), "account")

        let bank = STPFixtures.bankAccountParams()
        let bankDict = buildTokenParams(bank)
        XCTAssertEqual(STPAnalyticsClient.tokenType(fromParameters: bankDict), "bank_account")

        let applePay = STPFixtures.applePayPayment()
        let applePayDict = addTelemetry(applePay.stp_tokenParameters(apiClient: .shared))
        XCTAssertEqual(STPAnalyticsClient.tokenType(fromParameters: applePayDict), "apple_pay")
    }

    // MARK: - Tests various classes report usage

    func testCardTextFieldAddsUsage() {
        _ = STPPaymentCardTextField()
        XCTAssertTrue(
            STPAnalyticsClient.sharedClient.productUsage.contains("STPPaymentCardTextField")
        )
    }

    func testPaymentContextAddsUsage() {
        let keyManager = STPEphemeralKeyManager(
            keyProvider: MockKeyProvider(),
            apiVersion: "1",
            performsEagerFetching: false
        )
        let apiClient = STPAPIClient()
        let customerContext = STPCustomerContext.init(keyManager: keyManager, apiClient: apiClient)
        _ = STPPaymentContext(customerContext: customerContext)
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.contains("STPCustomerContext"))
    }

    func testApplePayContextAddsUsage() {
        _ = STPApplePayContext(paymentRequest: STPFixtures.applePayRequest(), delegate: nil)
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.contains("STPApplePayContext"))
    }

    func testCustomerContextAddsUsage() {
        let keyManager = STPEphemeralKeyManager(
            keyProvider: MockKeyProvider(),
            apiVersion: "1",
            performsEagerFetching: false
        )
        let apiClient = STPAPIClient()
        _ = STPCustomerContext(keyManager: keyManager, apiClient: apiClient)
        XCTAssertTrue(STPAnalyticsClient.sharedClient.productUsage.contains("STPCustomerContext"))
    }

    func testAddCardVCAddsUsage() {
        _ = STPAddCardViewController()
        XCTAssertTrue(
            STPAnalyticsClient.sharedClient.productUsage.contains("STPAddCardViewController")
        )
    }

    func testBankSelectionVCAddsUsage() {
        _ = STPBankSelectionViewController()
        XCTAssertTrue(
            STPAnalyticsClient.sharedClient.productUsage.contains("STPBankSelectionViewController")
        )
    }

    func testShippingVCAddsUsage() {
        let config = STPFixtures.paymentConfiguration()
        config.requiredShippingAddressFields = [STPContactField.postalAddress]
        _ = STPShippingAddressViewController(
            configuration: config,
            theme: .defaultTheme,
            currency: nil,
            shippingAddress: nil,
            selectedShippingMethod: nil,
            prefilledInformation: nil
        )
        XCTAssertTrue(
            STPAnalyticsClient.sharedClient.productUsage.contains(
                "STPShippingAddressViewController"
            )
        )
    }
}

// MARK: - Helpers

extension STPAnalyticsClientPaymentsTest {
    fileprivate func buildTokenParams<T: STPFormEncodable & NSObject>(_ object: T) -> [String: Any]
    {
        return addTelemetry(STPFormEncoder.dictionary(forObject: object))
    }

    fileprivate func addTelemetry(_ params: [String: Any]) -> [String: Any] {
        // STPAPIClient adds these before determining the token type,
        // so do the same in the test
        return STPTelemetryClient.shared.paramsByAddingTelemetryFields(toParams: params)
    }
}

// MARK: - Mock types

private struct MockAnalytic: Analytic {
    let event = STPAnalyticEvent.sourceCreation

    let params: [String: Any] = [
        "test_param1": 1,
        "test_param2": "two",
    ]
}

private struct MockErrorAnalytic: ErrorAnalytic {
    let event = STPAnalyticEvent.sourceCreation

    let params: [String: Any] = [
        "test_param1": 1,
        "test_param2": "two",
    ]

    let error: Error = NSError(domain: "domain", code: 100, userInfo: nil)
}

private struct MockAnalyticsClass1: STPAnalyticsProtocol {
    static let stp_analyticsIdentifier = "MockAnalyticsClass1"
}

private struct MockAnalyticsClass2: STPAnalyticsProtocol {
    static let stp_analyticsIdentifier = "MockAnalyticsClass2"
}

private class MockKeyProvider: NSObject, STPCustomerEphemeralKeyProvider {
    func createCustomerKey(
        withAPIVersion apiVersion: String,
        completion: @escaping STPJSONResponseCompletionBlock
    ) {
        guard apiVersion == "1" else { return }

        completion(nil, NSError.stp_genericConnectionError())
    }
}
