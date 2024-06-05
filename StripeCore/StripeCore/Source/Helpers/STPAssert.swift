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
    /// If set to `true` in an XCTest, the next assertion that fires populates `_testExpectAssertMessage` instead of crashing and resets this flag to `false`.
    public static var shouldSuppressNextSTPAlert: Bool = false
    /// The message of the assertion that fired when `_testExpectAssert` was `true`.
    public static var lastAssertMessage: String = ""
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
