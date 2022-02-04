//
//  XCTestCase+Stripe.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 11/3/21.
//

import XCTest

public extension XCTestCase {

    func expectation<Object: AnyObject, Value: Equatable>(
        for object: Object,
        keyPath: KeyPath<Object, Value>,
        equalsToValue value: Value,
        description: String? = nil
    ) -> KeyPathExpectation<Object, Value> {
        return KeyPathExpectation(
            object: object,
            keyPath: keyPath,
            equalsToValue: value,
            description: description
        )
    }

    func XCTAssertIs<T>(
        _ item: Any,
        _ t: T.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssert(item is T, "\(type(of: item)) is not type \(T.self)", file: file, line: line)
    }

}
