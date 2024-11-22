//
//  JSONSerialization+extension.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/4/24.
//

import Foundation

extension JSONSerialization {
    static func connectData(withJSONObject object: Any) throws -> Data {
        // Ensure keys are sorted for test stability.
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .fragmentsAllowed])
    }
}
