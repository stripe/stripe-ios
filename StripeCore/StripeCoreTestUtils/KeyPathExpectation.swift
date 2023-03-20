//
//  KeyPathExpectation.swift
//  StripeCoreTestUtils
//
//  Created by Ramon Torres on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

public class KeyPathExpectation: XCTNSPredicateExpectation {

    public convenience init<Object, Value: Equatable>(
        object: Object,
        keyPath: KeyPath<Object, Value>,
        equalsToValue value: Value,
        description: String? = nil
    ) {
        let description = description ?? "Expect predicate `\(keyPath)` == \(value) for \(String(describing: object))"

        self.init(
            object: object,
            keyPath: keyPath,
            evaluatedWith: { $0 == value},
            description: description
        )
    }

    public convenience init<Object, Value: Equatable>(
        object: Object,
        keyPath: KeyPath<Object, Value>,
        notEqualsToValue value: Value,
        description: String? = nil
    ) {
        let description = description ?? "Expect predicate `\(keyPath)` != \(value) for \(String(describing: object))"

        self.init(
            object: object,
            keyPath: keyPath,
            evaluatedWith: { $0 != value},
            description: description
        )
    }

    init<Object, Value>(
        object: Object,
        keyPath: KeyPath<Object, Value>,
        evaluatedWith block: @escaping (Value) -> Bool,
        description: String? = nil
    ) {
        let predicate = NSPredicate { object, _ in
            guard let unwrappedObject = object as? Object else {
                return false
            }

            return block(unwrappedObject[keyPath: keyPath])
        }

        super.init(predicate: predicate, object: object)

        expectationDescription = description
            ?? "Expect `\(keyPath)` to return `true` when evaluated with block."
    }

}
