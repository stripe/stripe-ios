//
//  STPFormEncoder.swift
//  StripePayments
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(InternalOnlyAPI) public class STPFormEncoder: NSObject {
    @_spi(InternalOnlyAPI) public class func dictionary(
        forObject object: STPFormEncodable
    ) -> [String: Any] {
        // returns [object root name : object.coded (eg [property name strings: property values)]
        let keyPairs = self.keyPairDictionary(forObject: object)
        let rootObjectName = type(of: object).rootObjectName()
        if let rootObjectName = rootObjectName {
            return [rootObjectName: keyPairs]
        } else {
            return keyPairs
        }
    }

    // MARK: - Internal

    /// Returns [Property name : Property's form encodable value]
    private class func keyPairDictionary(
        forObject object: STPFormEncodable
    ) -> [String: Any] {
        var keyPairs: [String: Any] = [:]
        for (keyPath, formFieldName) in type(of: object).propertyNamesToFormFieldNamesMapping() {
            if let rawValue = (object as Any)[keyPath: keyPath],
               let propertyValue = flattenOptional(rawValue) {
                keyPairs[formFieldName] = formEncodableValue(for: propertyValue)
            }
        }
        for (additionalFieldName, additionalFieldValue) in object.additionalAPIParameters {
            guard let additionalFieldName = additionalFieldName as? String else {
                assertionFailure()
                continue
            }
            keyPairs[additionalFieldName] = formEncodableValue(for: additionalFieldValue)
        }
        return keyPairs
    }

    private class func flattenOptional(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else {
            return value
        }
        guard let child = mirror.children.first else {
            return nil
        }
        return flattenOptional(child.value)
    }

    /// Expands object, and any subobjects, into key pair dictionaries if they are STPFormEncodable
    private class func formEncodableValue(for object: Any) -> NSObject {
        switch object {
        case let object as STPFormEncodable:
            return self.keyPairDictionary(forObject: object) as NSObject
        case let dict as [AnyHashable: Any]:
            let result = NSMutableDictionary(capacity: dict.count)
            for (key, value) in dict {
                result[formEncodableValue(for: key.base)] = formEncodableValue(for: value)
            }
            return result
        case let array as [Any]:
            let result = NSMutableArray()
            for element in array {
                result.add(formEncodableValue(for: element))
            }
            return result
        case let set as NSSet:
            let result = NSMutableSet()
            for element in set {
                result.add(self.formEncodableValue(for: element))
            }
            return result
        case let rawRepresentable as any RawRepresentable:
            return formEncodableValue(for: rawRepresentable.rawValue)
        case let object as NSObject:
            return object
        default:
            assertionFailure("Unexpected form encodable value \(object)")
            return "\(object)" as NSString
        }
    }
}
