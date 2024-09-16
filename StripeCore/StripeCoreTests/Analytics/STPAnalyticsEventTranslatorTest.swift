//
//  STPAnalyticsEventTranslatorTest.swift
//  StripeCoreTests
//

import Foundation
import XCTest

@testable @_spi(STP) @_spi(MobilePaymentElementEventingBeta) import StripeCore

class STPAnalyticsTranslatedEventTest: XCTestCase {
    func testSheetPresentation() {
        _testTranslationMapping(event: .mcShowCustomNewPM, translatedEventName: .presentedSheet)
        _testTranslationMapping(event: .mcShowCompleteNewPM, translatedEventName: .presentedSheet)
        _testTranslationMapping(event: .mcShowCustomSavedPM, translatedEventName: .presentedSheet)
        _testTranslationMapping(event: .mcShowCompleteSavedPM, translatedEventName: .presentedSheet)
    }
    func testTapPaymentMethodType() {
        _testTranslationMapping(event: .paymentSheetCarouselPaymentMethodTapped, translatedEventName: .selectedPaymentMethodType)
    }
    func testFormInteractions() {
        _testTranslationMapping(event: .paymentSheetFormShown, translatedEventName: .displayedPaymentMethodForm)
        _testTranslationMapping(event: .paymentSheetFormInteracted, translatedEventName: .startedInteractionWithPaymentMethodForm)
        _testTranslationMapping(event: .paymentSheetFormCompleted, translatedEventName: .completedPaymentMethodForm)
        _testTranslationMapping(event: .paymentSheetConfirmButtonTapped, translatedEventName: .tappedConfirmButton)
    }
    func testSavedPaymentMethods() {
        _testTranslationMapping(event: .mcOptionSelectCustomSavedPM, translatedEventName: .selectedSavedPaymentMethod)
        _testTranslationMapping(event: .mcOptionSelectCompleteSavedPM, translatedEventName: .selectedSavedPaymentMethod)
        _testTranslationMapping(event: .mcOptionRemoveCustomSavedPM, translatedEventName: .removedSavedPaymentMethod)
        _testTranslationMapping(event: .mcOptionRemoveCompleteSavedPM, translatedEventName: .removedSavedPaymentMethod)
    }
    func testAnalyticNotTranslated() {
        let translator = STPAnalyticsEventTranslator()

        let result = translator.translate(.paymentSheetLoadStarted, payload: [:])

        XCTAssertNil(result)
    }
    func _testTranslationMapping(event: STPAnalyticEvent, translatedEventName: MobilePaymentElementEvent.EventName) {
        let translator = STPAnalyticsEventTranslator()

        guard let result = translator.translate(event, payload: [:]) else {
            XCTFail("There is no mapping for event: \"\(event)\". See: STPAnalyticsEventTranslator")
            return
        }

        XCTAssertEqual(result.notificationName, Notification.Name.mobilePaymentElement)
        XCTAssertEqual(result.event.eventName, translatedEventName)
    }

    func testPayloadIsFiltered() {
        let translator = STPAnalyticsEventTranslator()
        let payload: [String: Any] = ["selected_lpm": "card",
                                      "otherData": "testValue",
        ]

        let result = translator.translate(.paymentSheetFormShown, payload: payload)

        XCTAssertEqual(result?.event.metadata as? [MobilePaymentElementEvent.MetadataKey: String], [.paymentMethodType: "card"])
    }

    func testTranslatesToEmptyPayload() {
        let translator = STPAnalyticsEventTranslator()
        let payload: [String: Any] = ["otherData": "testValue"]

        let result = translator.translate(.paymentSheetFormShown, payload: payload)
        XCTAssertEqual(result?.event.metadata as? [String: String], [:])
    }
}
