//
//  XCTestCase+Stripe.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 11/3/21.
//

import XCTest

extension XCTestCase {

    public func expectation<Object, Value: Equatable>(
        for object: Object,
        keyPath: KeyPath<Object, Value>,
        equalsToValue value: Value,
        description: String? = nil
    ) -> KeyPathExpectation {
        return KeyPathExpectation(
            object: object,
            keyPath: keyPath,
            equalsToValue: value,
            description: description
        )
    }

    public func expectation<Object, Value: Equatable>(
        for object: Object,
        keyPath: KeyPath<Object, Value>,
        notEqualsToValue value: Value,
        description: String? = nil
    ) -> KeyPathExpectation {
        return KeyPathExpectation(
            object: object,
            keyPath: keyPath,
            notEqualsToValue: value,
            description: description
        )
    }

    public func notNullExpectation<Object, Value>(
        for object: Object,
        keyPath: KeyPath<Object, Value?>,
        description: String? = nil
    ) -> KeyPathExpectation {
        let description =
            description ?? "Expect predicate `\(keyPath)` != nil for \(String(describing: object))"

        return KeyPathExpectation(
            object: object,
            keyPath: keyPath,
            evaluatedWith: { $0 != nil },
            description: description
        )
    }
}

public func XCTAssertIs<T>(
    _ item: Any,
    _ t: T.Type,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssert(item is T, "\(type(of: item)) is not type \(T.self)", file: file, line: line)
}
