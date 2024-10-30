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
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: nil
        )
        XCTAssertEqual(additionalParameters, "")
    }

    func test_someAdditionalParameters_notInstantDebits_noLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "",
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: nil
        )
        XCTAssertEqual(additionalParameters, "")
    }

    func test_someAdditionalParameters_instantDebits_noLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: nil,
            prefillDetails: nil
        )
        XCTAssertEqual(additionalParameters, "&testmode=true&return_payment_method=true")
    }

    func test_additionalParameters_instantDebits_noLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "",
            isInstantDebits: true,
            linkMode: nil,
            prefillDetails: nil
        )
        XCTAssertEqual(additionalParameters, "&return_payment_method=true")
    }

    func test_additionalParameters_notInstantDebits_someLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "",
            isInstantDebits: false,
            linkMode: .passthrough,
            prefillDetails: nil
        )
        XCTAssertEqual(additionalParameters, "")
    }

    func test_someAdditionalParameters_instantDebits_passthroughLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: .passthrough,
            prefillDetails: nil
        )
        XCTAssertEqual(additionalParameters, "&testmode=true&return_payment_method=true&link_mode=PASSTHROUGH")
    }

    func test_additionalParameters_instantDebits_linkCardBrandLinkMode() {
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "",
            isInstantDebits: true,
            linkMode: .linkCardBrand,
            prefillDetails: nil
        )
        XCTAssertEqual(additionalParameters, "&return_payment_method=true&link_mode=LINK_CARD_BRAND")
    }

    func test_additionalParameters_emptyPrefillDetails() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: nil,
            formattedPhoneNumber: nil,
            unformattedPhoneNumber: nil,
            countryCode: nil
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: prefillDetails
        )
        XCTAssertEqual(additionalParameters, "")
    }

    func test_additionalParameters_prefilledEmail() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: "test@example.com",
            formattedPhoneNumber: nil,
            unformattedPhoneNumber: nil,
            countryCode: nil
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: prefillDetails
        )
        XCTAssertEqual(additionalParameters, "&email=test@example.com")
    }

    func test_additionalParameters_fullPrefillDetails() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: "test@example.com",
            formattedPhoneNumber: "+1 (123) 456-7890",
            unformattedPhoneNumber: "1234567890",
            countryCode: "US"
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil,
            prefillDetails: prefillDetails
        )
        XCTAssertEqual(additionalParameters, "&email=test@example.com&linkMobilePhone=1234567890&linkMobilePhoneCountry=US")
    }

    func test_additionalParameters_fullPrefillDetails_instantDebits_passthroughLinkMode() {
        let prefillDetails = ElementsSessionContext.PrefillDetails(
            email: "test@example.com",
            formattedPhoneNumber: "+1 (123) 456-7890",
            unformattedPhoneNumber: "1234567890",
            countryCode: "US"
        )
        let additionalParameters = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: .passthrough,
            prefillDetails: prefillDetails
        )
        XCTAssertEqual(additionalParameters, "&testmode=true&return_payment_method=true&link_mode=PASSTHROUGH&email=test@example.com&linkMobilePhone=1234567890&linkMobilePhoneCountry=US")
    }
}
