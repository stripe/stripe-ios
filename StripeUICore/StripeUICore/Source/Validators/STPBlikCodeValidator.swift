//
//  STPBlikCodeValidator.swift
//  StripeUICoreTests
//
//  Created by Fionn Barrett on 07/07/2023.
//

import Foundation

@_spi(STP) public class STPBlikCodeValidator {
    public class func stringIsValidBlikCode(_ string: String?) -> Bool {
        if string == nil || (string?.count ?? 0) > 6 {
            return false
        }
        let pattern = "^[0-9]{6}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: string)
    }
}
