//
//  STPNumericStringValidator.swift
//  StripeCore
//
//  Created by Cameron Sabol on 3/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(InternalOnlyAPI) public enum STPTextValidationState: Int {
    case empty
    case incomplete
    case complete
    case invalid
}

@_spi(InternalOnlyAPI) open class STPNumericStringValidator: NSObject {
    /// Whether or not the target string contains only numeric characters.
    @_spi(InternalOnlyAPI) public class func isStringNumeric(_ string: String) -> Bool {
        return
            (string as NSString).rangeOfCharacter(from: CharacterSet.stp_invertedAsciiDigit)
            .location
            == NSNotFound
    }

    /// Returns a copy of the passed string with all non-numeric characters removed.
    @_spi(InternalOnlyAPI) public class func sanitizedNumericString(for string: String) -> String {
        return string.stp_stringByRemovingCharacters(from: CharacterSet.stp_invertedAsciiDigit)
    }
}
