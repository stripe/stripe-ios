//
//  CallSetterWithSerializableValueSender.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/7/24.
//

import Foundation

struct CallSetterWithSerializableValueSender<Value: Codable & Equatable>: MessageSender {
    struct Payload: Codable, Equatable {
        /// Name of the component-specific JS setter function on the component (e.g. `setFullTermsOfService`)
        let setter: String
        /// Args value to pass to the setter function
        let value: Value
    }
    let name: String = "callSetterWithSerializableValue"
    let payload: Payload
    private(set) var customKeyEncodingStrategy: CustomKeyCodingStrategy?
}
