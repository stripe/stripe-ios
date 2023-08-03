//
//  STPApplePayTest.swift
//  StripeiOS Tests
//
//  Created by David Estes on 9/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPApplePaySwiftTest: XCTestCase {
    func testAdditionalPaymentNetwork() {
        XCTAssertFalse(StripeAPI.supportedPKPaymentNetworks().contains(.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = [.JCB]
        XCTAssertTrue(StripeAPI.supportedPKPaymentNetworks().contains(.JCB))
        StripeAPI.additionalEnabledApplePayNetworks = []
    }

    // Tests stp_tokenParameters in StripePayments, not StripeApplePay
    func testStpTokenParameters() {
        let applePay = STPFixtures.applePayPayment()
        let applePayDict = applePay.stp_tokenParameters(apiClient: .shared)
        XCTAssertNotNil(applePayDict["pk_token"])
        XCTAssertEqual((applePayDict["card"] as! NSDictionary)["name"] as! String, "Test Testerson")
        XCTAssertEqual(applePayDict["pk_token_instrument_name"] as! String, "Master Charge")
    }
    
    func testPaymentRequestWithMerchantIdentifierCountryCurrency() {
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: "foo", country: "GB", currency: "GBP")
        XCTAssertEqual(paymentRequest?.merchantIdentifier, "foo")
        if #available(iOS 12, *) {
            let expectedNetworks = Set<AnyHashable>([
                .amex,
                .masterCard,
                .visa,
                .discover,
                .maestro
            ])
            XCTAssertEqual(Set<AnyHashable>(paymentRequest?.supportedNetworks), expectedNetworks)
        } else {
            let expectedNetworks = Set<AnyHashable>([
                .amex,
                .masterCard,
                .visa,
                .discover
            ])
            XCTAssertEqual(Set<AnyHashable>(paymentRequest?.supportedNetworks), expectedNetworks)
        }
        XCTAssertEqual(paymentRequest?.merchantCapabilities, PKMerchantCapability.capability3DS)
        XCTAssertEqual(paymentRequest?.countryCode, "GB")
        XCTAssertEqual(paymentRequest?.currencyCode, "GBP")
        XCTAssertEqual(paymentRequest?.requiredBillingContactFields, Set<AnyHashable>([.postalAddress]))
    }

    func testCanSubmitPaymentRequestReturnsYES() {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "foo"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"))
        ]

        XCTAssertTrue(StripeAPI.canSubmitPaymentRequest(request))
    }

    func testCanSubmitPaymentRequestIfTotalIsZero() {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "foo"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "0.00"))
        ]

        // "In versions of iOS prior to version 12.0 and watchOS prior to version 5.0, the amount of the grand total must be greater than zero."
        if #available(iOS 12, *) {
            XCTAssertTrue(StripeAPI.canSubmitPaymentRequest(request))
        } else {
            XCTAssertFalse(StripeAPI.canSubmitPaymentRequest(request))
        }
    }

    func testCanSubmitPaymentRequestReturnsNOIfMerchantIdentifierIsNil() {
        let request = PKPaymentRequest()
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"))
        ]

        XCTAssertFalse(StripeAPI.canSubmitPaymentRequest(request))
    }
}
