//
//  STPAnalyticsEventTranslatorTest.swift
//  StripeCoreTests
//

import Foundation
import XCTest

@testable @_spi(STP) @_spi(MobilePaymentElementEventingBeta) import StripeCore

class STPAnalyticsTranslatedEventTest: XCTestCase {
    func testSheetPresentation() {
        _testTranslationMapping(event: .mcShowCustomNewPM, translatedEventName: "presentedSheet")
        _testTranslationMapping(event: .mcShowCompleteNewPM, translatedEventName: "presentedSheet")
        _testTranslationMapping(event: .mcShowCustomSavedPM, translatedEventName: "presentedSheet")
        _testTranslationMapping(event: .mcShowCompleteSavedPM, translatedEventName: "presentedSheet")
    }
    func testTapPaymentMethodType() {
        _testTranslationMapping(event: .paymentSheetCarouselPaymentMethodTapped, translatedEventName: "selectedPaymentMethodType")
    }
    func testFormInteractions() {
        _testTranslationMapping(event: .paymentSheetFormShown, translatedEventName: "displayedPaymentMethodForm")
        _testTranslationMapping(event: .paymentSheetFormInteracted, translatedEventName: "startedInteractionWithPaymentMethodForm")
        _testTranslationMapping(event: .paymentSheetFormCompleted, translatedEventName: "completedPaymentMethodForm")
        _testTranslationMapping(event: .paymentSheetConfirmButtonTapped, translatedEventName: "tappedConfirmButton")
    }
    func testSavedPaymentMethods() {
        _testTranslationMapping(event: .mcOptionSelectCustomSavedPM, translatedEventName: "selectedSavedPaymentMethod")
        _testTranslationMapping(event: .mcOptionSelectCompleteSavedPM, translatedEventName: "selectedSavedPaymentMethod")
        _testTranslationMapping(event: .mcOptionRemoveCustomSavedPM, translatedEventName: "removedSavedPaymentMethod")
        _testTranslationMapping(event: .mcOptionRemoveCompleteSavedPM, translatedEventName: "removedSavedPaymentMethod")
    }
    func testAnalyticNotTranslated() {
        let translator = STPAnalyticsEventTranslator()
        let analytic = GenericAnalytic(event: .paymentSheetLoadStarted, params: [:])

        let result = translator.translate(analytic, payload: [:])

        XCTAssertNil(result)
    }
    func _testTranslationMapping(event: STPAnalyticEvent, translatedEventName: String) {
        let translator = STPAnalyticsEventTranslator()
        let analytic = GenericAnalytic(event: event, params: [:])

        guard let result = translator.translate(analytic, payload: [:]) else {
            XCTFail("There is no mapping for event: \"\(event)\". See: STPAnalyticsEventTranslator")
            return
        }

        XCTAssertEqual(result.notificationName, Notification.Name.mobilePaymentElement)
        XCTAssertEqual(result.event.eventName, translatedEventName)
    }
}
