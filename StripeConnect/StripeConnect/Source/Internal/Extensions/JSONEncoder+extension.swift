//
//  JSONEncoder+extension.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/4/24.
//

import Foundation

extension JSONEncoder {
    static var connectEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        // Ensure keys are sorted for test stability.
        encoder.outputFormatting = .sortedKeys
        return encoder
    }
}
