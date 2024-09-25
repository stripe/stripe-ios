//
//  FinancialConnectionsWebFlowTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Mat Schmid on 2024-09-25.
//

import XCTest
@_spi(STP) import StripeCore
@testable import StripeFinancialConnections

final class FinancialConnectionsWebFlowTests: XCTestCase {
    func test_noAdditionalParameters_empty() {
        let additionalParamers = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: nil,
            isInstantDebits: false,
            linkMode: nil
        )
        XCTAssertNil(additionalParamers)
    }

    func test_someAdditionalParameters_notInstantDebits_noLinkMode() {
        let additionalParamers = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "",
            isInstantDebits: false,
            linkMode: nil
        )
        XCTAssertEqual(additionalParamers, "")
    }

    func test_someAdditionalParameters_instantDebits_noLinkMode() {
        let additionalParamers = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: nil
        )
        XCTAssertEqual(additionalParamers, "&testmode=true&return_payment_method=true")
    }
    
    func test_additionalParameters_instantDebits_noLinkMode() {
        let additionalParamers = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "",
            isInstantDebits: true,
            linkMode: nil
        )
        XCTAssertEqual(additionalParamers, "&return_payment_method=true")
    }
    
    func test_additionalParameters_notInstantDebits_someLinkMode() {
        let additionalParamers = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "",
            isInstantDebits: false,
            linkMode: .passthrough
        )
        XCTAssertEqual(additionalParamers, "")
    }

    func test_someAdditionalParameters_instantDebits_passthroughLinkMode() {
        let additionalParamers = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "&testmode=true",
            isInstantDebits: true,
            linkMode: .passthrough
        )
        XCTAssertEqual(additionalParamers, "&testmode=true&return_payment_method=true&link_mode=PASSTHROUGH")
    }
    
    func test_additionalParameters_instantDebits_linkCardBrandLinkMode() {
        let additionalParamers = FinancialConnectionsWebFlowViewController.updateAdditionalParameters(
            startingAdditionalParameters: "",
            isInstantDebits: true,
            linkMode: .linkCardBrand
        )
        XCTAssertEqual(additionalParamers, "&return_payment_method=true&link_mode=LINK_CARD_BRAND")
    }
}
