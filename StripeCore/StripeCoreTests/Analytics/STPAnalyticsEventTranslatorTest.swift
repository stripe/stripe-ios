//
//  STPAnalyticsEventTranslatorTest.swift
//  StripeCoreTests
//

import Foundation
import XCTest

@testable @_spi(STP) @_spi(MobilePaymentElementAnalyticEventBeta) import StripeCore

class STPAnalyticsTranslatedEventTest: XCTestCase {
    let payloadWithLPM: [String: Any] = ["selected_lpm": "card"]
    let payloadWithoutLPM: [String: Any] = ["test_data": "data"]

    func testSheetPresentation() {
        _testTranslationMapping(event: .mcShowCustomNewPM, payload: payloadWithoutLPM, translatedEventName: .presentedSheet)
        _testTranslationMapping(event: .mcShowCompleteNewPM, payload: payloadWithoutLPM, translatedEventName: .presentedSheet)
        _testTranslationMapping(event: .mcShowCustomSavedPM, payload: payloadWithoutLPM, translatedEventName: .presentedSheet)
        _testTranslationMapping(event: .mcShowCompleteSavedPM, payload: payloadWithoutLPM, translatedEventName: .presentedSheet)
    }
    func testTapPaymentMethodType() {
        _testTranslationMapping(event: .paymentSheetCarouselPaymentMethodTapped, payload: payloadWithLPM,
                                translatedEventName: .selectedPaymentMethodType(.init(paymentMethodType: "card")))
    }
    func testFormInteractions() {
        _testTranslationMapping(event: .paymentSheetFormShown, payload: payloadWithLPM,
                                translatedEventName: .displayedPaymentMethodForm(.init(paymentMethodType: "card")))
        _testTranslationMapping(event: .paymentSheetFormInteracted, payload: payloadWithLPM,
                                translatedEventName: .startedInteractionWithPaymentMethodForm(.init(paymentMethodType: "card")))
        _testTranslationMapping(event: .paymentSheetFormCompleted, payload: payloadWithLPM,
                                translatedEventName: .completedPaymentMethodForm(.init(paymentMethodType: "card")))
        _testTranslationMapping(event: .paymentSheetConfirmButtonTapped, payload: payloadWithLPM,
                                translatedEventName: .tappedConfirmButton(.init(paymentMethodType: "card")))
    }
    func testSavedPaymentMethods() {
        _testTranslationMapping(event: .mcOptionSelectCustomSavedPM, payload: payloadWithLPM,
                                translatedEventName: .selectedSavedPaymentMethod(.init(paymentMethodType: "card")))
        _testTranslationMapping(event: .mcOptionSelectCompleteSavedPM, payload: payloadWithLPM,
                                translatedEventName: .selectedSavedPaymentMethod(.init(paymentMethodType: "card")))
        _testTranslationMapping(event: .mcOptionRemoveCustomSavedPM, payload: payloadWithLPM,
                                translatedEventName: .removedSavedPaymentMethod(.init(paymentMethodType: "card")))
        _testTranslationMapping(event: .mcOptionRemoveCompleteSavedPM, payload: payloadWithLPM,
                                translatedEventName: .removedSavedPaymentMethod(.init(paymentMethodType: "card")))
    }
    func testAnalyticNotTranslated() {
        let translator = STPAnalyticsEventTranslator()

        let result = translator.translate(.paymentSheetLoadStarted, payload: [:])

        XCTAssertNil(result)
    }
    func _testTranslationMapping(event: STPAnalyticEvent, payload: [String: Any], translatedEventName: MobilePaymentElementAnalyticEvent.Name) {
        let translator = STPAnalyticsEventTranslator()

        guard let result = translator.translate(event, payload: payload) else {
            XCTFail("There is no mapping for event: \"\(event)\". See: STPAnalyticsEventTranslator")
            return
        }

        XCTAssertEqual(result.notificationName, Notification.Name.mobilePaymentElement)
        XCTAssertEqual(result.event.name, translatedEventName)
    }
}
