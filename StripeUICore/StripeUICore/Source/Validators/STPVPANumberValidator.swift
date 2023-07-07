//
//  STPVPANumberValidator.swift
//  StripeUICore
//
//  Created by Nick Porter on 9/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public class STPVPANumberValidator: NSObject {
    public class func stringIsValidPartialVPANumber(_ string: String?) -> Bool {
        guard let string = string else {
            return true  // an empty string isn't *invalid*
        }
        return (string.components(separatedBy: "@").count - 1) <= 1
    }

    public class func stringIsValidVPANumber(_ string: String?) -> Bool {
        if string == nil || (string?.count ?? 0) > 30 {
            return false
        }
        // regex from https://stackoverflow.com/questions/55143204/how-to-validate-a-upi-id-using-regex
        let pattern = "[a-zA-Z0-9.\\-_]{2,256}@[a-zA-Z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: string?.lowercased())
    }
}
