//
//  IntentConfirmParamsTest.swift
//  StripePaymentSheetTests
//

import Foundation

@testable import StripePaymentSheet
import StripePaymentsTestUtils
import XCTest

class IntentConfirmParamsTest: XCTestCase {
    // MARK: Legacy
    func testSetAllowRedisplay_legacySI() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.saveForFutureUseCheckboxState = .hidden
        intentConfirmParams.setAllowRedisplay(paymentMethodSave: nil, isSettingUp: true)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPI_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.saveForFutureUseCheckboxState = .selected
        intentConfirmParams.setAllowRedisplay(paymentMethodSave: nil, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPI_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.saveForFutureUseCheckboxState = .deselected
        intentConfirmParams.setAllowRedisplay(paymentMethodSave: nil, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSession, PI+SFU & SetupIntent
    func testSetAllowRedisplay_SI_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(paymentMethodSave: true, isSettingUp: true)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_SI_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(paymentMethodSave: true, isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testSetAllowRedisplay_SI_saveDisabled() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(paymentMethodSave: false, isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSession, Payment Intents
    func testSetAllowRedisplay_PI_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(paymentMethodSave: true, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(paymentMethodSave: true, isSettingUp: false)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveDisabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(paymentMethodSave: false, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveDisabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(paymentMethodSave: false, isSettingUp: false)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSheet
    func testSetAllowRedisplayForCustomerSheet_legacy() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplayForCustomerSheet(.legacy)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplayForCustomerSheet_customerSession() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplayForCustomerSheet(.customerSheetWithCustomerSession)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
}
