//
//  KeyPathExpectation.swift
//  StripeCoreTestUtils
//
//  Created by Ramon Torres on 1/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

public class KeyPathExpectation<Object: AnyObject, Value: Equatable>: XCTNSPredicateExpectation {

    public init(
        object: Object,
        keyPath: KeyPath<Object, Value>,
        equalsToValue value: Value,
        description: String? = nil
    ) {
        let predicate = NSPredicate { object, _ in
            guard let unwrappedObject = object as? Object else {
                return false
            }

            return unwrappedObject[keyPath: keyPath] == value;
        }

        super.init(predicate: predicate, object: object)

        expectationDescription = description ?? makeDescription(
            object: object,
            value: value,
            keyPath: keyPath
        )
    }

    private func makeDescription(
        object: Object, value: Value,
        keyPath: KeyPath<Object, Value>
    ) -> String {
        return "Expect predicate `\(keyPath)` == \(value) for object \(String(describing: object))"
    }

}
