//
//  HostedSurfaceTest.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 12/20/23.
//

import Foundation
import XCTest
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripePaymentSheet

class HostedSurfaceTest: XCTestCase {

    // Test the initializer
    func testHostedSurfaceInitializer() {
        let paymentSheetConfig = PaymentSheetFormFactoryConfig.paymentElement(PaymentSheet.Configuration.init())

        let hostedSurfaceForPaymentSheet = HostedSurface(config: paymentSheetConfig)
        XCTAssertEqual(hostedSurfaceForPaymentSheet, .paymentSheet)

        let customerSheetConfig = PaymentSheetFormFactoryConfig.customerSheet(.init())

        let hostedSurfaceForCustomerSheet = HostedSurface(config: customerSheetConfig)
        XCTAssertEqual(hostedSurfaceForCustomerSheet, .customerSheet)
    }

    // Test analyticEvent function for every event in CardUpdateEvents
    func testPaymentSheetAnalyticEvents() {
        let hostedSurface = HostedSurface.paymentSheet
        testAnalyticEvents(for: hostedSurface)
    }

    func testCustomerSheetAnalyticEvents() {
        let hostedSurface = HostedSurface.customerSheet
        testAnalyticEvents(for: hostedSurface)
    }

    private func testAnalyticEvents(for hostedSurface: HostedSurface) {
        let events: [HostedSurface.CardUpdateEvents] = [
            .displayCardBrandDropdownIndicator,
            .cardBrandSelected,
            .openEditScreen,
            .updateCard,
            .updateCardFailed,
            .setDefaultPaymentMethod,
            .setDefaultPaymentMethodFailed,
            .closeEditScreen,
        ]

        let expectedEventsPaymentSheet: [HostedSurface.CardUpdateEvents: STPAnalyticEvent] = [
            .displayCardBrandDropdownIndicator: .paymentSheetDisplayCardBrandDropdownIndicator,
            .cardBrandSelected: .paymentSheetCardBrandSelected,
            .openEditScreen: .paymentSheetOpenEditScreen,
            .updateCard: .paymentSheetUpdateCard,
            .updateCardFailed: .paymentSheetUpdateCardFailed,
            .setDefaultPaymentMethod: .paymentSheetSetDefaultPaymentMethod,
            .setDefaultPaymentMethodFailed: .paymentSheetSetDefaultPaymentMethodFailed,
            .closeEditScreen: .paymentSheetClosesEditScreen,
        ]

        let expectedEventsCustomerSheet: [HostedSurface.CardUpdateEvents: STPAnalyticEvent] = [
            .displayCardBrandDropdownIndicator: .customerSheetDisplayCardBrandDropdownIndicator,
            .cardBrandSelected: .customerSheetCardBrandSelected,
            .openEditScreen: .customerSheetOpenEditScreen,
            .updateCard: .customerSheetUpdateCard,
            .updateCardFailed: .customerSheetUpdateCardFailed,
            .setDefaultPaymentMethod: .unexpectedCustomerSheetError,
            .setDefaultPaymentMethodFailed: .unexpectedCustomerSheetError,
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
