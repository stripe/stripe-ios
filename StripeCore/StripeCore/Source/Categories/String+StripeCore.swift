//
//  String+StripeCore.swift
//  StripeCore
//
//  Created by Mel Ludowise on 9/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) extension String {
    public func stp_stringByRemovingCharacters(from characterSet: CharacterSet) -> String {
        return String(unicodeScalars.filter { !characterSet.contains($0) })
    }

    public var isSecretKey: Bool {
        return self.hasPrefix("sk_")
    }

    public var nonEmpty: String? {
        stringIfHasContentsElseNil(self)
    }
    
    @_spi(STP) public var sanitizedKey: String {
        return (self.isSecretKey || self.hasPrefix("uk_"))
            ? "[REDACTED_LIVE_KEY]" : self
    }
}

@_spi(STP) public func stringIfHasContentsElseNil(
    _ string: String?
) ->  // MARK: -
    String?
{
    guard let string = string,
        !string.isEmpty
    else {
        return nil
    }
    return string
}
