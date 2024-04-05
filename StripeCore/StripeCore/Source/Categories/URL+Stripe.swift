//
//  URL+Stripe.swift
//  StripeCore
//
//  Created by David Estes on 4/4/24.
//

import Foundation

@_spi(STP) public class STPURL {
    @_spi(STP) public static func validUrl(string value: Any?) -> URL? {
        if #available(iOS 17.0, *) {
            return URL(string: value as? String ?? "", encodingInvalidCharacters: false)
        } else {
            return URL(string: value as? String ?? "")
        }
    }
}
