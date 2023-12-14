//
//  StripeJSONDecoder.swift
//  StripeCore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//
//  This is a bridge between NSJSONSerialization and Decoder, including some Stripe-specific behavior.
//

import Foundation

@_spi(STP) public class StripeJSONDecoder {
    @_spi(STP) public init() {}

    @_spi(STP) public var userInfo: [CodingUserInfoKey: Any] = [:]

    @_spi(STP) public var inputFormatting: JSONSerialization.ReadingOptions = []

    @_spi(STP) public func decode<T>(_ type: T.Type, from data: Data) throws -> T
    where T: Decodable {
        var inputFormatting = self.inputFormatting
        // We always allow fragments. (Though we mostly only use these for tests.)
        inputFormatting.insert(.fragmentsAllowed)
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: inputFormatting)
        } catch let error {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "The given data was not valid JSON.",
                    underlyingError: error
                )
            )
        }
        guard let object = jsonObject as? NSObject else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "The given data could not be decoded from JSON.",
                    underlyingError: nil
                )
            )
        }
        let decoder = _stpinternal_JSONDecoder(jsonObject: object)
        userInfo[UnknownFieldsDecodableSourceStorageKey] = data
        decoder.userInfo = userInfo
        let value: T = try decoder.castFromNSObject()
        if var sdValue = value as? UnknownFieldsDecodable {
            try sdValue.applyUnknownFieldDecodingTransforms(userInfo: userInfo, codingPath: [])
            return sdValue as! T
        }
        return value
    }
}

private class _stpinternal_JSONDecoder: Decoder, STPDecodingContainerProtocol {
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var codingPath: [CodingKey] = []
    var jsonObject: NSObject

    init(
        jsonObject: NSObject
    ) {
        self.jsonObject = jsonObject
    }

    func castFromNSObject<T>() throws -> T where T: Decodable {
        return try castFromNSObject(codingPath: codingPath, T.self, jsonObject)
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
    where Key: CodingKey {
        guard let dict = jsonObject as? NSDictionary else {
            throw DecodingError.typeMismatch(
                NSDictionary.self,
                .init(
                    codingPath: codingPath,
                    debugDescription: "KeyedContainer is not a dictionary",
                    underlyingError: nil
                )
            )
        }
        return KeyedDecodingContainer<Key>(
            STPKeyedDecodingContainer(
                codingPath: codingPath,
                dict: dict,
                allKeys: [],
                userInfo: userInfo
            )
        )
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        var objectToDecode = jsonObject

        // The implementation of Codable encodes Dictionaries that have Keys that are not exactly
        // `String.Type` or `Int.Type` as an `Array`.
        // If we have a Dictionary that has Keys that derived from String we end up here.
        // To solve this, just convert to an Array.
        // see: https://github.com/apple/swift/blob/d2085d8b0ed69e40a10e555669bb6cc9b450d0b3/stdlib/public/core/Codable.swift.gyb#L1967
        // For the decoding see: https://github.com/apple/swift/blob/d2085d8b0ed69e40a10e555669bb6cc9b450d0b3/stdlib/public/core/Codable.swift.gyb#L2036
        // Interestingly the default implementation does not handle this which seems like a bug.
        // See here: https://github.com/apple/swift-corelibs-foundation/blob/main/Sources/Foundation/JSONDecoder.swift
        if let dict = objectToDecode as? NSDictionary {
            let arrayCopy = NSMutableArray()
            for (key, value) in dict {
                arrayCopy.add(key)
                arrayCopy.add(value)
            }

            objectToDecode = arrayCopy
        }

        guard let array = objectToDecode as? NSArray else {
            throw DecodingError.typeMismatch(
                NSArray.self,
                .init(
                    codingPath: codingPath,
                    debugDescription: "UnkeyedContainer is not an array",
                    underlyingError: nil
                )
            )
        }
        return STPUnkeyedDecodingContainer(userInfo: userInfo, array: array, codingPath: codingPath)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return STPSingleValueDecodingContainer(
            codingPath: codingPath,
            userInfo: userInfo,
            object: jsonObject
        )
    }
}

private protocol STPDecodingContainerProtocol {
    var userInfo: [CodingUserInfoKey: Any] {
        get set
    }
}

private struct STPKeyedDecodingContainer<K>: STPDecodingContainerProtocol,
    KeyedDecodingContainerProtocol
where K: CodingKey {
    var codingPath: [CodingKey]

    var dict: NSDictionary
    var allKeys: [K]

    var userInfo: [CodingUserInfoKey: Any]

    typealias Key = K

    func _dictionaryKey(from key: K) -> String {
        let maintainExistingCase = userInfo[STPMaintainExistingCase] as? Bool ?? false
        var key = key.stringValue

        if !maintainExistingCase {
            key = URLEncoder.convertToSnakeCase(camelCase: key)
        }

        return key
    }

    func contains(_ key: K) -> Bool {
        let key = _dictionaryKey(from: key)
        return dict[key] != nil
    }

    func _objectForKey(_ key: K) throws -> NSObject {
        if !contains(key) {
            throw DecodingError.keyNotFound(
                key,
                .init(
                    codingPath: codingPath,
                    debugDescription: "Key \(key) not found in \(codingPath)",
                    underlyingError: nil
                )
            )
        }

        let key = _dictionaryKey(from: key)
        return dict[key] as! NSObject
    }

    func _decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        let newPath = codingPath + [key]
        let value: T = try castFromNSObject(codingPath: newPath, type, _objectForKey(key))
        if var sdValue = value as? UnknownFieldsDecodable {
            try sdValue.applyUnknownFieldDecodingTransforms(userInfo: userInfo, codingPath: newPath)
            return sdValue as! T
        }
        return value
    }

    func decodeNil(forKey key: K) throws -> Bool {
        return (try _objectForKey(key) is NSNull)
    }

    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        return try _decode(type, forKey: key)
    }

    func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        return try _decode(type, forKey: key)
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        return try _decode(type, forKey: key)
    }

    func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: K
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        assertionFailure("nestedContainer(keyedBy:forKey:) is not implemented.")
        return KeyedDecodingContainer<NestedKey>(
            STPKeyedDecodingContainer<NestedKey>(
                codingPath: [],
                dict: NSMutableDictionary(),
                allKeys: [],
                userInfo: [:]
            )
        )
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        assertionFailure("nestedUnkeyedContainer(forKey:) is not implemented.")
        return STPUnkeyedDecodingContainer(
            userInfo: [:],
            array: NSArray(),
            codingPath: [],
            currentIndex: 0
        )
    }

    func superDecoder() throws -> Decoder {
        assertionFailure("superDecoder() is not implemented.")
        return _stpinternal_JSONDecoder(jsonObject: NSNull())
    }

    func superDecoder(forKey key: K) throws -> Decoder {
        assertionFailure("superDecoder(forKey:) is not implemented.")
        return _stpinternal_JSONDecoder(jsonObject: NSNull())
    }

}

private struct STPUnkeyedDecodingContainer: UnkeyedDecodingContainer, STPDecodingContainerProtocol {
    var userInfo: [CodingUserInfoKey: Any]

    var array: NSArray

    var codingPath: [CodingKey]

    var count: Int? {
        return array.count
    }

    var isAtEnd: Bool {
        return currentIndex >= count ?? 0
    }

    var currentIndex: Int = 0

    mutating func _popObject() -> NSObject {
        assert(!isAtEnd, "Tried to read past the end of the container.")
        let object = array[currentIndex] as! NSObject
        currentIndex += 1
        return object
    }

    mutating func _decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        let newPath = codingPath + [STPCodingKey(intValue: currentIndex)!]

        let value: T = try castFromNSObject(codingPath: newPath, type, _popObject())
        if var sdValue = value as? UnknownFieldsDecodable {
            try sdValue.applyUnknownFieldDecodingTransforms(userInfo: userInfo, codingPath: newPath)
            return sdValue as! T
        }
        return value
    }

    mutating func decodeNil() throws -> Bool {
        let object = _popObject()
        return (object is NSNull)
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        return try _decode(type)
    }

    mutating func decode(_ type: String.Type) throws -> String {
        return try _decode(type)
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        return try _decode(type)
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        return try _decode(type)
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        return try _decode(type)
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        return try _decode(type)
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        return try _decode(type)
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        return try _decode(type)
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        return try _decode(type)
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        return try _decode(type)
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try _decode(type)
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try _decode(type)
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try _decode(type)
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try _decode(type)
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try _decode(type)
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        assertionFailure("nestedContainer(keyedBy:) is not implemented.")
        return KeyedDecodingContainer<NestedKey>(
            STPKeyedDecodingContainer<NestedKey>(
                codingPath: [],
                dict: NSMutableDictionary(),
                allKeys: [],
                userInfo: [:]
            )
        )
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        assertionFailure("nestedUnkeyedContainer(forKey:) is not implemented.")
        return STPUnkeyedDecodingContainer(userInfo: [:], array: NSArray(), codingPath: [])
    }

    mutating func superDecoder() throws -> Decoder {
        assertionFailure("superDecoder() is not implemented.")
        return _stpinternal_JSONDecoder(jsonObject: NSNull())
    }

}

private struct STPSingleValueDecodingContainer: SingleValueDecodingContainer,
    STPDecodingContainerProtocol
{
    var codingPath: [CodingKey]

    var userInfo: [CodingUserInfoKey: Any]

    var object: NSObject

    func _decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        let value: T = try castFromNSObject(codingPath: codingPath, type, object)
        if var sdValue = value as? UnknownFieldsDecodable {
            try sdValue.applyUnknownFieldDecodingTransforms(
                userInfo: userInfo,
                codingPath: codingPath
            )
            return sdValue as! T
        }
        return value
    }

    func decodeNil() -> Bool {
        return object == NSNull()
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        return try _decode(type)
    }

    func decode(_ type: String.Type) throws -> String {
        return try _decode(type)
    }

    func decode(_ type: Double.Type) throws -> Double {
        return try _decode(type)
    }

    func decode(_ type: Float.Type) throws -> Float {
        return try _decode(type)
    }

    func decode(_ type: Int.Type) throws -> Int {
        return try _decode(type)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        return try _decode(type)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        return try _decode(type)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        return try _decode(type)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        return try _decode(type)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        return try _decode(type)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try _decode(type)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try _decode(type)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try _decode(type)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try _decode(type)
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        return try _decode(type)
    }

}

// MARK: Casting logic

// These extensions help us maintain the type information for Arrays and Dictionaries within castFromNSObject, so that
// inner calls to castFromNSObject call the templated function without erasing the underlying type.
// I'm not sure if there's a cleaner way to do this...
private protocol _STPDecodableIsArray {
    static var valueType: Decodable.Type { get }
}
extension Array: _STPDecodableIsArray where Element: Decodable {
    static var valueType: Decodable.Type { return Element.self }
}
private protocol _STPDecodableIsDictionary {
    static var valueType: Decodable.Type { get }
}
extension Dictionary: _STPDecodableIsDictionary where Key == String, Value: Decodable {
    static var valueType: Decodable.Type { return Value.self }
}
extension Decodable {
    fileprivate static func _castFromNSObject(
        codingPath: [CodingKey] = [],
        decodingContainer: STPDecodingContainerProtocol,
        object: NSObject
    ) throws -> Self {
        return try decodingContainer.castFromNSObject(codingPath: codingPath, Self.self, object)
    }
}

extension STPDecodingContainerProtocol {
    func castFromNSObject<T>(
        codingPath: [CodingKey] = [],
        _ type: T.Type,
        _ object: NSObject
    ) throws -> T where T: Decodable {
        switch type {
        case is Double.Type:
            switch object as? String {
            case UnknownFieldsCodableFloats.PositiveInfinity.rawValue:
                return Double.infinity as! T
            case UnknownFieldsCodableFloats.NegativeInfinity.rawValue:
                return -Double.infinity as! T
            case UnknownFieldsCodableFloats.NaN.rawValue:
                return Double.nan as! T
            case .none, .some:
                guard let value = object as? Double, let returnValue = value as? T else {
                    throw DecodingError.dataCorrupted(
                        .init(
                            codingPath: codingPath,
                            debugDescription:
                                "Parsed JSON number <\(object)> does not fit in \(type).",
                            underlyingError: nil
                        )
                    )
                }
                return returnValue
            }
        case is Float.Type:
            switch object as? String {
            case UnknownFieldsCodableFloats.PositiveInfinity.rawValue:
                return Float.infinity as! T
            case UnknownFieldsCodableFloats.NegativeInfinity.rawValue:
                return -Float.infinity as! T
            case UnknownFieldsCodableFloats.NaN.rawValue:
                return Float.nan as! T
            case .none, .some:
                guard let value = object as? Float, let returnValue = value as? T else {
                    throw DecodingError.dataCorrupted(
                        .init(
                            codingPath: codingPath,
                            debugDescription:
                                "Parsed JSON number <\(object)> does not fit in \(type).",
                            underlyingError: nil
                        )
                    )
                }
                return returnValue
            }
        case is Bool.Type,
            is Int.Type,
            is Int8.Type,
            is Int16.Type,
            is Int32.Type,
            is Int64.Type,
            is UInt.Type,
            is UInt8.Type,
            is UInt16.Type,
            is UInt32.Type,
            is UInt64.Type,
            is String.Type:
            guard let value = object as? T else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: codingPath,
                        debugDescription: "Parsed JSON number <\(object)> does not fit in \(type).",
                        underlyingError: nil
                    )
                )
            }
            return value
        case is Decimal.Type:
            guard let decimal = (object as? NSNumber)?.decimalValue else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: codingPath,
                        debugDescription: "Could not convert <\(object)> to \(type).",
                        underlyingError: nil
                    )
                )
            }
            return decimal as! T
        case is URL.Type:
            guard let string = object as? String, let url = URL(string: string) else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: codingPath,
                        debugDescription: "Could not convert <\(object)> to \(type).",
                        underlyingError: nil
                    )
                )
            }
            return url as! T
        case is Data.Type:
            guard let string = object as? String, let data = Data(base64Encoded: string) else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: codingPath,
                        debugDescription: "Could not convert <\(object)> to \(type).",
                        underlyingError: nil
                    )
                )
            }
            return data as! T
        case is Date.Type:
            guard let ti = object as? TimeInterval else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: codingPath,
                        debugDescription: "Could not convert <\(object)> to \(type).",
                        underlyingError: nil
                    )
                )
            }
            return Date(timeIntervalSince1970: ti) as! T
        case is _STPDecodableIsDictionary.Type:
            guard let dict = object as? [String: Any] else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: codingPath,
                        debugDescription: "Could not convert <\(object)> to \(type).",
                        underlyingError: nil
                    )
                )
            }
            var convertedDict: [String: Any] = [:]
            for (k, v) in dict {
                let dictType = T.self as! (_STPDecodableIsDictionary.Type)
                convertedDict[k] = try dictType.valueType._castFromNSObject(
                    codingPath: codingPath,
                    decodingContainer: self,
                    object: v as! NSObject
                )
            }
            return convertedDict as! T
        case is _STPDecodableIsArray.Type:
            guard let array = object as? [Any] else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: codingPath,
                        debugDescription: "Could not convert <\(object)> to \(type).",
                        underlyingError: nil
                    )
                )
            }
            var convertedArray: [Any] = []
            for i in array {
                let arrayType = T.self as! (_STPDecodableIsArray.Type)
                convertedArray.append(
                    try arrayType.valueType._castFromNSObject(
                        codingPath: codingPath,
                        decodingContainer: self,
                        object: i as! NSObject
                    )
                )
            }
            return convertedArray as! T
        case is SafeEnumDecodable.Type:
            do {
                let decoder = _stpinternal_JSONDecoder(jsonObject: object)
                decoder.userInfo = userInfo
                decoder.codingPath = codingPath
                return try T(from: decoder)
            } catch Swift.DecodingError.dataCorrupted {
                let enumDecodableType = T.self as! (SafeEnumDecodable.Type)
                return enumDecodableType.unparsable as! T
            }
        default:
            let decoder = _stpinternal_JSONDecoder(jsonObject: object)
            decoder.userInfo = userInfo
            decoder.codingPath = codingPath
            return try T(from: decoder)
        }
    }
}
