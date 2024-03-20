//
//  IntentTest.swift
//  StripePaymentSheetTests
//

import Foundation
@_spi(STP) import StripeCore
@testable import StripePaymentSheet
import XCTest

final class IntentTest: XCTestCase {

    func testSupportsLink_pkUser_linkPM() throws {
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(elementsSession: STPElementsSession.elementsSessionWithLinkEnabled(),
                                           intentConfig: intentConfig)
        XCTAssertTrue(intent.supportsLink(config.apiClient.publishableKeyIsUserKey))
    }
    func testSupportsLink_ukUser_linkPM() throws {
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "uk_123"
        let intent = Intent.deferredIntent(elementsSession: STPElementsSession.elementsSessionWithLinkEnabled(),
                                           intentConfig: intentConfig)
        XCTAssertFalse(intent.supportsLink(config.apiClient.publishableKeyIsUserKey))
    }
    func testSupportsLink_pkUser_NolinkPM() throws {
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(elementsSession: STPElementsSession.elementsSessionWithLinkDisabled(),
                                           intentConfig: intentConfig)
        XCTAssertFalse(intent.supportsLink(config.apiClient.publishableKeyIsUserKey))
    }
    func testSupportsLink_ukUser_NolinkPM() throws {
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "uk_123"
        let intent = Intent.deferredIntent(elementsSession: STPElementsSession.elementsSessionWithLinkDisabled(),
                                           intentConfig: intentConfig)
        XCTAssertFalse(intent.supportsLink(config.apiClient.publishableKeyIsUserKey))
    }
}

extension STPElementsSession {
    static func elementsSessionWithLinkEnabled() -> STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["card", "link"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "apple_pay_preference": "enabled",
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }
    static func elementsSessionWithLinkDisabled() -> STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["card"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "apple_pay_preference": "enabled",
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }
}
