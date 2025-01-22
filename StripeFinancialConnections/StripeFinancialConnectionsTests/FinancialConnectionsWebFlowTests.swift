//
//  FinancialConnectionsWebFlowTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Mat Schmid on 2024-09-25.
//

@_spi(STP) import StripeCore
@testable import StripeFinancialConnections
import XCTest

final class FinancialConnectionsWebFlowTests: XCTestCase {
    func test_noAdditionalParameters_empty() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: nil,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertNil(additionalParameters)
    }

    func test_someAdditionalParameters_notInstantDebits_noLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: "",
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: nil,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertNil(additionalParameters)
    }

    func test_someAdditionalParameters_instantDebits_noLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: nil,
            prefillDetails: nil,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&testmode=true&return_payment_method=true&expand_payment_method=true")
    }

    func test_additionalParameters_instantDebits_noLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: "",
            isInstantDebits: true,
            linkMode: nil,
            prefillDetails: nil,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&return_payment_method=true&expand_payment_method=true")
    }

    func test_additionalParameters_notInstantDebits_someLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: "",
            isInstantDebits: false,
            linkMode: .passthrough,
            prefillDetails: nil,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertNil(additionalParameters)
    }

    func test_someAdditionalParameters_instantDebits_passthroughLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: .passthrough,
            prefillDetails: nil,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&testmode=true&return_payment_method=true&expand_payment_method=true&link_mode=PASSTHROUGH")
    }

    func test_additionalParameters_instantDebits_linkCardBrandLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: "",
            isInstantDebits: true,
            linkMode: .linkCardBrand,
            prefillDetails: nil,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&return_payment_method=true&expand_payment_method=true&link_mode=LINK_CARD_BRAND")
    }

    func test_additionalParameters_emptyPrefillDetails() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: nil,
            formattedPhoneNumber: nil,
            unformattedPhoneNumber: nil,
            countryCode: nil
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: prefillDetails,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertNil(additionalParameters)
    }

    func test_additionalParameters_prefilledEmail() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: "test@example.com",
            formattedPhoneNumber: nil,
            unformattedPhoneNumber: nil,
            countryCode: nil
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: prefillDetails,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&email=test%40example.com")
    }

    func test_additionalParameters_fullPrefillDetails() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: "test@example.com",
            formattedPhoneNumber: "+1 (123) 456-7890",
            unformattedPhoneNumber: "1234567890",
            countryCode: "US"
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: prefillDetails,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&email=test%40example.com&linkMobilePhone=1234567890&linkMobilePhoneCountry=US")
    }

    func test_additionalParameters_fullPrefillDetails_instantDebits_passthroughLinkMode() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: "test@example.com",
            formattedPhoneNumber: "+1 (123) 456-7890",
            unformattedPhoneNumber: "1234567890",
            countryCode: "US"
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: .passthrough,
            prefillDetails: prefillDetails,
            billingDetails: nil,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&testmode=true&return_payment_method=true&expand_payment_method=true&link_mode=PASSTHROUGH&email=test%40example.com&linkMobilePhone=1234567890&linkMobilePhoneCountry=US")
    }

    func test_additionalParameters_emptyBillingDetails() {
        let billingDetails = ElementsSessionContext.BillingDetails(
            name: nil,
            email: nil,
            phone: nil,
            address: nil
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: nil,
            billingDetails: billingDetails,
            incentiveEligibilitySession: nil
        )
        XCTAssertNil(additionalParameters)
    }

    func test_additionalParameters_billingDetails() {
        let billingDetails = ElementsSessionContext.BillingDetails(
            name: "Foo Bar",
            email: "foo@bar.com",
            phone: "+1 (123) 456-7890",
            address: ElementsSessionContext.BillingDetails.Address(
                city: "Toronto",
                country: "CA",
                line1: "123 Main St",
                line2: "",
                postalCode: "A0B 1C2",
                state: "ON"
            )
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: true,
            linkMode: nil,
            prefillDetails: nil,
            billingDetails: billingDetails,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&return_payment_method=true&expand_payment_method=true&billingDetails%5Bname%5D=Foo%20Bar&billingDetails%5Bemail%5D=foo%40bar.com&billingDetails%5Bphone%5D=+1%20(123)%20456-7890&billingDetails%5Baddress%5D%5Bcity%5D=Toronto&billingDetails%5Baddress%5D%5Bcountry%5D=CA&billingDetails%5Baddress%5D%5Bline1%5D=123%20Main%20St&billingDetails%5Baddress%5D%5Bpostal_code%5D=A0B%201C2&billingDetails%5Baddress%5D%5Bstate%5D=ON")
    }
    
    func test_additionalParameters_incentiveEligible() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: true,
            linkMode: nil,
            prefillDetails: nil,
            billingDetails: nil,
            incentiveEligibilitySession: .payment("pi_123")
        )
        XCTAssertEqual(
            additionalParameters,
            "&return_payment_method=true&expand_payment_method=true&instantDebitsIncentive=true&incentiveEligibilitySession=pi_123"
        )
    }

    func test_additionalParameters_fullBillingDetails_fullPrefillDetails_instantDebits_passthroughLinkMode() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: "test@example.com",
            formattedPhoneNumber: "+1 (123) 456-7890",
            unformattedPhoneNumber: "1234567890",
            countryCode: "US"
        )
        let billingDetails = ElementsSessionContext.BillingDetails(
            name: "Foo Bar",
            email: "foo@bar.com",
            phone: "+1 (123) 456-7890",
            address: ElementsSessionContext.BillingDetails.Address(
                city: "Toronto",
                country: "CA",
                line1: "123 Main St",
                line2: nil,
                postalCode: "A0B 1C2",
                state: "ON"
            )
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.buildEncodedUrlParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: .passthrough,
            prefillDetails: prefillDetails,
            billingDetails: billingDetails,
            incentiveEligibilitySession: nil
        )
        XCTAssertEqual(additionalParameters, "&testmode=true&return_payment_method=true&expand_payment_method=true&link_mode=PASSTHROUGH&billingDetails%5Bname%5D=Foo%20Bar&billingDetails%5Bemail%5D=foo%40bar.com&billingDetails%5Bphone%5D=+1%20(123)%20456-7890&billingDetails%5Baddress%5D%5Bcity%5D=Toronto&billingDetails%5Baddress%5D%5Bcountry%5D=CA&billingDetails%5Baddress%5D%5Bline1%5D=123%20Main%20St&billingDetails%5Baddress%5D%5Bpostal_code%5D=A0B%201C2&billingDetails%5Baddress%5D%5Bstate%5D=ON&email=test%40example.com&linkMobilePhone=1234567890&linkMobilePhoneCountry=US")
    }
}
