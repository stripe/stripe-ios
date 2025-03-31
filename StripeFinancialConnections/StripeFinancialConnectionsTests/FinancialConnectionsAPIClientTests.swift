//
//  FinancialConnectionsAsyncAPIClientTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Mat Schmid on 2024-08-02.
//

import XCTest

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripeFinancialConnections

class FinancialConnectionsAsyncAPIClientTests: XCTestCase {
    private let mockApiClient = APIStubbedTestCase.stubbedAPIClient()

    func testConusmerPublishableKeyProvider() {
        let apiClient = FinancialConnectionsAsyncAPIClient(apiClient: mockApiClient)
        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true))

        let consumerPublishableKey = "consumerPublishableKey"
        apiClient.consumerPublishableKey = consumerPublishableKey
        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true))

        apiClient.isLinkWithStripe = true
        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true))

        let unverifiedConsumerSession = ConsumerSessionData(
            clientSecret: "clientSecret",
            emailAddress: "emailAddress",
            redactedFormattedPhoneNumber: "redactedFormattedPhoneNumber",
            verificationSessions: []
        )
        apiClient.consumerSession = unverifiedConsumerSession
        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true))

        let verifiedConsumerSession = ConsumerSessionData(
            clientSecret: "clientSecret",
            emailAddress: "emailAddress",
            redactedFormattedPhoneNumber: "redactedFormattedPhoneNumber",
            verificationSessions: [
                VerificationSession(
                    type: .sms,
                    state: .verified
                ),
            ]
        )
        apiClient.consumerSession = verifiedConsumerSession
        XCTAssertEqual(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: true), consumerPublishableKey)

        XCTAssertNil(apiClient.consumerPublishableKeyProvider(canUseConsumerKey: false))
    }

    func testEmptyBillingAddressEncodedAsParameters() throws {
        let billingAddress = BillingAddress()
        let encodedBillingAddress = try FinancialConnectionsAsyncAPIClient.encodeAsParameters(billingAddress)

        XCTAssertNil(encodedBillingAddress)
    }

    func testBillingAddressEncodedAsParameters() throws {
        let billingAddress = BillingAddress(
            name: "Bobby Tables",
            line1: "123 Fake St",
            line2: nil,
            city: "Utopia",
            state: "CA",
            postalCode: "90210",
            countryCode: "US"
        )
        let encodedBillingAddress = try FinancialConnectionsAsyncAPIClient.encodeAsParameters(billingAddress)

        XCTAssertEqual(encodedBillingAddress?["name"] as? String, "Bobby Tables")
        XCTAssertEqual(encodedBillingAddress?["line_1"] as? String, "123 Fake St")
        XCTAssertNil(encodedBillingAddress?["line_2"])
        XCTAssertEqual(encodedBillingAddress?["locality"] as? String, "Utopia")
        XCTAssertEqual(encodedBillingAddress?["administrative_area"] as? String, "CA")
        XCTAssertEqual(encodedBillingAddress?["postal_code"] as? String, "90210")
        XCTAssertEqual(encodedBillingAddress?["country_code"] as? String, "US")
    }

    func testBillingAddressEncodedAsParametersNonNilLine2() throws {
        let billingAddress = BillingAddress(
            name: "Bobby Tables",
            line1: "123 Fake St",
            line2: "",
            city: "Utopia",
            state: "CA",
            postalCode: "90210",
            countryCode: "US"
        )
        let encodedBillingAddress = try FinancialConnectionsAsyncAPIClient.encodeAsParameters(billingAddress)

        XCTAssertEqual(encodedBillingAddress?["name"] as? String, "Bobby Tables")
        XCTAssertEqual(encodedBillingAddress?["line_1"] as? String, "123 Fake St")
        XCTAssertNil(encodedBillingAddress?["line_2"])
        XCTAssertEqual(encodedBillingAddress?["locality"] as? String, "Utopia")
        XCTAssertEqual(encodedBillingAddress?["administrative_area"] as? String, "CA")
        XCTAssertEqual(encodedBillingAddress?["postal_code"] as? String, "90210")
        XCTAssertEqual(encodedBillingAddress?["country_code"] as? String, "US")
    }

    func testApplyAttestationParameters() async {
        // Mark API client as testmode to use a mock assertion
        mockApiClient.publishableKey = "pk_test"

        let baseParameters: [String: Any] = [
            "base_parameter": true,
        ]
        let apiClient = FinancialConnectionsAsyncAPIClient(apiClient: mockApiClient)
        let updatedParameters = await apiClient.assertAndApplyAttestationParameters(
            to: baseParameters,
            api: .linkSignUp,
            pane: .consent
        )

        XCTAssertNotNil(updatedParameters["base_parameter"])
        XCTAssertNotNil(updatedParameters["app_id"])
        XCTAssertNotNil(updatedParameters["key_id"])
        XCTAssertNotNil(updatedParameters["device_id"])
        XCTAssertNotNil(updatedParameters["ios_assertion_object"])
    }
}
