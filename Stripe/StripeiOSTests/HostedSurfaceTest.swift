//
//  HostedSurfaceTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 12/20/23.
//

import Foundation
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class HostedSurfaceTest: XCTestCase {

    // Test the initializer
    func testHostedSurfaceInitializer() {
        let paymentSheetConfig = PaymentSheetFormFactoryConfig.paymentSheet(PaymentSheet.Configuration.init())

        let hostedSurfaceForPaymentSheet = HostedSurface(config: paymentSheetConfig)
        XCTAssertEqual(hostedSurfaceForPaymentSheet, .paymentSheet)

        let customerSheetConfig = PaymentSheetFormFactoryConfig.customerSheet(.init())

        let hostedSurfaceForCustomerSheet = HostedSurface(config: customerSheetConfig)
        XCTAssertEqual(hostedSurfaceForCustomerSheet, .customerSheet)
    }

    // Test analyticEvent function for every event in CardBrandChoiceEvents
    func testPaymentSheetAnalyticEvents() {
        let hostedSurface = HostedSurface.paymentSheet
        testAnalyticEvents(for: hostedSurface)
    }

    func testCustomerSheetAnalyticEvents() {
        let hostedSurface = HostedSurface.customerSheet
        testAnalyticEvents(for: hostedSurface)
    }

    private func testAnalyticEvents(for hostedSurface: HostedSurface) {
        let events: [HostedSurface.CardBrandChoiceEvents] = [
            .displayCardBrandDropdownIndicator,
            .openCardBrandDropdown,
            .closeCardBrandDropDown,
            .openCardBrandEditScreen,
            .updateCardBrand,
            .updateCardBrandFailed,
            .closeEditScreen,
        ]

        let expectedEventsPaymentSheet: [HostedSurface.CardBrandChoiceEvents: STPAnalyticEvent] = [
            .displayCardBrandDropdownIndicator: .paymentSheetDisplayCardBrandDropdownIndicator,
            .openCardBrandDropdown: .paymentSheetOpenCardBrandDropdown,
            .closeCardBrandDropDown: .paymentSheetCloseCardBrandDropDown,
            .openCardBrandEditScreen: .paymentSheetOpenCardBrandEditScreen,
            .updateCardBrand: .paymentSheetUpdateCardBrand,
            .updateCardBrandFailed: .paymentSheetUpdateCardBrandFailed,
            .closeEditScreen: .paymentSheetClosesEditScreen,
        ]

        let expectedEventsCustomerSheet: [HostedSurface.CardBrandChoiceEvents: STPAnalyticEvent] = [
            .displayCardBrandDropdownIndicator: .customerSheetDisplayCardBrandDropdownIndicator,
            .openCardBrandDropdown: .customerSheetOpenCardBrandDropdown,
            .closeCardBrandDropDown: .customerSheetCloseCardBrandDropDown,
            .openCardBrandEditScreen: .customerSheetOpenCardBrandEditScreen,
            .updateCardBrand: .customerSheetUpdateCardBrand,
            .updateCardBrandFailed: .customerSheetUpdateCardBrandFailed,
            .closeEditScreen: .customerSheetClosesEditScreen,
        ]

        for event in events {
            let analyticEvent = hostedSurface.analyticEvent(for: event)
            // assert that the event is the expected one
            switch hostedSurface {
            case .paymentSheet:
                XCTAssertEqual(analyticEvent, expectedEventsPaymentSheet[event])
            case .customerSheet:
                XCTAssertEqual(analyticEvent, expectedEventsCustomerSheet[event])
            }
        }
    }
}
