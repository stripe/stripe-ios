//
//  PollingViewTests.swift
//  StripePaymentSheetTests
//
//  Created by Fionn Barrett on 08/08/2023.
//

import Foundation

@_spi(InternalOnlyAPI) @testable import StripeCore
@_spi(InternalOnlyAPI) @testable import StripePayments
@_spi(InternalOnlyAPI) @testable import StripePaymentSheet

import XCTest

class PollingViewTests: XCTestCase {

    func testPollingViewModelBLIK() {
        let pollingViewModel = PollingViewModel(paymentMethodType: .blik)
        let deadlineInterval = pollingViewModel.deadline.timeIntervalSinceNow
        XCTAssertTrue(deadlineInterval > 60 - 0.5 && deadlineInterval <= 60, "The deadline is not within the specified range")
        XCTAssertEqual(pollingViewModel.CTA, .Localized.blik_confirm_payment)
    }

    func testPollingViewModelMBWay() {
        let pollingViewModel = PollingViewModel(paymentMethodType: .mbWay)

        XCTAssertEqual(pollingViewModel.CTA, .Localized.mb_way_confirm_payment)
        XCTAssertEqual(pollingViewModel.retryInterval, 1)
        XCTAssertEqual(pollingViewModel.deadline.timeIntervalSinceNow, 60 * 4, accuracy: 0.5)
    }

    func testPollingViewModelBizum() {
        let pollingViewModel = PollingViewModel(paymentMethodType: .bizum)

        XCTAssertEqual(pollingViewModel.CTA, .Localized.bizum_confirm_payment)
        XCTAssertEqual(pollingViewModel.retryInterval, 1)
        XCTAssertEqual(pollingViewModel.deadline.timeIntervalSinceNow, 70 * 60, accuracy: 0.5)
    }

    func testPollingViewModelPix() {
        let pollingViewModel = PollingViewModel(paymentMethodType: .pix)

        XCTAssertEqual(pollingViewModel.CTA, .Localized.pix_confirm_payment)
        XCTAssertFalse(pollingViewModel.showsCountdown)
        XCTAssertEqual(pollingViewModel.retryInterval, 2)
        XCTAssertEqual(pollingViewModel.deadline.timeIntervalSinceNow, 24 * 60 * 60, accuracy: 0.5)
    }

    func testPollingViewModelFromConfirmationMetadata() {
        // Given Pix's polling screen from the confirmation metadata
        let screen = ConfirmationMetadata.NextAction.PollingScreen(seconds: 90, intervalSeconds: 2, showsCountdown: false, deadlineField: "expires_at", instructions: .pix)

        // When the view model is made from it
        let pollingViewModel = PollingViewModel(screen: screen)

        // Then it shows and polls as configured
        XCTAssertEqual(pollingViewModel.CTA, .Localized.pix_confirm_payment)
        XCTAssertFalse(pollingViewModel.showsCountdown)
        XCTAssertEqual(pollingViewModel.retryInterval, 2)
        XCTAssertEqual(pollingViewModel.deadline.timeIntervalSinceNow, 90, accuracy: 0.5)
    }

    func testPollingViewModelMatchesConfirmationMetadataForEveryPollingType() {
        for type in PollingViewModel.supportedPaymentMethods {
            let native = PollingViewModel(paymentMethodType: type)
            let screen = ConfirmationMetadata.native(for: type)!.nextActions.values.compactMap { nextAction -> ConfirmationMetadata.NextAction.PollingScreen? in
                guard case .pollingScreen(let screen, _) = nextAction.presenter else { return nil }
                return screen
            }.first!
            let fromMetadata = PollingViewModel(screen: screen)
            XCTAssertEqual(native.CTA, fromMetadata.CTA, type.identifier)
            XCTAssertEqual(native.showsCountdown, fromMetadata.showsCountdown, type.identifier)
            XCTAssertEqual(native.retryInterval, fromMetadata.retryInterval, type.identifier)
            XCTAssertEqual(native.deadline.timeIntervalSince(fromMetadata.deadline), 0, accuracy: 0.5, type.identifier)
        }
    }
}
