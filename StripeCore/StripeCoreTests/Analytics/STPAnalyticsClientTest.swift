//
//  STPAnalyticsClientTest.swift
//  StripeCoreTests
//
//  Created by Yuki Tokuhiro on 12/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable@_spi(STP) @_spi(MobilePaymentElementAnalyticEventBeta) import StripeCore

class STPAnalyticsClientTest: XCTestCase {

    func testIsUnitOrUITest_alwaysTrueInTest() {
        XCTAssertTrue(STPAnalyticsClient.isUnitOrUITest)
    }

    func testShouldRedactLiveKeyFromLog() {
        let analyticsClient = STPAnalyticsClient()

        let payload = analyticsClient.commonPayload(STPAPIClient(publishableKey: "sk_live_foo"))

        XCTAssertEqual("[REDACTED_LIVE_KEY]", payload["publishable_key"] as? String)
    }

    func testShouldRedactUserKeyFromLog() {
        let analyticsClient = STPAnalyticsClient()

        let payload = analyticsClient.commonPayload(STPAPIClient(publishableKey: "uk_live_foo"))

        XCTAssertEqual("[REDACTED_LIVE_KEY]", payload["publishable_key"] as? String)
    }

    func testShouldNotRedactLiveKeyFromLog() {
        let analyticsClient = STPAnalyticsClient()

        let payload = analyticsClient.commonPayload(STPAPIClient(publishableKey: "pk_foo"))

        XCTAssertEqual("pk_foo", payload["publishable_key"] as? String)
    }

    func testLogShouldRespectAPIClient() {
        STPAPIClient.shared.publishableKey = "pk_shared"
        let apiClient = STPAPIClient(publishableKey: "pk_not_shared")
        let analyticsClient = STPAnalyticsClient()
        // ...logging an arbitrary analytic and passing apiClient...
        analyticsClient.log(analytic: GenericAnalytic.init(event: .addressShow, params: [:]), apiClient: apiClient)
        // ...should use the passed in apiClient publishable key and not the shared apiClient
        let payload = analyticsClient._testLogHistory.first!
        XCTAssertEqual("pk_not_shared", payload["publishable_key"] as? String)
    }
    func testmcShowCustomNewPM() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .presentedSheet = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            e.fulfill()
        }
        _testLogEvent(event: .mcShowCustomNewPM,
                      params: [:], observer: observer)
        wait(for: [e], timeout: 1)
    }

    func testmcShowCompleteNewPM() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .presentedSheet = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            e.fulfill()
        }
        _testLogEvent(event: .mcShowCompleteNewPM,
                      params: [:], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testmcShowCustomSavedPM() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .presentedSheet = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            e.fulfill()
        }
        _testLogEvent(event: .mcShowCustomSavedPM,
                      params: [:], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testmcShowCompleteSavedPM() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .presentedSheet = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            e.fulfill()
        }
        _testLogEvent(event: .mcShowCompleteSavedPM,
                      params: [:], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testPaymentSheetCarouselPaymentMethodTapped() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .selectedPaymentMethodType(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .paymentSheetCarouselPaymentMethodTapped,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }

    func testPaymentSheetFormShown() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .displayedPaymentMethodForm(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .paymentSheetFormShown,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }

    func testPaymentSheetFormInteracted() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .startedInteractionWithPaymentMethodForm(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .paymentSheetFormInteracted,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testPaymentSheetFormCompleted() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .completedPaymentMethodForm(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .paymentSheetFormCompleted,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testPaymentSheetConfirmButtonTapped() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .tappedConfirmButton(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .paymentSheetConfirmButtonTapped,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testMcOptionSelectCustomSavedPM() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .selectedSavedPaymentMethod(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .mcOptionSelectCustomSavedPM,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testMcOptionSelectCompleteSavedPM() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .selectedSavedPaymentMethod(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .mcOptionSelectCompleteSavedPM,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testMcOptionRemoveCustomSavedPM() {
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .removedSavedPaymentMethod(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .mcOptionRemoveCustomSavedPM,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func testMcOptionRemoveCompleteSavedPM(){
        let e = expectation(description: "")
        let observer = TestObserver { eventName in
            guard case .removedSavedPaymentMethod(let data) = eventName else {
                XCTFail("Failed to convert eventName")
                return
            }
            XCTAssertEqual(data.paymentMethodType, "card")
            e.fulfill()
        }
        _testLogEvent(event: .mcOptionRemoveCompleteSavedPM,
                      params: ["selected_lpm": "card"], observer: observer)
        wait(for: [e], timeout: 1)
    }
    func _testLogEvent(event: STPAnalyticEvent, params: [String: Any], observer: TestObserver) {
        let notificationCenter = NotificationCenter()
        let analyticsClient = STPAnalyticsClient()

        notificationCenter.addObserver(observer,
                                       selector: #selector(TestObserver.mobilePaymentElementNotification(notification:)),
                                       name: .mobilePaymentElement, object: nil)
        let genericAnalytic = GenericAnalytic(event: event, params: params)
        analyticsClient.log(analytic: genericAnalytic, notificationCenter: notificationCenter)
    }

}

class TestObserver {
    let onNotificationCallback: (MobilePaymentElementAnalyticEvent.Name) -> Void

    init(_ callback: @escaping (MobilePaymentElementAnalyticEvent.Name) -> Void) {
        onNotificationCallback = callback
    }
    @objc
    func mobilePaymentElementNotification(notification: NSNotification) {
        guard let event = notification.object as? MobilePaymentElementAnalyticEvent else {
            XCTFail("Failed to convert to MobilePaymentElementAnalyticEvent")
            return
        }
        onNotificationCallback(event.name)
    }
}
