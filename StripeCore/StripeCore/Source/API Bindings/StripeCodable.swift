//
//  StripeCodable.swift
//  StripeiOS
//
//  Created by David Estes on 7/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

// This contains ~most of our custom encoding/decoding logic for handling unknown fields.
//
// It isn't intended for public use, but exposing objects with this protocol
// requires that we make the protocol itself public.
//
// If you'd like this behavior for your own JSON Codable structs, I wouldn't
// recommend doing something like this - you're better off just copying JSONDecoder from
// https://github.com/apple/swift-corelibs-foundation/blob/master/Sources/Foundation/JSONDecoder.swift
// and modifying it for your needs.
//

import Foundation

/// A Decodable object that retains unknown fields.
/// :nodoc:
public protocol StripeDecodable: Decodable {
    /// This should not be used directly.
    /// Use the `allResponseFields` accessor instead.
    /// :nodoc:
    var _allResponseFieldsStorage: NonEncodableParameters? { get set }
}

/// An Encodable object that allows unknown fields to be set.
/// :nodoc:
public protocol StripeEncodable: Encodable {
    /// This should not be used directly.
    /// Use the `additionalParameters` accessor instead.
    /// :nodoc:
    var _additionalParametersStorage: NonEncodableParameters? { get set }
}

/// A Codable enum that sets an "unparsable" case
/// instead of failing on values that are unknown to the SDK.
/// StripeEnumCodable properties must always be optional.
/// :nodoc:
public protocol StripeEnumCodable: Codable {
    /// If the value is unparsable, the result will be available in
    /// the `allResponseFields` of the parent object.
    static var unparsable: Self { get }
    
    // It'd be nice to include the value of the unparsable enum
    // as an associated value, but Swift can't auto-generate the Codable
    // keys if we do that.
}

extension StripeDecodable {
    /// A dictionary containing all response fields from the original JSON,
    /// including unknown fields.
    public internal(set) var allResponseFields: [String: Any] {
        get {
            self._allResponseFieldsStorage?.storage ?? [:]
        }
        set {
            if self._allResponseFieldsStorage == nil {
                self._allResponseFieldsStorage = NonEncodableParameters()
            }
            self._allResponseFieldsStorage!.storage = newValue
        }
    }
    
    static func decodedObject(jsonData: Data) throws -> Self {
        return try JSONDecoder.decode(jsonData: jsonData)
    }
}

extension StripeEncodable {
    /// You can use this property to add additional fields to an API request that are not explicitly defined by the object's interface. This can be useful when using beta features that haven't been added to the Stripe SDK yet. For example, if the /v1/tokens API began to accept a beta field called "test_field", you might do the following:
    /// var cardParams = PaymentMethodParams.Card()
    /// // add card values
    /// cardParams.additionalParameters = ["test_field": "example_value"]
    /// PaymentsAPI.shared.createToken(withParameters: cardParams completion:...);
    public var additionalParameters: [String: Any] {
        get {
            self._additionalParametersStorage?.storage ?? [:]
        }
        set {
            if self._additionalParametersStorage == nil {
                self._additionalParametersStorage = NonEncodableParameters()
            }
            self._additionalParametersStorage!.storage = newValue
        }
    }
}

extension StripeEncodable {
    func encodeJSONDictionary() throws -> [String: Any] {
        // To create a payload, we'll:
        // 1. Create JSON from the Encodable object
        // 2. Decode the JSON to a Dictionary
        // 3. Merge in the additionalParameters
        // 4. Use stp_setFormPayload to create the payload
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .custom({ codingKeys in
            let key = codingKeys.last!
            // We must return a valid CodingKey, and we're guaranteed to never receive an empty dictionary.
            return JSONKey(stringValue: URLEncoder.convertToSnakeCase(camelCase: key.stringValue), intValue: key.intValue)
        })
        // This prevents the encoder from throwing when encountering a non-conforming float.
        // We don't have any floats in our API, but it's good to do something sensible here.
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: StripeCodableFloats.PositiveInfinity.rawValue, negativeInfinity: StripeCodableFloats.NegativeInfinity.rawValue, nan: StripeCodableFloats.NaN.rawValue)
        
        // Set up a dictionary on the encoder to fill during encoding
        let dictionary = NSMutableDictionary()
        encoder.userInfo[StripeEncodableSourceStorageKey] = dictionary

        // Apply transformations
        let objectToEncode = IncludeUnknownFields.applyUnknownFieldEncodingTransforms(userInfo: encoder.userInfo, codingPath: [], encodeObject: self)

        // Encode the object to JSON data
        let jsonData = try encoder.encode(objectToEncode)
        // Convert the JSON data into a JSON dictionary
        var jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]

        // Merge in the additional parameters we collected in our encoder userInfo's NSMutableDictionary
        // during encoding
        try jsonDictionary.merge(dictionary as! [String : Any], uniquingKeysWith: Dictionary<String, Any>.stp_deepMerge)
        return jsonDictionary
    }
}

@_spi(STP) public enum StripeCodableFloats: String {
    case PositiveInfinity = "Inf"
    case NegativeInfinity = "-Inf"
    case NaN = "nan"
}

/// A protocol that conforms to both StripeEncodable and StripeDecodable.
/// :nodoc:
public protocol StripeCodable: StripeEncodable, StripeDecodable { }

/// A property wrapper which overrides the Codable behavior to include unknown fields.
/// :nodoc:
@propertyWrapper
public struct IncludeUnknownFields<T> {
    public var wrappedValue: T?
    
    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
}

let StripeEncodableSourceStorageKey = CodingUserInfoKey(rawValue: "StripeEncodableSourceStorageKey")!
let StripeDecodableSourceStorageKey = CodingUserInfoKey(rawValue: "StripeDecodableSourceStorageKey")!

extension IncludeUnknownFields: Encodable where T: StripeEncodable {
    /// :nodoc:
    public func encode(to encoder: Encoder) throws {
        guard let wrappedValue = wrappedValue else {
            // We don't want to encode nil fields.
            // This matches the behavior of the old SDK.
            return
        }
        var container = encoder.singleValueContainer()
        let transformedWrappedValue = IncludeUnknownFields.applyUnknownFieldEncodingTransforms(userInfo: encoder.userInfo, codingPath: encoder.codingPath, encodeObject: wrappedValue)
        try container.encode(transformedWrappedValue)
    }
}

extension IncludeUnknownFields: Decodable where T: StripeDecodable {
    /// :nodoc:
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        var object = try container.decode(T.self)
        object = try IncludeUnknownFields.applyUnknownFieldDecodingTransforms(userInfo: decoder.userInfo, codingPath: decoder.codingPath, decodedObject: object)
        self.wrappedValue = object
   }
}

extension IncludeUnknownFields where T: StripeEncodable {
    static func applyUnknownFieldEncodingTransforms(userInfo: [CodingUserInfoKey : Any],
                                            codingPath: [CodingKey],
                                            encodeObject: T) -> T {
        // If we have additional parameters, add these to the parameters we're sending.
        // Follow the encoder codingPath *up*, then store it in the userInfo
        
        // We can't modify the userInfo of the encoder directly,
        // but we *can* give it a reference to an NSMutableDictionary
        // and mutate that as we go.
        if !encodeObject.additionalParameters.isEmpty,
           let dictionary = userInfo[StripeEncodableSourceStorageKey] as? NSMutableDictionary {
            var mutateDictionary = dictionary
            for path in codingPath {
                // Make sure we're dealing with snake_case.
                let snakeValue = URLEncoder.convertToSnakeCase(camelCase: path.stringValue)
                // If the dictionary exists at that level, retrieve it as an NSMutableDictionary reference
                if let subDictionary = mutateDictionary[snakeValue] as? NSMutableDictionary {
                    mutateDictionary = subDictionary
                } else {
                    // If it does not exist, create an NSMutableDictionary at that level.
                    let newDictionary = NSMutableDictionary()
                    mutateDictionary[snakeValue] = newDictionary
                    mutateDictionary = newDictionary
                }
            }
            // Merge the additionalParameters dictionary onto the existing dictionary.
            mutateDictionary.addEntries(from: encodeObject.additionalParameters)
        }
        // This is hacky, but let's consume the NonEncodable parameters here.
        // It'd be nice if we could convince encodeIfPresent that something is *not* present even
        // when it is, but that doesn't appear to be possible using the
        // auto-synthesized KeyedEncodingContainer.
        // (See https://github.com/apple/swift/blob/main/lib/Sema/DerivedConformanceCodable.cpp#L731
        // for the code that generates these encodeIfPresent calls.)
        // We could also codegen our KeyedEncodingContainer, but I like our current lack of codegen.
        var encodeObjectWithoutParameters = encodeObject
        encodeObjectWithoutParameters._additionalParametersStorage = nil
        // And if the value contains a non-nil _allResponseFieldsStorage,
        // (if it's both Encodable and Decodable *and* we decoded ourselves it, for example)
        // we'll want to avoid decoding that as well.
        if var decodableEncodeObject = encodeObjectWithoutParameters as? StripeDecodable {
            decodableEncodeObject._allResponseFieldsStorage = nil
            encodeObjectWithoutParameters = decodableEncodeObject as! T
        }
        return encodeObjectWithoutParameters
    }
}


extension IncludeUnknownFields where T: StripeDecodable {
    static func applyUnknownFieldDecodingTransforms(userInfo: [CodingUserInfoKey : Any]
, codingPath: [CodingKey], decodedObject: T) throws -> T {
        var object = decodedObject

        // Follow the encoder's codingPath down the userInfo JSON dictionary
        if let originalJSON = userInfo[StripeDecodableSourceStorageKey] as? Data,
           var jsonDictionary = try JSONSerialization.jsonObject(with: originalJSON, options: []) as? [String: Any] {
            for path in codingPath {
                let snakeValue = URLEncoder.convertToSnakeCase(camelCase: path.stringValue)
                // This will always be a dictionary. If it isn't then something is being
                // decoded as an object by JSONDecoder, but a dictionary by JSONSerialization.
                jsonDictionary = jsonDictionary[snakeValue] as! [String : Any]
            }
            // Set the allResponseFields dictionary, so that users can access unknown fields.
            object.allResponseFields = jsonDictionary
            
            // If the wrapped value is also *encodable*, we'll want some special behavior
            // so it can be re-encoded without losing the unknown fields.
            // To do this, we'll:
            // 1. Re-encode it (without unknown fields) to a dictionary
            // 2. Subtract the "known fields" dictionay from our source dictionary
            // 3. Set additionalParameters to the resulting dictionary, giving us
            //    a dictionary of only our missing or uninterpretable fields.
            // When the object is later re-encoded, the additionalParameters will
            // be re-added to the encoded JSON.
            if var encodableValue = object as? StripeEncodable {
                let encodedDictionary = try encodableValue.encodeJSONDictionary()
                encodableValue.additionalParameters = jsonDictionary.subtracting(encodedDictionary)
                object = encodableValue as! T
            }
        }
        return object
    }
}

// This must be public. If it isn't available to StripePayments
// (for example), these `decode/encode` extensions won't override
// the standard library decode, and decoding unknown fields will fail.
/// :nodoc:
@_spi(STP) public extension KeyedDecodingContainer {
    // The synthesizer for Decodable types will treat anything with
    // a property wrapper as non-optional and require it to exist in the JSON.
    // (See https://forums.swift.org/t/using-property-wrappers-with-codable/29804)
    // Work around this by overriding IncludeUnknownFields*Codable decoding to use `decodeIfPresent`.
    /// :nodoc:
    func decode<T>(_ type: IncludeUnknownFields<T>.Type, forKey key: KeyedEncodingContainer<K>.Key) throws -> IncludeUnknownFields<T> where T : StripeDecodable {
        return try decodeIfPresent(type, forKey: key) ?? IncludeUnknownFields<T>(wrappedValue: nil)
    }
    
    private struct AlwaysDecodable: Decodable {}
    
    // Overriding parsing for StripeEnumCodable arrays to include `.unparsable` instead.
    // (Thanks to
    // https://medium.com/mobimeo-technology/safely-decoding-enums-in-swift-1df532af9f42
    // for this strategy!)
    /// :nodoc:
    func decode<T: StripeEnumCodable>(_ type: [T].Type, forKey key: K) throws -> [T] {
        var container = try nestedUnkeyedContainer(forKey: key)
        var result: [T] = []
        while !container.isAtEnd {
            do {
                try result.append(container.decode(T.self))
            } catch Swift.DecodingError.dataCorrupted {
                result.append(.unparsable)
                // Consume this using a non-failable decoder to forward the container
                _ = try container.decode(AlwaysDecodable.self)
            }
        }
        return result
    }
    
    // Same as above, but for nilable properties
    /// :nodoc:
    func decodeIfPresent<T: StripeEnumCodable>(_ type: [T].Type, forKey key: K) throws -> [T]?  {
        do {
            var container = try nestedUnkeyedContainer(forKey: key)
            var result: [T] = []
            while !container.isAtEnd {
                do {
                    try result.append(container.decode(T.self))
                } catch Swift.DecodingError.dataCorrupted {
                    result.append(.unparsable)
                    // Consume this to fast-forward the container
                    _ = try container.decode(AlwaysDecodable.self)
                }
            }
            return result
        } catch Swift.DecodingError.keyNotFound {
            // If the container is nil:
            return nil
        }
    }
    
    // Overriding parsing for StripeEnumCodables to `.unparsable` on failure, or nil on empty.
    // A side effect of this is that StripeEnumCodables must be optional, or they'll
    // fall through to `decode`, which we do not override.
    // (In Objective-C, we could instead swizzle the function and call the underlying implementation!)
    // If we used a property wrapper instead, we could do this without overloading
    // decodeIfPresent directly, and could then support both optional and non-optional enums.
    /// :nodoc:
    func decodeIfPresent<T: StripeEnumCodable>(_ type: T.Type, forKey key: K) throws -> T? {
        do {
            return try decode(T.self, forKey: key)
        } catch Swift.DecodingError.dataCorrupted {
            return .unparsable
        } catch Swift.DecodingError.keyNotFound {
            return nil
        }
    }
}

/// :nodoc:
@_spi(STP) public extension KeyedEncodingContainer {
    // Similar to the above KeyedDecodingContainer, but on the encoding side.
    // This is a workaround to deal with the fact that property wrappers are never nil,
    // which means the auto-generated code calls `encode` instead of `encodeWithPresent`.
    // We'll intercept the compiler-generated encode to only encode non-nil wrappedValues.
    /// :nodoc:
    mutating func encode<T>(_ value: IncludeUnknownFields<T>, forKey key: KeyedEncodingContainer<K>.Key) throws where T : StripeEncodable {
        if value.wrappedValue != nil {
            // We're overriding `encode`, but we can still call `encodeIfPresent`, which
            // does the same thing but works on nil values. (But we know this isn't a nil value,
            // as we.)
            try encodeIfPresent(value, forKey: key)
        }
    }
}

/// This should not be used directly.
/// Use the `additionalParameters` and `allResponseFields` accessors instead.
/// :nodoc:
public struct NonEncodableParameters {
    @_spi(STP) public internal(set) var storage: [String: Any] = [:]
}

extension NonEncodableParameters: Decodable {
    /// :nodoc:
    public init(from decoder: Decoder) throws {
        // no-op
    }
}

extension NonEncodableParameters: Encodable {
    /// :nodoc:
    public func encode(to encoder: Encoder) throws {
        // no-op
    }
}

extension NonEncodableParameters: Equatable {
    /// :nodoc:
    public static func == (lhs: NonEncodableParameters, rhs: NonEncodableParameters) -> Bool {
        return NSDictionary(dictionary: lhs.storage).isEqual(to: rhs.storage)
    }
}

// The default debugging behavior for structs is to print *everything*,
// which is undesirable as it could contain card numbers or other PII.
// For now, override it to just give an overview of the struct.
extension NonEncodableParameters: CustomStringConvertible, CustomDebugStringConvertible, CustomLeafReflectable {
    /// :nodoc:
    public var customMirror: Mirror {
        return Mirror(reflecting:self.description)
    }

    /// :nodoc:
    public var debugDescription: String {
        return description
    }
    
    /// :nodoc:
    public var description: String {
        return "\(storage.count) fields"
    }
}

extension JSONDecoder {
    static func decode<T: StripeDecodable>(jsonData: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .custom({ codingKeys in
            let key = codingKeys.last!
            // We must return a valid CodingKey, and we're guaranteed to never receive an empty dictionary.
            return JSONKey(stringValue: URLEncoder.convertToCamelCase(snakeCase: key.stringValue), intValue: key.intValue)
        })
        // All Stripe dates use .secondsSince1970
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.userInfo[StripeDecodableSourceStorageKey] = jsonData
        var object = try decoder.decode(T.self, from: jsonData)
        object = try IncludeUnknownFields.applyUnknownFieldDecodingTransforms(userInfo: decoder.userInfo, codingPath: [], decodedObject: object)
        return object
    }
}

/// A CodingKey used for JSON coding.
internal struct JSONKey: CodingKey {
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
