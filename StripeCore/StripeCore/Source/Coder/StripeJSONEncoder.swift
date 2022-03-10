//
//  StripeJSONEncoder.swift
//  StripeCore
//
//  This is a bridge between NSJSONSerialization and Encoder, including some Stripe-specific behavior.
//


import Foundation

class StripeJSONEncoder {
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    var outputFormatting: JSONSerialization.WritingOptions = []
    
    func encode<T>(_ value: T) throws -> Data where T : Encodable {
        var outputFormatting = self.outputFormatting
        outputFormatting.insert(.fragmentsAllowed)
        return try JSONSerialization.data(withJSONObject: castToNSObject(value), options: outputFormatting)
    }
}

// Make sure StripeJSONEncoder can call castToNSObject
extension StripeJSONEncoder: StripeEncodingContainer { }

class _stpinternal_JSONEncoder: Encoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    enum ContainerValue {
        case dict(NSMutableDictionary)
        case array(NSMutableArray)
        case singleValue(NSObject)
    }
    
    private var container: ContainerValue?
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let dict = NSMutableDictionary()
        self.container = .dict(dict)
        return KeyedEncodingContainer<Key>(STPKeyedEncodingContainer(codingPath: codingPath, dict: dict, userInfo: userInfo))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        // We've been asked for an array, so initialize a top-level empty array to handle the case of an empty array.
        let array = NSMutableArray()
        self.container = .array(array)
        return STPUnkeyedEncodingContainer(codingPath: codingPath, array: array, userInfo: userInfo)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        self.container = .singleValue(NSNull())
        return STPSingleValueEncodingContainer(codingPath: codingPath, encodingBlock: { self.container = .singleValue($0) }, userInfo: userInfo)
    }
    
    /// Return the NSObject contained by this encoder: Either a dictionary, an array, or a single object.
    var singleContainer: NSObject {
        guard let container = container else {
            assertionFailure("Called singleContainer on an empty decoder")
            return NSNull()
        }
        switch container {
        case .dict(let dict):
            return dict
        case .array(let array):
            return array
        case .singleValue(let singleValue):
            return singleValue
        }
    }
}

struct STPKeyedEncodingContainer<K>: StripeEncodingContainer, KeyedEncodingContainerProtocol where K: CodingKey {
    var codingPath: [CodingKey]
    
    typealias Key = K
    
    var dict: NSMutableDictionary
    var userInfo: [CodingUserInfoKey: Any]
    
    mutating private func encode(object: NSObject, forKey key: K) throws {
        let maintainExistingCase = userInfo[STPMaintainExistingCase] as? Bool ?? false
        
        let stringKey = key.stringValue
        let key = maintainExistingCase ? stringKey : URLEncoder.convertToSnakeCase(camelCase: stringKey)

        dict[key] = object
    }
    
    mutating func encodeNil(forKey key: K) throws {
        try encode(object: NSNull(), forKey: key)
    }
    
    mutating func encode(_ value: Bool, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: String, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: Double, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: Float, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: Int, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: Int8, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: Int16, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: Int32, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: Int64, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt8, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt16, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt32, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }
    
    mutating func encode(_ value: UInt64, forKey key: K) throws {
        try encode(object: castToNSObject(value), forKey: key)
    }

    mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        if value is NonEncodableParameters {
            // Don't encode this
            return
        }
        try encode(object: castToNSObject(codingPath: codingPath + [key], value), forKey: key)
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        // This is messy to support and we don't have any situations
        // in the Stripe SDK where we want to use it. The implementation
        // would probably look similar to superEncoder() above.
        assertionFailure("nestedContainer(keyedBy:) is not implemented.")
        return KeyedEncodingContainer<NestedKey>(STPKeyedEncodingContainer<NestedKey>(codingPath: codingPath + [key], dict: NSMutableDictionary(), userInfo: userInfo))
    }
    
    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        // This is messy to support and we don't have any situations
        // in the Stripe SDK where we want to use it. The implementation
        // would probably look similar to superEncoder() above.
        assertionFailure("nestedUnkeyedContainer(forKey:) is not implemented.")
        return STPUnkeyedEncodingContainer(codingPath: codingPath + [key], array: NSMutableArray(), userInfo: userInfo)
    }
    
    mutating func superEncoder() -> Encoder {
        // See above superEncoder() comment.
        assertionFailure("superEncoder() is not implemented.")
        return _stpinternal_JSONEncoder()
    }
    
    mutating func superEncoder(forKey key: K) -> Encoder {
        // See above superEncoder() comment.
        assertionFailure("superEncoder(forKey:) is not implemented.")
        return _stpinternal_JSONEncoder()
    }
}

struct STPUnkeyedEncodingContainer: UnkeyedEncodingContainer, StripeEncodingContainer {
    var codingPath: [CodingKey]
    
    var count: Int = 0
    
    var array: NSMutableArray
    var userInfo: [CodingUserInfoKey: Any]

    mutating func encodeNil() throws {
        array.add(NSNull())
        count += 1
    }
    
    mutating func encode(_ value: Bool) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: String) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: Double) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: Float) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: Int) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: Int8) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: Int16) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: Int32) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: Int64) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: UInt) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: UInt8) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: UInt16) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: UInt32) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode(_ value: UInt64) throws {
        try array.add(castToNSObject(value))
        count += 1
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        if value is NonEncodableParameters {
            // Don't encode this
            return
        }
        
        try array.add(castToNSObject(codingPath: codingPath + [STPCodingKey(intValue: count)!], value))
        
        count += 1
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        // This is messy to support and we don't have any situations
        // in the Stripe SDK where we want to use it. The implementation
        // would probably look similar to superEncoder() below.
        assertionFailure("nestedContainer(keyedBy:) is not implemented.")
        return KeyedEncodingContainer<NestedKey>(STPKeyedEncodingContainer(codingPath: codingPath, dict: NSMutableDictionary(), userInfo: userInfo))
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        // This is messy to support and we don't have any situations
        // in the Stripe SDK where we want to use it. The implementation
        // would probably look similar to superEncoder() below.
        assertionFailure("nestedUnkeyedContainer() is not implemented.")
        return STPUnkeyedEncodingContainer(codingPath: codingPath, array: NSMutableArray(), userInfo: userInfo)
    }
    
    mutating func superEncoder() -> Encoder {
        // Super-encoding is messy and we don't have any situations in
        // the Stripe SDK where a Codable inherits from another Codable.
        // If you'd like to implement this, see
        // https://forums.swift.org/t/writing-encoders-and-decoders-different-question/10232/5
        //  for details.
        assertionFailure("superEncoder() is not implemented.")
        return _stpinternal_JSONEncoder()
    }
    
    
}

struct STPSingleValueEncodingContainer: SingleValueEncodingContainer, StripeEncodingContainer {
    var codingPath: [CodingKey]
    
    var encodingBlock: (NSObject) -> Void
    var userInfo: [CodingUserInfoKey: Any]
    
    mutating func encodeNil() throws {
        encodingBlock(NSNull())
    }
    
    mutating func encode(_ value: Bool) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: String) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: Double) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: Float) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: Int) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: Int8) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: Int16) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: Int32) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: Int64) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: UInt) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: UInt8) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: UInt16) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: UInt32) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode(_ value: UInt64) throws {
        encodingBlock(try castToNSObject(value))
    }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        if value is NonEncodableParameters {
            // Don't encode this
            return
        }
        encodingBlock(try castToNSObject(value))
    }
}

protocol StripeEncodingContainer {
    var userInfo: [CodingUserInfoKey: Any] {
        get set
    }
}

extension StripeEncodingContainer {
    fileprivate func castToNSObject<T>(codingPath: [CodingKey] = [], _ value: T) throws -> NSObject where T : Encodable {
        switch value {
        case let n as Bool:
            return n as NSObject
        case let n as String:
            return n as NSObject
        case let n as Double:
            if n == .infinity {
                return "Inf" as NSObject
            }
            if n == -.infinity {
                return "-Inf" as NSObject
            }
            if n.isNaN {
                return "nan" as NSObject
            }
            return n as NSObject
        case let n as Float:
            if n == .infinity {
                return "Inf" as NSObject
            }
            if n == -.infinity {
                return "-Inf" as NSObject
            }
            if n.isNaN {
                return "nan" as NSObject
            }
            return n as NSObject
        case let n as Int:
            return n as NSObject
        case let n as Int8:
            return n as NSObject
        case let n as Int16:
            return n as NSObject
        case let n as Int32:
            return n as NSObject
        case let n as Int64:
            return n as NSObject
        case let n as UInt:
            return n as NSObject
        case let n as UInt8:
            return n as NSObject
        case let n as UInt16:
            return n as NSObject
        case let n as UInt32:
            return n as NSObject
        case let n as UInt64:
            return n as NSObject
        case let decimal as Decimal:
            return NSDecimalNumber(decimal: decimal)
        case let url as URL:
            return url.absoluteString as NSObject
        case let date as Date:
            // Stripe expects an integer number of seconds since the Unix epoch
            return Int(date.timeIntervalSince1970) as NSObject
        case let data as Data:
            // Stripe expects base64-encoded data
            return data.base64EncodedString() as NSObject
        case is Dictionary<AnyHashable, Any>:
            let encoder = _stpinternal_JSONEncoder()
            encoder.userInfo = userInfo
            // If this is a dictionary, don't apply transformations to the keys
            encoder.userInfo[STPMaintainExistingCase] = true
            encoder.codingPath = codingPath
            try value.encode(to: encoder)
            return encoder.singleContainer
        default:
            let encoder = _stpinternal_JSONEncoder()
            encoder.userInfo = userInfo
            encoder.codingPath = codingPath
            try value.encode(to: encoder)
            return encoder.singleContainer
        }
    }
}

// Constants
fileprivate let STPMaintainExistingCase = CodingUserInfoKey(rawValue: "_STPMaintainExistingCase")!

fileprivate struct STPCodingKey: CodingKey {
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = intValue.description
    }
    
    init(stringValue: String, intValue: Int?) {
        self.intValue = intValue
        self.stringValue = stringValue
    }
    
    var stringValue: String
    var intValue: Int?
}
