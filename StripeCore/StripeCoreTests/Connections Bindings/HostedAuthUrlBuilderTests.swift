//
//  HostedAuthUrlBuilderTests.swift
//  StripeCore
//
//  Created by Mat Schmid on 2025-03-27.
//

import Foundation
@testable @_spi(STP) import StripeCore
import XCTest

class HostedAuthUrlBuilderTests: XCTestCase {
    let baseUrl = URL(string: "https://auth.stripe.com/link-accounts")!

    // MARK: - Basic URL Tests

    func testBuildWithMinimalParameters() {
        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: false,
            hasExistingAccountholderToken: false,
            elementsSessionContext: nil
        )

        XCTAssertTrue(result.absoluteString.contains("launched_by=ios_sdk"))
        XCTAssertFalse(result.absoluteString.contains("return_payment_method=true"))
    }

    func testAdditionalQueryParameters() {
        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: false,
            hasExistingAccountholderToken: false,
            elementsSessionContext: nil,
            additionalQueryParameters: "custom=value&another=param"
        )

        XCTAssertTrue(result.absoluteString.contains("custom=value"))
        XCTAssertTrue(result.absoluteString.contains("another=param"))
        XCTAssertTrue(result.absoluteString.contains("launched_by=ios_sdk"))
    }

    func testEmptyAdditionalQueryParametersAreNotAdded() {
        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: false,
            hasExistingAccountholderToken: false,
            elementsSessionContext: nil,
            additionalQueryParameters: ""
        )

        XCTAssertFalse(result.absoluteString.contains("&&&"))
        XCTAssertTrue(result.absoluteString.contains("launched_by=ios_sdk"))
    }

    // MARK: - Instant Debits Tests

    func testInstantDebitsParametersNotAddedWhenHasExistingAccountholderToken() {
        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: true,
            hasExistingAccountholderToken: true,
            elementsSessionContext: nil
        )

        XCTAssertFalse(result.absoluteString.contains("return_payment_method=true"))
        XCTAssertFalse(result.absoluteString.contains("expand_payment_method=true"))
        XCTAssertTrue(result.absoluteString.contains("launched_by=ios_sdk"))
    }

    func testInstantDebitsBasicParameters() {
        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: true,
            hasExistingAccountholderToken: false,
            elementsSessionContext: nil
        )

        XCTAssertTrue(result.absoluteString.contains("return_payment_method=true"))
        XCTAssertTrue(result.absoluteString.contains("expand_payment_method=true"))
        XCTAssertTrue(result.absoluteString.contains("launched_by=ios_sdk"))
    }

    func testInstantDebitsWithIncentiveEligibilitySession() {
        let intentId = ElementsSessionContext.IntentID.payment("pi_123456789")
        let context = ElementsSessionContext(
            intentId: intentId,
            eligibleForIncentive: true
        )

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: true,
            hasExistingAccountholderToken: false,
            elementsSessionContext: context
        )

        XCTAssertTrue(result.absoluteString.contains("instantDebitsIncentive=true"))
        XCTAssertTrue(result.absoluteString.contains("incentiveEligibilitySession=pi_123456789"))
    }

    func testInstantDebitsWithLinkMode() {
        let context = ElementsSessionContext(linkMode: .linkPaymentMethod)

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: true,
            hasExistingAccountholderToken: false,
            elementsSessionContext: context
        )

        XCTAssertTrue(result.absoluteString.contains("link_mode=LINK_PAYMENT_METHOD"))
    }

    // MARK: - Billing Details Tests

    func testInstantDebitsWithCompleteBillingDetails() {
        let address = ElementsSessionContext.BillingDetails.Address(
            city: "San Francisco",
            country: "US",
            line1: "123 Market St",
            line2: "Apt 456",
            postalCode: "94107",
            state: "CA"
        )

        let billingDetails = ElementsSessionContext.BillingDetails(
            name: "John Doe",
            email: "john@example.com",
            phone: "1234567890",
            address: address
        )

        let context = ElementsSessionContext(billingDetails: billingDetails)

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: true,
            hasExistingAccountholderToken: false,
            elementsSessionContext: context
        )

        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Bname%5D=John%20Doe"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Bemail%5D=john%40example.com"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Bphone%5D=1234567890"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Baddress%5D%5Bcity%5D=San%20Francisco"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Baddress%5D%5Bcountry%5D=US"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Baddress%5D%5Bline1%5D=123%20Market%20St"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Baddress%5D%5Bline2%5D=Apt%20456"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Baddress%5D%5Bpostal_code%5D=94107"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Baddress%5D%5Bstate%5D=CA"))
    }

    func testInstantDebitsWithPartialBillingDetails() {
        let address = ElementsSessionContext.BillingDetails.Address(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postalCode: "94107",
            state: nil
        )

        let billingDetails = ElementsSessionContext.BillingDetails(
            name: "John Doe",
            email: nil,
            phone: nil,
            address: address
        )

        let context = ElementsSessionContext(billingDetails: billingDetails)

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: true,
            hasExistingAccountholderToken: false,
            elementsSessionContext: context
        )

        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Bname%5D=John%20Doe"))
        XCTAssertTrue(result.absoluteString.contains("billingDetails%5Baddress%5D%5Bpostal_code%5D=94107"))
        XCTAssertFalse(result.absoluteString.contains("billingDetails%5Bemail%5D="))
        XCTAssertFalse(result.absoluteString.contains("billingDetails%5Baddress%5D%5Bcity%5D="))
    }

    // MARK: - Prefill Details Tests

    func testPrefillDetailsFromElementsSessionContext() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: "user@example.com",
            formattedPhoneNumber: "+1 (555) 123-4567",
            unformattedPhoneNumber: "5551234567",
            countryCode: "US"
        )

        let context = ElementsSessionContext(prefillDetails: prefillDetails)

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: false,
            hasExistingAccountholderToken: false,
            elementsSessionContext: context
        )

        XCTAssertTrue(result.absoluteString.contains("email=user%40example.com"))
        XCTAssertTrue(result.absoluteString.contains("linkMobilePhone=5551234567"))
        XCTAssertTrue(result.absoluteString.contains("linkMobilePhoneCountry=US"))
    }

    func testWebPrefillDetailsOverride() {
        let contextPrefill = ElementsSessionContext.PrefillDetails(
            email: "user@example.com",
            formattedPhoneNumber: "+1 (555) 123-4567",
            unformattedPhoneNumber: "5551234567",
            countryCode: "US"
        )

        let overridePrefill = WebPrefillDetails(
            email: "override@example.com",
            phone: "9998887777",
            countryCode: "CA"
        )

        let context = ElementsSessionContext(prefillDetails: contextPrefill)

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: false,
            hasExistingAccountholderToken: false,
            elementsSessionContext: context,
            prefillDetailsOverride: overridePrefill
        )

        XCTAssertTrue(result.absoluteString.contains("email=override%40example.com"))
        XCTAssertTrue(result.absoluteString.contains("linkMobilePhone=9998887777"))
        XCTAssertTrue(result.absoluteString.contains("linkMobilePhoneCountry=CA"))
        XCTAssertFalse(result.absoluteString.contains("user%40example.com"))
    }

    func testPartialPrefillDetails() {
        let prefillDetails = WebPrefillDetails(
            email: "user@example.com",
            phone: nil,
            countryCode: nil
        )

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: false,
            hasExistingAccountholderToken: false,
            elementsSessionContext: nil,
            prefillDetailsOverride: prefillDetails
        )

        XCTAssertTrue(result.absoluteString.contains("email=user%40example.com"))
        XCTAssertFalse(result.absoluteString.contains("linkMobilePhone="))
        XCTAssertFalse(result.absoluteString.contains("linkMobilePhoneCountry="))
    }

    // MARK: - URL Edge Cases

    func testBaseUrlWithTrailingAmpersand() {
        let baseUrlWithAmpersand = URL(string: "https://auth.stripe.com/link-accounts?param=value&")!

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrlWithAmpersand,
            isInstantDebits: false,
            hasExistingAccountholderToken: false,
            elementsSessionContext: nil
        )

        XCTAssertFalse(result.absoluteString.contains("&&"))
        XCTAssertTrue(result.absoluteString.contains("launched_by=ios_sdk"))
    }

    func testURLEncoding() {
        let prefillDetails = WebPrefillDetails(
            email: "user+test@example.com",  // Contains special characters
            phone: "555 123 4567",  // Contains spaces
            countryCode: "US"
        )

        let result = HostedAuthUrlBuilder.build(
            baseHostedAuthUrl: baseUrl,
            isInstantDebits: false,
            hasExistingAccountholderToken: false,
            elementsSessionContext: nil,
            prefillDetailsOverride: prefillDetails
        )

        // Check that special characters are properly URL encoded
        XCTAssertTrue(result.absoluteString.contains("email=user+test%40example.com"))
        XCTAssertTrue(result.absoluteString.contains("linkMobilePhone=555%20123%204567"))
    }
}
