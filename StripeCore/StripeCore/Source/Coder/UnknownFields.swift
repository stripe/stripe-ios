//
//  UnknownFields.swift
//  StripeCore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension UnknownFieldsEncodable {
    func applyUnknownFieldEncodingTransforms(
        userInfo: [CodingUserInfoKey: Any],
        codingPath: [CodingKey]
    ) {
        if !(userInfo[StripeIncludeUnknownFieldsKey] as? Bool ?? false) {
            // Don't include unknown fields.
            return
        }
        // If we have additional parameters, add these to the parameters we're sending.
        // Follow the encoder codingPath *up*, then store it in the userInfo

        // We can't modify the userInfo of the encoder directly,
        // but we *can* give it a reference to an NSMutableDictionary
        // and mutate that as we go.
        if !self.additionalParameters.isEmpty,
            let dictionary = userInfo[UnknownFieldsEncodableSourceStorageKey]
                as? NSMutableDictionary
        {
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
            mutateDictionary.addEntries(from: self.additionalParameters)
        }
    }
}

extension UnknownFieldsDecodable {
    mutating func applyUnknownFieldDecodingTransforms(
        userInfo: [CodingUserInfoKey: Any],
        codingPath: [CodingKey]
    ) throws {
        var object = self

        // Follow the encoder's codingPath down the userInfo JSON dictionary
        if let originalJSON = userInfo[UnknownFieldsDecodableSourceStorageKey] as? Data,
            var jsonDictionary = try JSONSerialization.jsonObject(with: originalJSON, options: [])
                as? [String: Any]
        {
            for path in codingPath {
                let snakeValue = URLEncoder.convertToSnakeCase(camelCase: path.stringValue)
                // This will always be a dictionary. If it isn't then something is being
                // decoded as an object by JSONDecoder, but a dictionary by JSONSerialization.
                jsonDictionary = jsonDictionary[snakeValue] as! [String: Any]
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
            if var encodableValue = object as? UnknownFieldsEncodable {
                let encodedDictionary = try encodableValue.encodeJSONDictionary(
                    includingUnknownFields: false
                )
                encodableValue.additionalParameters = jsonDictionary.subtracting(encodedDictionary)
                object = encodableValue as! Self
            }
        }
        self = object
    }
}

let StripeIncludeUnknownFieldsKey = CodingUserInfoKey(rawValue: "_StripeIncludeUnknownFieldsKey")!

let UnknownFieldsEncodableSourceStorageKey = CodingUserInfoKey(
    rawValue: "_UnknownFieldsEncodableSourceStorageKey"
)!
let UnknownFieldsDecodableSourceStorageKey = CodingUserInfoKey(
    rawValue: "_UnknownFieldsDecodableSourceStorageKey"
)!
