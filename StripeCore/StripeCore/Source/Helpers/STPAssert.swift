//
//  STPAssert.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 3/25/24.
//

import Foundation

#if ENABLE_STPASSERTIONFAILURE
/// A very barebones way to test stpasserts in XCTest.
@_spi(STP) public class STPAssertTestUtil {
    /// If set to `true` in an XCTest, the next assertion that fires populates `lastAssertMessage` instead of crashing and resets this flag to `false`.
    /// After each test finishes, an auto-registered XCTestObservation observer resets this flag
    /// to prevent state from leaking between tests (e.g. if the expected assertion never fires).
    public static var shouldSuppressNextSTPAlert: Bool = false {
        didSet {
            // Lazily register our test observer the first time a test opts into suppression.
            if shouldSuppressNextSTPAlert {
                _ = Self._registerObserver
            }
        }
    }
    /// The message of the assertion that fired when `shouldSuppressNextSTPAlert` was `true`.
    /// Reset automatically after each test by the observer.
    public static var lastAssertMessage: String = ""

    // One-time registration of a test observer that resets state after every test.
    // Uses NSClassFromString/performSelector to avoid importing XCTest in production code.
    // Each perform() call is guarded with responds(to:) to avoid doesNotRecognizeSelector crashes
    // in case XCTest internals ever change.
    private static let _registerObserver: Void = {
        let sharedSel = NSSelectorFromString("sharedTestObservationCenter")
        let addObserverSel = NSSelectorFromString("addTestObserver:")

        guard let centerClass = NSClassFromString("XCTestObservationCenter") as? NSObject.Type,
              centerClass.responds(to: sharedSel),
              let shared = centerClass.perform(sharedSel)?.takeUnretainedValue(),
              shared.responds(to: addObserverSel) else {
            return
        }

        // addTestObserver: requires formal XCTestObservation conformance.
        // Add it dynamically at runtime so we don't need to import XCTest.
        guard let observationProtocol = objc_getProtocol("XCTestObservation") else {
            return
        }
        class_addProtocol(_STPAssertTestObserver.self, observationProtocol)

        let observer = _STPAssertTestObserver()
        _observerRef = observer
        _ = shared.perform(addObserverSel, with: observer)
    }()

    // Strong reference to keep the observer alive for the lifetime of the test run.
    private static var _observerRef: AnyObject?
}

/// Resets STPAssertTestUtil state after each test to prevent cross-test pollution.
/// Conforms to XCTestObservation via Obj-C runtime message dispatch — the selector
/// `testCaseDidFinish:` is recognized without formal protocol conformance or an XCTest import.
private class _STPAssertTestObserver: NSObject {
    @objc func testCaseDidFinish(_ testCase: AnyObject) {
        STPAssertTestUtil.shouldSuppressNextSTPAlert = false
        STPAssertTestUtil.lastAssertMessage = ""
    }
}
#endif

/// A wrapper that only calls `assertionFailure` when the `ENABLE_STPASSERTIONFAILURE` compiler flag is set.
/// Use this for assertions that should not trigger in merchant apps.
@inlinable @_spi(STP) public func stpAssertionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    #if ENABLE_STPASSERTIONFAILURE
    if NSClassFromString("XCTest") != nil && STPAssertTestUtil.shouldSuppressNextSTPAlert {
        STPAssertTestUtil.shouldSuppressNextSTPAlert = false
        STPAssertTestUtil.lastAssertMessage = message()
        return
    }
    assertionFailure(message(), file: file, line: line)
    #else
    print("⚠️ STPAssertionFailure: \(message()) in \(file) on line \(line)")
    #endif
}

/// A wrapper that only calls `assert` when the `ENABLE_STPASSERTIONFAILURE` compiler flag is set.
/// Use this for assertions that should not trigger in merchant apps.
@inlinable @_spi(STP) public func stpAssert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    #if ENABLE_STPASSERTIONFAILURE
    assert(condition(), message(), file: file, line: line)
    #else
    if !condition() {
        print("⚠️ STPAssertionFailure: \(message()) in \(file) on line \(line)")
    }
    #endif
}
