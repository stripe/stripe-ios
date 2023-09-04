//
//  ViewModelObservationNotifierTest.swift
//  StripeCoreTests
//
//  Created by Eduardo Urias on 10/10/23.
//

@_spi(STP) @testable import StripeCore
import XCTest

final class ViewModelObservationNotifierTest: XCTestCase {
    class TestObserver {}

    func testMultipleObserversInvoked() {
        let notifier = ViewModelObservationNotifier()

        var aCalled = false
        var bCalled = false

        let observerA = TestObserver()
        notifier.addObserver(observerA) {
            XCTAssertFalse(aCalled)
            aCalled = true
        }
        let observerB = TestObserver()
        notifier.addObserver(observerB) {
            XCTAssertFalse(bCalled)
            bCalled = true
        }
        notifier.notify()

        XCTAssertTrue(aCalled)
        XCTAssertTrue(bCalled)
    }

    func testMultipleCallbacksInvoked() {
        let notifier = ViewModelObservationNotifier()

        var aCalled = false
        var bCalled = false

        let observer = TestObserver()
        notifier.addObserver(observer) {
            XCTAssertFalse(aCalled)
            aCalled = true
        }
        notifier.addObserver(observer) {
            XCTAssertFalse(bCalled)
            bCalled = true
        }
        notifier.notify()

        XCTAssertTrue(aCalled)
        XCTAssertTrue(bCalled)
    }

    func testRemoveObserver() {
        let notifier = ViewModelObservationNotifier()

        var callbackCalled = false

        let observer = TestObserver()

        notifier.addObserver(observer) {
            XCTAssertFalse(callbackCalled)
            callbackCalled = true
        }
        notifier.notify()

        XCTAssertEqual(notifier.observers.count, 1)
        XCTAssertTrue(callbackCalled)

        notifier.removeObserver(observer)
        XCTAssertEqual(notifier.observers.count, 0)
        notifier.notify()
    }

    func testDeallocatedObserversAreRemoved() {
        let notifier = ViewModelObservationNotifier()

        var callbackCalled = false

        var observer: TestObserver? = TestObserver()

        notifier.addObserver(observer!) {
            XCTAssertFalse(callbackCalled)
            callbackCalled = true
        }
        notifier.notify()

        XCTAssertEqual(notifier.observers.count, 1)
        XCTAssertTrue(callbackCalled)

        // Deallocate the observer.
        observer = nil
        notifier.notify()

        // Deallocated observer should be removed after calling notify.
        XCTAssertEqual(notifier.observers.count, 0)
    }
}
