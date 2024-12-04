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
        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: nil, isSettingUp: true)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPI_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.saveForFutureUseCheckboxState = .selected
        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: nil, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPI_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.saveForFutureUseCheckboxState = .deselected
        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: nil, isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSession, PI+SFU & SetupIntent
    func testSetAllowRedisplay_SI_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: true)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_SI_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testInvalidState_SetAllowRedisplay_SI_saveEnabled_allowRedisplay() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        // The backend will prevent allowRedisplayValue from being set, when paymentMethodSave is set to enabled
        // but our code should be defensive enough to ensure allowRedisplayOverride does not override the value
        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: .always),
                                              isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testSetAllowRedisplay_SI_saveDisabled() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testSetAllowRedisplay_SI_saveDisabled_allowRedisplayOverrideAlways() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: .always),
                                              isSettingUp: true)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_SI_saveDisabled_allowRedisplayOverrideLimited() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: .limited),
                                              isSettingUp: true)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_SI_saveDisabled_allowRedisplayOverrideUnspecified() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: .unspecified),
                                              isSettingUp: true)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    // MARK: CustomerSession, Payment Intents
    func testSetAllowRedisplay_PI_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: true, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: false)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveDisabled_hidden() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: nil),
                                              isSettingUp: false)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testSetAllowRedisplay_PI_saveDisabled_hidden_doesNotOverride() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(mobilePaymentElementFeatures: .init(paymentMethodSave: false, paymentMethodRemove: false, paymentMethodRemoveLast: true, paymentMethodSaveAllowRedisplayOverride: .limited),
                                              isSettingUp: false)

        // Ensure that allowRedisplayOverride doesn't override: (hidden checkbox and not attached to customer)
        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
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
