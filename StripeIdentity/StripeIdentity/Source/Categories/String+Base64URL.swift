//
//  String+Base64URL.swift
//  StripeIdentity
//
//  Created by Stripe on 7/23/26.
//

import Foundation

extension String {
    var base64URLDecodedData: Data? {
        let illegalCharacters = CharacterSet(charactersIn: "+/ \n")
        guard !hasSuffix("="), rangeOfCharacter(from: illegalCharacters) == nil else {
            return nil
        }

        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        switch base64.count % 4 {
        case 0:
            break
        case 2:
            base64 += "=="
        case 3:
            base64 += "="
        default:
            return nil
        }
        return Data(base64Encoded: base64)
    }
}
