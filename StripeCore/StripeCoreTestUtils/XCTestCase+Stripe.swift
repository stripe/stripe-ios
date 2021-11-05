//
//  XCTestCase+Stripe.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 11/3/21.
//

import XCTest

public extension XCTestCase {
    func XCTAssertIs<T>(
        _ item: Any,
        _ t: T.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssert(item is T, "\(type(of: item)) is not type \(T.self)", file: file, line: line)
    }
}
