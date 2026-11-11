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
        // Given Pix's polling screen from the confirmation metadata, with the server's strings
        let screen = ConfirmationMetadata.NextAction.PollingScreen(
            seconds: 90,
            intervalSeconds: 2,
            showsCountdown: false,
            deadlineField: "expires_at",
            title: "Zahlung bestätigen",
            instructions: "Mit Pix bezahlen.",
            cancelButton: "Abbrechen",
            failureTitle: "Zahlung fehlgeschlagen",
            failureInstructions: "Bitte zurückgehen."
        )

        // When the view model is made from it
        let pollingViewModel = PollingViewModel(screen: screen)

        // Then it shows the server's strings and polls as configured
        XCTAssertEqual(pollingViewModel.title, "Zahlung bestätigen")
        XCTAssertEqual(pollingViewModel.CTA, "Mit Pix bezahlen.")
        XCTAssertEqual(pollingViewModel.cancelButtonTitle, "Abbrechen")
        XCTAssertEqual(pollingViewModel.failureTitle, "Zahlung fehlgeschlagen")
        XCTAssertEqual(pollingViewModel.failureInstructions, "Bitte zurückgehen.")
        XCTAssertFalse(pollingViewModel.showsCountdown)
        XCTAssertEqual(pollingViewModel.retryInterval, 2)
        XCTAssertEqual(pollingViewModel.deadline.timeIntervalSinceNow, 90, accuracy: 0.5)
    }

    func testServerInstructionsFillInTheTimeRemaining() {
        // Given BLIK's screen with the server's ICU instructions
        let screen = ConfirmationMetadata.NextAction.PollingScreen(seconds: 60, intervalSeconds: 1, showsCountdown: true, deadlineField: nil, title: "Approve payment", instructions: "Confirm within {time_remaining}.", cancelButton: "Cancel", failureTitle: "Failed", failureInstructions: "Go back")

        // When the time left is filled in
        let instructions = PollingViewModel(screen: screen).instructions(timeRemaining: "0:59")

        // Then the ICU argument is replaced
        XCTAssertEqual(instructions, "Confirm within 0:59.")
    }

    func testPollingViewModelMatchesConfirmationMetadataForEveryPollingType() {
        for type in PollingViewModel.supportedPaymentMethods {
            let native = PollingViewModel(paymentMethodType: type)
            let screen = ConfirmationMetadata.native(for: type)!.nextActions.values.compactMap { nextAction -> ConfirmationMetadata.NextAction.PollingScreen? in
                guard case .pollingScreen(let screen, _) = nextAction.presenter else { return nil }
                return screen
            }.first!
            let fromMetadata = PollingViewModel(screen: screen)
            // The bundled table's English renders the same text as the SDK's English strings
            XCTAssertEqual(native.instructions(timeRemaining: "0:59"), fromMetadata.instructions(timeRemaining: "0:59"), type.identifier)
            XCTAssertEqual(native.title, fromMetadata.title, type.identifier)
            XCTAssertEqual(native.cancelButtonTitle, fromMetadata.cancelButtonTitle, type.identifier)
            XCTAssertEqual(native.failureTitle, fromMetadata.failureTitle, type.identifier)
            XCTAssertEqual(native.failureInstructions, fromMetadata.failureInstructions, type.identifier)
            XCTAssertEqual(native.showsCountdown, fromMetadata.showsCountdown, type.identifier)
            XCTAssertEqual(native.retryInterval, fromMetadata.retryInterval, type.identifier)
            XCTAssertEqual(native.deadline.timeIntervalSince(fromMetadata.deadline), 0, accuracy: 0.5, type.identifier)
        }
    }
}
