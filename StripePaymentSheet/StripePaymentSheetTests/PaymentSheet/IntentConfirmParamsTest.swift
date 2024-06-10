//
//  IntentConfirmParamsTest.swift
//  StripePaymentSheetTests
//

import Foundation

@testable import StripePaymentSheet
import StripePaymentsTestUtils
import XCTest

class IntentConfirmParamsTest: XCTestCase {
    func testSetAllowRedisplay_legacy() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(for: .legacy)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_pi_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_pi_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveDisabled_hidden() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveEnabled_pi_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveEnabled)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_saveEnabled_pi_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: .paymentSheetWithCustomerSessionPaymentMethodSaveEnabled)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_customerSession() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        intentConfirmParams.setAllowRedisplay(for: .customerSheetWithCustomerSession)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
}
