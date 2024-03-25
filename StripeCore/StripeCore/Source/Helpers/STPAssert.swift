//
//  STPAssert.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 3/25/24.
//

import Foundation

/// A wrapper that only calls `assertionFailure` when the `ENABLE_STPASSERTIONFAILURE` compiler flag is set.
/// Use this for assertions that should not trigger in merchant apps.
@inlinable @_spi(STP) public func stpAssertionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    #if ENABLE_STPASSERTIONFAILURE
    assertionFailure(message(), file: file, line: line)
    #else
    print("⚠️ STPAssertionFailure: \(message()) in \(file) on line \(line)")
    #endif
}
