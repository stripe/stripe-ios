//
//  STPFormEncoder.swift
//  StripePayments
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public class STPFormEncoder: NSObject {
    @objc @_spi(STP) public class func dictionary(
        forObject object: (NSObject & STPFormEncodable)
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
        forObject object: (NSObject & STPFormEncodable)
    )
        -> [String:
        Any]
    {
        var keyPairs: [String: Any] = [:]
        for (propertyName, formFieldName) in type(of: object).propertyNamesToFormFieldNamesMapping()
        {
            if let propertyValue = object.value(forKeyPath: propertyName) {
                guard let propertyValue = propertyValue as? NSObject else {
                    assertionFailure()
                    continue
                }
                keyPairs[formFieldName] = formEncodableValue(for: propertyValue)
            }
        }
        for (additionalFieldName, additionalFieldValue) in object.additionalAPIParameters {
            guard let additionalFieldName = additionalFieldName as? String,
                let additionalFieldValue = additionalFieldValue as? NSObject
            else {
                assertionFailure()
                continue
            }
            keyPairs[additionalFieldName] = formEncodableValue(for: additionalFieldValue)
        }
        return keyPairs
    }

    /// Expands object, and any subobjects, into key pair dictionaries if they are STPFormEncodable
    private class func formEncodableValue(for object: NSObject) -> NSObject {
        switch object {
        case let object as NSObject & STPFormEncodable:
            return self.keyPairDictionary(forObject: object) as NSObject
        case let dict as NSDictionary:
            let result = NSMutableDictionary(capacity: dict.count)
            dict.enumerateKeysAndObjects({ key, value, _ in
                if let key = key as? NSObject,  // Don't all keys need to be Strings?
                    let value = value as? NSObject
                {
                    result[formEncodableValue(for: key)] = formEncodableValue(for: value)
                } else {
                    assertionFailure()  // TODO remove
                }
            })
            return result
        case let array as NSArray:
            let result = NSMutableArray()
            for element in array {
                guard let element = element as? NSObject else {
                    assertionFailure()  // TODO remove
                    continue
                }
                result.add(formEncodableValue(for: element))
            }
            return result
        case let set as NSSet:
            let result = NSMutableSet()
            for element in set {
                guard let element = element as? NSObject else {
                    continue
                }
                result.add(self.formEncodableValue(for: element))
            }
            return result
        default:
            return object
        }
    }
}
