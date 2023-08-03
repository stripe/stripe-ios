//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPObjcBridgeTest.m
//  StripeiOS Tests
//
//  Created by David Estes on 9/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import PassKit
import Stripe
import XCTest

class StripeAPIBridgeTest: XCTestCase {
    func testStripeAPIBridge() {
        let testKey = "pk_test_123"
        StripeAPI.defaultPublishableKey = testKey
        XCTAssertEqual(StripeAPI.defaultPublishableKey, testKey)
        StripeAPI.defaultPublishableKey = nil

        StripeAPI.advancedFraudSignalsEnabled = false
        XCTAssertFalse(StripeAPI.advancedFraudSignalsEnabled)
        StripeAPI.advancedFraudSignalsEnabled = true


        StripeAPI.maxRetries = 2
        XCTAssertEqual(StripeAPI.maxRetries, 2)
        StripeAPI.maxRetries = 3

        // Check that this at least doesn't crash
        StripeAPI.handleStripeURLCallback(with: URL(string: "https://example.com"))

        StripeAPI.jcbPaymentNetworkSupported = true
        XCTAssertTrue(StripeAPI.jcbPaymentNetworkSupported)
        StripeAPI.jcbPaymentNetworkSupported = false

        StripeAPI.additionalEnabledApplePayNetworks = [.JCB]
        XCTAssertTrue(StripeAPI.additionalEnabledApplePayNetworks.contains(PKPaymentNetwork.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = []

        let request = StripeAPI.paymentRequest(withMerchantIdentifier: "test", country: "US", currency: "USD")
        request?.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"))
        ]
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wdeprecated"
        let request2 = StripeAPI.paymentRequest(withMerchantIdentifier: "test")
        request2?.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"))
        ]
        //#pragma clang diagnostic pop

        XCTAssertTrue(StripeAPI.canSubmitPaymentRequest(request))
        XCTAssertTrue(StripeAPI.canSubmitPaymentRequest(request2))

        XCTAssertTrue(StripeAPI.deviceSupportsApplePay())
    }

    func testSTPAPIClientBridgeKeys() {
        let testKey = "pk_test_123"
        StripeAPI.defaultPublishableKey = testKey
        XCTAssertEqual(testKey, StripeAPI.defaultPublishableKey)
        StripeAPI.defaultPublishableKey = nil
    }

    func testSTPAPIClientBridgeSettings() {
        let client = STPAPIClient(publishableKey: "pk_test_123")
        let config = STPPaymentConfiguration()
        client.configuration = config
        XCTAssertEqual(config, client.configuration)

        let stripeAccount = "acct_123"
        client.stripeAccount = stripeAccount
        XCTAssertEqual(stripeAccount, client.stripeAccount)

        let appInfo = STPAppInfo(name: "test", partnerId: "abc123", version: "1.0", url: "https://example.com")
        client.appInfo = appInfo
        XCTAssertEqual(appInfo.name, client.appInfo.name)

        XCTAssertNotNil(STPAPIClient.apiVersion)
    }
}
