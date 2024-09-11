//
//  STPCardBrandChoice.swift
//  StripePayments
//
//  Created by Nick Porter on 8/29/23.
//

import Foundation

/// Card brand choice information for an intent
/// You cannot directly instantiate an `STPCardBrandChoice`.
/// - seealso: https://stripe.com/docs/card-brand-choice
class STPCardBrandChoice: NSObject {
    
    /// Determines if this intent is eligible for card brand choice
    let eligible: Bool
    
    /// :nodoc:
    let allResponseFields: [AnyHashable: Any]
    
    /// :nodoc:
    @objc override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPCardBrandChoice.self), self),
            // Properties
            "eligible = \(String(describing: eligible))",
        ]
        
        return "<\(props.joined(separator: "; "))>"
    }
    
    private init(
        eligible: Bool,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.eligible = eligible
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPCardBrandChoice: STPAPIResponseDecodable {
    
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response else {
            return nil
        }
        
        return STPCardBrandChoice(
            eligible: dict["eligible"] as? Bool ?? false,
            allResponseFields: dict
        ) as? Self
    }
    
}

extension STPCardBrandChoice: Encodable {
    enum CodingKeys: String, CodingKey {
        case eligible
        case allResponseFields
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eligible, forKey: .eligible)
        var allResponseFieldsContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: .allResponseFields)
        try encodeValue(fromObjectContainer: &allResponseFieldsContainer, map: allResponseFields)
    }
    
    func encodeValue(fromObjectContainer container: inout KeyedEncodingContainer<JSONCodingKeys>, map: [AnyHashable:Any]) throws {
        for k in map.keys {
            let value = map[k]
            let encodingKey = JSONCodingKeys(anyhashableValue: k)
            
            if let value = value as? String {
                try container.encode(value, forKey: encodingKey)
            } else if let value = value as? Int {
                try container.encode(value, forKey: encodingKey)
            } else if let value = value as? Double {
                try container.encode(value, forKey: encodingKey)
            } else if let value = value as? Bool {
                try container.encode(value, forKey: encodingKey)
            } else if let value = value as? [AnyHashable: Any] {
                var keyedContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: encodingKey)
                try encodeValue(fromObjectContainer: &keyedContainer, map: value)
            } else if let value = value as? [Any] {
                var unkeyedContainer = container.nestedUnkeyedContainer(forKey: encodingKey)
                try encodeValue(fromArrayContainer: &unkeyedContainer, arr: value)
            } else {
                try container.encodeNil(forKey: encodingKey)
            }
        }
    }
    
    func encodeValue(fromArrayContainer container: inout UnkeyedEncodingContainer, arr: [Any]) throws {
        for value in arr {
            if let value = value as? String {
                try container.encode(value)
            } else if let value = value as? Int {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? [AnyHashable: Any] {
                var keyedContainer = container.nestedContainer(keyedBy: JSONCodingKeys.self)
                try encodeValue(fromObjectContainer: &keyedContainer, map: value)
            } else if let value = value as? [Any] {
                var unkeyedContainer = container.nestedUnkeyedContainer()
                try encodeValue(fromArrayContainer: &unkeyedContainer, arr: value)
            } else {
                try container.encodeNil()
            }
        }
    }
}

struct JSONCodingKeys: CodingKey {
    var stringValue: String
    var anyhashableValue: AnyHashable
    init(anyhashableValue: AnyHashable) {
        self.stringValue = "\(anyhashableValue)"
        self.anyhashableValue = anyhashableValue
    }
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.anyhashableValue = stringValue
    }
    
    var intValue: Int?
    
    init?(intValue: Int) { 
        self.stringValue = "\(intValue)"
        self.anyhashableValue = intValue
    }
}
