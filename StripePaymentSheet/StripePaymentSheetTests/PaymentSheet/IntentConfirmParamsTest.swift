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

        let elementsSession = STPElementsSession.emptyElementsSession

        let intent = Intent.setupIntent(elementsSession: elementsSession, setupIntent: STPFixtures.setupIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden
        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPI_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        let elementsSession = STPElementsSession.emptyElementsSession

        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: STPFixtures.paymentIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .selected
        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPI_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        let elementsSession = STPElementsSession.emptyElementsSession

        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: STPFixtures.paymentIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected
        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_legacyPISFU_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))

        let elementsSession = STPElementsSession.emptyElementsSession
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["card"], setupFutureUsage: .offSession)
        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: paymentIntent)
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden
        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSession, SetupIntent
    func testSetAllowRedisplay_SI_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])

        let intent = Intent.setupIntent(elementsSession: elementsSession, setupIntent: STPFixtures.setupIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_SI_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let intent = Intent.setupIntent(elementsSession: elementsSession, setupIntent: STPFixtures.setupIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    func testSetAllowRedisplay_SI_saveDisabled() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "disabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let intent = Intent.setupIntent(elementsSession: elementsSession, setupIntent: STPFixtures.setupIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSession, PISFU
    func testSetAllowRedisplay_PISFU_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["card"], setupFutureUsage: .offSession)
        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: paymentIntent)
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PISFU_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["card"], setupFutureUsage: .offSession)
        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: paymentIntent)
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PISFU_saveDisabled() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "disabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: ["card"], setupFutureUsage: .offSession)
        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: paymentIntent)
        intentConfirmParams.saveForFutureUseCheckboxState = .hidden

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.limited, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }

    // MARK: CustomerSession, Payment Intents
    func testSetAllowRedisplay_PI_saveEnabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: STPFixtures.paymentIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveEnabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "enabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: STPFixtures.paymentIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.always, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveDisabled_deselected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "disabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: STPFixtures.paymentIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .deselected

        intentConfirmParams.setAllowRedisplay(for: intent)

        XCTAssertEqual(.unspecified, intentConfirmParams.paymentMethodParams.allowRedisplay)
    }
    func testSetAllowRedisplay_PI_saveDisabled_selected() {
        let intentConfirmParams = IntentConfirmParams(type: .stripe(.card))
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                                "payment_sheet": [
                                                                    "enabled": true,
                                                                    "features": ["payment_method_save": "disabled",
                                                                                 "payment_method_remove": "enabled",
                                                                                ],
                                                                ],
                                                                "customer_sheet": [
                                                                    "enabled": false
                                                                ],
                                                            ])
        let intent = Intent.paymentIntent(elementsSession: elementsSession, paymentIntent: STPFixtures.paymentIntent())
        intentConfirmParams.saveForFutureUseCheckboxState = .selected

        intentConfirmParams.setAllowRedisplay(for: intent)

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
