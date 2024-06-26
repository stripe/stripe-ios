//
//  IntentConfirmParamsTest.swift
//  StripePaymentSheetTests
//

import Foundation

@testable import StripePaymentSheet
import StripePaymentsTestUtils
import XCTest

class IntentConfirmParamsTest: XCTestCase {
    func testSetAllowRedisplay_legacy_settingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(for: .legacy, isSettingUp: true)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_pi_deselected_settingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_pi_selected_settingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, isSettingUp: true)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_hidden_settingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveEnabled_pi_deselected_settingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveEnabled, isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveEnabled_pi_selected_settingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveEnabled, isSettingUp: true)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_customerSession_settingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(for: .customerSheetWithCustomerSession, isSettingUp: true)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: Not setting up
    func testSetAllowRedisplay_legacy_notSettingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(for: .legacy, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_pi_deselected_notSettingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_pi_selected_notSettingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, isSettingUp: false)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_hidden_notSettingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        // This isn't a real use case. If payment_method_save == disabled, and checkbox is hidden, then settingUp should be true
        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveEnabled_pi_deselected_notSettingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveEnabled, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveEnabled_pi_selected_notSettingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveEnabled, isSettingUp: false)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_customerSession_notSettingUp() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        // This isn't a real use case. customerSheetWithCustomerSession is always setting up. Nonetheless, we should default to .always.
        intentConfirmParams.setAllowRedisplay(for: .customerSheetWithCustomerSession, isSettingUp: false)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
}
